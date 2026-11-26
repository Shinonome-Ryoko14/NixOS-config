# ryoko add: append packages to hosts/<host>/extra-packages.nix.

usage() {
  cat <<'EOF'
用法: ryoko add [-y] [--no-build] [--dry-run] <软件包>...

软件包使用 pkgs 属性名，可写点号路径（例如 nur.repos.lihaoze123.try）。
默认构建后询问是否切换。
EOF
}

assume_yes=${RYOKO_ASSUME_YES:-0}
build=1
dry_run=0
args=()
while [ $# -gt 0 ]; do
  case "$1" in
    -y | --yes) assume_yes=1; shift ;;
    --no-build) build=0; shift ;;
    --dry-run) dry_run=1; shift ;;
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

before_packages=$("$RYOKO_SELECTION" packages list --file "$(packages_file)")

packages=()
for raw in "${args[@]}"; do
  packages+=("${raw#nixpkgs#}")
done
for package in "${packages[@]}"; do
  validate_package "$package"
done

if [ "$dry_run" = 1 ]; then
  tmpdir=$(mktemp -d)
  cp -a "$(packages_file)" "$tmpdir/packages"
  "$RYOKO_SELECTION" packages add --file "$tmpdir/packages" "${packages[@]}" >/dev/null
  diff -u "$(packages_file)" "$tmpdir/packages" || true
  rm -rf "$tmpdir"
  exit 0
fi

snapshot_managed
if ! "$RYOKO_SELECTION" packages add --file "$(packages_file)" "${packages[@]}" >/dev/null; then
  restore_managed
  die "更新软件包清单失败"
fi
after_packages=$("$RYOKO_SELECTION" packages list --file "$(packages_file)")
if [ "$before_packages" = "$after_packages" ]; then
  note "没有变化"
  exit 0
fi
note "已更新受管清单"
finish_changes "$build"
