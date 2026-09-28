#!/usr/bin/env bash
# 一键发新版本构建：改 version.txt -> 提交 -> push（push 即触发 GitHub Actions 出包）
#
# 用法：
#   ./release.sh                 # 自动取上游最新 tag
#   ./release.sh dsh-v0.1.7-rc.2 # 指定 tag
#   ./release.sh --dry-run       # 只打印将要用的 tag，不改文件、不推送
#
# 注意：需要本机已配置可用的 GitHub SSH key（本仓库用 git@github.com:J-YeFen/dsh-win-build.git）。
set -euo pipefail
cd "$(dirname "$0")"

TAG=""
DRY=0
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY=1 ;;
    -h|--help) sed -n '2,12p' "$0"; exit 0 ;;
    *) TAG="$arg" ;;
  esac
done

if [ -z "$TAG" ]; then
  echo "查询上游最新 tag ..."
  TAG=$(curl -sSf "https://api.github.com/repos/deepseek-ai/deepseek-harness/tags?per_page=5" |
        /usr/bin/python3 -c "import json,sys; d=json.load(sys.stdin); print(d[0]['name']); [print('  候选:', t['name'], file=sys.stderr) for t in d]")
  echo "选定: $TAG"
fi

if [ "$DRY" = "1" ]; then
  echo "[dry-run] 会写入 version.txt: $TAG"
  echo "[dry-run] 当前 version.txt: $(cat version.txt 2>/dev/null || echo '(缺失)')"
  exit 0
fi

echo "$TAG" > version.txt
git add version.txt
if git diff --cached --quiet; then
  echo "version.txt 没变化（仍是 $TAG），直接触发一次构建？"
  echo "如需强制重跑，请到 Actions 页手动 Run workflow。"
  exit 0
fi

git -c commit.gpgsign=false commit -q -m "build $TAG"
GIT_SSH_COMMAND="ssh -o ConnectTimeout=20 -o ServerAliveInterval=10" git push origin main

echo
echo "已推送。构建会自动触发（约 10-20 分钟）："
echo "  https://github.com/J-YeFen/dsh-win-build/actions"
echo "产物 artifact 名：dsh-desktop-win-x64-${TAG#dsh-v}"
