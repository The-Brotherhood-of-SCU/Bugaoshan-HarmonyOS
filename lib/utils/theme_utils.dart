import 'package:flutter/material.dart';
import 'package:system_theme/system_theme.dart';

import 'package:bugaoshan/utils/platform_utils.dart';

const Color fallbackThemeColor = Colors.blue;

Future<Color> loadSystemAccentColor() async {
  if (AppPlatform.isHarmony) return fallbackThemeColor;
  try {
    SystemTheme.fallbackColor = fallbackThemeColor;
    await SystemTheme.accentColor.load();
    return SystemTheme.accentColor.accent;
  } catch (_) {
    return fallbackThemeColor;
  }
}

Color currentSystemAccentColor() {
  if (AppPlatform.isHarmony) return fallbackThemeColor;
  return SystemTheme.accentColor.accent;
}
