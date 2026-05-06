import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:bugaoshan/utils/platform_utils.dart';

class WidgetUpdateService {
  static const _channel = MethodChannel('bugaoshan/update');

  Future<void> updateWidgetData() async {
    if (!AppPlatform.supportsHomeWidget) return;
    try {
      debugPrint('WidgetUpdate: starting update...');
      await _channel.invokeMethod('updateWidget');
      debugPrint('WidgetUpdate: completed successfully');
    } catch (e, stack) {
      debugPrint('WidgetUpdate: FAILED: $e');
      debugPrint('WidgetUpdate: stack: $stack');
    }
  }
}
