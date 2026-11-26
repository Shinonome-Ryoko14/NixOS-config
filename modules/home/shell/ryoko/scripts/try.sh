# ryoko try: enter a temporary shell containing the given packages.

usage() {
  cat <<'EOF'
用法: ryoko try <软件包>...

等价于 nix shell nixpkgs#<软件包>，退出后不留下任何东西。
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    -h | --help) usage; exit 0 ;;
    --) shift; break ;;
    *) break ;;
  esac
done
if [ $# -eq 0 ]; then
  usage
  exit 1
fi

installables=()
for raw in "$@"; do
  installables+=("nixpkgs#${raw#nixpkgs#}")
done
exec nix shell "${installables[@]}"
