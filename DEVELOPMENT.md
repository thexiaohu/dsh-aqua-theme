# 开发说明

## 源码与运行时

- `src/client/` — 上游 TypeScript 源码，仅供参考，**不会被打包**
- `lib/client.js` — DSH 实际加载的构建产物（`package.json` 的 `main`）

**改动必须直接改 `lib/client.js`。** 重新构建会用上游代码覆盖所有修改。

`lib/client.js` 保留宿主要求的 `window.__ModuleLoader__.load(...)` 外壳，CSS 内联其中。

## 修改后验证

```powershell
node --check lib/client.js
```

注意：`node --check` 只验证语法，**不会发现未定义的函数引用**。改完需启动 DSH 实测。

## 本地安装

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1 -Profile desktop
```

安装脚本**不会覆盖已有安装**：本地已存在 `lib/client.js` 时直接复用，保留你的修改。需要重新下载时加 `-Force`。

## 已知约束

- CSS 在模板字符串内，**注释里不能出现反引号**（会导致整个模块解析失败）
- 宿主元素的 `z-index` 保持原值（顶栏/输入框/统计行 8、侧栏 9），只调整插件自己的层
- `backdrop-filter` 会创建层叠上下文，`transform` 也是 —— 调整层数时需留意
