# ryoko gc: garbage-collect old generations. Dry-run unless --yes is given.

usage() {
  cat <<'EOF'
用法: ryoko gc [--days N] [--yes]

默认只打印将被删除的内容；确认后加 --yes 执行。
EOF
}

days=30
assume_yes=0
while [ $# -gt 0 ]; do
  case "$1" in
    --days) days=${2:?缺少天数}; shift 2 ;;
    --days=*) days=${1#*=}; shift ;;
    -y | --yes) assume_yes=1; shift ;;
    -h | --help) usage; exit 0 ;;
    *) die "未知参数: $1" ;;
  esac
done

if [ "$assume_yes" = 1 ]; then
  sudo nix-collect-garbage --delete-older-than "${days}d"
else
  note "dry-run：删除 ${days} 天前的代际；确认后加 --yes 执行"
  sudo nix-collect-garbage --dry-run --delete-older-than "${days}d"
fi
