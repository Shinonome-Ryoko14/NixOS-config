# ryoko info: describe an application switch or package.

usage() {
  cat <<'EOF'
用法: ryoko info <应用|软件包>
EOF
}

if [ $# -eq 0 ]; then
  usage
  exit 1
fi
config_check
name=${1#nixpkgs#}

if is_app "$name"; then
  description=$(jq -r --arg n "$name" '.[] | select(.name == $n) | .description' <<<"$RYOKO_APPS_JSON")
  printf '应用: %s\n描述: %s\n' "$name" "$description"
  if is_enabled "$name"; then
    printf '状态: 已启用\n'
  else
    printf '状态: 未启用\n'
  fi
else
  printf '软件包: %s\n' "$name"
  if is_managed_pkg "$name"; then
    printf '状态: 已加入 extra-packages.nix\n'
  else
    printf '状态: 未受管\n'
  fi
  if [[ $name != *.* ]]; then
    pname=$(nix eval --raw "nixpkgs#$name.pname" 2>/dev/null || true)
    version=$(nix eval --raw "nixpkgs#$name.version" 2>/dev/null || true)
    if [ -n "$pname" ]; then printf '名称: %s\n' "$pname"; fi
    if [ -n "$version" ]; then printf '版本: %s\n' "$version"; fi
  else
    printf '提示: 属性路径跳过 nixpkgs 查询\n'
  fi
fi

printf '\n声明位置:\n'
rg -n --fixed-strings \
  --glob '!flake.lock' --glob '!result*' --glob '!.git' \
  -e "$name" "$RYOKO_FLAKE" | head -20 || true
