# ryoko timer: sleep for a duration and notify when it ends.

usage() {
  cat <<'EOF'
用法:
  ryoko timer <时长> [消息]
  ryoko timer --bg <时长> [消息]
  ryoko timer --list
  ryoko timer --cancel [id|all]

时长示例: 25m、1h30m、90s（必须带单位）。
EOF
}

parse_duration() {
  local raw=$1 total=0 number unit
  [[ $raw =~ ^([0-9]+[smhd])+$ ]] || return 1
  while [[ $raw =~ ^([0-9]+)([smhd])(.*)$ ]]; do
    number=${BASH_REMATCH[1]}
    unit=${BASH_REMATCH[2]}
    raw=${BASH_REMATCH[3]}
    case "$unit" in
      s) total=$((total + number)) ;;
      m) total=$((total + number * 60)) ;;
      h) total=$((total + number * 3600)) ;;
      d) total=$((total + number * 86400)) ;;
    esac
  done
  printf '%s\n' "$total"
}

notify() {
  local message=$1
  if [ "${RYOKO_DESKTOP:-0}" = 1 ] && have noctalia; then
    if noctalia msg notification-show "ryoko timer" "$message" >/dev/null 2>&1; then
      return 0
    fi
  fi
  if have notify-send; then
    notify-send "ryoko timer" "$message" || true
  fi
}

timer_dir="${RYOKO_CACHE}/timers"
mkdir -p "$timer_dir"

case "${1:-}" in
  -h | --help)
    usage
    exit 0
    ;;
  --list)
    found=0
    for meta in "$timer_dir"/*; do
      if [ ! -e "$meta" ]; then continue; fi
      IFS=$'\t' read -r id pid end message <"$meta" || continue
      if kill -0 "$pid" 2>/dev/null; then
        remaining=$((end - $(date +%s)))
        if [ "$remaining" -lt 0 ]; then remaining=0; fi
        minutes=$((remaining / 60))
        seconds=$((remaining % 60))
        printf '%s  剩余 %dm%02ds  %s\n' "$id" "$minutes" "$seconds" "$message"
        found=1
      else
        rm -f "$meta"
      fi
    done
    if [ "$found" = 0 ]; then
      note "没有正在运行的计时器"
    fi
    exit 0
    ;;
  --cancel)
    target=${2:-all}
    cancelled=0
    for meta in "$timer_dir"/*; do
      if [ ! -e "$meta" ]; then continue; fi
      IFS=$'\t' read -r id pid _ _ <"$meta" || continue
      if [ "$target" != all ] && [ "$target" != "$id" ]; then
        continue
      fi
      pkill -TERM -P "$pid" 2>/dev/null || true
      kill -TERM "$pid" 2>/dev/null || true
      rm -f "$meta"
      cancelled=$((cancelled + 1))
    done
    printf '已取消 %s 个计时器\n' "$cancelled"
    exit 0
    ;;
esac

background=0
if [ "${1:-}" = --bg ]; then
  background=1
  shift
fi
if [ $# -eq 0 ]; then
  usage
  exit 1
fi
duration=$1
shift
seconds=$(parse_duration "$duration") || die "无法解析时长: $duration"
if [ $# -gt 0 ]; then
  message="$*"
else
  message="计时结束"
fi

if [ "$background" = 1 ]; then
  end=$(( $(date +%s) + seconds ))
  id="$(date +%s)-$$-$RANDOM"
  meta="$timer_dir/$id"
  nohup bash -c '
    sleep "$1"
    if [ "$4" = 1 ] && command -v noctalia >/dev/null 2>&1; then
      noctalia msg notification-show "ryoko timer" "$2" >/dev/null 2>&1 || true
    elif command -v notify-send >/dev/null 2>&1; then
      notify-send "ryoko timer" "$2" || true
    fi
    rm -f "$3"
  ' _ "$seconds" "$message" "$meta" "$RYOKO_DESKTOP" >/dev/null 2>&1 &
  pid=$!
  printf '%s\t%s\t%s\t%s\n' "$id" "$pid" "$end" "$message" >"$meta"
  printf '后台计时 %s（id: %s），到时通知\n' "$duration" "$id"
else
  printf '计时 %s ...\n' "$duration"
  sleep "$seconds"
  notify "$message"
  printf '计时结束: %s\n' "$message"
fi
