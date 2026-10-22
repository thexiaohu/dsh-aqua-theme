># @deepseek-ai/dsh-client-ui-aqua

**Aqua** 是一层高自由度的玻璃质感主题（glassmorphism），套在 DeepSeek Harness 网页端：顶栏、侧边栏、输入框、统计行、轨迹视图全部变成磨砂玻璃片。关掉总开关即完全还原原生界面，不改 DSH 任何一行源码。

![](assets/1.png)

![](assets/2.png)

![](assets/3.png)

![](assets/4.png)

## ⚠️ 重要：本仓库是修改版，不是原创

> **署名 / Credits**
> - 原作者：**WYH66666666** — https://github.com/WYH66666666/DSH-Transparent-UI-Plugin
> - 0.1.1-rc.2 适配：**du-u-uck** — https://github.com/du-u-uck/DSH-Transparent-UI-Plugin
> - v0.2.x 适配：**acdsh4869** — https://github.com/acdsh4869/dsh-aqua-theme
> - 本仓库：**thexiaohu** — 在 acdsh4869 适配版基础上做了代码清理与功能精简

> **修改声明 / Modification Notice**
>
> 本仓库是原作品的**修改 / 适配版**，不是原创。
> - 原作者（Original author）：**WYH66666666**
> - 修改内容（Changes）：DeepSeek Harness **0.2.x** 兼容适配 + 代码清理与功能精简
> - 修改日期（Date of modification）：**2026-10**
> - 维护仓库（Maintained at）：`thexiaohu/dsh-aqua-theme`
> - 许可（License）：**AGPL-3.0**（沿用上游许可，必须保留）

## ⚠️ 源码与构建产物不同步（重要）

**本仓库的 `lib/client.js` 是修改后的构建产物，而 `src/` 目录仍是上游原始源码。**

这意味着：

| 你的操作 | 结果 |
|---|---|
| 直接使用 `lib/` | ✅ 得到清理后的版本（推荐） |
| 运行 `pnpm run bundle` 重新构建 | ⚠️ **会覆盖清理后的 `lib/`，恢复成上游原始版** |

如果你要重新构建，请先明白这一点。清理的内容见下方「本仓库的修改」。

## 本仓库的修改

在 `acdsh4869/dsh-aqua-theme` 基础上做了以下改动（**仅修改 `lib/client.js` 构建产物**）：

### 删除的功能

| 项目 | 原因 |
|---|---|
| 流体 WebGL 背景 | 该 WebGL 层在 `theme/change` 时丢失 token 覆盖，会在背景上画出一块实心色板 |
| 壁纸 / 视频背景 | 无 UI 入口，`background` 恒为 `"fluid"`，整条链路不可达 |
| 模式选择器（云母/兼容） | 用户只需云母效果 |
| 「恢复默认效果」按钮 | 保留设置值即可，不需要重置 |
| 背景亮度滑块 | 无 UI 入口 |
| 辉光颜色深浅滑块 | 保留色调滑块即可 |

### 新增的功能

| 项目 | 说明 |
|---|---|
| 「主题设置」统一标题 | 所有控件归到一组，不再有多个小标题 |
| 玻璃模糊度 / 玻璃磨砂度 | 滑块名称更明确 |
| 鼠标辉光色调 | 明确该滑块控制辉光而非流体 |
| 鱼数量 / 鱼尺寸 / 鱼颜色深浅 | 可调中鱼数量、小鱼数量、尺寸、透明度 |
| 复选框式开关 | 粒子鲸鱼 / 小鱼 / 网状交互 / 鼠标辉光 / 悬停下压 |

### 修复的问题

| 问题 | 修复 |
|---|---|
| 鼠标移到输入框左侧时面板上移 | `spot` 选择器从 `[data-dsh-inputbar]` 改为 `[data-composer-card]`，消除 spot 与 visual 的范围差 |
| 鱼群分布不均、成团 | 改用 Mitchell's Best-Candidate（蓝噪声）算法，无格点结构、无空洞 |
| 小鱼集中在下半区 | 小鱼槽位改为步进分配，均匀穿插 |
| 网格线几乎不可见 | 透明度从 `.10/.20` 提升到 `.22/.42` |
| 鲸鱼粒子偏淡 | 浅色模式 RGB 基准加深，亮度下限从 `.2` 提到 `.52` |
| 小鱼太小 | 尺寸提升，透明度从 `0.22` 提到 `0.55` |
| 网格绘制卡顿 | 单路径绘制 + 平方距离比较 + dpr 从 2 降到 1.5 |
| 辉光卡顿 | 改用 CSS 变量 `--gx/--gy`，避免每次 `pointermove` 重写 `background-image` |
| 鲸鱼卡顿 | 平方距离提前返回 + `alpha` 取整替代 `toFixed(3)` |

## 特性

- **玻璃材质**：模糊度、磨砂度可调，云母模式下布局变为悬浮玻璃卡片
- **环境装饰**：粒子鲸鱼、小鱼群、网状交互、鼠标辉光、悬停下压，均可单独开关
- **鱼群可调**：中鱼数量、小鱼数量、鱼尺寸、鱼颜色深浅
- **一键开关**：关闭即完全还原原生界面，无残留

## 安装

### 前提

- DeepSeek Harness **`0.2.0-rc.2`** 或更高（桌面端 v0.22.3+）
- Node.js 18+（仅重新构建时需要）

### 方式一：本地文件夹安装（推荐）

1. 下载或 clone 本仓库到本地：

```sh
git clone https://github.com/thexiaohu/dsh-aqua-theme.git
```

2. 运行安装脚本：

```powershell
powershell -ExecutionPolicy Bypass -Command ".\install.ps1 -Source '你的绝对路径\dsh-aqua-theme' -Profile web"
```

3. **刷新 Web 界面**即可生效。

本地路径会建立 **junction 软链**，之后修改代码或重建会直接反映到 DSH，无需重装。

### 方式二：手动安装（macOS / Linux）

```sh
git clone https://github.com/thexiaohu/dsh-aqua-theme.git

# 建立软链
ln -s "$PWD/dsh-aqua-theme" "$DSH_HOME/profiles/node_modules/@deepseek-ai/dsh-client-ui-aqua"
```

再往 `$DSH_HOME/profiles/web/cordis.patch.yml` 追加：

```yaml
- insert:
    - id: ui-aqua
      name: '@deepseek-ai/dsh-client-ui-aqua'
```

刷新 Web 界面。

### 方式三：Windows 手动安装

```powershell
# 1. 建立 junction
New-Item -ItemType Junction `
  -Path "$env:USERPROFILE\.dsh\profiles\node_modules\@deepseek-ai\dsh-client-ui-aqua" `
  -Target "你的绝对路径\dsh-aqua-theme"

# 2. 编辑 %USERPROFILE%\.dsh\profiles\web\cordis.patch.yml，追加：
#    - insert:
#        - id: ui-aqua
#          name: '@deepseek-ai/dsh-client-ui-aqua'
```

## 使用

刷新 Web 界面后，Aqua **默认开启**。

打开 **设置 → 通用设置 → 外观**，在「主题设置」下可以看到：

### 滑块

| 滑块 | 范围 | 说明 |
|---|---|---|
| 玻璃模糊度 | 0–40px | 玻璃背景的模糊半径 |
| 玻璃磨砂度 | 0–100% | 玻璃的磨砂程度 |
| 鼠标辉光色调 | 0–360° | 辉光颜色（色相） |
| 中鱼数量 | 0–24 条 | 中等大小的鱼的数量 |
| 小鱼数量 | 0–24 条 | 小尺寸鱼的数量 |
| 鱼尺寸 | 8–80px | 基准尺寸，大鱼=1.6×、中鱼=1×、小鱼=0.62× |
| 鱼颜色深浅 | 0–100% | 鱼的透明度 |

### 复选框

粒子鲸鱼 / 小鱼 / 网状交互 / 鼠标辉光 / 悬停下压

> 若刷新后未出现设置项，重启 DSH 进程后再试。

## 已知行为

- **调整小鱼数量时，中鱼尺寸可能变化**：因为小鱼槽位的分配依赖总数，改变数量会重新分配「哪条鱼算小鱼」，导致某些位置的鱼从固定的小尺寸变成随机的中尺寸。位置和尺寸系数本身是稳定的。
- **鱼群位置随窗口尺寸变化**：布局用像素坐标计算，改变窗口大小会重新分布。

## 兼容性

适配 **DeepSeek Harness `0.2.0-rc.2`**（含桌面端 v0.22.3 及以上），版本号 `2.0.0-rc.1`。

上游适配记录见 [CHANGELOG.md](CHANGELOG.md)。

## 重新构建（谨慎）

```sh
pnpm install
pnpm run bundle   # tsdown + tsc + wrap-client.mjs → 完整 lib/
```

⚠️ **重新构建会覆盖本仓库的修改**，恢复成上游原始版（含流体 WebGL 代码）。除非你打算自己重新实现那些清理。

## 许可证

**AGPL-3.0** — 沿用上游许可。

本项目基于 WYH66666666 的原创作品，经 du-u-uck、acdsh4869 及本仓库多次修改。根据 AGPL-3.0：

- 必须保留原作者署名
- 衍生作品必须同样使用 AGPL-3.0
- 分发时必须提供完整源码

详见 [LICENSE](LICENSE)。

AGPL-3.0 © 原作者 WYH66666666 及各适配者
