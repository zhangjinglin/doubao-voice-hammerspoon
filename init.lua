-- ============================================
-- 豆包语音监控：开始自动静音，结束恢复声音并切 ABC
-- 单文件独立配置，放到 ~/.hammerspoon/init.lua 即可用
-- 依赖：~/.hammerspoon/bin/doubao_voice_watch（见 install.sh 编译安装）
-- ============================================

-- ===== 可配置项 =====
local ENGLISH_SOURCE_ID = "com.apple.keylayout.ABC" -- 语音结束后切到的输入法
local SETTLE_DELAY = 0.3                            -- 结束后延迟多久再切（盖过输入法的抢回）
local FALLBACK_OUTPUT = "Mac mini Speakers"         -- 当前输出设备不支持软件静音时（如 HDMI 显示器），切到这个可控设备
local WATCH_BIN = os.getenv("HOME") .. "/.hammerspoon/bin/doubao_voice_watch"
-- ====================

local task = nil
local taskBuf = ""
local prevMuted = false
local origDevice = nil
local switchedToFallback = false
local fallbackPrevMuted = false
local fallbackPrevVolume = nil

local function muteCurrent()
    local dev = hs.audiodevice.defaultOutputDevice()
    if not dev then
        return false
    end
    origDevice = dev
    prevMuted = dev:muted() or false
    dev:setMuted(true)
    if dev:muted() then
        print("[doubao-voice] muted on " .. tostring(dev:name()))
        return true
    end
    -- 当前设备不支持软件静音（如 HDMI 显示器），切到可控设备
    local fb = hs.audiodevice.findOutputByName(FALLBACK_OUTPUT)
    if fb then
        fallbackPrevMuted = fb:muted() or false
        fallbackPrevVolume = fb:volume()
        fb:setMuted(true)
        fb:setVolume(0)
        fb:setDefaultOutputDevice()
        switchedToFallback = true
        print("[doubao-voice] device unmuttable, switched to " .. FALLBACK_OUTPUT)
        return true
    end
    print("[doubao-voice] mute failed, no fallback device")
    return false
end

local function unmuteCurrent()
    if switchedToFallback then
        switchedToFallback = false
        if origDevice then
            origDevice:setDefaultOutputDevice()
            print("[doubao-voice] switched back to " .. tostring(origDevice:name()))
            origDevice = nil
        end
        local fb = hs.audiodevice.findOutputByName(FALLBACK_OUTPUT)
        if fb then
            if fallbackPrevVolume then
                fb:setVolume(fallbackPrevVolume)
            end
            fb:setMuted(fallbackPrevMuted)
        end
    else
        local dev = hs.audiodevice.defaultOutputDevice()
        if dev then
            dev:setMuted(prevMuted)
        end
        print("[doubao-voice] unmuted, restored=" .. tostring(prevMuted))
    end
end

local function onVoiceStart(info)
    print("[doubao-voice] VOICE ON " .. tostring(info or ""))
    muteCurrent()
end

local function onVoiceEnd()
    print("[doubao-voice] VOICE OFF")
    unmuteCurrent()
    hs.timer.doAfter(SETTLE_DELAY, function()
        local cur = hs.keycodes.currentSourceID()
        if cur ~= ENGLISH_SOURCE_ID then
            hs.keycodes.currentSourceID(ENGLISH_SOURCE_ID)
            print("[doubao-voice] switched, now=" .. tostring(hs.keycodes.currentSourceID()))
        end
    end)
end

local function handleLine(line)
    if line:match("^VOICE ON") then
        onVoiceStart(line:sub(10))
    elseif line:match("^VOICE OFF") then
        onVoiceEnd()
    end
end

local function startTask()
    taskBuf = ""
    task = hs.task.new(WATCH_BIN, function(exitCode, stdOut, stdErr)
        print(string.format("[doubao-voice] watcher exited(%s), restart in 1s", tostring(exitCode)))
        task = nil
        hs.timer.doAfter(1, function()
            if task == nil then
                startTask()
            end
        end)
        return true
    end, function(t, stdOut, stdErr)
        if stdOut and #stdOut > 0 then
            taskBuf = taskBuf .. stdOut
            while true do
                local i = taskBuf:find("\n")
                if not i then
                    break
                end
                handleLine(taskBuf:sub(1, i - 1))
                taskBuf = taskBuf:sub(i + 1)
            end
        end
        return true
    end)
    task:start()
    print("[doubao-voice] watcher started")
end

startTask()
hs.alert.show("豆包语音监控已启动")
