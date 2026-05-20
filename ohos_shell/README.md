# HarmonyOS Shell

This directory keeps the HarmonyOS/OpenHarmony native wrapper in `ohos/`.

The Flutter app sources are not tracked here. They are generated from the repository root before a HarmonyOS build to avoid maintaining a stale duplicate copy of `lib/`, `assets/`, `pubspec.yaml`, and `l10n.yaml`.

## Local Build

Run these commands from the repository root after installing the Flutter-OH toolchain:

```bash
python3 .github/scripts/prepare_ohos.py
cd ohos_shell
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n
flutter build hap --release
```

GitHub Actions runs the same preparation step in `.github/workflows/release.yml`.
