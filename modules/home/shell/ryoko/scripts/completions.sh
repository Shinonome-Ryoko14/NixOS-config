# ryoko completions: static completion data for zsh.

case "${1:-commands}" in
  commands)
    cat <<'EOF'
list
enable
disable
add
remove
search
try
info
where
apply
status
update
gen
gc
ime
wall
timer
lock
suspend
reboot
shutdown
power
git
upload
dashboard
EOF
    ;;
  apps)
    jq -r '.[].name' <<<"$RYOKO_APPS_JSON"
    ;;
  packages)
    "$RYOKO_SELECTION" packages list --file "$(packages_file)"
    ;;
  *)
    die "用法: ryoko completions [commands|apps|packages]"
    ;;
esac
