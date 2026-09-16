# 给 DSH 的自装说明书（在对方手机上，让 DSH 自己把环境装好）

> **怎么用**：把本文件整篇粘给手机上新装好的 DSH（或让它读这个文件），它会照着做。
> 适用：安卓 arm64 + Termux + 全新安装的 DSH。**全程不需要 VPN**（所有下载走 npmmirror / 腾讯云镜像）。
> 本文件写给 AI 执行者看；人类只需要做『第 0 步』那三行命令。

---

## 0. 人类先做（3 行，Termux 里）
```bash
pkg update -y && pkg install -y nodejs-lts clang curl unzip python zstd gawk coreutils diffutils
npm install -g @deepseek-ai/dsh@0.1.5-rc.1 --registry=https://registry.npmmirror.com
node $PREFIX/lib/node_modules/@deepseek-ai/dsh/lib/bin.js --version
```
然后按 DSH 自己的方式把服务起起来（`node $PREFIX/lib/node_modules/@deepseek-ai/dsh/lib/bin.js --help` 看可用命令），
用手机浏览器打开 `127.0.0.1:<端口>` 进到对话界面。（Termux 里若直接敲 `dsh` 报 `bad interpreter`，属已知坑，用上面那条 node 全路径即可。）
> ⚠️ Termux 必须来自于 GitHub Releases 的 `termux-app_*_universal.apk` 或 `arm64-v8a.apk`；**不要用 Google Play 版**（已停更，依赖装不上）。

## 1. 执行者（DSH）的任务
把这台手机上的 DSH 环境修好并装齐，使"会话能打开、服务能常驻、有运维脚本、有界面适配"。**逐条执行、每步验证、失败即停并报告**，不要跳步、不要猜。

## 2. 先说清三条硬约束
1. **不需要 VPN**。任何一步若只能靠翻墙完成，说明你走错路了 —— 停下来报告。
2. **不要动用户数据**：`~/.dsh/sessions/**`（会话记录）与 `~/.dsh/storages/**` 一律不许删改。
3. **令牌是凭据**：`~/.dsh` 下的令牌/密钥**不要打印、不要外发、不要贴进对话**。

## 3. 材料从哪来（二选一）
- **A · 有安装包**（推荐）：对方会给你 `dsh-mobile-*.zip` 或 `dsh-mobile-*.tar.gz`。
  - zip：手机文件管理器解压到下载目录即可；
  - tar.gz：**不用解压**，放进下载目录即可（`tar -xzf` 在 Termux 里执行）。
  解压后根目录应有：`install.sh`、`lib/`、`payload/`、`tools/`、`docs/`、`README.zh.md`。
- **B · 没有安装包**：向用户要一个**国内可访问**的直链（Gitee 附件 / 网盘直链 / GitHub 加速前缀，形如
  `https://<加速站>/https://github.com/<user>/<repo>/releases/download/<tag>/<file>`），下载后**必须核对 SHA256**
  与用户给你的值一致，再继续。

## 4. 执行安装（脚本是唯一真源）
```bash
cd <解压出来的 dsh-mobile-* 目录>
bash install.sh --mode=browser     # 只装运行环境；或 --mode=apk 额外现场编译签名 DshShell APK
```
**你不需要自己重写这些步骤** —— 它们已经在脚本里，且经过验证。脚本内部会依次做：
1. 体检（架构 / 空间 / 网络 / 是否已装）
2. 装基础依赖：`nodejs-lts`(≥v20 会检查) `curl` `unzip` `python` `zstd` `gawk` `coreutils` `diffutils` **`clang`**
   （`clang` 必须有：要现场编译两个 `.so`，不编译则**会话打不开**）
3. （APK 模式）装 `openjdk-21 aapt aapt2 apksigner d8`
4. 装 DSH（npmmirror）并打**核心补丁**
5. `ensure_android_native`：用 `clang` 编译 `node-addon-system/src/flock.c → bin/system.node`
6. `ensure_sharp_wasm`：sharp 在 Android 无预编译产物 → 装 `@img/sharp-wasm32` 并指向 WASM 运行时
7. 装 Termux 侧运维脚本 + 编译 `link-fix.so`（把 Termux 上被拒的 `link()` 降级为复制）
8. 装界面适配插件 `dsh-mobile-adapt`，起服务并自检

> 想核对细节就看 `lib/stage-*.sh` 与 `install.sh`；**以脚本为准**，不要凭记忆补命令。
> 脚本会**先做空间预检**（浏览器模式 1536MB / APK 模式 2560MB），空间不够会直接告诉你。

## 5. 验收（逐条跑，把结果回报给用户）
```bash
node -v                     # ≥ v20
dshstatus                   # 服务与看门狗各 1 个实例
dsh-app-repair               # 不带参数看它自己的用法（本机装了它就用；没装就跳过这一条）
dsh-mobile-repair            # 修（幂等；DSH 升级后必跑）—— 这是包内脚本，路径以实际解压位置为准
# 原生模块是否就位（路径随版本可能变：自己找，不要照抄）
find $PREFIX/lib/node_modules/@deepseek-ai/dsh -name "*.node" 2>/dev/null | head
node -e "require('node-addon-system')" 2>&1 | head -3   # 不报错即 OK
curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:<端口>/   # 200/302 都算通
```
通过标准：**会话能打开、界面能刷新、`dshstatus` 正常、上面 native 一行打印 `native OK`**。
再让用户实际发一条消息、看一下界面是否正常（AI 看不到屏幕，必须由用户确认）。

## 6. 出问题怎么办
1. 先跑 `dsh-mobile-repair`（DSH 升级后必跑；它会重装/重修那 5 项）。
2. `dshstatus`、`tail -50 ~/.dsh/run/*.log` 看现象。
3. 读包内 `docs/故障排查.md`、`docs/权限与安全.md`、`docs/手动安装.md`。
4. 仍不行：**停下来**，把"哪一步、什么命令、原始报错"三样回报给用户，不要反复乱试。

## 7. 装完提醒用户（写给他的三句话）
1. 把 **Termux 与 DshShell 在最近任务里加锁**（否则系统清理会强停应用，表现为掉线）。
2. 给 Termux：**自启动开**、省电策略**无限制**、存储权限允许。
3. 以后 DSH 升级（`npm i -g @deepseek-ai/dsh`）之后，**再跑一次 `dsh-mobile-repair`**。

## 8. 这个说明**不包含**什么（别承诺）
- 不含「跨端协作」（手机↔电脑群聊/接力，`dsh-workbench` + 看板）—— 仍在迭代，稳定后单独发。
- 不含已签名 APK：APK 用**接收方自己的令牌**现场编译（那 APK 本身是凭据）。
- 不含任何令牌/密钥；安装包已脱敏并审计过。
