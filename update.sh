#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
#  DshShell 一键更新（老用户用）
#
#  用法（在 Termux 里粘这一条）：
#    bash <(curl -fsSL 'https://gh-proxy.com/https://raw.githubusercontent.com/USER/REPO/REF/update.sh')
#
#  它做什么：
#    1) 拉取发布清单（发布直链.txt），拿到"当前最新载荷包"的地址与校验值
#    2) 与本机已装的版本比对 —— **已经是最新就直接说，不重复下载**
#    3) 不是最新 → 下载新载荷 → 校验 sha256 → 解压 → 交给 install.sh
#       （install.sh 是幂等的：不会重复安装、不动你的会话记录）
#
#  与 bootstrap.sh 的区别：
#    bootstrap.sh 面向**新用户**（首次部署，什么都要建）
#    update.sh    面向**老用户**（只更新，先比对版本，避免白下）
#
#  与「检查更新」的区别：
#    「检查更新」更新的是**客户端 APK**（DshShell 本身）
#    本条命令更新的是**服务端/适配/脚本**（DSH 本体补丁、插件、运维命令）
#    两者互补，建议都做。
# ============================================================
set -u

REPO="18477514055/DeepseekHarness-mobile"
REF="main"

WORK="$HOME/dsh-mobile-setup"
TAR="$WORK/update.tar.gz"
STATE="$HOME/.dsh-mobile-update"

red()  { printf '\033[31m%s\033[0m\n' "$*" >&2; }
grn()  { printf '\033[32m%s\033[0m\n' "$*"; }
ylw()  { printf '\033[33m%s\033[0m\n' "$*"; }
die()  { red "❌ $*"; exit 1; }

# 加速前缀（按手机侧无 VPN 实测排序）；空串 = 官方原址，放最后兜底
PROXIES=(
  "https://gh-proxy.com/"
  "https://ghproxy.net/"
  "https://ghfast.top/"
  ""
)

command -v curl >/dev/null 2>&1 || { pkg install -y curl || die "需要 curl"; }
mkdir -p "$WORK" || die "无法创建 $WORK"

# ---------- 1) 取发布清单（多源）----------
LIST_URL_RAW="https://raw.githubusercontent.com/$REPO/$REF/发布直链.txt"
LIST="$WORK/发布直链.txt"
get_list() {
  local pre u
  for pre in "${PROXIES[@]}"; do
    u="${pre}${LIST_URL_RAW}"
    echo "   · 试：$u"
    if curl -L --fail --connect-timeout 10 -m 60 -s -o "$LIST.part" "$u"; then
      if [ -s "$LIST.part" ] && grep -q '^[0-9a-f]\{64\}' "$LIST.part"; then
        mv -f "$LIST.part" "$LIST"; return 0
      fi
    fi
    rm -f "$LIST.part"
  done
  return 1
}

echo "① 获取发布清单…"
if ! get_list; then
  # 清单拉不到时退一步：直接按"当天/昨天"猜名字没意义，给出可操作提示
  red "❌ 拉不到发布清单（所有镜像都失败）"
  echo "   可能原因：网络受限 / 仓库地址变了 / 该分支还没有 发布直链.txt"
  echo "   你也可以直接重跑一次**首次安装的那条命令**（bootstrap.sh）—— 它同样能更新。"
  echo "   或者问发布者要最新的载荷包，放到「下载」目录后跑：bash install.sh"
  exit 1
fi
grn "   清单已获取"

# ---------- 2) 解析出载荷包的地址与校验值 ----------
# 清单格式：<sha256>  <文件名>  <候选url...>
PAYLOAD_NAME=$(grep -E '^[0-9a-f]{64}' "$LIST" | awk '$2 ~ /^dsh-mobile-.*\.tar\.gz$/ {print $2; exit}')
PAYLOAD_SHA=$(grep -E "dsh-mobile-.*\.tar\.gz$" "$LIST" | awk '{print $1; exit}')
[ -n "$PAYLOAD_NAME" ] && [ -n "$PAYLOAD_SHA" ] || die "清单里没找到载荷包条目"
PAYLOAD_VER=$(printf '%s' "$PAYLOAD_NAME" | sed -E 's/^dsh-mobile-([0-9]+)\.tar\.gz$/\1/')

# ---------- 3) 与已装版本比对：一样就不折腾 ----------
PREV=""
[ -f "$STATE/version" ] && PREV=$(cat "$STATE/version" 2>/dev/null | tr -d '\r\n')
echo
echo "② 版本比对"
echo "   本机上次更新到：${PREV:-（没有记录，可能是首次更新）}"
echo "   仓库当前最新  ：$PAYLOAD_VER"
if [ -n "$PREV" ] && [ "$PREV" = "$PAYLOAD_VER" ]; then
  grn "   ✅ 已经是最新，无需更新（不重复下载）"
  echo
  echo "   还想强制重跑一遍安装器（例如怀疑某项坏了）："
  echo "     bash $WORK/src/install.sh"
  exit 0
fi

# ---------- 4) 下载新载荷（多源 + 逐个校验）----------
echo
echo "③ 下载新载荷 $PAYLOAD_NAME …"
mapfile -t URLS < <(grep -E "^$PAYLOAD_SHA" "$LIST" | head -1 | cut -d' ' -f3- | tr ' ' '\n' | grep -v '^$')
[ "${#URLS[@]}" -gt 0 ] || die "清单里这一行没有可用地址"

OKD=0
for u in "${URLS[@]}"; do
  echo "   · 试：$u"
  rm -f "$TAR"
  if curl -L --fail --connect-timeout 8 -m 30 --retry 1 -s -o "$TAR" "$u"; then
    if [ "$(sha256sum "$TAR" 2>/dev/null | cut -d' ' -f1)" = "$PAYLOAD_SHA" ]; then
      grn "   ✓ 下载并校验通过"; OKD=1; break
    fi
    ylw "   ✗ 校验不通过（文件可能没下完），换下一个源"
  else
    echo "   ✗ 这个源不行，换下一个"
  fi
done
if [ "$OKD" != 1 ]; then
  rm -f "$TAR"
  ylw "⚠️ 所有源都没成功。"
  echo "   兜底办法（任选）："
  echo "     ① 直接用**首次安装那条命令**（bootstrap.sh），它带完整的换源逻辑"
  echo "     ② 让发布者把 $PAYLOAD_NAME 发给你，放进「下载」目录，然后跑："
  echo "        bash $WORK/src/install.sh"
  exit 1
fi

# ---------- 5) 解压并交给安装器 ----------
echo
echo "④ 解压…"
rm -rf "$WORK/src"; mkdir -p "$WORK/src"
tar xzf "$TAR" -C "$WORK/src" --strip-components=1 || die "解压失败"
[ -f "$WORK/src/install.sh" ] || die "压缩包内容异常（缺少 install.sh）"
grn "   解压到 $WORK/src"

echo
echo "⑤ 开始更新（安装器是幂等的，不会重复装、不动你的会话记录）…"
echo
set +e
bash "$WORK/src/install.sh" "$@"
RC=$?
set -e

if [ "$RC" = 0 ]; then
  mkdir -p "$STATE"
  printf '%s' "$PAYLOAD_VER" > "$STATE/version"
  printf '%s\n' "$(date '+%F %T')" > "$STATE/updated-at"
  echo
  grn "✅ 更新完成（版本 $PAYLOAD_VER，已记录到 $STATE/version）"
  echo "   ★ 提醒：客户端 APK 的更新请到应用里点「⋮ 菜单 → 检查更新」。"
else
  red "❌ 安装器退出码 $RC —— 更新未完成"
  echo "   再跑一次本命令即可（幂等）；或看日志：tail -30 ~/.dsh/run/setup.log"
  exit "$RC"
fi
