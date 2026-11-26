# ryoko wall: control the Noctalia wallpaper.

usage() {
  cat <<'EOF'
用法:
  ryoko wall              下一张
  ryoko wall next
  ryoko wall random
  ryoko wall prev
  ryoko wall get
  ryoko wall list         用 fzf 从壁纸目录选择
  ryoko wall <图片路径>
EOF
}

if [ "${RYOKO_DESKTOP:-0}" != 1 ]; then
  die "桌面未启用"
fi
have noctalia || die "找不到 noctalia"

action=${1:-next}
case "$action" in
  next)
    noctalia msg wallpaper-next
    ;;
  random)
    noctalia msg wallpaper-random
    ;;
  prev | previous)
    noctalia msg wallpaper-previous
    ;;
  get)
    noctalia msg wallpaper-get
    ;;
  list)
    if [ ! -d "$RYOKO_WALLPAPER_DIR" ]; then
      die "壁纸目录不存在: $RYOKO_WALLPAPER_DIR"
    fi
    picked=$(find "$RYOKO_WALLPAPER_DIR" -maxdepth 2 -type f \
      \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) \
      -print | fzf --prompt '壁纸> ') || true
    if [ -n "$picked" ]; then
      noctalia msg wallpaper-set "$picked"
    fi
    ;;
  *)
    path=$(realpath -- "$action") || die "路径不存在: $action"
    if [ ! -f "$path" ]; then
      die "文件不存在: $action"
    fi
    noctalia msg wallpaper-set "$path"
    ;;
esac
