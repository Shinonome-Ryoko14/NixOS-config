# ryoko gen: list generations, switch to one, or roll back.

usage() {
  cat <<'EOF'
用法:
  ryoko gen              列出代际
  ryoko gen --json       输出 JSON
  ryoko gen <编号>       切换到指定代际
  ryoko gen rollback     回滚到上一代
EOF
}

case "${1:-list}" in
  list | "")
    nixos-rebuild list-generations
    ;;
  --json)
    nixos-rebuild list-generations --json
    ;;
  rollback)
    config_check
    confirm "回滚到上一代？" || exit 0
    sudo nixos-rebuild switch --rollback
    ;;
  [0-9]*)
    number=$1
    link="/nix/var/nix/profiles/system-${number}-link"
    if [ ! -e "$link" ]; then
      die "代际不存在: $number"
    fi
    confirm "切换到代际 $number？" || exit 0
    sudo nix-env -p /nix/var/nix/profiles/system --set "$link"
    sudo "$link/bin/switch-to-configuration" switch
    ;;
  *)
    usage
    exit 1
    ;;
esac
