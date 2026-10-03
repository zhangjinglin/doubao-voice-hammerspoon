#!/bin/bash
# 一键安装豆包语音监控
# 用法：./install.sh [--force]
set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
HS_DIR="$HOME/.hammerspoon"
BIN_DIR="$HS_DIR/bin"

echo "== 1/3 检查 Hammerspoon =="
if [ ! -d "/Applications/Hammerspoon.app" ]; then
    echo "未找到 Hammerspoon，正在安装..."
    brew install --cask hammerspoon
else
    echo "Hammerspoon 已安装"
fi

echo "== 2/3 编译语音监控进程 =="
mkdir -p "$BIN_DIR"
swiftc -O -o "$BIN_DIR/doubao_voice_watch" "$REPO_DIR/doubao_voice_watch.swift"
echo "编译完成：$BIN_DIR/doubao_voice_watch"

echo "== 3/3 安装 Hammerspoon 配置 =="
if [ -f "$HS_DIR/init.lua" ]; then
    if cmp -s "$REPO_DIR/init.lua" "$HS_DIR/init.lua"; then
        echo "配置已是最新，跳过"
    elif [ "$1" == "--force" ]; then
        cp "$HS_DIR/init.lua" "$HS_DIR/init.lua.bak.$(date +%Y%m%d%H%M%S)"
        echo "旧配置已备份"
        cp "$REPO_DIR/init.lua" "$HS_DIR/init.lua"
    else
        echo "检测到你已有自己的 init.lua，是否覆盖？(y/N)"
        read -r answer
        if [ "$answer" == "y" ] || [ "$answer" == "Y" ]; then
            cp "$HS_DIR/init.lua" "$HS_DIR/init.lua.bak.$(date +%Y%m%d%H%M%S)"
            echo "旧配置已备份"
            cp "$REPO_DIR/init.lua" "$HS_DIR/init.lua"
        else
            echo "保留现有配置。请手动把本仓库 init.lua 的内容合并进你的配置。"
            exit 0
        fi
    fi
else
    mkdir -p "$HS_DIR"
    cp "$REPO_DIR/init.lua" "$HS_DIR/init.lua"
fi

echo ""
echo "安装完成！接下来："
echo "1. 打开 Hammerspoon，授予「辅助功能」权限"
echo "2. 点击菜单栏图标 -> Reload Config"
echo "3. 长按豆包语音键说句话，验证自动静音 + 结束切 ABC"
