import 'package:flutter/foundation.dart' show kDebugMode, kIsWasm, kIsWeb;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:bugaoshan/models/version_info.dart';
import 'package:bugaoshan/providers/environment_info/native.dart';

class AppInfoProvider {
  PackageInfo packageInfo;
  AppInfoProvider(this.packageInfo) {
    _version = packageInfo.version;
  }

  late String _version;

  String get currentVersion {
    return _version;
  }

  String get gitTag =>
      const String.fromEnvironment('GIT_TAG', defaultValue: 'null');
  String get gitCommit =>
      const String.fromEnvironment('GIT_COMMIT', defaultValue: 'null');
  String get gitCommitDateRaw =>
      const String.fromEnvironment('GIT_COMMIT_DATE', defaultValue: 'null');
  String get buildTime =>
      const String.fromEnvironment('BUILD_TIME', defaultValue: 'null');
  String get shortCommit =>
      gitCommit.length >= 7 ? gitCommit.substring(0, 7) : gitCommit;

  Future<VersionInfo> getVersionInfo() async {
    return VersionInfo(
      app:
          "AppName: ${packageInfo.appName}\n"
          "BuildNumber: ${packageInfo.buildNumber}\n"
          "Version: ${packageInfo.version}\n"
          "Signature: ${packageInfo.buildSignature}\n"
          "Installer: ${packageInfo.installerStore}\n"
          "PackageName: ${packageInfo.packageName}",
      environment: await getEnvironmentInfo(),
      flag:
          "Web: $kIsWeb\n"
          "WASM: $kIsWasm\n"
          "Debug: $kDebugMode",
      build:
          "Tag: $gitTag\n"
          "Commit: $shortCommit\n"
          "CommitDate: $gitCommitDateRaw\n"
          "BuildTime: $buildTime",
    );
  }
}
