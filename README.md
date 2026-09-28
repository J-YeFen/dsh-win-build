# dsh-win-build

在 GitHub Actions 上构建 **免安装、未签名、win-x64 目录版** 的 DeepSeek Harness 桌面版，
本机不需要 Windows、不需要装任何工具链。

本仓库只放 workflow + 一个版本文件；构建时它会去 checkout 上游
[`deepseek-ai/deepseek-harness`](https://github.com/deepseek-ai/deepseek-harness)
的指定 tag，并运行官方打包命令：

```
pnpm --filter "@deepseek-ai/dsh-desktop" run package:win:x64:dir --unsigned
```

## 改动版本（一键更新）

本仓库带一个 `release.sh`，在 macOS/Linux 上一条命令搞定：

```bash
./release.sh                 # 自动取上游最新 tag
./release.sh dsh-v0.1.8-alpha.1
./release.sh --dry-run       # 只看看会用什么 tag
```

它做三件事：写 `version.txt` → commit → push；push 会自动触发构建。

手动等价写法：

```bash
echo "dsh-v0.1.8-alpha.1" > version.txt
git commit -am "build dsh-v0.1.8-alpha.1" && git push
```

push 会自动触发构建（`paths` 只盯着 `version.txt` 和 workflow 文件，改 README 不会触发）。

也可以在 **Actions → dsh-desktop-win-portable → Run workflow** 里临时填一个 tag（留空 = 读 `version.txt`）。

> 桌面壳（Electron）与内嵌的 `@deepseek-ai/dsh` 必须同版本发布，所以升级 = 换 tag 重新出包，
> 不能只替换 dsh。

## 产物

每次运行上传 artifact **`dsh-desktop-win-x64-<版本>`**（zip）。里面是 electron-builder 产出的
可搬运应用目录（通常是 `win-unpacked/`）：

```
win-unpacked/
  DSH-VERSION.txt               <- 本次构建的版本/tag/构建时间（更新器读它）
  DeepSeek Harness.exe
  resources/app.asar            <- dsh 生产依赖树
  resources/app.asar.unpacked/  <- 原生模块
  resources/runtime/            <- 内置 Python / Node / pnpm
```

**下载需要登录 GitHub**（artifact 接口即使用公开仓库也要求认证）。
如果浏览器下载大 zip 不稳，可改用：

```bash
gh run download -R J-YeFen/dsh-win-build -n dsh-desktop-win-x64-0.1.7-rc.2
```

## 本地怎么用：配套的一键更新器

`J-YeFen/dsh-plugins` 工作区的 `build-win10/desktop/` 里有一套固定程序：

```
D:\dsh-desktop\
  versions\<版本>\            <- 每个版本一个目录（互不覆盖）
  current.txt                 <- 当前版本
  启动-DeepSeek Harness.cmd
  更新-DeepSeek Harness.cmd    <- 拖入新 zip 即完成更新
```

它按"只拷贝变化文件"（未变文件用硬链接复用）做**增量更新**，旧版本保留可一键回滚，
并且**完全不碰** `%USERPROFILE%\.dsh`（配置/会话/凭据/已装插件都在那里，天然不被覆盖）。
详见 `build-win10/desktop/README.md`。

## 构建环境说明（为什么这样写）

* `runs-on: windows-2022`：runner 自带 Visual C++ Build Tools + Windows SDK —— 打包的
  `beforeBuild` 钩子会用 `cl.exe` 编译安装器 UI 组件，**连 `--dir` 也绕不过**。
* Node 24 + `corepack prepare pnpm@11.7.0`（仓库 `packageManager` 固定版本）。
* **必须自己写 `.env.windows`**：0.1.7 起 `apps/desktop/.env.windows.example` 里两个
  mandatory-update origin 是空值，直接拷贝模板会校验失败（`test` 部署还要求
  `allowedAuthOrigins` 非空）。未签名构建不会访问这些地址，只是打包期校验/嵌入。
* 未签名产物没有 `app-update.yml`、没有 blockmap、没有更新源，所以 electron-updater 的
  自动/增量下载**不可用**；更新靠上面的脚本搬运。
