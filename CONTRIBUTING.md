# 贡献指南

欢迎提交 Issue 和 Pull Request！

## 📥 下载体验

**前往上游 [Release 页面](https://github.com/The-Brotherhood-of-SCU/Bugaoshan/releases/latest) 下载 Android、Windows 或 Linux 最新版本。HarmonyOS HAP 不在通用 Release 中发布。**

---

## 💻 本地开发

### 环境要求

- 标准平台：[Flutter SDK](https://flutter.dev/docs/get-started/install) >= 3.44、Dart SDK >= 3.11.0；GitHub Actions 使用 Flutter 3.44.6
- Flatpak：打包清单固定 Flutter 3.44.4
- HarmonyOS：固定 CPF Flutter 3.41.9 / Dart 3.11.5，并需要 DevEco Studio 6.1.1 Release、Java 17；完整配置见 [HarmonyOS 开发指南](docs/HARMONYOS.md)
- Windows：[NuGet CLI](https://learn.microsoft.com/en-us/nuget/install-nuget-client-tools?tabs=windows#nugetexe-cli)，供 `flutter_inappwebview` Windows target 构建使用

标准 Flutter SDK 不能用于构建 HarmonyOS HAP；HarmonyOS 开发必须使用指南中固定到具体提交的 CPF Flutter。

### 安装运行

```bash
# 克隆仓库
git clone git@github.com:The-Brotherhood-of-SCU/Bugaoshan-HarmonyOS.git
# 或
git clone https://github.com/The-Brotherhood-of-SCU/Bugaoshan-HarmonyOS.git

cd Bugaoshan-HarmonyOS
```

> #### Pre-commit Hook
>
> 项目内置了 pre-commit hook，会在提交时自动对暂存的 `.dart` 文件执行 `dart format`。
>
> 克隆仓库后，将 hook 链接或复制到 `.git/hooks/`：
>
> ```bash
> # Linux / macOS
> ln -sf .githooks/pre-commit .git/hooks/pre-commit
>
> # Windows (Git Bash)
> cp .githooks/pre-commit .git/hooks/pre-commit
> ```

> #### 设置镜像源
>
> 安装依赖前设置国内镜像源，否则 `pubspec.lock` 会变国际源，导致工作区产生不必要的 diff。
>
> 持久化设置：
>
> ```bash
> # Windows (管理员 PowerShell)
> setx PUB_HOSTED_URL "https://pub.flutter-io.cn" /M
> setx FLUTTER_STORAGE_BASE_URL "https://storage.flutter-io.cn" /M
>
> # Linux / macOS (添加到 shell 配置文件 ~/.bashrc, ~/.zshrc 等)
> export PUB_HOSTED_URL=https://pub.flutter-io.cn
> export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
> ```

```bash
# 安装依赖（已设镜像则直接执行）
flutter pub get

# 运行代码生成（DI / JSON 序列化）
dart run build_runner build --delete-conflicting-outputs

# build_runner 完成后生成国际化代码
flutter gen-l10n

# 运行 App
flutter run
```

---

## 📁 项目结构

```
lib/
├── injection/            # 依赖注入（GetIt + Injectable）
├── l10n/                 # 国际化（ARB 文件及生成代码）
├── models/               # 数据模型
├── pages/                # 页面
├── providers/            # 状态管理
├── services/             # 业务逻辑与服务层
├── utils/                # 工具类与常量
├── widgets/              # 可复用 UI 组件
├── app.dart              # App 配置与主题
└── main.dart             # 入口
```

---

## 🛠️ 技术栈

| 类别     | 技术                                                                                                         |
| -------- | ------------------------------------------------------------------------------------------------------------ |
| 框架     | [Flutter](https://flutter.dev)                                                                               |
| 状态管理 | Flutter 内置 `ValueNotifier` / `ChangeNotifier`、`ValueListenableBuilder` / `ListenableBuilder`             |
| 依赖注入 | [GetIt](https://pub.dev/packages/get_it) + [Injectable](https://pub.dev/packages/injectable)                 |
| 网络请求 | [`package:http`](https://pub.dev/packages/http) + 自定义 `CookieClient`                                      |
| 本地存储 | [SQLite](https://pub.dev/packages/sqflite)、[SharedPreferences](https://pub.dev/packages/shared_preferences) |
| 国际化   | Flutter `flutter_localizations`                                                                              |
| 国密算法 | [dart_sm](https://pub.dev/packages/dart_sm)（SM2/SM3/SM4）                                                   |
| OCR      | [scu_ocr_lite](https://github.com/The-Brotherhood-of-SCU/scu_ocr_lite_dart)（纯 Dart 实现）                  |

---

## 🔄 贡献流程

1. Fork 本仓库
2. 创建功能分支 (`git checkout -b feature/your-feature`)
3. 提交更改 (`git commit -m 'feat: add some feature'`)
4. 推送分支 (`git push origin feature/your-feature`)
5. 发起 Pull Request

---

## 团队

**The-Brotherhood-of-SCU** — 一个非官方的四川大学开源组织

---

## 许可证

本项目基于 [AGPL-3.0](LICENSE) 协议开源。
