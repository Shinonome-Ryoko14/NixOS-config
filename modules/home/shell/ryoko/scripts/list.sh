# ryoko list: show application switches and managed packages.

usage() {
  cat <<'EOF'
用法: ryoko list [-i|--interactive] [--all] [--json]

  -i, --interactive  用 fzf 切换应用、移除受管软件包
  --all              额外列出实际安装的 Home Manager 与系统软件包
  --json             输出 JSON
EOF
}

interactive=0
list_all=0
json=0
while [ $# -gt 0 ]; do
  case "$1" in
    -i | --interactive) interactive=1; shift ;;
    --all) list_all=1; shift ;;
    --json) json=1; shift ;;
    -h | --help) usage; exit 0 ;;
    *) die "未知参数: $1" ;;
  esac
done
config_check

mapfile -t enabled < <("$RYOKO_SELECTION" apps list --file "$(apps_file)")
mapfile -t managed < <("$RYOKO_SELECTION" packages list --file "$(packages_file)")

contains() {
  local needle=$1 item
  shift
  for item in "$@"; do
    if [ "$item" = "$needle" ]; then return 0; fi
  done
  return 1
}

print_overview() {
  local mark name description
  printf '应用开关  hosts/%s/enabled-apps.nix\n' "$RYOKO_HOST"
  while IFS=$'\t' read -r name description; do
    if [ -z "$name" ]; then continue; fi
    if contains "$name" "${enabled[@]}"; then mark="[x]"; else mark="[ ]"; fi
    printf '  %s %-14s %s\n' "$mark" "$name" "$description"
  done < <(jq -r '.[] | "\(.name)\t\(.description)"' <<<"$RYOKO_APPS_JSON")

  printf '\n受管软件包  hosts/%s/extra-packages.nix\n' "$RYOKO_HOST"
  if [ ${#managed[@]} -eq 0 ]; then
    printf '  （空）\n'
  else
    printf '  %s\n' "${managed[@]}"
  fi
}

print_status() {
  local generation dirty current_system booted_system
  generation=$(nixos-rebuild list-generations --json 2>/dev/null | jq -r '.[] | select(.current) | "\(.generation)（\(.date)）"' 2>/dev/null || true)
  if [ -n "$generation" ]; then
    printf '\n系统代际  %s\n' "$generation"
  fi
  dirty=$(git -C "$RYOKO_FLAKE" status --porcelain | wc -l)
  printf '配置仓库  %s 个未提交改动\n' "$dirty"
  current_system=$(readlink -f /run/current-system 2>/dev/null || true)
  booted_system=$(readlink -f /run/booted-system 2>/dev/null || true)
  if [ -n "$current_system" ] && [ -n "$booted_system" ] && [ "$current_system" != "$booted_system" ]; then
    printf '提示      当前系统与启动系统不同，建议重启\n'
  fi
}

print_json() {
  local enabled_json managed_json
  enabled_json=$(printf '%s\n' "${enabled[@]}" | jq -R -s 'split("\n") | map(select(length > 0))')
  managed_json=$(printf '%s\n' "${managed[@]}" | jq -R -s 'split("\n") | map(select(length > 0))')
  jq -n \
    --argjson catalog "$RYOKO_APPS_JSON" \
    --argjson enabled "$enabled_json" \
    --argjson packages "$managed_json" \
    '{catalog: $catalog, enabled: $enabled, packages: $packages}'
}

print_all() {
  note "==> Home Manager 软件包（求值中）"
  nix eval --json "$RYOKO_FLAKE#nixosConfigurations.$RYOKO_HOST.config.home-manager.users.$RYOKO_USER.home.packages" \
    --apply 'ps: map (p: p.pname or p.name) ps' | jq -r '.[]' | sort -u
  note "==> 系统软件包（求值中）"
  nix eval --json "$RYOKO_FLAKE#nixosConfigurations.$RYOKO_HOST.config.environment.systemPackages" \
    --apply 'ps: map (p: p.pname or p.name) ps' | jq -r '.[]' | sort -u
}

run_interactive() {
  local choices selected kind name changed package
  have fzf || die "需要 fzf"
  [ -t 1 ] || die "需要终端"
  choices=$(
    jq -r '.[] | "app\t\(.name)\t\(.description)"' <<<"$RYOKO_APPS_JSON"
    for package in "${managed[@]}"; do
      printf 'pkg\t%s\t已受管，选中以移除\n' "$package"
    done
  )
  selected=$(printf '%s\n' "$choices" | fzf --multi --delimiter=$'\t' --with-nth=2,3 \
    --header '应用: 空格切换；软件包: 空格选中以移除' \
    --bind 'space:toggle+down,tab:toggle+down') || true
  if [ -z "$selected" ]; then
    return 0
  fi
  snapshot_managed
  changed=0
  while IFS=$'\t' read -r kind name _; do
    if [ -z "$kind" ]; then continue; fi
    case "$kind" in
      app)
        if contains "$name" "${enabled[@]}"; then
          "$RYOKO_SELECTION" apps remove --file "$(apps_file)" "$name" >/dev/null || true
        else
          "$RYOKO_SELECTION" apps add --file "$(apps_file)" "$name" >/dev/null || true
        fi
        changed=1
        ;;
      pkg)
        "$RYOKO_SELECTION" packages remove --file "$(packages_file)" "$name" >/dev/null || true
        changed=1
        ;;
    esac
  done <<<"$selected"
  if [ "$changed" = 0 ]; then
    return 0
  fi
  finish_changes 1
}

if [ "$json" = 1 ]; then
  print_json
  exit 0
fi
if [ "$interactive" = 1 ]; then
  run_interactive
  exit 0
fi
print_overview
print_status
if [ "$list_all" = 1 ]; then
  print_all
fi
