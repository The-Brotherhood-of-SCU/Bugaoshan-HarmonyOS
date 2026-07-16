# HarmonyOS 开发指南

本项目使用 CPF Flutter 的 OpenHarmony 适配版本构建 HarmonyOS HAP，平台工程直接位于仓库根目录的 `ohos/`。

## 固定版本

| 组件 | 版本 |
| --- | --- |
| CPF Flutter | 3.41.9 (`aa33b6e2a6ed5e2672e45eef43d1221310a96878`) |
| Dart | 3.11.5 |
| Java | 17 |
| OHOS 最低兼容版本 | 5.1.0 (API 18) |
| 当前真机验证版本 | OpenHarmony 6.1.1.120 (API 24) |

Flutter SDK 和 OHOS 插件都固定到了不可变 Git 提交。升级时应同时验证 SDK、插件和真机，不要只移动其中一个版本。

## macOS 环境

安装 DevEco Studio 后，克隆 CPF Flutter：

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
export TOOL_HOME="/Applications/DevEco-Studio.app/Contents"
export DEVECO_SDK_HOME="$TOOL_HOME/sdk"
export HOS_SDK_HOME="$DEVECO_SDK_HOME"
export PUB_HOSTED_URL="https://pub.flutter-io.cn"
export FLUTTER_STORAGE_BASE_URL="https://storage.flutter-io.cn"
export FLUTTER_GIT_URL="https://gitcode.com/CPF-Flutter/flutter_flutter.git"
export PATH="$HOME/Developer/flutter-ohos/bin:$TOOL_HOME/tools/ohpm/bin:$TOOL_HOME/tools/hvigor/bin:$TOOL_HOME/tools/node/bin:$TOOL_HOME/sdk/default/openharmony/toolchains:$PATH"
```

重新打开终端后配置 SDK 并检查环境：

```bash
flutter config --ohos-sdk "/Applications/DevEco-Studio.app/Contents/sdk"
flutter doctor -v
flutter devices
```

## 依赖与生成

```bash
flutter pub get
dart run build_runner build
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

## 当前平台行为

- 课表使用 CPF `sqflite`，与其他平台共用 SQLite 数据模型。
- 登录令牌和记住的凭据使用 `flutter_secure_storage_ohos` 加密存储。
- 背景图片、外部链接、分享、应用信息和 SharedPreferences 已接入 OHOS 插件。
- ICS 导入通过 `bugaoshan/update` MethodChannel 调用系统日历处理应用。
- HarmonyOS 更新入口打开 Release 下载页，不尝试申请系统级静默安装权限。
- Android 桌面小组件、OCR 自动登录和相册直接保存暂未在 HarmonyOS 启用。

CI 会构建 unsigned HAP 作为编译产物，但不会把无签名 HAP 发布给最终用户。正式分发需要配置与 bundleName `com.scubrotherhood.bugaoshan` 匹配的发布证书和 Profile。
