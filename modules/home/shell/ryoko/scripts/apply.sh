# ryoko apply: build the host and optionally switch to it.

usage() {
  cat <<'EOF'
用法: ryoko apply [--build|--boot|--test] [-y]

  --build  只构建，不激活
  --boot   构建并设为下次启动默认（图形登录变更后使用）
  --test   构建并临时激活
  默认     构建 → 显示 diff → 询问是否 switch
EOF
}

mode="switch"
assume_yes=0
while [ $# -gt 0 ]; do
  case "$1" in
    --build) mode="build"; shift ;;
    --boot) mode="boot"; shift ;;
    --test) mode="test"; shift ;;
    -y | --yes) assume_yes=1; shift ;;
    -h | --help) usage; exit 0 ;;
    *) die "未知参数: $1" ;;
  esac
done
export RYOKO_ASSUME_YES=$assume_yes
config_check

git -C "$RYOKO_FLAKE" status --short
printf '\n'

case "$mode" in
  build)
    note "==> 构建"
    build_only || die "构建失败"
    note "构建完成（未切换）"
    ;;
  switch | boot | test)
    apply_changes "$mode"
    ;;
esac
