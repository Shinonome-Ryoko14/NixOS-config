# ryoko search: fuzzy search nixpkgs with nix-search-tv.

usage() {
  cat <<'EOF'
用法: ryoko search [关键词]

在终端中打开 fzf 选择软件包；非终端环境直接输出前 50 个匹配。
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    -h | --help) usage; exit 0 ;;
    *) break ;;
  esac
done
have nix-search-tv || die "nix-search-tv 未安装"
query="$*"

# nix-search-tv 的索引同时包含 NixOS 选项；只保留 nixpkgs 软件包。
package_list() {
  nix-search-tv print 2>/dev/null | grep '^nixpkgs/ ' || true
}

if [ ! -t 1 ]; then
  package_list | sed 's|^nixpkgs/ ||' | grep -i -- "$query" | head -50 || true
  exit 0
fi

if [ -n "$query" ]; then
  package_list | fzf --query "$query" --prompt 'nixpkgs> ' \
    --preview 'nix-search-tv preview {}' --preview-window 'right:60%'
else
  package_list | fzf --prompt 'nixpkgs> ' \
    --preview 'nix-search-tv preview {}' --preview-window 'right:60%'
fi
