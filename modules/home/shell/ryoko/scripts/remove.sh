# ryoko remove: drop packages from hosts/<host>/extra-packages.nix.

usage() {
  cat <<'EOF'
用法: ryoko remove [-y] [--no-build] <软件包>...

只移除 extra-packages.nix 中的条目；应用开关请用 ryoko disable。
EOF
}

assume_yes=${RYOKO_ASSUME_YES:-0}
build=1
args=()
while [ $# -gt 0 ]; do
  case "$1" in
    -y | --yes) assume_yes=1; shift ;;
    --no-build) build=0; shift ;;
    -h | --help) usage; exit 0 ;;
    --) shift; while [ $# -gt 0 ]; do args+=("$1"); shift; done ;;
    -*) die "未知参数: $1" ;;
    *) args+=("$1"); shift ;;
  esac
done
if [ ${#args[@]} -eq 0 ]; then
  usage
  exit 1
fi
export RYOKO_ASSUME_YES=$assume_yes
config_check

packages=()
for raw in "${args[@]}"; do
  name=${raw#nixpkgs#}
  if is_managed_pkg "$name"; then
    packages+=("$name")
  else
    note "$name 不在受管清单"
  fi
done

if [ ${#packages[@]} -eq 0 ]; then
  note "没有需要移除的项"
  exit 0
fi

snapshot_managed
"$RYOKO_SELECTION" packages remove --file "$(packages_file)" "${packages[@]}" >/dev/null || true
note "已更新受管清单"
finish_changes "$build"
