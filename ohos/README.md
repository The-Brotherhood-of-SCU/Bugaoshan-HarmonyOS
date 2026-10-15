# HarmonyOS 开发指南

本目录是不高山上（Bugaoshan）的 HarmonyOS 原生工程，与其他平台在同一分支维护。
DevEco Studio 直接打开本目录。

## 目录结构

```text
ohos/
├── AppScope/          # 应用标识、版本与图标
├── entry/             # 原生入口、平台通道、课表卡片与资源
├── hvigor/            # Hvigor 配置
├── hvigorfile.ts      # 原生构建任务
├── hvigorconfig.ts     # Flutter 插件模块注入
├── oh-package.json5   # 鸿蒙工程依赖
├── build-profile.json5
└── vendor/cpf/        # 本地 CPF 源码克隆（不入库）
```

## 环境要求

| 工具 | 版本 |
| --- | --- |
| HarmonyOS SDK | API 26（编译与目标），最低安装 API 20 |
| DevEco Studio | 26.0.0.821，使用配套 Node、OHPM 和 Hvigor |
| Flutter OH | 见根 `pubspec.yaml` 的 OH 平台包来源 |

## 构建

确认 PATH 中的 `flutter` 指向 Flutter OH，并且 `ohos/local.properties` 中的
`flutter.sdk` 指向同一套 SDK。DevEco Sync 会在首次使用或依赖变更后自动执行
`flutter pub get --no-example --enforce-lockfile`，生成插件列表并安装
`flutter-hvigor-plugin`。Sync 中的 Pub 命令使用根锁指定的 `pub.flutter-io.cn` 镜像。
更新 `pubspec.yaml` 中的 Git 提交后，先按 `CONTRIBUTING.md` 设置相同的
`PUB_HOSTED_URL`，在仓库根目录运行 `flutter pub get --no-example` 生成新锁；
Sync 的 `--enforce-lockfile` 不会自动更新锁文件。

在 DevEco Studio 中打开本目录并执行 Sync，然后运行或构建 HAP：

- **Debug**：选择 `entry` 模块直接运行。
- **Release**：`Build > Build Hap(s)/APP(s)`。
- 真机部署需在 DevEco 中配置调试签名；签名路径、证书和密码不得提交。

无签名 `build-profile.json5` 基线受版本控制，使 DevEco 在首次 Sync 前即可识别本工程。

## Flutter 依赖

鸿蒙沿用根 `pubspec.yaml` 与根 `pubspec.lock`，不维护独立锁文件。
OH 平台实现通过根 `pubspec.yaml` 的普通 Git 依赖声明：

| 包 | 来源 |
| --- | --- |
| `shared_preferences_ohos` / `image_picker_ohos` / `path_provider_ohos` / `url_launcher_ohos` | CPF `flutter_packages` |
| `sqflite_ohos` | CPF `flutter_sqflite` |
| `package_info_plus_ohos` / `share_plus_ohos` | 独立 [package_info_plus_ohos](https://github.com/HuajiFruit/package_info_plus_ohos) 和 [share_plus_ohos](https://github.com/HuajiFruit/share_plus_ohos) Git 仓库；普通依赖固定提交 |

`open_file_ohos` 作为普通 Git 依赖声明。根 `lib/utils/open_file.dart` 的 `openFile(path)`
在鸿蒙调用该包，其他平台调用官方 `OpenFilex`。

> 根锁包含 WebView 提交 `edd0663cf` 与 `flutter_inappwebview_ohos 1.1.3`，
> 以及上述 OH 平台包、`open_file_ohos`、`image_gallery_saver_plus` 和安全存储 OH 实现。
> 依赖已解析；原生编译与真机功能仍待验证。

## 原生导航、按钮与开关

Flutter 继续使用根 `lib/widgets/navigation/adaptive_home_dock.dart` 与
`lib/widgets/adaptive/adaptive_glass_controls.dart` 的现有封装，业务页面不维护鸿蒙副本。
OHOS 分支通过 CPF Flutter 的 `OhosView` 嵌入 ArkUI；iOS 保留原有能力探测与 UIKit 路径。
OHOS 能力缓存放在现有控件封装内供 Dock 共用；两个封装各自构造平台视图，
使用现有 `isOhos` 工具识别系统。

原生实现在 `entry/src/main/ets/platform/native_ui/`，由 `EntryAbility` 为每个引擎注册
`NativeUiPlugin`，不修改生成的插件注册文件。每个视图单独持有配置与通道，不使用
`AppStorage` 共享开关值；视图或引擎释放时注销 handler 并关闭溢出菜单。

| 功能 | API 20–25 | API 26+ |
| --- | --- | --- |
| 窄屏 Home Dock | 普通 ArkUI `Tabs`，内容避让底栏 | 原生悬浮底栏，内容延伸与底部留白复用 Flutter 现有实现 |
| 已接入按钮 | ArkUI `Button` | ArkUI `Button`；表单按钮不宣称具有沉浸光感 |
| 已接入开关 | ArkUI `ToggleType.Switch` | 系统沉浸光感开关，遵循系统材质设置与设备能力 |
| 宽屏导航 | 原有 Flutter `NavigationRail` | 原有 Flutter `NavigationRail` |

底栏最多展示五项，超出时展示前三项、当前额外项（或第四项）及“更多”。
“更多”使用可滚动的原生半模态列表，支持全部入口与角标。Flutter 仍按稳定 ID 管理
选中项、学生身份筛选与页面状态；原生侧不创建业务页。
底部安全区由 Flutter 传入，原生 `Tabs` 关闭默认安全区扩展，避免重复避让。
原生图标使用 OHOS 系统 `sys.symbol` 资源与 ArkUI `SymbolGlyph`，不新增 SVG 图标文件。
iOS 继续使用系统 SF Symbols；共享封装传入的图标名称由 OHOS 后端映射为本平台符号。

能力通道沿用 `bugaoshan/liquid_glass`。OHOS 使用 `getCapabilities`，返回
`version: 1`、`backend: ohos`、各控件能力、`floatingDock`、材质能力与布局尺寸。
普通原生控件可用不等于材质可用。视图类型沿用 `bugaoshan/liquid_glass_dock` 和
`bugaoshan/liquid_glass_control`；实例通道追加 `/<viewId>`。
`update` 接收完整配置；原生仅回传 `select(String)`、`activate(null)` 或 `change(bool)`。
开关值与导航选择以 Flutter 为准，配置下发不触发业务回调。
开关单独记录原生侧的临时值，Flutter 拒绝修改时恢复显示；父行与控件的重复点击被合并。

### 验证交接

此次仅修改代码与文档，未执行依赖解析、分析、格式化、测试或构建。
本机可读取的 DevEco SDK 为 API 21；新增 API 26 材质及悬浮栏接口依据官方 API 定义接入，
请使用工程要求的 API 26 SDK 构建。API 26 材质实现在版本判断后延迟加载，
避免旧系统启动时加载新系统模块；普通原生控件不依赖该模块。

可先运行 `test/ohos_native_ui_test.dart` 与既有 `test/adaptive_glass_controls_test.dart`、
`test/adaptive_home_dock_test.dart`；ArkTS 配置校验用例已接入 `ohosTest` 的测试入口。
真机重点确认：API 20 与 API 26 的普通/悬浮导航、深浅色、系统关闭材质、文字缩放、RTL、
禁用/loading、开关与行点击只触发一次、从开关区域起手滚动、入口增删重排、超五项菜单、
键盘、安全区、弹窗与 WebView 叠放，以及多次进出页面后的通道和视图释放。

`OhosView` 使用同层纹理合成；系统材质能否正确采样其后的 Flutter 滚动内容仍须真机确认。
当前实现没有截图模糊或额外全局浮层；声明支持材质仅表示接口可用，不代表跨渲染层视觉已验收。

## 本地 CPF 源码

`vendor/cpf/` 保存 CPF 仓库的本地工作副本，**不入库**，只用于维护和对照源码。
根依赖不再引用其中的 `package_info_plus_ohos` 和 `share_plus_ohos` 路径。
