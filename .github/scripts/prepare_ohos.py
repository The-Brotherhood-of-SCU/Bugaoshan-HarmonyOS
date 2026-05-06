"""Prepare the generated Flutter shell for HarmonyOS builds."""

from __future__ import annotations

import shutil
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SHELL = ROOT / "ohos_shell"
OHOS_WRAPPER = SHELL / "ohos"

OCR_STUB = """import 'dart:typed_data';

class OcrService {
  static Future<void> init() async {}

  static Future<void> dispose() async {}

  static Future<String> performOcr(Uint8List imageBytes) async {
    return '';
  }
}
"""

OHOS_DEPENDENCY_OVERRIDES = """
dependency_overrides:
  shared_preferences:
    git:
      url: "https://gitcode.com/openharmony-tpc/flutter_packages.git"
      path: "packages/shared_preferences/shared_preferences"
  shared_preferences_ohos:
    git:
      url: "https://gitcode.com/openharmony-tpc/flutter_packages.git"
      path: "packages/shared_preferences/shared_preferences_ohos"
  shared_preferences_foundation:
    git:
      url: "https://gitcode.com/openharmony-tpc/flutter_packages.git"
      path: "packages/shared_preferences/shared_preferences_foundation"
  path_provider:
    git:
      url: "https://gitcode.com/openharmony-tpc/flutter_packages.git"
      path: "packages/path_provider/path_provider"
  path_provider_ohos:
    git:
      url: "https://gitcode.com/openharmony-tpc/flutter_packages.git"
      path: "packages/path_provider/path_provider_ohos"
  path_provider_foundation:
    git:
      url: "https://gitcode.com/openharmony-tpc/flutter_packages.git"
      path: "packages/path_provider/path_provider_foundation"
  url_launcher:
    git:
      url: "https://gitcode.com/openharmony-tpc/flutter_packages.git"
      path: "packages/url_launcher/url_launcher"
  url_launcher_ohos:
    git:
      url: "https://gitcode.com/openharmony-tpc/flutter_packages.git"
      path: "packages/url_launcher/url_launcher_ohos"
  flutter_secure_storage:
    git:
      url: "https://gitcode.com/openharmony-sig/fluttertpc_flutter_secure_storage.git"
      path: "flutter_secure_storage"
  flutter_secure_storage_ohos:
    git:
      url: "https://gitcode.com/openharmony-sig/fluttertpc_flutter_secure_storage.git"
      path: "flutter_secure_storage_ohos"
  flutter_secure_storage_platform_interface:
    git:
      url: "https://gitcode.com/openharmony-sig/fluttertpc_flutter_secure_storage.git"
      path: "flutter_secure_storage_platform_interface"
  package_info_plus:
    git:
      url: "https://gitcode.com/openharmony-sig/flutter_plus_plugins.git"
      path: "packages/package_info_plus/package_info_plus"
"""


def mirror_directory(source: Path, destination: Path) -> None:
    if destination.exists():
        shutil.rmtree(destination)
    shutil.copytree(source, destination)


def patch_pubspec() -> None:
    path = SHELL / "pubspec.yaml"
    lines = path.read_text(encoding="utf-8").splitlines()
    patched: list[str] = []
    in_environment = False

    for line in lines:
        stripped = line.strip()
        if line.startswith("environment:"):
            in_environment = True
        elif line and not line.startswith(" ") and not line.startswith("#"):
            in_environment = False

        if in_environment and stripped.startswith("sdk:"):
            patched.append("  sdk: '>=3.9.0 <4.0.0'")
            continue

        if line.lstrip().startswith("flutter_litert:"):
            continue

        patched.append(line)

    text = "\n".join(patched).rstrip() + "\n"
    if "dependency_overrides:" not in text:
        text += "\n" + OHOS_DEPENDENCY_OVERRIDES.lstrip()

    path.write_text(text, encoding="utf-8")


def main() -> None:
    if not OHOS_WRAPPER.exists():
        raise SystemExit(f"HarmonyOS wrapper not found: {OHOS_WRAPPER}")

    mirror_directory(ROOT / "lib", SHELL / "lib")
    mirror_directory(ROOT / "assets", SHELL / "assets")
    shutil.copy2(ROOT / "pubspec.yaml", SHELL / "pubspec.yaml")
    shutil.copy2(ROOT / "l10n.yaml", SHELL / "l10n.yaml")

    patch_pubspec()
    (SHELL / "lib" / "services" / "ocr_service.dart").write_text(
        OCR_STUB,
        encoding="utf-8",
    )

    print(f"Prepared HarmonyOS Flutter shell at {SHELL}")


if __name__ == "__main__":
    main()
