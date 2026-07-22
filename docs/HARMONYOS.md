# HarmonyOS 开发指南

本项目基于上游不高山上 `2.2.0+3`，使用 CPF Flutter 的 OpenHarmony 适配版本构建 HarmonyOS HAP，平台工程直接位于仓库根目录的 `ohos/`。

## 固定版本

| 组件 | 版本 |
| --- | --- |
| 不高山上 | 2.2.0+3 |
| CPF Flutter | 3.41.9 (`aa33b6e2a6ed5e2672e45eef43d1221310a96878`) |
| Dart | 3.11.5 |
| Java | 17 |
| DevEco Studio | 6.1.1 Release |
| OHOS 编译 SDK | 6.1.1 Release (API 24) |
| OHOS 目标版本 | 6.1.0 Release (API 23) |
| OHOS 最低兼容版本 | 5.1.0 (API 18) |
| 当前真机验证版本 | OpenHarmony 6.1.1.120 (API 24) |

Flutter SDK 和 OHOS 插件都固定到了不可变 Git 提交。升级时应同时验证 SDK、插件和真机，不要只移动其中一个版本。

## 安装与分发

上游 [GitHub Release](https://github.com/The-Brotherhood-of-SCU/Bugaoshan/releases/latest) 提供 Android APK、Windows 压缩包和 Linux 压缩包，不包含 HarmonyOS HAP。HarmonyOS HAP 不参与通用 Release 流程，需要使用本指南中的环境单独构建，并通过匹配 `com.scubrotherhood.bugaoshan` 的证书和 Profile 签名后分发。

Release 中的 Android APK 不能代替 HAP 安装到 HarmonyOS。CI 生成的 unsigned HAP 仅用于构建验证，也不是面向用户的安装包。

## macOS 环境

安装 DevEco Studio 6.1.1 Release 后，克隆 CPF Flutter。不要使用 Beta SDK
构建分发包，否则产物的 `pack.info` 会包含 `releaseType: Beta1`，无法通过
AppGallery Connect 上架检测。

```bash
mkdir -p "$HOME/Developer"
git clone --branch oh-3.41.9-release \
  https://gitcode.com/CPF-Flutter/flutter_flutter.git \
  "$HOME/Developer/flutter-ohos"
git -C "$HOME/Developer/flutter-ohos" checkout \
  aa33b6e2a6ed5e2672e45eef43d1221310a96878

FLUTTER_OH_ROOT="$HOME/Developer/flutter-ohos" \
  python3 .github/scripts/configure_flutter_ohos.py
```

CPF 的 3.41.9 分支没有版本 tag，`configure_flutter_ohos.py` 用于写入确定的 Flutter 版本元数据，避免 SDK 被识别为 `0.0.0-unknown`。

将以下配置加入 `~/.zprofile`：

```bash
export JAVA_HOME="/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home"
export TOOL_HOME="/Applications/DevEco-Studio-6.1.1.app/Contents"
export DEVECO_SDK_HOME="$TOOL_HOME/sdk"
export HOS_SDK_HOME="$DEVECO_SDK_HOME"
export PUB_HOSTED_URL="https://pub.flutter-io.cn"
export FLUTTER_STORAGE_BASE_URL="https://storage.flutter-io.cn"
export FLUTTER_GIT_URL="https://gitcode.com/CPF-Flutter/flutter_flutter.git"
export PATH="$HOME/Developer/flutter-ohos/bin:$TOOL_HOME/tools/ohpm/bin:$TOOL_HOME/tools/hvigor/bin:$TOOL_HOME/tools/node/bin:$TOOL_HOME/sdk/default/openharmony/toolchains:$PATH"
```

重新打开终端后配置 SDK 并检查环境：

```bash
flutter config --ohos-sdk "/Applications/DevEco-Studio-6.1.1.app/Contents/sdk"
flutter doctor -v
flutter devices
```

`flutter doctor -v` 应显示 API 24，且 SDK 的
`default/openharmony/ets/oh-uni-package.json` 中必须是
`"releaseType": "Release"`。

## 依赖与生成

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n
flutter analyze
flutter test
```

OHOS 插件通过 `pubspec.yaml` 中的 `dependency_overrides` 固定到 CPF 仓库。不要将这些依赖恢复为未固定的分支或 `any`。

## 构建与签名

`ohos/build-profile.json5` 包含本地证书路径和口令，因此不会提交到 Git。首次构建先创建本地配置：

```bash
cp ohos/build-profile.json5.example ohos/build-profile.json5
```

无签名构建可用于 CI 验证：

```bash
flutter build hap --debug --no-codesign
flutter build hap --release --no-codesign
```

真机调试需要使用 DevEco Studio 打开 `ohos/`，进入 `File -> Project Structure -> Signing Configs`，为 `default` 勾选自动签名并等待证书、Profile 和密钥路径生成。之后运行：

```bash
flutter build hap --debug
flutter run --debug -d <device-id>
```

调试产物位于 `build/ohos/hap/entry-default-signed.hap`。

AppGallery Connect 使用的 `.app` 通过以下命令构建：

```bash
flutter clean
flutter pub get
flutter build hap --release
cd ohos
hvigorw assembleApp -p product=default -p buildMode=release --no-daemon
```

签名 App Pack 位于 `ohos/build/outputs/default/ohos-default-signed.app`。上传前检查
同目录的 `pack.info`，其中 `apiVersion.releaseType` 必须是 `Release`。测试分发时
使用 DevEco Studio 的 `Build -> Upload Product -> Testing Only`，由 AppGallery
Connect 使用云管理证书重新签名。

## 当前平台行为

以下能力已适配 HarmonyOS：

- 课表使用 CPF `sqflite`，与其他平台共用 SQLite 数据模型。
- 登录令牌和记住的凭据使用 `flutter_secure_storage_ohos` 加密存储。
- 外部链接、分享、应用信息和 SharedPreferences 已接入 OHOS 插件。
- ICS 导入通过 `bugaoshan/update` MethodChannel 调用系统日历处理应用。
- 课表背景图可正常从系统图库选择，也可从背景图提取主题色。
- OCR 自动登录使用纯 Dart `scu_ocr_lite`，在 HarmonyOS 上保留并纳入真机验证。

以下能力当前暂不提供：

- 校园模块中的教务处、党委学工部和青春川大通知公告，以及通知附件下载管理入口。
- Android 桌面课表小组件及其设置、首次启动引导中的小组件页面。
- 全屏图片查看器中的“保存到相册”和“分享”操作；图片本身仍可在查看器中浏览。这不影响从系统图库选择课表背景图，也不代表 HarmonyOS 上所有分享能力都不可用。
- 跟随系统强调色；仍可使用自定义主题色或从课表背景图提取主题色。
- 部分依赖通用文件选择器或文件打开器的操作，例如将日历导出为指定位置的 `.ics` 文件、保存认证日志。通过系统日历处理应用导入课程和校历仍然可用。
- 应用内检查、下载和安装更新。HarmonyOS HAP 采用独立的构建与分发流程，不从上游通用 Release 选择安装包。

## CI 验证

GitHub 托管 runner 没有可可靠自动安装的 DevEco Studio 6.1.1 Release / HarmonyOS API 24 Release SDK。`.github/workflows/build-ohos.yml` 因此在 Pull Request 上使用固定 CPF Flutter 执行依赖解析、代码生成、本地化生成、静态分析和完整 Dart/Widget 测试。

unsigned release HAP 构建仅能通过 `workflow_dispatch` 显式启用，并要求带有 `harmonyos-api-24-release` 标签的 self-hosted macOS runner。该 runner 必须预装 DevEco Studio 6.1.1 Release，将 `DEVECO_SDK_HOME` 指向其 `Contents/sdk`，并可访问 GitCode 和 Flutter/Pub 镜像。工作流会在构建前验证 ETS 和 Native SDK 都是 API 24 `Release`，不符合时直接失败。

CI 生成的 unsigned HAP 只作为短期 Actions 验证产物，不会被 `.github/workflows/release.yml` 下载或发布。正式分发需要配置与 bundleName `com.scubrotherhood.bugaoshan` 匹配的发布证书和 Profile。
