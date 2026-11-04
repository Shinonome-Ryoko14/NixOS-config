#!/usr/bin/env bash
# Waybar 自定义模块：DMS 通知中心状态
# DMS 负责通知守护，Noctalia 的通知面板保持关闭。
set -euo pipefail

dnd="$(dms ipc call notifications getDoNotDisturb 2>/dev/null | tr -d '\n' | tr '[:upper:]' '[:lower:]' || true)"

case "$dnd" in
  *true*|*on*|*enable*|*enabled*)
    printf '{"text": "", "alt": "dnd", "tooltip": "请勿打扰已开启\\n左键：打开通知中心\\n右键：关闭请勿打扰", "class": "dnd"}\n'
    ;;
  *)
    printf '{"text": "", "alt": "active", "tooltip": "左键：打开通知中心\\n右键：开启请勿打扰", "class": "active"}\n'
    ;;
esac
