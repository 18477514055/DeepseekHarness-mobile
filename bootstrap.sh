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
SHA256="23659a286b02fe3305ad05486bd0dd94f9cbd3ad7fbe6b8529bde447e024bf8a"
# ★ 多源候选（打包时由 dist/发布直链.txt 自动生成）：GitHub 原址 + 国内加速前缀，逐个试
MIRRORS=("https://ghproxy.net/https://raw.githubusercontent.com/18477514055/DeepseekHarness-mobile/main/dsh-mobile-20260920.tar.gz" "https://ghproxy.net/https://cdn.jsdelivr.net/gh/18477514055/DeepseekHarness-mobile@main/dsh-mobile-20260920.tar.gz" "https://raw.githubusercontent.com/18477514055/DeepseekHarness-mobile/main/dsh-mobile-20260920.tar.gz" "https://gh-proxy.com/https://raw.githubusercontent.com/18477514055/DeepseekHarness-mobile/main/dsh-mobile-20260920.tar.gz" "https://ghfast.top/https://raw.githubusercontent.com/18477514055/DeepseekHarness-mobile/main/dsh-mobile-20260920.tar.gz" "https://cdn.jsdelivr.net/gh/18477514055/DeepseekHarness-mobile@main/dsh-mobile-20260920.tar.gz" "https://github.com/18477514055/DeepseekHarness-mobile/raw/main/dsh-mobile-20260920.tar.gz")
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
  # ★ 2026-09-20 调整顺序：**Termux 私有目录优先**。
  #   原因：网盘方案要求用户把载荷放进 Termux 私有目录（因为很多手机上
  #   共享目录根本读不到）。原来共享目录排在前面 ⇒ 优先用了共享目录那份，
  #   在"读不到共享目录"的手机上就等于没找到 → 白跑一趟网络。
  #   私有目录永远读得到，所以放最前；共享目录退为兜底（能读时也能用）。
  for c in "$HOME"/dsh-mobile-*.tar.gz \
           "$HOME/Download"/dsh-mobile-*.tar.gz \
           "$(dirname "$0")"/dsh-mobile-*.tar.gz \
           "$(dirname "$0")"/*.tar.gz \
           "$HOME/storage/downloads"/dsh-mobile-*.tar.gz \
           /storage/emulated/0/Download/dsh-mobile-*.tar.gz \
           /sdcard/Download/dsh-mobile-*.tar.gz; do
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

# ★ 2026-09-19 新增：顺手把 Termux:API 也装上。
#   为什么放在这里（用户实测反馈驱动）：很多人手机上 termux-setup-storage 跑不通，
#   共享存储与 Termux 私有目录不互通。此时「先下到下载目录再点安装」这条路是断的。
#   而 Termux:API 是**必须安装的 APK**（它提供 termux-open 等命令）。
#   ⇒ 那就由脚本自己下到共享存储（不依赖 ~/storage 符号链接）并尝试拉起安装界面；
#     万一共享存储也不可用，就只提示、**绝不中断**，让主安装照常走完。
echo "④ 准备 Termux:API（可选但强烈建议）…"
TA_NAME="termux-api-app_v0.53.0+github.debug.apk"
TA_SHA="ecf916ff80ae751e65c092f51c055cce4de417ebeea8e449cd0f294afdbde39a"
TA_BASE="https://github.com/termux/termux-api/releases/download/v0.53.0/$TA_NAME"
TA_URLS=(
  "https://gh-proxy.com/$TA_BASE"
  "https://ghproxy.net/$TA_BASE"
  "$TA_BASE"
)
TA_SHARED=""
for d in /storage/emulated/0/Download /sdcard/Download /storage/self/primary/Download /mnt/sdcard/Download; do
  [ -d "$d" ] && [ -w "$d" ] && { TA_SHARED="$d"; break; }
done
TA_DEST="${TA_SHARED:-$WORK}/$TA_NAME"
if command -v termux-open >/dev/null 2>&1; then
  grn "   termux-api 客户端命令已在，跳过"
elif [ -f "$TA_DEST" ] && [ "$(sha256sum "$TA_DEST" 2>/dev/null | cut -d' ' -f1)" = "$TA_SHA" ]; then
  grn "   Termux:API 安装包已在：$TA_DEST"
else
  echo "   下载 Termux:API 安装包…"
  OKA=0
  for u in "${TA_URLS[@]}"; do
    rm -f "$TA_DEST.part"
    if curl -L --fail --connect-timeout 15 -m 180 -s -o "$TA_DEST.part" "$u"; then
      if [ "$(sha256sum "$TA_DEST.part" 2>/dev/null | cut -d' ' -f1)" = "$TA_SHA" ]; then
        mv -f "$TA_DEST.part" "$TA_DEST"; OKA=1; break
      fi
    fi
    rm -f "$TA_DEST.part"
  done
  if [ "$OKA" = 1 ]; then
    grn "   已下载并校验：$TA_DEST"
    if [ -t 0 ]; then
      if command -v termux-open >/dev/null 2>&1; then
        termux-open "$TA_DEST" >/dev/null 2>&1 || true
      else
        am start -a android.intent.action.VIEW -d "file://$TA_DEST" \
          -t application/vnd.android.package-archive >/dev/null 2>&1 || true
      fi
      echo "   → 若弹出安装界面，点「安装」即可（装完会回到这里）"
    fi
  else
    echo "   ⚠️ Termux:API 没下下来（不影响主安装）。可稍后手动装，或重跑本命令。"
  fi
fi

echo "⑤ 开始安装 DSH…"
echo
exec bash "$WORK/src/install.sh" "$@"
