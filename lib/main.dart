import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:bugaoshan/app.dart';
import 'package:bugaoshan/injection/injector.dart';
import 'package:bugaoshan/services/window_state_service.dart';
import 'package:bugaoshan/services/update_service.dart';
import 'package:bugaoshan/utils/platform_utils.dart';
import 'package:bugaoshan/utils/theme_utils.dart';

Future<void> main() async {
  try {
    await _initializeApp();
    runApp(MyApp());
  } catch (error, stackTrace) {
    debugPrint('Startup error: $error\n$stackTrace');
    runApp(_StartupErrorApp(errorMessage: stackTrace.toString()));
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

  // 清理下载的安装包（首次打开或更新后）。
  getIt<UpdateService>().cleanupOldPackages();

  // 桌面端记住窗口位置和大小，下次启动时恢复
  if (AppPlatform.isDesktop) {
    await WindowStateService.create(getIt<SharedPreferences>());
  }

  // 获取系统主题颜色
  await loadSystemAccentColor();

  // 启动时不再在 main 进行图片解码或等待；预加载交由 app 层在 post-frame 时处理，以避免重复加载与启动阻塞。
}

class _StartupErrorApp extends StatelessWidget {
  final String? errorMessage;
  const _StartupErrorApp({this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              children: [
                Text(
                  '不高山上启动失败',
                  textAlign: TextAlign.center,
                  textScaler: TextScaler.linear(1.5),
                ),
                Text(errorMessage ?? ''),
                ElevatedButton(
                  onPressed: () async {
                    await getIt<SharedPreferences>().clear();
                  },
                  child: const Text('Clear Shared Preferences'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
