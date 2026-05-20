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

ENTRY_ABILITY = """
import { FlutterAbility, FlutterEngine } from '@ohos/flutter_ohos';
import MethodChannel, { MethodResult } from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodChannel';
import MethodCall from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodCall';
import Want from '@ohos.app.ability.Want';
import wantConstant from '@ohos.app.ability.wantConstant';
import fileuri from '@ohos.file.fileuri';
import { GeneratedPluginRegistrant } from '../plugins/GeneratedPluginRegistrant';

const CHANNEL = 'bugaoshan/update';

export default class EntryAbility extends FlutterAbility {
  configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    GeneratedPluginRegistrant.registerWith(flutterEngine)
    this.configureBugaoshanChannel(flutterEngine)
  }

  private configureBugaoshanChannel(flutterEngine: FlutterEngine): void {
    const messenger = flutterEngine.getDartExecutor().getBinaryMessenger();
    const channel = new MethodChannel(messenger, CHANNEL);
    channel.setMethodCallHandler({
      onMethodCall: (call: MethodCall, result: MethodResult) => {
        switch (call.method) {
          case 'importIcsToCalendar':
            this.importIcsToCalendar(call.argument('path') as string, result);
            break;
          case 'updateWidget':
            result.success(null);
            break;
          case 'installApk':
          case 'installHap':
            this.openInstallFile(call.argument('path') as string, result);
            break;
          default:
            result.notImplemented();
        }
      }
    });
  }

  private importIcsToCalendar(path: string, result: MethodResult): void {
    if (!path) {
      result.error('INVALID_ARGUMENT', 'Path is empty', null);
      return;
    }

    const uri = fileuri.getUriFromPath(path);
    const want: Want = {
      flags: wantConstant.Flags.FLAG_AUTH_READ_URI_PERMISSION | wantConstant.Flags.FLAG_AUTH_WRITE_URI_PERMISSION,
      action: 'ohos.want.action.viewData',
      uri: uri,
      type: 'text/calendar',
      parameters: {
        mimeType: 'text/calendar'
      }
    };

    this.context.startAbility(want).then(() => {
      result.success('opened');
    }).catch((err: ESObject) => {
      result.error('OPEN_FAILED', err?.message ?? JSON.stringify(err), null);
    });
  }

  private openInstallFile(path: string, result: MethodResult): void {
    if (!path) {
      result.error('INVALID_ARGUMENT', 'Path is empty', null);
      return;
    }

    const uri = fileuri.getUriFromPath(path);
    const want: Want = {
      flags: wantConstant.Flags.FLAG_AUTH_READ_URI_PERMISSION,
      action: 'ohos.want.action.viewData',
      uri: uri,
      type: 'application/octet-stream',
      parameters: {
        mimeType: 'application/octet-stream'
      }
    };

    this.context.startAbility(want).then(() => {
      result.success(null);
    }).catch((err: ESObject) => {
      result.error('OPEN_FAILED', err?.message ?? JSON.stringify(err), null);
    });
  }
}
""".lstrip()

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
  image_picker:
    git:
      url: "https://gitcode.com/openharmony-tpc/flutter_packages.git"
      path: "packages/image_picker/image_picker"
  image_picker_ohos:
    git:
      url: "https://gitcode.com/openharmony-tpc/flutter_packages.git"
      path: "packages/image_picker/image_picker_ohos"
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
    if "\n  flutter_secure_storage_ohos:" not in text:
        text = text.replace(
            "  flutter_secure_storage: ^10.0.0\n",
            "  flutter_secure_storage: ^10.0.0\n  flutter_secure_storage_ohos: any\n",
        )
    if "dependency_overrides:" not in text:
        text += "\n" + OHOS_DEPENDENCY_OVERRIDES.lstrip()

    path.write_text(text, encoding="utf-8")


def patch_secure_storage_provider() -> None:
    path = SHELL / "lib" / "providers" / "secure_storage_provider.dart"
    lines = path.read_text(encoding="utf-8").splitlines()
    if not lines:
        raise SystemExit(f"Secure storage provider is empty: {path}")

    if lines[0].startswith("import 'package:flutter_secure_storage"):
        index = 1
        while index < len(lines) and lines[index].startswith("    if "):
            index += 1
        lines = [
            "import 'package:flutter_secure_storage_ohos/flutter_secure_storage_ohos.dart';"
        ] + lines[index:]

    path.write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")


def main() -> None:
    if not OHOS_WRAPPER.exists():
        raise SystemExit(f"HarmonyOS wrapper not found: {OHOS_WRAPPER}")

    mirror_directory(ROOT / "lib", SHELL / "lib")
    mirror_directory(ROOT / "assets", SHELL / "assets")
    shutil.copy2(ROOT / "pubspec.yaml", SHELL / "pubspec.yaml")
    shutil.copy2(ROOT / "l10n.yaml", SHELL / "l10n.yaml")

    patch_pubspec()
    patch_secure_storage_provider()
    (SHELL / "lib" / "services" / "ocr_service.dart").write_text(
        OCR_STUB,
        encoding="utf-8",
    )
    (OHOS_WRAPPER / "entry" / "src" / "main" / "ets" / "entryability" / "EntryAbility.ets").write_text(
        ENTRY_ABILITY,
        encoding="utf-8",
    )

    print(f"Prepared HarmonyOS Flutter shell at {SHELL}")


if __name__ == "__main__":
    main()
