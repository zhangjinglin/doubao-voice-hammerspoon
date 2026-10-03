# 豆包语音监控 for Hammerspoon

长按豆包输入法语音键说话时，自动把系统静音（避免外放干扰录音）；
松开结束语音后，自动恢复声音，并把输入法切到英文 ABC。

## 为什么不用按键监听

豆包的语音键默认是按住 Fn（也可以改成其他键，但不管设成哪个，
长按时按键事件都会被输入法层吞掉），Hammerspoon 的 `eventtap`
在长按场景下根本收不到松开事件，短按还会混进合成的按键事件、
松开后输入源被抢回。
所以改盯**语音悬浮窗本身**：它出现 = 语音开始，它消失 = 语音结束，
这个信号谁也吞不掉。

## 它做了什么

- 常驻 Swift 小进程（`doubao_voice_watch`）轮询系统底层窗口列表，
  只看 `豆包输入法` 的浮窗（实测语音条为 layer=3），变化时输出一行文本
- Hammerspoon 用 `hs.task` 拉起它，读到 `VOICE ON` 就静音，
  读到 `VOICE OFF` 就恢复静音状态、延迟切 ABC
- CPU 占用约 0.1%~0.4%，可忽略

## 安装

```bash
git clone <你的仓库地址> doubao-voice-hammerspoon
cd doubao-voice-hammerspoon
chmod +x ./install.sh
./install.sh
```

已有自己 Hammerspoon 配置的，安装脚本会先备份再让你选是否覆盖，
也可以手动把 `init.lua` 的内容合并进去。

装完后：打开 Hammerspoon → 授予「辅助功能」权限 → Reload Config。

## 文件说明

| 文件 | 说明 |
| --- | --- |
| `init.lua` | Hammerspoon 配置（单文件，全部逻辑） |
| `doubao_voice_watch.swift` | 监控进程源码，输出 `VOICE ON` / `VOICE OFF` |
| `install.sh` | 一键安装：装 Hammerspoon、编译 Swift、备份并安装配置 |

## 可配置项（`init.lua` 顶部）

- `ENGLISH_SOURCE_ID`：语音结束后切到的输入法，默认英文 ABC
- `SETTLE_DELAY`：结束后延迟多久再切，默认 0.3 秒
