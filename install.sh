#!/usr/bin/env bash
# 安装本仓库的 skills 到各类 agent 工具的 skills 目录。
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$REPO_DIR/skills"

TARGET="claude"
MODE="symlink"
ALL=0
FORCE=0
DEST_OVERRIDE=""
PICKED=()

usage() {
  cat <<'EOF'
用法: ./install.sh [选项]

  --target claude|hermes|codex|all   安装目标，默认 claude
  --all                              安装全部 skill，默认只装 liam-page-writing
  --skill NAME                       只装指定 skill，可重复
  --copy                             复制而不是软链接
  --force                            目标已存在时覆盖
  --dest PATH                        覆盖默认安装目录（调试用）
  -h, --help                         显示本帮助
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target) TARGET="${2:?}"; shift 2 ;;
    --all) ALL=1; shift ;;
    --skill) PICKED+=("${2:?}"); shift 2 ;;
    --copy) MODE="copy"; shift ;;
    --force) FORCE=1; shift ;;
    --dest) DEST_OVERRIDE="${2:?}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "未知参数: $1" >&2; usage; exit 1 ;;
  esac
done

target_dir() {
  case "$1" in
    claude) echo "$HOME/.claude/skills" ;;
    hermes) echo "$HOME/.hermes/skills" ;;
    codex)  echo "$HOME/.codex/skills" ;;
    *) echo "未知目标: $1" >&2; exit 1 ;;
  esac
}

resolve_skills() {
  if (( ${#PICKED[@]} > 0 )); then
    printf '%s\n' "${PICKED[@]}"
  elif (( ALL )); then
    find "$SRC" -mindepth 1 -maxdepth 1 -type d -exec basename {} \;
  else
    echo "liam-page-writing"
  fi
}

install_into() {
  local base="$1" name="$2"
  local src="$SRC/$name" dest="$base/$name"

  if [[ ! -d "$src" ]]; then
    echo "  跳过 $name：仓库里没有这个 skill" >&2
    return 1
  fi

  mkdir -p "$base"

  if [[ -e "$dest" || -L "$dest" ]]; then
    if (( FORCE )); then
      rm -rf "$dest"
    else
      echo "  跳过 $name：$dest 已存在，加 --force 覆盖" >&2
      return 0
    fi
  fi

  if [[ "$MODE" == "copy" ]]; then
    cp -R "$src" "$dest"
    echo "  复制 $name -> $dest"
  else
    ln -s "$src" "$dest"
    echo "  链接 $name -> $dest"
  fi
}

TARGETS=()
if [[ "$TARGET" == "all" ]]; then
  TARGETS=(claude hermes codex)
else
  TARGETS=("$TARGET")
fi

mapfile -t SKILL_NAMES < <(resolve_skills)

echo "仓库: $REPO_DIR"
echo "待装: ${SKILL_NAMES[*]}"

for t in "${TARGETS[@]}"; do
  if [[ -n "$DEST_OVERRIDE" ]]; then
    base="$DEST_OVERRIDE"
  else
    base="$(target_dir "$t")"
  fi
  echo "[$t] $base"
  for s in "${SKILL_NAMES[@]}"; do
    install_into "$base" "$s" || true
  done
done

if [[ " ${TARGETS[*]} " == *" codex "* && -z "$DEST_OVERRIDE" ]]; then
  echo
  echo "提示: Codex CLI 不会自动扫描 skills 目录，请在 ~/.codex/AGENTS.md 里加一行："
  echo "  可用的技能见 ~/.codex/skills/，需要时读取对应的 SKILL.md。"
fi

echo
echo "完成。"
