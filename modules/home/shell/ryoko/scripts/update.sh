# ryoko update: update flake inputs, build and offer to switch.

usage() {
  cat <<'EOF'
用法: ryoko update [输入...]

不带参数时更新全部 flake 输入；也可以只更新某个输入，例如
ryoko update nixpkgs
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    -h | --help) usage; exit 0 ;;
    *) break ;;
  esac
done
config_check

if [ $# -eq 0 ]; then
  note "==> nix flake update"
  ( cd "$RYOKO_FLAKE" && nix flake update )
else
  note "==> nix flake update $*"
  ( cd "$RYOKO_FLAKE" && nix flake update "$@" )
fi

printf '\n'
git -C "$RYOKO_FLAKE" --no-pager diff --stat -- flake.lock || true

if ! apply_changes switch; then
  die "构建失败；flake.lock 已更新，检查后可用 git checkout -- flake.lock 还原"
fi
