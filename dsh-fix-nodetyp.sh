#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
#  dsh-fix-nodetyp —— 修「装 DSH 时卡在 node-pty 编译失败」
#
#  症状（真实报错，来自接收方）：
#     > node-pty@1.2.0-beta.15 install
#     > node scripts/prebuild.js || node-gyp rebuild
#     > Rebuilding because directory .../prebuilds/android-arm64 does not exist
#     gyp: Undefined variable android_ndk_path in binding.gyp
#     gyp ERR! configure error
#     npm error code 1
#     ❌ DSH 安装失败
#
#  根因：node-pty 只带 darwin/linux/win32 预编译，没有 android；
#        它的 install 脚本于是回退到 node-gyp 编译，而 node 的 common.gypi
#        需要一个 android_ndk_path 变量，默认没人提供 ⇒ 直接失败。
#        旧版 npm 会跳过 install 脚本（所以老用户侥幸没事），
#        新版 npm（node 24）会真的执行 ⇒ 新用户必然踩到。
#
#  修法：那个变量是**从环境变量读**的；Termux 自带的 clang 工具链就是等价的 NDK。
#        指过去再编译一次即可（不下载任何 NDK）。
#
#  用法（★ 不用把文件放进 Termux —— 和你装 DSH 时一样，粘一条命令）：
#     bash <(curl -fsSL 'https://ghproxy.net/https://raw.githubusercontent.com/
#       USER/REPO/REF/dsh-fix-nodetyp.sh')
#
#  为什么用这条路：用户反馈过"脚本放不进私有仓库"—— 那就别放，
#  直接下载来执行（与 bootstrap.sh 同一条通道）。
# ============================================================
set -u

PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
PTY="$PREFIX/lib/node_modules/@deepseek-ai/dsh/node_modules/node-pty"
GYP="$PREFIX/lib/node_modules/npm/node_modules/node-gyp/bin/node-gyp.js"

red()  { printf '\033[31m%s\033[0m\n' "$*" >&2; }
grn()  { printf '\033[32m%s\033[0m\n' "$*"; }
ylw()  { printf '\033[33m%s\033[0m\n' "$*"; }
dim()  { printf '   %s\n' "$*"; }
die()  { red "❌ $*"; exit 1; }

echo "════════ 修复 node-pty（DSH 的硬依赖）════════"
echo

# ---------- 0) 先看现在是不是已经好的 ----------
if [ -d "$PTY" ]; then
  if node -e "require('$PTY')" >/dev/null 2>&1; then
    grn "✅ 现在 node-pty 已经能加载了，不需要修。"
    dim "如果你仍然装不上，请把完整报错发给发布者。"
    exit 0
  fi
  ylw "node-pty 存在但加载不了，开始修…"
else
  ylw "找不到 node-pty 目录：$PTY"
  dim "说明 DSH 本体还没装上。请先重跑一次安装命令，再跑本脚本。"
  exit 1
fi

command -v node >/dev/null 2>&1 || die "找不到 node（先装：pkg install -y nodejs-lts）"
command -v clang >/dev/null 2>&1 || { ylw "缺 clang，正在装（编译必需）…"; pkg install -y clang || die "装 clang 失败"; }
[ -f "$GYP" ] || die "找不到 node-gyp（$GYP）" "确认 npm 完整：pkg install -y nodejs-lts"

# ---------- 1) 清掉上次的残留编译目录（避免半成品干扰） ----------
echo "① 清理上次残留…"
rm -rf "$PTY/build" "$PTY/prebuilds/android-arm64" 2>/dev/null || true
grn "   已清理"

# ---------- 2) 设好变量并编译 ----------
echo
echo "② 编译 node-pty（用 Termux 自带的 clang，不下载 NDK）…"
dim "android_ndk_path=$PREFIX"
cd "$PTY" || die "进不去 $PTY"
if timeout 900 env android_ndk_path="$PREFIX" ANDROID_NDK="$PREFIX" node "$GYP" rebuild 2>&1 | tail -6; then
  :
fi

# ---------- 3) 校验 ----------
echo
echo "③ 校验结果…"
if node -e "require('$PTY')" >/dev/null 2>&1; then
  grn "✅ 修好了！node-pty 现在可以加载。"
  # 顺手做一次真的 spawn，确保不是"能加载但不能用"
  if timeout 30 node -e "
    const p=require('$PTY');
    const t=p.spawn('/bin/sh',['-c','echo OK'],{name:'xterm',cols:80,rows:24});
    t.onData(d=>{ if(String(d).includes('OK')) process.exit(0); });
    setTimeout(()=>process.exit(1),5000);
  " >/dev/null 2>&1; then
    grn "   并且真的能起终端（spawn 成功）"
  else
    ylw "   能加载但 spawn 没验证通过 —— 可能仍不完整，请把本输出发给发布者"
  fi
  echo
  grn "现在重跑一次安装命令即可继续："
  dim "bash <(curl -fsSL '<你原来那条 bootstrap 命令>')"
  exit 0
else
  red "❌ 仍然加载不了。"
  echo "   请把下面这些信息发给发布者："
  echo "   ---"
  echo "   node -v: $(node -v 2>&1)"
  echo "   npm -v : $(npm -v 2>&1)"
  echo "   clang  : $(command -v clang 2>&1)"
  echo "   pty 目录内容："
  ls -la "$PTY" 2>&1 | head -12 | sed 's/^/     /'
  echo "   build 目录："
  ls -la "$PTY/build/Release" 2>&1 | head -6 | sed 's/^/     /'
  echo "   ---"
  exit 1
fi
