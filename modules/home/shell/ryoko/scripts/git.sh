# ryoko git / ryoko upload: inspect, commit and push the configuration repo.

if [ "${RYOKO_GIT_MODE:-git}" = upload ]; then
  set -- upload "$@"
fi

action=${1:-status}
shift || true

usage() {
  cat <<'EOF'
用法:
  ryoko git status
  ryoko git save [-m 消息] [-a|--all] [-y]
  ryoko git push
  ryoko git sync
  ryoko upload [-m 消息] [-b 分支] [-a|--all] [--pr] [--main] [-y]

save 只提交选中的文件；upload 默认从 main 新建 ryoko/<日期> 分支，
提交并推送，--pr 时再开 Pull Request。hardware-configuration.nix
永远不会被提交。
EOF
}

repo() { git -C "$RYOKO_FLAKE" "$@"; }

changed_files() {
  local entry path other status
  while IFS= read -r -d '' entry; do
    status=${entry:0:2}
    path=${entry:3}
    if [[ $status == R* || $status == *R ]]; then
      IFS= read -r -d '' other || true
      if [[ $path != hosts/*/hardware-configuration.nix ]]; then printf '%s\n' "$path"; fi
      if [ -n "$other" ] && [[ $other != hosts/*/hardware-configuration.nix ]]; then printf '%s\n' "$other"; fi
    else
      if [[ $path != hosts/*/hardware-configuration.nix ]]; then printf '%s\n' "$path"; fi
    fi
  done < <(repo -c core.quotepath=false status --porcelain=v1 -z)
}

select_files() {
  local all_flag=$1
  shift
  local -a files=("$@")
  if [ ${#files[@]} -eq 0 ]; then
    die "没有可提交的改动"
  fi
  if [ "$all_flag" = 1 ] || [ ! -t 0 ] || ! have fzf; then
    printf '%s\n' "${files[@]}"
    return 0
  fi
  printf '%s\n' "${files[@]}" | fzf --multi \
    --header '空格选择要提交的文件，Ctrl-A 全选，回车确认' \
    --bind 'space:toggle+down,tab:toggle+down,ctrl-a:select-all,ctrl-d:deselect-all'
}

build_message() {
  local given=${1:-} template output
  if [ -n "$given" ]; then
    printf '%s\n' "$given"
    return 0
  fi
  template=$(mktemp)
  cat >"$template" <<'EOF'
# <type>(<scope>): <描述>
#
# type: feat | fix | refactor | chore | docs | style | test
# scope: cli | desktop | nixos | home | docs | flake
#
# 空行后可以写正文。以 # 开头的行会被忽略。
EOF
  "${EDITOR:-nvim}" "$template" || {
    rm -f "$template"
    die "编辑器退出失败"
  }
  output=$(grep -v '^#' "$template" || true)
  output=$(printf '%s\n' "$output" | sed -e '/./,$!d' -e :a -e '/^\n*$/{$d;N;ba' -e '}')
  rm -f "$template"
  if [ -z "$output" ]; then
    die "提交信息为空"
  fi
  printf '%s\n' "$output"
}

stage_and_commit() {
  local selected=$1 message=$2
  local -a files=()
  local file msgfile staged
  while IFS= read -r file; do
    if [ -n "$file" ]; then files+=("$file"); fi
  done <<<"$selected"
  if [ ${#files[@]} -eq 0 ]; then
    die "未选择文件"
  fi

  for file in "${files[@]}"; do
    if [[ $file == hosts/*/hardware-configuration.nix ]]; then
      note "跳过机器本地文件: $file" >&2
      continue
    fi
    repo add -- "$file" || die "无法暂存: $file"
  done

  staged=$(repo diff --cached --name-only -- ':(glob)hosts/*/hardware-configuration.nix' || true)
  if [ -n "$staged" ]; then
    repo reset -q -- ':(glob)hosts/*/hardware-configuration.nix'
    repo add -N -f -- ':(glob)hosts/*/hardware-configuration.nix'
    die "已阻止提交 hardware-configuration.nix"
  fi

  if repo diff --cached --quiet; then
    die "没有暂存任何改动"
  fi

  msgfile=$(mktemp)
  printf '%s\n' "$message" >"$msgfile"
  if ! repo commit -F "$msgfile"; then
    rm -f "$msgfile"
    die "提交失败"
  fi
  rm -f "$msgfile"
  repo log -1 --oneline
}

status_cmd() {
  config_check
  repo status --short --branch
  printf '\n== 最近提交 ==\n'
  repo log --oneline --decorate -5 || true
  printf '\n== 未推送 ==\n'
  if repo rev-parse --abbrev-ref '@{u}' >/dev/null 2>&1; then
    local ahead
    ahead=$(repo rev-list --count '@{u}..HEAD')
    if [ "$ahead" = 0 ]; then
      printf '无\n'
    else
      repo log --oneline '@{u}..HEAD'
    fi
  else
    printf '当前分支没有上游\n'
  fi
  printf '\n== 改动统计 ==\n'
  repo diff --stat || true
  printf '\n提示: hosts/%s/hardware-configuration.nix 永远不会被提交\n' "$RYOKO_HOST"
}

save_cmd() {
  local select_all=0 message_arg=""
  while [ $# -gt 0 ]; do
    case "$1" in
      -a | --all) select_all=1; shift ;;
      -m | --message) message_arg=${2:?缺少消息}; shift 2 ;;
      -y | --yes) export RYOKO_ASSUME_YES=1; shift ;;
      -h | --help) usage; exit 0 ;;
      *) die "未知参数: $1" ;;
    esac
  done
  config_check
  local -a files=()
  mapfile -t files < <(changed_files)
  if [ ${#files[@]} -eq 0 ]; then
    die "没有可提交的改动"
  fi
  local selected message
  selected=$(select_files "$select_all" "${files[@]}") || true
  if [ -z "$selected" ]; then
    note "已取消"
    exit 0
  fi
  message=$(build_message "$message_arg")
  stage_and_commit "$selected" "$message"
}

push_cmd() {
  config_check
  repo push -u origin HEAD
}

sync_cmd() {
  config_check
  local dirty branch
  dirty=$(repo status --porcelain | grep -v 'hosts/.*/hardware-configuration.nix' || true)
  if [ -n "$dirty" ]; then
    die "工作区不干净，先提交或 stash"
  fi
  repo fetch origin --prune
  branch=$(repo rev-parse --abbrev-ref HEAD)
  if [ "$branch" = main ] || [ "$branch" = master ]; then
    repo pull --rebase --autostash origin "$branch"
  else
    repo rebase origin/main
  fi
}

upload_cmd() {
  local select_all=0 message_arg="" branch_arg="" want_pr=0 want_main=0
  while [ $# -gt 0 ]; do
    case "$1" in
      -a | --all) select_all=1; shift ;;
      -m | --message) message_arg=${2:?缺少消息}; shift 2 ;;
      -b | --branch) branch_arg=${2:?缺少分支名}; shift 2 ;;
      --pr) want_pr=1; shift ;;
      --main) want_main=1; shift ;;
      -y | --yes) export RYOKO_ASSUME_YES=1; shift ;;
      -h | --help) usage; exit 0 ;;
      *) die "未知参数: $1" ;;
    esac
  done
  config_check

  local current branch
  current=$(repo rev-parse --abbrev-ref HEAD)
  if [ "$want_main" = 1 ]; then
    branch=$current
  elif [ -n "$branch_arg" ]; then
    branch=$branch_arg
  elif [ "$current" != main ] && [ "$current" != master ]; then
    branch=$current
  else
    branch="ryoko/$(date +%Y%m%d-%H%M)"
  fi

  if [ "$branch" != "$current" ]; then
    if repo show-ref --verify --quiet "refs/heads/$branch"; then
      repo switch "$branch" || die "切换分支失败: $branch"
    else
      repo switch -c "$branch" || die "创建分支失败: $branch"
    fi
  fi

  local -a files=()
  mapfile -t files < <(changed_files)
  if [ ${#files[@]} -gt 0 ]; then
    local selected message
    selected=$(select_files "$select_all" "${files[@]}") || true
    if [ -z "$selected" ]; then
      note "已取消"
      exit 0
    fi
    message=$(build_message "$message_arg")
    stage_and_commit "$selected" "$message"
  else
    note "工作区没有改动，直接推送现有提交"
  fi

  repo push -u origin HEAD

  if [ "$want_pr" = 1 ]; then
    have gh || die "gh 未安装"
    local existing
    existing=$(cd "$RYOKO_FLAKE" && gh pr list --head "$branch" --state open --json url -q '.[0].url' 2>/dev/null || true)
    if [ -n "$existing" ]; then
      note "PR 已存在: $existing"
    else
      ( cd "$RYOKO_FLAKE" && gh pr create --base main --head "$branch" --fill )
    fi
  fi
}

case "$action" in
  status) status_cmd "$@" ;;
  save) save_cmd "$@" ;;
  push) push_cmd "$@" ;;
  sync) sync_cmd "$@" ;;
  upload) upload_cmd "$@" ;;
  help | -h | --help) usage ;;
  *)
    usage
    exit 1
    ;;
esac
