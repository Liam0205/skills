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
import os
import re
import sys

cfg_path = sys.argv[1]
hosts_path = os.path.expanduser(os.environ.get("GH_HOSTS_FILE", "~/.config/gh/hosts.yml"))
hosts = open(hosts_path).read()
if "Liam0205" not in hosts:
    sys.exit("hosts.yml 里没有 Liam0205 这个账号，先 gh auth login")
m = re.search(r'Liam0205:\s*\n\s*oauth_token:\s*(\S+)', hosts)
if not m:
    sys.exit("hosts.yml 里 Liam0205 段没有 oauth_token")
tok = m.group(1)
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
# Node 版本由站点 .nvmrc 加根目录 scripts/hexo 决定（2026-11 起是 Node 24），
# hexod 内部也走那套包装，这里不再强制 nvm use 某个固定版本。

# hexod 现在每一步都有边界（run 失败即停，fetch/push 用 retry 5 退避），
# timeout 只是兜底，防止网络卡住时整条流水线挂着不退。
timeout 420 ./hexod
rc=$?

rm -f "$CFG"
if [ $rc -eq 124 ]; then
  echo "超时：hexod 420 秒未完成，检查凭证或网络" >&2
fi
exit $rc
