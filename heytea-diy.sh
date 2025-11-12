#!/usr/bin/env bash
#
# heytea-diy.sh
# 启动打包后的 heytea-diy + 自动证书 + 自动系统代理
# 需在 macOS 上以 root（sudo）运行
#

set -e

# ---------- 1. 默认参数 ----------
PORT=8080

print_help() {
  cat <<EOF
用法: sudo $0 [-p <端口>]

选项:
  -p <端口>    指定 mitmproxy 监听端口 (默认: 8080)
  -h, --help       显示本帮助
EOF
}

# ---------- 2. 解析命名参数 ----------
while [[ $# -gt 0 ]]; do
  case "$1" in
    -p)
      if [[ -n "$2" && ! "$2" =~ ^- ]]; then
        PORT="$2"
        shift 2
      else
        echo "错误: -p 需要一个端口号" >&2
        exit 1
      fi
      ;;
    -h|--help)
      print_help
      exit 0
      ;;
    *)
      echo "未知参数: $1" >&2
      print_help
      exit 1
      ;;
  esac
done

# ---------- 3. 确保是 root（sudo）运行 ----------
if [ "$(id -u)" -ne 0 ]; then
  echo "请使用 sudo 运行本脚本，例如："
  echo "  sudo $0 -p 9000"
  exit 1
fi

# ---------- 4. 路径配置 ----------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROXY_BIN="${SCRIPT_DIR}/heytea-diy"

if [ ! -x "$PROXY_BIN" ]; then
  echo "未找到可执行的代理程序: $PROXY_BIN"
  echo "请确认 heytea-diy 放在脚本同目录，并有执行权限 (chmod +x)。"
  exit 1
fi

echo "脚本目录 : $SCRIPT_DIR"
echo "代理程序 : $PROXY_BIN"
echo "监听端口 : $PORT"
echo

# ---------- 5. 启动 heytea-diy（如果还没启动） ----------
if pgrep -f "$PROXY_BIN" >/dev/null 2>&1; then
  echo "检测到 heytea-diy 已在运行，跳过启动。"
else
  echo "未检测到运行中的 heytea-diy，正在启动..."
  "$PROXY_BIN" -p "$PORT" >/tmp/heytea-diy.log 2>&1 &
  sleep 1
fi

# ---------- 6. 等待 mitmproxy 生成证书 ----------
# 假设 heytea-diy 是以 root 启动的，HOME 为 /var/root
CERT_PEM=~/.mitmproxy/mitmproxy-ca-cert.pem
CERT_CER=~/.mitmproxy/mitmproxy-ca-cert.cer

echo
echo "等待 mitmproxy 生成 CA 证书文件（最多 60 秒）..."

CERT_FILE=""

for i in $(seq 1 60); do
  if [ -e $CERT_PEM ]; then
    CERT_FILE=$CERT_PEM
    break
  elif [ -e $CERT_CER ]; then
    CERT_FILE=$CERT_CER
    break
  fi
  sleep 1
done

if [ -z "$CERT_FILE" ]; then
  echo "60 秒内未在 ~/.mitmproxy 中找到 mitmproxy 证书文件。"
  echo "请检查 heytea-diy 是否正常运行，或手动访问 http://mitm.it 生成证书后重试。"
  exit 1
fi

echo "已找到 mitmproxy CA 证书: $CERT_FILE"

# ---------- 7. 检查 / 导入证书到 System.keychain ----------
echo
echo "检查 System.keychain 中是否已经存在 mitmproxy 证书..."

if security find-certificate -c "mitmproxy" /Library/Keychains/System.keychain >/dev/null 2>&1; then
  echo "检测到 System.keychain 已存在 mitmproxy 证书，跳过导入。"
else
  echo "未找到 mitmproxy 证书，正在导入并设为受信任根证书..."

  security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain "$CERT_FILE"

  echo "证书导入完成。注意：在新版本 macOS 上，可能会弹出 GUI 确认框需要你点允许。"
fi

# ---------- 8. 配置所有网络服务 HTTP/HTTPS 代理 ----------
echo
echo "正在为所有网络服务配置 HTTP/HTTPS 代理为 127.0.0.1:${PORT} ..."

SERVICES=$(networksetup -listallnetworkservices | tail -n +2)

while IFS= read -r svc; do
  [ -z "$svc" ] && continue
  if [[ "$svc" == \** ]]; then
    echo "跳过禁用网络服务: $svc"
    continue
  fi

  echo "配置网络服务: $svc"

  networksetup -setwebproxy "$svc" 127.0.0.1 "$PORT" >/dev/null 2>&1 || true
  networksetup -setwebproxystate "$svc" on >/dev/null 2>&1 || true

  networksetup -setsecurewebproxy "$svc" 127.0.0.1 "$PORT" >/dev/null 2>&1 || true
  networksetup -setsecurewebproxystate "$svc" on >/dev/null 2>&1 || true

done <<< "$SERVICES"

echo
echo "======================================="
echo "mitmproxy 已启动，证书已导入/确认存在。"
echo "系统 HTTP/HTTPS 代理已设置为: 127.0.0.1:${PORT}"
echo "可以打开浏览器访问 http://mitm.it 测试。"
echo "======================================="