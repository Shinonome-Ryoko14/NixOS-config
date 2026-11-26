# ryoko where: locate a keyword in the configuration repository.

usage() {
  cat <<'EOF'
用法: ryoko where [--open] <关键词>

--open 用 $EDITOR（默认 nvim）打开第一个匹配位置。
EOF
}

open=0
term=""
while [ $# -gt 0 ]; do
  case "$1" in
    --open) open=1; shift ;;
    -h | --help) usage; exit 0 ;;
    --) shift; while [ $# -gt 0 ]; do term+="$1 "; shift; done ;;
    -*) die "未知参数: $1" ;;
    *) term+="$1 "; shift ;;
  esac
done
term=${term% }
if [ -z "$term" ]; then
  usage
  exit 1
fi

config_check
matches=$(rg -n --fixed-strings \
  --glob '!flake.lock' --glob '!result*' --glob '!.git' \
  -e "$term" "$RYOKO_FLAKE" || true)
if [ -z "$matches" ]; then
  die "没有找到: $term"
fi
printf '%s\n' "$matches"

if [ "$open" = 1 ]; then
  first=$(printf '%s\n' "$matches" | head -1)
  file=${first%%:*}
  rest=${first#*:}
  line=${rest%%:*}
  exec "${EDITOR:-nvim}" "+$line" "$file"
fi
