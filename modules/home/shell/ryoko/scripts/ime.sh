# ryoko ime: control Fcitx5/Rime and the xhup dictionary tools.

usage() {
  cat <<'EOF'
用法:
  ryoko ime status
  ryoko ime restart
  ryoko ime deploy
  ryoko ime add <词语> [--code ...] [--category ...] [--yes]
  ryoko ime lookup <词语>
  ryoko ime sync          # 从 ~/src/xhup-dicts 拉取后重新部署
EOF
}

action=${1:-status}
shift || true

case "$action" in
  status)
    if have fcitx5-remote && fcitx5-remote --check >/dev/null 2>&1; then
      printf 'fcitx5: running (state %s)\n' "$(fcitx5-remote)"
    else
      printf 'fcitx5: stopped\n'
    fi
    ;;
  restart)
    if have fcitx5-remote && fcitx5-remote --check >/dev/null 2>&1; then
      fcitx5-remote -e || true
      sleep 0.5
    fi
    fcitx5 -d
    note "fcitx5 已重启"
    ;;
  deploy)
    have xhup-add-word || die "xhup-add-word 未安装（需要 my.desktop.enable）"
    xhup-add-word deploy
    ;;
  add)
    have xhup-add-word || die "xhup-add-word 未安装（需要 my.desktop.enable）"
    exec xhup-add-word add "$@"
    ;;
  lookup)
    have xhup-lookup || die "xhup-lookup 未安装（需要 my.desktop.enable）"
    exec xhup-lookup "$@"
    ;;
  sync)
    have xhup-add-word || die "xhup-add-word 未安装（需要 my.desktop.enable）"
    if [ -d "$RYOKO_XHUP_DIR/.git" ]; then
      git -C "$RYOKO_XHUP_DIR" pull --rebase --autostash
    else
      note "提示: $RYOKO_XHUP_DIR 不是 git 仓库，跳过远端同步" >&2
    fi
    xhup-add-word deploy
    ;;
  *)
    usage
    exit 1
    ;;
esac
