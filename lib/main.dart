import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:bugaoshan/app.dart';
import 'package:bugaoshan/injection/injector.dart';
import 'package:bugaoshan/services/window_state_service.dart';
import 'package:bugaoshan/utils/platform_utils.dart';
import 'package:bugaoshan/utils/theme_utils.dart';

Future<void> main() async {
  try {
    await _initializeApp();
    runApp(MyApp());
  } catch (error, stackTrace) {
    debugPrint('Startup error: $error\n$stackTrace');
    runApp(const _StartupErrorApp());
  }
}

Future<void> _initializeApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    DartPluginRegistrant.ensureInitialized();
    if (AppPlatform.isDesktop) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }
  configureDependencies();
  await ensureBasicDependencies();

  // 桌面端记住窗口位置和大小，下次启动时恢复
  if (!kIsWeb && AppPlatform.isDesktop) {
    await WindowStateService.create(getIt<SharedPreferences>());
  }

  // 获取系统主题颜色
  await loadSystemAccentColor();
}

class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text('Bugaoshan 启动失败', textAlign: TextAlign.center),
            ),
          ),
        ),
      ),
    );
  }
}
