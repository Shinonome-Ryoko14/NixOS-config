# Shared helpers for ryoko commands. Sourced by concatenation, not `source`,
# so runtime inputs stay explicit in each generated wrapper.

die() { printf 'ryoko: %s\n' "$*" >&2; exit 1; }
note() { printf '%s\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }

config_check() {
  [ -n "${RYOKO_FLAKE:-}" ] || die "RYOKO_FLAKE 未设置"
  [ -d "$RYOKO_FLAKE" ] || die "配置仓库不存在: $RYOKO_FLAKE"
  [ -d "$RYOKO_FLAKE/.git" ] || die "不是 git 仓库: $RYOKO_FLAKE"
}

apps_file() { printf '%s/hosts/%s/enabled-apps.nix' "$RYOKO_FLAKE" "$RYOKO_HOST"; }
packages_file() { printf '%s/hosts/%s/extra-packages.nix' "$RYOKO_FLAKE" "$RYOKO_HOST"; }

is_app() {
  jq -e --arg n "$1" 'any(.[]; .name == $n)' <<<"$RYOKO_APPS_JSON" >/dev/null 2>&1
}

is_enabled() {
  "$RYOKO_SELECTION" apps has --file "$(apps_file)" "$1" >/dev/null 2>&1
}

is_managed_pkg() {
  "$RYOKO_SELECTION" packages has --file "$(packages_file)" "$1" >/dev/null 2>&1
}

validate_package() {
  local package=${1#nixpkgs#}
  if [[ $package == *.* ]]; then
    note "提示: $package 是属性路径，跳过存在性检查（构建时会验证）"
    return 0
  fi
  if nix eval --raw "nixpkgs#$package.pname" >/dev/null 2>&1; then
    return 0
  fi
  if nix eval --raw "nixpkgs#$package.name" >/dev/null 2>&1; then
    return 0
  fi
  die "找不到软件包: $package"
}

confirm() {
  local prompt=${1:-继续？} answer
  if [ "${RYOKO_ASSUME_YES:-0}" = 1 ]; then
    return 0
  fi
  if [ ! -t 0 ]; then
    return 1
  fi
  read -r -p "$prompt [y/N] " answer || answer=""
  case "$answer" in
    y | Y | yes | YES) return 0 ;;
    *) return 1 ;;
  esac
}

snapshot_managed() {
  RYOKO_SNAPSHOT=$(mktemp -d)
  cp -a "$(apps_file)" "$RYOKO_SNAPSHOT/apps"
  cp -a "$(packages_file)" "$RYOKO_SNAPSHOT/packages"
  trap 'rm -rf "${RYOKO_SNAPSHOT:-}"' EXIT
}

restore_managed() {
  cp -a "$RYOKO_SNAPSHOT/apps" "$(apps_file)"
  cp -a "$RYOKO_SNAPSHOT/packages" "$(packages_file)"
}

build_only() {
  ( cd "$RYOKO_FLAKE" && nh os build "$RYOKO_FLAKE#$RYOKO_HOST" )
}

apply_changes() {
  local mode=${1:-switch}
  note "==> 构建"
  build_only || return 1
  if [ "$mode" = build ]; then
    note "构建完成（未切换）"
    return 0
  fi
  note "==> 配置改动"
  git -C "$RYOKO_FLAKE" --no-pager diff --stat || true
  if [ "$mode" = switch ] && ! confirm "构建成功，切换到新系统？"; then
    note "已保留改动；稍后运行 ryoko apply"
    return 0
  fi
  ( cd "$RYOKO_FLAKE" && nh os "$mode" "$RYOKO_FLAKE#$RYOKO_HOST" )
}

finish_changes() {
  local build=${1:-1}
  [ "$build" = 1 ] || return 0
  if ! apply_changes switch; then
    restore_managed
    die "构建失败，已还原受管清单"
  fi
}
