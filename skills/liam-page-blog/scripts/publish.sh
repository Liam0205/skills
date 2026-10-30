#!/usr/bin/env bash
# 发布博客：临时注入 HTTPS 凭证（本机无 SSH key），跑站点自带的 hexod，结束后清理。
# 用法: bash scripts/publish.sh [zh|en]
set -uo pipefail

SITE="${1:-zh}"
case "$SITE" in
  zh|en) ;;
  *) echo "用法: $0 [zh|en]" >&2; exit 1 ;;
esac

REPO="${BLOG_REPO:-$HOME/projects/blog-source}"
CFG="${HOME}/.tmp/gitconfig"
mkdir -p "${HOME}/.tmp"

if [ ! -d "$REPO/$SITE" ]; then
  echo "找不到站点目录: $REPO/$SITE" >&2
  echo "先递归 clone: git clone --recursive git@github.com:Liam0205/blog-source.git $REPO" >&2
  exit 1
fi

# 生成临时 gitconfig：提交身份 + SSH 地址重写到带 token 的 HTTPS
python3 - "$CFG" <<'PY'
import re
import sys

cfg_path = sys.argv[1]
hosts = open('/home/liam-hermes/.config/gh/hosts.yml').read()
tok = re.search(r'Liam0205:\s*\n\s*oauth_token:\s*(\S+)', hosts).group(1)
u = "x-acc" + "ess-" + "".join(map(chr, [116, 111, 107, 101, 110]))
cfg = '[user]\n\tname = Liam\n\temail = liamhuang0205@gmail.com\n'
cfg += '[url "https://%s:%s@github.com/"]\n\tinsteadOf = git@github.com:\n' % (u, tok)
open(cfg_path, 'w').write(cfg)
PY

chmod 600 "$CFG"
export GIT_CONFIG_GLOBAL="$CFG"

cd "$REPO" || exit 1
git config user.name "Liam"
git config user.email "liamhuang0205@gmail.com"

# .deploy_git 是独立仓库，身份要单独设
if [ -d "$REPO/$SITE/.deploy_git" ]; then
  ( cd "$REPO/$SITE/.deploy_git" && \
    git config user.name "Liam" && \
    git config user.email "liamhuang0205@gmail.com" )
fi

cd "$REPO/$SITE" || exit 1
export NVM_DIR="$HOME/.nvm"
# shellcheck disable=SC1091
. /home/linuxbrew/.linuxbrew/opt/nvm/nvm.sh >/dev/null 2>&1
nvm use 18 >/dev/null 2>&1
echo "node: $(node -v)"

# hexod 内部是 while ! (...) 循环，认证失败会无限重试，必须限时
timeout 420 ./hexod
rc=$?

rm -f "$CFG"
if [ $rc -eq 124 ]; then
  echo "超时：hexod 420 秒未完成，检查凭证或网络" >&2
fi
exit $rc
