# ryoko power: lock, suspend, reboot or shut down.

usage() {
  cat <<'EOF'
用法:
  ryoko lock
  ryoko suspend
  ryoko reboot [-y]
  ryoko shutdown [-y]
  ryoko power              用 fzf 选择操作
EOF
}

action=${1:-menu}
shift || true
for argument in "$@"; do
  case "$argument" in
    -y | --yes) export RYOKO_ASSUME_YES=1 ;;
    -h | --help) usage; exit 0 ;;
    *) die "未知参数: $argument" ;;
  esac
done

do_lock() {
  if have dms && dms ipc call lock status >/dev/null 2>&1; then
    dms ipc call lock lock
  elif have loginctl; then
    loginctl lock-session
  else
    die "找不到可用的锁屏命令"
  fi
}

case "$action" in
  lock)
    do_lock
    ;;
  suspend)
    systemctl suspend || sudo systemctl suspend
    ;;
  reboot)
    confirm "确认重启？" || exit 0
    systemctl reboot || sudo systemctl reboot
    ;;
  shutdown | poweroff)
    confirm "确认关机？" || exit 0
    systemctl poweroff || sudo systemctl poweroff
    ;;
  menu)
    [ -t 1 ] || die "需要终端"
    choice=$(printf '%s\n' 'lock 锁屏' 'suspend 挂起' 'reboot 重启' 'shutdown 关机' | fzf --prompt '电源> ') || true
    if [ -z "$choice" ]; then
      exit 0
    fi
    exec ryoko-power "${choice%% *}"
    ;;
  *)
    usage
    exit 1
    ;;
esac
