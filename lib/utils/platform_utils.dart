import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:os_type/os_type.dart';

class AppPlatform {
  const AppPlatform._();

  static bool get isHarmony => !kIsWeb && OS.isHarmony;

  static bool get isAndroid => !kIsWeb && !isHarmony && Platform.isAndroid;

  static bool get isIOS => !kIsWeb && Platform.isIOS;

  static bool get isWindows => !kIsWeb && Platform.isWindows;

  static bool get isLinux => !kIsWeb && Platform.isLinux;

  static bool get isMacOS => !kIsWeb && Platform.isMacOS;

  static bool get isDesktop => isWindows || isLinux || isMacOS;

  static bool get isMobile => isAndroid || isIOS || isHarmony;

  static bool get supportsHomeWidget => isAndroid;

  static bool get supportsAutoLogin => !isHarmony;

  static bool get supportsSystemCalendarImport => isAndroid || isHarmony;

  static bool get supportsInAppUpdate =>
      isAndroid || isWindows || isLinux || isHarmony;
}
