#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
#  DshShell 一键安装（接收方用）
#
#  用法（在 Termux 里粘贴这一条）：
#    bash <(curl -fsSL 这个文件的直链)
#  或者先把本文件和安装包都下到 Download，再：
#    bash ~/storage/downloads/一键安装.sh
#
#  它会：下载安装包 → 校验 SHA256 → 解压 → 运行安装器
# ============================================================
set -u
# ↓↓↓ 发布者需要把下面两行填上（填好后本脚本就能独立工作）↓↓↓
TARBALL_URL="${DSHM_TARBALL_URL:-}"
SHA256="1299819c18a5d1da2a2e2aa1846e9653be93aa3b5a339813675fc820d6c666bc"
# ★ 多源候选（打包时由 dist/发布直链.txt 自动生成）：GitHub 原址 + 国内加速前缀，逐个试
MIRRORS=("https://gh-proxy.com/https://raw.githubusercontent.com/18477514055/DeepseekHarness-mobile/main/dsh-mobile-20260919.tar.gz" "https://ghproxy.net/https://raw.githubusercontent.com/18477514055/DeepseekHarness-mobile/main/dsh-mobile-20260919.tar.gz" "https://raw.githubusercontent.com/18477514055/DeepseekHarness-mobile/main/dsh-mobile-20260919.tar.gz" "https://cdn.jsdelivr.net/gh/18477514055/DeepseekHarness-mobile@main/dsh-mobile-20260919.tar.gz" "https://ghfast.top/https://raw.githubusercontent.com/18477514055/DeepseekHarness-mobile/main/dsh-mobile-20260919.tar.gz" "https://github.com/18477514055/DeepseekHarness-mobile/raw/main/dsh-mobile-20260919.tar.gz")
# ↑↑↑ 发布者填写区结束 ↑↑↑

NAME="dsh-mobile-setup"
WORK="$HOME/$NAME"
TAR="$WORK/setup.tar.gz"

red()  { printf '\033[31m%s\033[0m\n' "$*" >&2; }
grn()  { printf '\033[32m%s\033[0m\n' "$*"; }
die()  { red "❌ $*"; exit 1; }

# ★ 拿安装包的三条路（2026-09-16 加强）：① 本机已有文件（最稳）② 直链下载 ③ 下载失败时给可操作提示
#   命令行里直链下不动是常态：网盘直链要 cookie / 加速站要 VPN / curl 不跟某些跳转 —— 所以本地文件优先。
LOCAL=""
if [ -n "${DSHM_LOCAL:-}" ]; then
  LOCAL="$DSHM_LOCAL"
else
  # ★ 逐个候选**先校验再采用**：Download 里常躺着旧版本的包，不能拿它硬装（否则报"校验不通过"让人一头雾水）
  for c in "$(dirname "$0")"/dsh-mobile-*.tar.gz \
           "$(dirname "$0")"/*.tar.gz \
           /storage/emulated/0/Download/dsh-mobile-*.tar.gz \
           /sdcard/Download/dsh-mobile-*.tar.gz \
           "$HOME/storage/downloads"/dsh-mobile-*.tar.gz \
           "$HOME/Download"/dsh-mobile-*.tar.gz \
           "$HOME"/dsh-mobile-*.tar.gz; do
    [ -f "$c" ] || continue
    g=$(sha256sum "$c" 2>/dev/null | cut -d' ' -f1)
    if [ "$g" = "$SHA256" ]; then LOCAL="$c"; break; fi
    echo "  · 跳过（不是这一版）：$(basename "$c")"
  done
fi
help_find_file() {
  red "❌ 还没拿到安装包。三条最容易成功的办法（任选一条，然后重跑本脚本）："
  echo "   ① 让发送方把 dsh-mobile-*.zip 发给你 → 用手机文件管理器解压到 下载 目录（最稳）"
  echo "   ② 用手机浏览器打开下载链接（浏览器能过网盘页/跳转/要 cookie 的直链），下到 下载 目录"
  echo "   ③ 和发送方在同一 Wi-Fi / 热点下：他在自己手机跑  cd ~/Download && python3 -m http.server 8899"
  echo "      你用浏览器打开 http://<他的IP>:8899/ 直接点文件下载（不用外网、不用 VPN）"
  echo "   本脚本已在这些位置找过：脚本同目录 / Download / /sdcard/Download / ~/storage/downloads / ~"
  die "把 tar.gz 放到上面任一位置即可，或者确认直链真的可用"
}

command -v curl >/dev/null 2>&1 || { pkg install -y curl || die "需要 curl"; }
mkdir -p "$WORK" || die "无法创建 $WORK"

try_download() {   # $1=url；下载成功**且校验通过**才算数
  rm -f "$TAR"
  curl -L --fail --connect-timeout 6 -m 30 --retry 1 -s -o "$TAR" "$1" || return 1
  [ "$(sha256sum "$TAR" 2>/dev/null | cut -d' ' -f1)" = "$SHA256" ] || return 1
  return 0
}
if [ -n "$LOCAL" ]; then
  echo "① 使用本机已有的安装包：$LOCAL"
  cp -f "$LOCAL" "$TAR" || die "复制安装包失败：$LOCAL"
else
  URLS=()
  case "$TARBALL_URL" in __*|"") ;; *) URLS+=("$TARBALL_URL") ;; esac
  if [ "${#MIRRORS[@]}" -gt 0 ]; then URLS+=("${MIRRORS[@]}"); fi
  [ "${#URLS[@]}" -gt 0 ] || help_find_file
  echo "① 下载安装包（会自动换源，共 ${#URLS[@]} 个候选）…"
  OKD=0
  for u in "${URLS[@]}"; do
    echo "   · 试：$u"
    if try_download "$u"; then echo "   ✓ 下载并校验通过"; OKD=1; break; fi
    echo "   ✗ 这个源不行，换下一个"
  done
  [ "$OKD" = 1 ] || { rm -f "$TAR"; help_find_file; }
fi

echo "② 校验完整性…"
GOT=$(sha256sum "$TAR" | cut -d' ' -f1)
if [ "$GOT" != "$SHA256" ]; then
  rm -f "$TAR"
  die "校验不通过（文件可能没下完或被篡改）：期望 $SHA256，实际 $GOT"
fi
grn "   校验通过"

echo "③ 解压…"
rm -rf "$WORK/src"; mkdir -p "$WORK/src"
tar xzf "$TAR" -C "$WORK/src" --strip-components=1 || die "解压失败"
[ -f "$WORK/src/install.sh" ] || die "压缩包内容异常（缺少 install.sh）"
grn "   解压到 $WORK/src"

echo "④ 开始安装…"
echo
exec bash "$WORK/src/install.sh" "$@"
