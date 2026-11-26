# ryoko disable: remove applications or packages from the managed lists.

usage() {
  cat <<'EOF'
用法: ryoko disable [-y] [--no-build] <应用|软件包>...

应用名从 hosts/<host>/enabled-apps.nix 移除；其他名字从
hosts/<host>/extra-packages.nix 移除。默认构建后询问是否切换。
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

apps=()
packages=()
for raw in "${args[@]}"; do
  name=${raw#nixpkgs#}
  if is_app "$name"; then
    if is_enabled "$name"; then
      apps+=("$name")
    else
      note "$name 已经禁用"
    fi
  else
    if is_managed_pkg "$name"; then
      packages+=("$name")
    else
      note "$name 不在受管清单"
    fi
  fi
done

if [ ${#apps[@]} -eq 0 ] && [ ${#packages[@]} -eq 0 ]; then
  note "没有需要修改的项"
  exit 0
fi

snapshot_managed
if [ ${#apps[@]} -gt 0 ]; then
  "$RYOKO_SELECTION" apps remove --file "$(apps_file)" "${apps[@]}" >/dev/null || true
fi
if [ ${#packages[@]} -gt 0 ]; then
  "$RYOKO_SELECTION" packages remove --file "$(packages_file)" "${packages[@]}" >/dev/null || true
fi
note "已更新受管清单"
finish_changes "$build"
