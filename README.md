# dsh-mobile

把「DSH（DeepSeek Harness）」装到安卓手机上所用的**分发载荷**仓库。

这个仓库本身不是一个程序，只是**下载中转站**：里面的压缩包由接收方的 Termux 用 `curl` 直接下载，
所以必须放在一个能直链访问的地方（这也是它放在 GitHub 而不是网盘的原因 ——
安卓把「下载目录」和「Termux 家目录」隔离了，网盘下的文件 Termux 一般读不到）。

---

## 一、接收方要下什么

| 文件 | 用途 |
|---|---|
| `dsh-mobile-一键安装.sh` | **接收方要跑的一键脚本**（已内置下面那个包的 SHA256） |
| `dsh-mobile-20260916.tar.gz` | 安装包本体（约 153 KB） |
| `dsh-mobile-20260916.tar.gz.sha256` | 上面那个包的校验和 |

### ★ 更省事的一条路：直接用 Release 的整包 zip（2026-09-17 起）

Raw 直链下不动时（比如本机 github.com 被代理拦了），用 Release：

```
https://github.com/18477514055/DeepseekHarness-mobile/releases/latest
```

里面有 **`dsh-mobile-20260917.zip`**（约 169 KB）—— 解压后一个目录就是全套
（一键脚本 + 载荷 + 校验和 + 三份文档）。放进 Termux 家目录或 Download，然后：

```bash
cd <解压出来的目录> && bash dsh-mobile-一键安装.sh
```

脚本会**优先用同目录里的 `dsh-mobile-20260916.tar.gz`**（先校验再采用），所以外网不通也能装。

> ⚠️ 2026-09-17 之前，一键脚本里的 `TARBALL_URL` 与 `MIRRORS` 是**空占位符**，
> 脚本只能靠"本机已有安装包"那条退路工作。**现已填入可用直链 + 4 个候选源**，
> 脚本从此可独立工作（每个源都校验 SHA256 才采用）。
>
> ⚠️ Release 里那份脚本附件的文件名是 **ASCII 的 `install-dsh-mobile.sh`**（内容与
> `dsh-mobile-一键安装.sh` 完全相同）。原因：非 ASCII 文件名经命令行上传时会被吃掉字符
> （实测传成了 `dsh-mobile-.sh`）。**仓库内那份仍是正确的中文名**，以仓库为准。

**直链**（仓库 `18477514055/DeepseekHarness-mobile`，分支 `main`）：

```
https://raw.githubusercontent.com/18477514055/DeepseekHarness-mobile/main/dsh-mobile-20260916.tar.gz
https://raw.githubusercontent.com/18477514055/DeepseekHarness-mobile/main/dsh-mobile-一键安装.sh
https://raw.githubusercontent.com/18477514055/DeepseekHarness-mobile/main/dsh-mobile-20260916.tar.gz.sha256
```

**先读文档再动手**（这两份是权威说明，按需选一份）：

- `分享-DshShell-安装说明.md` —— 完整说明：这是什么、怎么装、掉线怎么办。**建议先看这份。**
- `安装手册-给接收方.txt` —— 简短版，两条通道怎么分工。
- `给DSH的自装说明.md` —— 环境已经装好、只差让 DSH 自己配置时用；这份是**写给 AI 执行者**的。

---

## 二、想自己核对一下再跑（推荐）

```bash
curl -L -O https://raw.githubusercontent.com/18477514055/DeepseekHarness-mobile/main/dsh-mobile-20260916.tar.gz
sha256sum dsh-mobile-20260916.tar.gz
```

结果应当等于：

```
f20e93a3d80286dbd8ceb7ac337ecaaabc1b3aac2ace57252756193e17152621
```

（这个值同时也写在 `dsh-mobile-20260916.tar.gz.sha256` 里，一键脚本内置的就是它。）

---

## 三、国内直连 GitHub 慢的话

下面几个加速前缀是**实测过可用**的（按快慢排序），把整条 raw 地址拼在后面即可：

```
https://gh-proxy.com/https://raw.githubusercontent.com/18477514055/DeepseekHarness-mobile/main/dsh-mobile-20260916.tar.gz
https://ghproxy.net/https://raw.githubusercontent.com/18477514055/DeepseekHarness-mobile/main/dsh-mobile-20260916.tar.gz
https://cdn.jsdelivr.net/gh/18477514055/DeepseekHarness-mobile@main/dsh-mobile-20260916.tar.gz
https://raw.githubusercontent.com/18477514055/DeepseekHarness-mobile/main/dsh-mobile-20260916.tar.gz
```

一键脚本内部已经带了多个候选源，会逐个试、失败自动换下一个，并**对每个源都校验 SHA256**才采用。

---

## 四、这个仓库里还有什么

| 文件 | 说明 |
|---|---|
| `SHA256SUMS.txt` | 本仓库全部文件的校验和（含上面 3 个以外的东西） |
| `上传说明-给维护者.md` | 维护者用的：怎么建仓库、传哪些文件、raw 链接怎么回填 |
| `安装手册-给接收方.txt` | 接收方文档（同上） |
| `分享-DshShell-安装说明.md` | 接收方文档（同上） |
| `给DSH的自装说明.md` | 接收方文档（同上） |

---

## 五、注意

- **本仓库不含任何令牌、密钥或配对码**，也不含用户数据。
- 不要把 Termux 的 APK 传到这里：GitHub 网页上传单文件限 25 MB，而它约 34 MB。
  需要发 APK 请走 Releases（附件上限 2 GB）或网盘。
- 载荷对应的是 **2026-09-16** 这一版；换版本时文件名里的日期会变，
  请以本文档与 `SHA256SUMS.txt` 为准，不要凭记忆拼旧链接。
