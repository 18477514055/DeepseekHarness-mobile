# DshShell 分享安装说明（2026-09-16 稳定包 · 含 Termux）

> 这一份是**给接收方看的**，连同安装包一起发出去即可。
> 包里另有 `安装说明.txt`（随包简版）和 `docs/`（故障排查 / 权限与安全 / 手动安装）。

## 一、这是什么
把「DSH（DeepSeek Harness）」装到安卓手机上，并给它套一个**原生应用外壳 DshShell**：
点图标就能用、掉线自动拉起、开屏有真实进度、外观接近原生 App。**不需要电脑、不需要 VPN。**

## 二、要发出去的文件
**方式一（推荐：一次发一个文件）**
| 文件 | 大小 | 作用 |
|---|---|---|
| `dsh-mobile-含Termux-20260916.zip` | 33MB | 推荐：内含下面全部内容，安卓自带解压就能打开 |
| `dsh-mobile-小包-20260916.zip` | 0.2MB | 只含安装包+一键脚本+说明（先发这个最省流量；Termux APK 另发） |
| 它们的 `.sha256` | 66B | 校验和 |

**方式二（分开发，包更小）**
| 文件 | 大小 | 作用 |
|---|---|---|
| `dsh-mobile-20260916.tar.gz` | 152KB | 安装包本体 |
| `dsh-mobile-20260916.tar.gz.sha256` | 93B | 校验和 |
| `dsh-mobile-一键安装.sh` | 2.7KB | 一键脚本（已预填校验和，支持离线） |
| `termux-app_v0.118.3+github-debug_arm64-v8a.apk` | 34MB | **Termux 本体**（已替你下好，对方不用翻墙） |
| `termux-0.118.3-校验和.txt` | 300B | Termux 的 SHA256 + 签名指纹 |
| `分享-DshShell-安装说明.md` | 本文件 | 说明 |

> **微信/QQ 不让发 `.apk` 时**：改发同目录的 `termux-app_v0.118.3-arm64.apk.gz`，
> 对方收到后把文件名末尾的 `.gz` 去掉（变成 `.apk`）再安装即可。
>
> 对方说无法解压时：安卓自带解压不支持 `.tar.gz`，请改发上面的 `.zip`（安卓原生支持）。
> 也可以告诉他：`.tar.gz` 根本不用手动解压 —— 放进下载目录后，Termux 里的一键脚本会自己解压。

## 二·五、安装器会装哪些依赖（列表）
**基础依赖（两种模式都装）**：`nodejs-lts`（**Node.js**，脚本会检查必须 ≥ v20）、`curl`、`unzip`、`python`、
`zstd`、`gawk`、`coreutils`、`diffutils`、**`clang`**。
> 为什么连 `clang` 也要装：有两处必须**在本机编译**的原生模块 ——
> `node-addon-system` 的 `system.node`（不编译的话**会话打不开**）和 `link-fix.so`（不编译的话 npm 装不上东西）。
> 它会把 `libLLVM` 一起带来，**约 270MB**，所以请预留 **≥1.5GB** 空间（脚本会先做空间预检）。

**APK 模式额外装**：`openjdk-21`、`aapt`、`aapt2`、`apksigner`、`d8`（用于在手机上现场编译签名 DshShell）。

## 二·六、下载不到时怎么办（三条路，按成功率排序）
1. **让发送方把 zip 发给你**（微信/QQ），用手机文件管理器解压到「下载」→ 跑一键脚本。最稳，不依赖任何外网。
2. **用手机浏览器打开下载链接**再存到「下载」：浏览器能过「网盘页面 / 跳转 / 要 cookie 的直链」，命令行 curl 往往过不去。
3. **同一 Wi-Fi 或热点下直连发送方**：他在自己手机上跑 `cd ~/Download && python3 -m http.server 8899`，
   你用浏览器打开 `http://<他的IP>:8899/` 直接点文件下载（不用外网、不用 VPN）。

> 一键脚本现在会**先找本机文件并逐个校验**（脚本同目录 / Download / /sdcard/Download / ~/storage/downloads / ~），
> **自动跳过不是这一版的旧包**；直链下不动时**不再直接报错退出**，而是把上面三条路打印给你。

## 二·七、长期分发：用 Gitee 直链（不用局域网、不用 VPN）
把发布物放进**公开仓库**，命令行就能直连下载（实测：`gitee.com/<用户>/<仓库>/raw/<分支>/<文件>` 会 302 跳到签名 CDN，
**不需要登录、不需要 Referer**，`curl -L` 正常）：
```
termux-setup-storage
cd ~
curl -L -O https://gitee.com/<你的用户名>/<仓库名>/raw/master/dsh-mobile-20260916.tar.gz
curl -L -O https://gitee.com/<你的用户名>/<仓库名>/raw/master/dsh-mobile-一键安装.sh
bash dsh-mobile-一键安装.sh
```
> 打包时把直链写进 `dist/发布直链.txt`（一行），重打包会**自动烧进一键脚本**，接收方连链接都不用填。
> 注意：Gitee 的 raw 直链带签名、会过期，所以**必须让 curl 跟随跳转（`-L`）**，不要把签名 URL 抄下来存着。



## 二·八、上传到 GitHub 的清单（发布者照这个传）
**仓库里只需要这 3 个文件（共 153KB，都在 GitHub 网页上传限制内）**：
```
dsh-mobile-20260916.tar.gz
dsh-mobile-20260916.tar.gz.sha256
dsh-mobile-一键安装.sh
```
上传后拿到 raw 链接（形如 https://raw.githubusercontent.com/<你>/<仓库>/main/dsh-mobile-20260916.tar.gz），
让打包脚本把它写进 dist/发布直链.txt 再打包 —— 一键脚本会自动生成多个国内加速候选源
（原址 + jsDelivr + ghproxy + gh-proxy + ghfast），逐个试、每个都校验 SHA256。

> Termux 那个 34MB 的 APK **不要传进仓库**（GitHub 网页上传单文件限 25MB）：当 Release 附件（限 2GB），
> 或让对方用加速前缀直接从 Termux 官方下载（无需 VPN）：
> ```
> curl -L -O 'https://ghproxy.net/https://github.com/termux/termux-app/releases/download/v0.118.3/termux-app_v0.118.3%2Bgithub-debug_arm64-v8a.apk'
> # 下不动就换 gh-proxy.com / ghfast.top 前缀；SHA256：72fdb596045116bf5ba1b5bdf5b26fddb9acc0bd074ad9f2da9eb0ae85e83a4e
> ```

## 二·九、一条命令把安装包塞进 Termux（不靠局域网、不靠仓库、不靠 VPN）
**`termux-storage-get`** —— 它弹出安卓的**文件选择器**，把你选中的文件**写进 Termux 家目录**。

**准备（一次性）**
1. 装我们提供的 **Termux:API** App：`termux-api-app_v0.53.0+github.debug.apk`（`com.termux.api`，8.4MB）
   - SHA256 `ecf916ff80ae751e65c092f51c055cce4de417ebeea8e449cd0f294afdbde39a`
   - 它的签名证书与 Termux 本体**完全相同**（`b6da0148…e1`）—— 这是二者能配合工作的前提，必须用同一来源的版本
2. Termux 里执行：`pkg install -y termux-api`

**然后每传一个文件就一条命令**
```
termux-storage-get ~/dsh-mobile-20260916.tar.gz     # 弹选择器 → 选中微信/QQ 收到的那个包
termux-storage-get ~/dsh-mobile-一键安装.sh          # 同一办法把脚本也拿进来
bash dsh-mobile-一键安装.sh
```

**顺带两个更好用的**
- 脚本只有 4.6KB：在聊天里**复制它的全文** → Termux 里 `termux-clipboard-get > dsh-mobile-一键安装.sh`（剪贴板直接变文件）
- 没有 Termux:API App 时的退路：`termux-setup-storage` → 把文件**保存到「下载」** → `cp ~/storage/downloads/dsh-mobile-20260916.tar.gz ~/`

## 二·十、关于浏览器依赖（重要）
- **APK 模式不需要任何浏览器**：DshShell 用的是系统 **WebView**（android.webkit.WebView），与 Chrome / Edge 这些 App 无关。
  所以「没装浏览器」只影响**浏览器模式**，不影响正常使用。
- **浏览器模式已改成优先 Edge**：com.microsoft.emmx → 再 Chrome → 再任意能响应 VIEW 的浏览器。
  Edge 在国内可直接下载，需要浏览器模式就装它。
- **我们不打包 Edge / Chrome**：两者都是专有软件，再分发违反授权。包里只做「优先尝试 + 失败时提示你自己装」。
- 极少数机器把**系统 WebView 停用**了，那时 APK 模式也会白屏 —— 去应用商店装/启用 Android System WebView 即可。
- 一句话：**能装 APK 就用 APK 模式**，它对浏览器零依赖。

## 三、接收方要做的三步

**第 0 步 · 装 Termux（用我们提供的这个，不用翻墙）**
安装 `termux-app_v0.118.3+github-debug_arm64-v8a.apk`（`com.termux`，v0.118.3，arm64）。
安装时系统会问「允许安装未知应用」→ 允许。
- 这是官方 GitHub 发布版，我们**逐字节核验过**：SHA256 `72fdb596…a4e` 与官方校验和一致，
  签名证书 SHA-256 `b6da0148…e1`。
- 仅支持 **arm64** 手机（近七八年的安卓机基本都是）。若对方是特别老的 32 位机型，说一声我换 `armeabi-v7a`。
- ⚠️ 不要用 Google Play 版的 Termux（已停更，装不上本包依赖）。

**第 1 步 · 把安装包放进手机「下载」目录**
- 收到 **zip**：用手机自带文件管理器**解压到下载目录**（安卓原生支持 zip）；
- 收到 **tar.gz**：**不用解压**，直接放进下载目录即可（Termux 里跑脚本时会自动解压）。

**第 2 步 · 在 Termux 里跑两行**
```bash
termux-setup-storage          # 第一次要允许访问存储（弹窗点允许）
bash ~/storage/downloads/dsh-mobile-一键安装.sh
```
脚本会：**核对 SHA256 → 解压 → 运行安装器**。校验不过会直接停下（不会装半成品）。

> 安装包放在别处：`DSHM_LOCAL=/完整/路径/dsh-mobile-20260916.tar.gz bash ~/storage/downloads/dsh-mobile-一键安装.sh`
> 若你把它传到网盘并拿到直链：`DSHM_TARBALL_URL=直链 bash 一键安装.sh`

## 四、安装器会做什么（约 5~15 分钟，看网速）
1. 体检（架构 / 空间 / 网络 / 是否已装）
2. 装基础依赖
3. **问你要哪种模式**：**浏览器模式**（最快）或 **本机 APK 版**（推荐：下 android.jar → **在你手机上现场编译并签名** DshShell → 拉起系统安装器）
4. 装 DSH（走 npmmirror，**免翻墙**）→ 打 5 项核心补丁（不加会崩或打不开会话）
5. 起服务取**本机自己的令牌** → 装界面适配插件
6. 自检并给结论

**令牌与安全**：分发包里**不含任何令牌/密钥**（构建时已脱敏 + 审计）。APK 用**接收方自己的令牌**现场构建 ——
所以本包**不发**现成的已签名 APK，这是有意的：那个 APK 本身就是一份凭据。

## 五、装完之后
- 打开 **DshShell** 图标：首次约 **13~20 秒**（有进度条）；以后秒开。
- **把 Termux 和 DshShell 在最近任务里加锁**：MIUI 等系统的一键清理会强停应用，加锁免得"掉线还得去 Termux 手动拉起"。
- 给 Termux：**自启动开**、省电策略**无限制**、存储权限允许。DshShell 不需要自启动。

## 六、出问题怎么办
```bash
dsh-mobile-repair     # 万能修复：DSH 升级后必跑；界面/服务不对先跑它
dshstatus             # 看服务与看门狗状态
```
细的看包里 `docs/故障排查.md`、`docs/权限与安全.md`、`docs/手动安装.md`。

## 七、这个版本里有什么 / 没有什么
**有**：DshShell v1.4.3（versionCode 18，含崩溃页的「诊断与修复」面板）、DSH 0.1.5-rc.1 的 5 项本地修复、
运维脚本（`dshweb`/`dshwatchdog`/`dshstatus`/`dshstop`/`dsh-release`/`dsh-app-repair`/`dsh-mobile-repair` 等）、
界面适配插件 `dsh-mobile-adapt`、APK 源码（`Termux.java`/`MainActivity.java`/等待页）。
**没有**：
- **已签名的 APK**（见第四节：现场用接收方自己的令牌编译）；
- **「跨端协作」功能**（手机↔电脑的群聊/接力，即 `dsh-workbench` + 看板）—— 仍在快速迭代（正在改"按对话真隔离"），
  不放进稳定包，稳定后单独出。

## 八、发布者自查（重建时必看）
```bash
cd ~/dsh-backup/dsh-mobile
bash tools/sync-payload.sh           # 现场同步 + 脱敏 + 审计 + 生成 MANIFEST
bash tools/make-release.sh --no-sync # 打 dist/dsh-mobile-<日期>.tar.gz + .sha256
```
**每次重打包后必须重填** `dist/一键安装.sh` 里的 SHA256（取新的 `.sha256`），否则接收方卡在"校验不通过"。
本次校验和：

```
f20e93a3d80286dbd8ceb7ac337ecaaabc1b3aac2ace57252756193e17152621  dsh-mobile-20260916.tar.gz
72fdb596045116bf5ba1b5bdf5b26fddb9acc0bd074ad9f2da9eb0ae85e83a4e  termux-app_v0.118.3+github-debug_arm64-v8a.apk
```

（`.tar.gz` / `.zip` 合并包的校验和以**它们旁边的 `.sha256` 文件**为准 —— 它们没法把自己写进自己内部。）

Termux APK 来源（官方，需 VPN）：<https://github.com/termux/termux-app/releases/tag/v0.118.3>

