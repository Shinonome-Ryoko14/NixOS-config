# ryoko dashboard: fzf menu for the most common actions.

usage() {
  cat <<'EOF'
用法: ryoko dashboard

不带参数的 `ryoko` 也会在终端里打开这个面板。
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    -h | --help) usage; exit 0 ;;
    *) die "未知参数: $1" ;;
  esac
done

[ -t 1 ] || die "需要终端"
have fzf || die "需要 fzf"

choice=$(
  cat <<'EOF' | fzf --prompt 'ryoko> ' --header '选择操作'
list      切换应用与软件包
add       搜索并添加软件包
apply     构建并切换系统
status    系统与仓库状态
update    更新 flake 输入
gen       系统代际
gc        清理旧代际（dry-run）
ime       输入法
wall      壁纸
git       查看仓库状态
upload    提交并推送到 GitHub
power     电源
EOF
) || true

if [ -z "$choice" ]; then
  exit 0
fi

action=${choice%% *}
case "$action" in
  list)
    exec ryoko-list -i
    ;;
  add)
    selected=$(ryoko-search) || exit 0
    if [ -z "$selected" ]; then
      exit 0
    fi
    exec ryoko-add "${selected#nixpkgs/ }"
    ;;
  *)
    exec "ryoko-$action"
    ;;
esac
