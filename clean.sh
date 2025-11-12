#!/usr/bin/env bash
#
# clean.sh
# 关闭代理
#

set -e

if [ "$(id -u)" -ne 0 ]; then
  echo "请使用 sudo 运行本脚本，例如："
  echo "  sudo $0"
  exit 1
fi

SERVICES=$(networksetup -listallnetworkservices | tail -n +2)

while IFS= read -r svc; do
  [ -z "$svc" ] && continue
  if [[ "$svc" == \** ]]; then
    echo "跳过禁用网络服务: $svc"
    continue
  fi

  echo "关闭网络服务代理: $svc"

  networksetup -setwebproxystate "$svc" off >/dev/null 2>&1 || true
  networksetup -setsecurewebproxystate "$svc" off >/dev/null 2>&1 || true
done <<< "$SERVICES"

echo "代理已关闭。"

# ---------- 3. 中止代理进程 ----------
echo "尝试结束代理进程..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROXY_BIN="${SCRIPT_DIR}/heytea-diy"

PIDS=$(pgrep -f "$PROXY_BIN" || true)
if [ -n "$PIDS" ]; then
  echo "找到 heytea-diy 进程: $PIDS"
  kill $PIDS 2>/dev/null || true
else
  echo "未发现基于路径匹配的 heytea-diy 进程。"
fi