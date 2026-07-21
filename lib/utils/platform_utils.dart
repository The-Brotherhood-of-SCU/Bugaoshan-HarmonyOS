import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:os_type/os_type.dart';

class AppPlatform {
  const AppPlatform._();

  static bool get isHarmony => !kIsWeb && OS.isHarmony;

  static bool get isAndroid {
    if (kIsWeb || OS.isHarmony) return false;
    return Platform.isAndroid ||
        defaultTargetPlatform == TargetPlatform.android;
  }

  static bool get isIOS => !kIsWeb && Platform.isIOS;

  static bool get isWindows => !kIsWeb && Platform.isWindows;

  static bool get isLinux => !kIsWeb && Platform.isLinux;

  static bool get isMacOS => !kIsWeb && Platform.isMacOS;

  static bool get isDesktop => isWindows || isLinux || isMacOS;

  static bool get isMobile => isHarmony || isAndroid || isIOS;

  static bool get supportsHomeWidget => isAndroid;

  static bool get supportsSystemCalendarImport => isHarmony || isAndroid;

  static bool get supportsInAppUpdate =>
      !isHarmony && (isAndroid || isWindows || isLinux);
}
