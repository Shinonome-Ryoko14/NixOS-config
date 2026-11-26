# ryoko enable: add applications or packages to the managed lists.

usage() {
  cat <<'EOF'
用法: ryoko enable [-y] [--no-build] [--dry-run] <应用|软件包>...

应用名来自 modules/app-catalog.nix；其他名字会作为软件包加入
hosts/<host>/extra-packages.nix。默认构建后询问是否切换。
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

before_apps=$("$RYOKO_SELECTION" apps list --file "$(apps_file)")
before_packages=$("$RYOKO_SELECTION" packages list --file "$(packages_file)")

apps=()
packages=()
for raw in "${args[@]}"; do
  name=${raw#nixpkgs#}
  if is_app "$name"; then
    apps+=("$name")
  else
    packages+=("$name")
  fi
done

packages_to_add=()
for package in "${packages[@]}"; do
  validate_package "$package"
  packages_to_add+=("$package")
done

if [ "$dry_run" = 1 ]; then
  tmpdir=$(mktemp -d)
  cp -a "$(apps_file)" "$tmpdir/apps"
  cp -a "$(packages_file)" "$tmpdir/packages"
  if [ ${#apps[@]} -gt 0 ]; then
    "$RYOKO_SELECTION" apps add --file "$tmpdir/apps" "${apps[@]}" >/dev/null
  fi
  if [ ${#packages_to_add[@]} -gt 0 ]; then
    "$RYOKO_SELECTION" packages add --file "$tmpdir/packages" "${packages_to_add[@]}" >/dev/null
  fi
  diff -u "$(apps_file)" "$tmpdir/apps" || true
  diff -u "$(packages_file)" "$tmpdir/packages" || true
  rm -rf "$tmpdir"
  exit 0
fi

snapshot_managed
if [ ${#apps[@]} -gt 0 ]; then
  if ! "$RYOKO_SELECTION" apps add --file "$(apps_file)" "${apps[@]}" >/dev/null; then
    restore_managed
    die "更新应用清单失败"
  fi
fi
if [ ${#packages_to_add[@]} -gt 0 ]; then
  if ! "$RYOKO_SELECTION" packages add --file "$(packages_file)" "${packages_to_add[@]}" >/dev/null; then
    restore_managed
    die "更新软件包清单失败"
  fi
fi
after_apps=$("$RYOKO_SELECTION" apps list --file "$(apps_file)")
after_packages=$("$RYOKO_SELECTION" packages list --file "$(packages_file)")
if [ "$before_apps" = "$after_apps" ] && [ "$before_packages" = "$after_packages" ]; then
  note "没有变化"
  exit 0
fi
note "已更新受管清单"
finish_changes "$build"
