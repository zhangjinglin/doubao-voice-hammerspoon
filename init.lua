-- ============================================
-- 豆包语音监控：开始自动静音，结束恢复声音并切 ABC
-- 单文件独立配置，放到 ~/.hammerspoon/init.lua 即可用
-- 依赖：~/.hammerspoon/bin/doubao_voice_watch（见 install.sh 编译安装）
-- ============================================

-- ===== 可配置项 =====
local ENGLISH_SOURCE_ID = "com.apple.keylayout.ABC" -- 语音结束后切到的输入法
local SETTLE_DELAY = 0.3                            -- 结束后延迟多久再切（盖过输入法的抢回）
local WATCH_BIN = os.getenv("HOME") .. "/.hammerspoon/bin/doubao_voice_watch"
-- ====================

local task = nil
local taskBuf = ""
local prevMuted = false

local function setMuted(m)
    local dev = hs.audiodevice.defaultOutputDevice()
    if dev then
        dev:setMuted(m)
    end
end

local function onVoiceStart(info)
    print("[doubao-voice] VOICE ON " .. tostring(info or ""))
    local dev = hs.audiodevice.defaultOutputDevice()
    prevMuted = dev and dev:muted() or false
    setMuted(true)
end

local function onVoiceEnd()
    print("[doubao-voice] VOICE OFF")
    setMuted(prevMuted)
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
