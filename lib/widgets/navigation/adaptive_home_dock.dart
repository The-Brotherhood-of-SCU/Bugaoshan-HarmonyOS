import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bugaoshan/utils/app_log.dart';
import 'package:bugaoshan/widgets/adaptive/adaptive_glass_controls.dart';

/// Flutter 保留导航状态；原生侧只负责显示和发送稳定的 destination id。
class HomeDockDestination {
  const HomeDockDestination({
    required this.id,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.symbol,
    required this.selectedSymbol,
    this.showBadge = false,
    this.badgeLabel = '',
  });

  final String id;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String symbol;
  final String selectedSymbol;
  final bool showBadge;
  final String badgeLabel;

  Map<String, Object> toNative() => {
    'id': id,
    'label': label,
    'symbol': symbol,
    'selectedSymbol': selectedSymbol,
    'badge': showBadge,
    'badgeLabel': badgeLabel,
  };
}

/// iOS 26+ 使用 UITabBarController，OHOS 使用 ArkUI Tabs。
/// 仅承载一个原生视图，避免为每个按钮创建平台视图和通信通道。
class AdaptiveHomeDock extends StatefulWidget {
  const AdaptiveHomeDock({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.reduceMotion = false,
    this.onNativeModeChanged,
    this.onContentOverlapChanged,
    this.moreLabel,
    this.cancelLabel,
  }) : assert(destinations.length >= 2),
       assert(selectedIndex >= 0 && selectedIndex < destinations.length);

  final List<HomeDockDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final bool reduceMotion;
  final ValueChanged<bool>? onNativeModeChanged;

  /// 原生栏可以是普通栏；只有悬浮栏才让页面内容延伸到栏后。
  final ValueChanged<bool>? onContentOverlapChanged;
  final String? moreLabel;
  final String? cancelLabel;

  @override
  State<AdaptiveHomeDock> createState() => _AdaptiveHomeDockState();
}

class _AdaptiveHomeDockState extends State<AdaptiveHomeDock> {
  static const _capabilities = MethodChannel('bugaoshan/liquid_glass');
  static const _viewType = 'bugaoshan/liquid_glass_dock';
  static const _channelTimeout = Duration(seconds: 2);

  bool _supported = false;
  OhosNativeUiCapabilities _ohos = const OhosNativeUiCapabilities();
  bool _updateScheduled = false;
  MethodChannel? _viewChannel;

  @override
  void initState() {
    super.initState();
    if (usesOhosNativeUi ||
        (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS)) {
      unawaited(_checkSupport());
    }
  }

  Future<void> _checkSupport() async {
    if (usesOhosNativeUi) {
      final capabilities = await OhosNativeUiCapabilities.load();
      if (!mounted) return;
      setState(() {
        _ohos = capabilities;
        _supported = capabilities.dock;
      });
      widget.onNativeModeChanged?.call(capabilities.dock);
      widget.onContentOverlapChanged?.call(capabilities.floatingDock);
      return;
    }
    try {
      final supported = await _capabilities
          .invokeMethod<bool>('isSupported')
          .timeout(_channelTimeout);
      if (!mounted) return;
      final native = supported == true;
      setState(() => _supported = native);
      widget.onNativeModeChanged?.call(native);
      widget.onContentOverlapChanged?.call(native);
    } catch (e) {
      // 旧 Runner / 测试没有注册原生桥时仍可正常导航。
      AppLog.w('AdaptiveHomeDock', 'Native glass unavailable: $e');
      if (mounted) widget.onNativeModeChanged?.call(false);
      if (mounted) widget.onContentOverlapChanged?.call(false);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scheduleUpdate();
  }

  @override
  void didUpdateWidget(covariant AdaptiveHomeDock oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleUpdate();
  }

  double get _textScale =>
      (MediaQuery.textScalerOf(context).scale(12) / 12).clamp(1.0, 2.0);

  Map<String, Object> _parameters() {
    final theme = Theme.of(context);
    return {
      'items': widget.destinations.map((item) => item.toNative()).toList(),
      'selectedId': widget.destinations[widget.selectedIndex].id,
      'tint': theme.colorScheme.primary.toARGB32(),
      'brightness': theme.brightness.name,
      'reduceMotion':
          widget.reduceMotion || MediaQuery.disableAnimationsOf(context),
      'highContrast': MediaQuery.highContrastOf(context),
      'textScale': _textScale,
      'direction': Directionality.of(context).name,
      if (usesOhosNativeUi)
        'bottomInset': MediaQuery.viewPaddingOf(context).bottom,
      if (widget.moreLabel != null) 'moreLabel': widget.moreLabel!,
      if (widget.cancelLabel != null) 'cancelLabel': widget.cancelLabel!,
    };
  }

  void _onPlatformViewCreated(int id) {
    if (!mounted || !_supported) return;
    _viewChannel?.setMethodCallHandler(null);
    _viewChannel = MethodChannel('$_viewType/$id')
      ..setMethodCallHandler(_handleNativeCall);
    // 创建期间 Dock 配置可能已变化，发送当前完整状态覆盖 creationParams。
    _scheduleUpdate();
  }

  Future<void> _handleNativeCall(MethodCall call) async {
    if (!mounted ||
        !_supported ||
        call.method != 'select' ||
        call.arguments is! String) {
      return;
    }
    final index = widget.destinations.indexWhere(
      (item) => item.id == call.arguments,
    );
    // 忽略重排 / 删除后的过期事件，不能按原生侧的旧 index 导航。
    if (index >= 0 && index != widget.selectedIndex) {
      widget.onDestinationSelected(index);
    }
  }

  void _scheduleUpdate() {
    if (_viewChannel == null || _updateScheduled) return;
    _updateScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateScheduled = false;
      if (mounted && _supported) unawaited(_updateNative());
    });
  }

  Future<void> _updateNative() async {
    final channel = _viewChannel;
    if (channel == null) return;
    try {
      await channel
          .invokeMethod<void>('update', _parameters())
          .timeout(_channelTimeout);
    } catch (e) {
      AppLog.w('AdaptiveHomeDock', 'Native dock update failed: $e');
      if (mounted && identical(channel, _viewChannel)) {
        channel.setMethodCallHandler(null);
        _viewChannel = null;
        setState(() => _supported = false);
        widget.onNativeModeChanged?.call(false);
        widget.onContentOverlapChanged?.call(false);
      }
    }
  }

  @override
  void dispose() {
    _viewChannel?.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_supported) {
      return NavigationBar(
        selectedIndex: widget.selectedIndex,
        onDestinationSelected: widget.onDestinationSelected,
        destinations: [
          for (final item in widget.destinations)
            NavigationDestination(
              icon: Badge(
                isLabelVisible: item.showBadge,
                child: Icon(item.icon),
              ),
              selectedIcon: Badge(
                isLabelVisible: item.showBadge,
                child: Icon(item.selectedIcon),
              ),
              label: item.label,
              tooltip: '',
            ),
        ],
      );
    }

    // iOS 由 UIKit 处理底部安全区；OHOS 将 inset 传给原生栏，避免重复避让。
    // 悬浮栏的取景与阴影区域不再由 Flutter 外层 SafeArea/圆角裁剪。
    final parameters = _parameters();
    final layoutDirection = Directionality.of(context);
    return SizedBox(
      height: (usesOhosNativeUi ? _ohos.dockHeight : 88) +
          MediaQuery.viewPaddingOf(context).bottom,
      child: usesOhosNativeUi
          ? OhosView(
              viewType: _viewType,
              layoutDirection: layoutDirection,
              creationParams: parameters,
              creationParamsCodec: const StandardMessageCodec(),
              onPlatformViewCreated: _onPlatformViewCreated,
              clipBehavior: Clip.none,
            )
          : UiKitView(
              viewType: _viewType,
              layoutDirection: layoutDirection,
              creationParams: parameters,
              creationParamsCodec: const StandardMessageCodec(),
              onPlatformViewCreated: _onPlatformViewCreated,
            ),
    );
  }
}
