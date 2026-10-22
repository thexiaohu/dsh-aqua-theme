# 开发说明

仓库只保留运行时文件，不附带构建源码：

    lib/client.js      DSH 实际加载的插件本体（CSS 内联其中）
    lib/index.js       node 侧空壳，让插件出现在加载器列表里
    cordis.patch.yml   把 client 注册进 profile 的浏览器清单
    package.json       dsh.client 声明注入项与平台
    install.ps1        本地安装脚本

改动**直接编辑 `lib/client.js`** 即可。

## 修改后验证

    node --check lib/client.js

注意 `node --check` 只验证语法，不会发现未定义的函数引用。改完启动 DSH 实测。

## 已知约束

- CSS 在模板字符串内，注释里不能出现反引号，否则整个模块解析失败
- 宿主元素的 z-index 保持原值（顶栏/输入框/统计行 8、侧栏 9），只调整插件自己的层
- backdrop-filter 与 transform 都会创建层叠上下文，调整层数时需留意
