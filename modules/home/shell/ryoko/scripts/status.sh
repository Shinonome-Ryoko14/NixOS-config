# ryoko status: summarize the repository, generations and desktop services.

usage() {
  cat <<'EOF'
用法: ryoko status
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    -h | --help) usage; exit 0 ;;
    *) die "未知参数: $1" ;;
  esac
done
config_check

printf '== 配置仓库 ==\n'
git -C "$RYOKO_FLAKE" status --short --branch

printf '\n== 系统 ==\n'
generations=$(nixos-rebuild list-generations --json 2>/dev/null || true)
if [ -n "$generations" ]; then
  printf '%s\n' "$generations" | jq -r '.[] | select(.current) | "当前代际: \(.generation)  构建于 \(.date)"'
  latest=$(printf '%s\n' "$generations" | jq -r '[.[].generation] | max')
  current=$(printf '%s\n' "$generations" | jq -r '.[] | select(.current) | .generation')
  if [ "$latest" != "$current" ]; then
    printf '提示: 有更新的代际 %s（当前 %s）\n' "$latest" "$current"
  fi
fi

current_system=$(readlink -f /run/current-system 2>/dev/null || true)
booted_system=$(readlink -f /run/booted-system 2>/dev/null || true)
if [ -n "$current_system" ] && [ -n "$booted_system" ] && [ "$current_system" != "$booted_system" ]; then
  printf '提示: 当前系统与启动系统不同，建议重启\n'
fi

df -h / | tail -1

printf '\n== 服务 ==\n'
service_state() {
  case "$1" in
    niri)
      if pgrep -x niri >/dev/null 2>&1; then echo running; else echo -; fi
      ;;
    dms)
      if have dms && dms ipc call lock status >/dev/null 2>&1; then echo running; else echo -; fi
      ;;
    noctalia)
      if have noctalia && noctalia msg wallpaper-get >/dev/null 2>&1; then echo running; else echo -; fi
      ;;
    fcitx5)
      if have fcitx5-remote && fcitx5-remote --check >/dev/null 2>&1; then echo running; else echo -; fi
      ;;
  esac
}
for process in niri dms noctalia fcitx5; do
  printf '  %-10s %s\n' "$process" "$(service_state "$process")"
done

if have systemctl; then
  failed=$(systemctl --failed --no-legend --plain 2>/dev/null | wc -l)
  printf '  failed units: %s\n' "$failed"
fi
