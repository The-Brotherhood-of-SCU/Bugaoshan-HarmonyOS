import 'dart:typed_data';

import 'package:bugaoshan/injection/injector.dart';
import 'package:bugaoshan/widgets/adaptive/adaptive_glass_controls.dart';
import 'package:bugaoshan/widgets/navigation/adaptive_home_dock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _capabilities = MethodChannel('bugaoshan/liquid_glass');
const _destinations = [
  HomeDockDestination(
    id: 'course', label: 'Courses', icon: Icons.book,
    selectedIcon: Icons.book, symbol: 'book', selectedSymbol: 'book.fill',
  ),
  HomeDockDestination(
    id: 'campus', label: 'Campus', icon: Icons.school,
    selectedIcon: Icons.school, symbol: 'building.2', selectedSymbol: 'building.2.fill',
  ),
];

Map<Object?, Object?> _caps({
  bool dock = true, bool button = true, bool toggle = true, bool floating = false,
}) => {
  'version': 1, 'backend': 'ohos', 'dock': dock, 'button': button,
  'switch': toggle, 'floatingDock': floating, 'immersiveDock': false,
  'immersiveSwitch': false, 'dockHeight': floating ? 88 : 64,
  'switchWidth': 64, 'switchHeight': 48,
};

Widget _host(Widget child, {Widget? dock}) => MaterialApp(
  home: MediaQuery(
    data: const MediaQueryData(
      size: Size(400, 800), viewPadding: EdgeInsets.only(bottom: 20),
    ),
    child: Scaffold(body: Center(child: child), bottomNavigationBar: dock),
  ),
);

AdaptiveGlassButton _button(VoidCallback onPressed) => AdaptiveGlassButton(
  label: 'Save', onPressed: onPressed,
  fallback: FilledButton(onPressed: onPressed, child: const Text('Save')),
);

class _Bridge {
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final types = <int, String>{};
  final creations = <int, Map<Object?, Object?>>{};
  final updates = <int, List<Map<Object?, Object?>>>{};
  final disposed = <int>[];
  int queries = 0;
  bool failUpdates = false;

  void install(Map<Object?, Object?> capabilities, {bool missing = false}) {
    messenger.setMockMethodCallHandler(_capabilities, (call) async {
      expect(call.method, 'getCapabilities');
      queries++;
      if (missing) throw MissingPluginException();
      return capabilities;
    });
    messenger.setMockMethodCallHandler(SystemChannels.platform_views, (call) async {
      if (call.arguments is! Map) return null;
      final args = call.arguments as Map<Object?, Object?>;
      final id = args['id'] as int;
      if (call.method == 'create') {
        types[id] = args['viewType'] as String;
        creations[id] = const StandardMessageCodec().decodeMessage(
          ByteData.sublistView(args['params'] as Uint8List),
        ) as Map<Object?, Object?>;
        updates[id] = [];
        messenger.setMockMethodCallHandler(MethodChannel('${types[id]}/$id'), (call) async {
          expect(call.method, 'update');
          if (failUpdates) throw PlatformException(code: 'NATIVE_VIEW_FAILED');
          updates[id]!.add(call.arguments as Map<Object?, Object?>);
          return null;
        });
        return 1000 + id;
      }
      if (call.method == 'resize') {
        return {
          'width': (args['width'] as num).round(),
          'height': (args['height'] as num).round(),
        };
      }
      if (call.method == 'dispose') disposed.add(id);
      return null;
    });
  }

  int control(String label) => creations.keys.singleWhere(
    (id) => creations[id]!['label'] == label,
  );

  Future<void> send(int id, String method, Object? value) async {
    await messenger.handlePlatformMessage(
      '${types[id]}/$id',
      const StandardMethodCodec().encodeMethodCall(MethodCall(method, value)),
      (_) {},
    );
  }

  void uninstall() {
    messenger.setMockMethodCallHandler(_capabilities, null);
    messenger.setMockMethodCallHandler(SystemChannels.platform_views, null);
    for (final id in types.keys) {
      messenger.setMockMethodCallHandler(MethodChannel('${types[id]}/$id'), null);
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Bridge bridge;

  setUp(() async {
    await getIt.reset();
    SharedPreferences.setMockInitialValues({});
    debugOhosNativeUiOverride = true;
    LiquidGlassCapabilities.resetForTesting();
    bridge = _Bridge();
  });
  tearDown(() async {
    bridge.uninstall();
    debugOhosNativeUiOverride = null;
    LiquidGlassCapabilities.resetForTesting();
    await getIt.reset();
  });

  test('native support is independent of immersive material and validates metrics', () {
    final raw = _caps(button: false, floating: true)
      ..['switchWidth'] = double.nan
      ..['dockHeight'] = 10000;
    final caps = OhosNativeUiCapabilities.fromMap(raw);
    expect(caps.dock, isTrue);
    expect(caps.button, isFalse);
    expect(caps.toggle, isTrue);
    expect(caps.floatingDock, isTrue);
    expect(caps.immersiveDock, isFalse);
    expect(caps.switchWidth, 64);
    expect(caps.dockHeight, 160);
    final invalid = OhosNativeUiCapabilities.fromMap({...raw, 'version': 2});
    expect(invalid.dock, isFalse);
    expect(invalid.toggle, isFalse);
  });

  testWidgets('OHOS wrappers share capabilities and create native controls without material', (tester) async {
    bridge.install(_caps());
    final nativeModes = <bool>[];
    final overlaps = <bool>[];
    await tester.pumpWidget(_host(
      Column(mainAxisSize: MainAxisSize.min, children: [
        _button(() {}),
        AdaptiveGlassSwitch(value: false, onChanged: (_) {}, semanticLabel: 'Alerts'),
      ]),
      dock: AdaptiveHomeDock(
        destinations: _destinations, selectedIndex: 0, onDestinationSelected: (_) {},
        onNativeModeChanged: nativeModes.add, onContentOverlapChanged: overlaps.add,
      ),
    ));
    await tester.pumpAndSettle();
    expect(bridge.queries, 1);
    expect(find.byType(OhosView), findsNWidgets(3));
    expect(find.byType(UiKitView), findsNothing);
    expect(nativeModes, [true]);
    expect(overlaps, [false]);
    final dockId = bridge.types.keys.singleWhere((id) => bridge.types[id]!.endsWith('_dock'));
    expect(bridge.creations[dockId]!['bottomInset'], 20);
    final dockView = find.byWidgetPredicate(
      (widget) => widget is OhosView && widget.viewType.endsWith('_dock'),
    );
    expect(tester.getSize(dockView).height, 84);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets('native activation respects loading, disabled state and event kind', (tester) async {
    bridge.install(_caps());
    var presses = 0;
    Widget button({bool enabled = true, bool loading = false}) => _host(
      AdaptiveGlassButton(
        label: 'Save', onPressed: enabled ? () => presses++ : null, loading: loading,
        fallback: const SizedBox(width: 100, height: 48),
      ),
    );
    await tester.pumpWidget(button());
    await tester.pumpAndSettle();
    final id = bridge.control('Save');
    await bridge.send(id, 'activate', null);
    await bridge.send(id, 'activate', 'invalid');
    await bridge.send(id, 'change', true);
    expect(presses, 1);
    await tester.pumpWidget(button(loading: true));
    await tester.pumpAndSettle();
    expect(bridge.updates[id]!.last['enabled'], isFalse);
    expect(bridge.updates[id]!.last['loading'], isTrue);
    await bridge.send(id, 'activate', null);
    await tester.pumpWidget(button(enabled: false));
    await tester.pumpAndSettle();
    await bridge.send(id, 'activate', null);
    expect(presses, 1);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets('unsupported controls keep their actionable Flutter fallback', (tester) async {
    bridge.install(_caps(dock: false, button: false));
    var presses = 0;
    await tester.pumpWidget(_host(Column(mainAxisSize: MainAxisSize.min, children: [
      _button(() => presses++),
      AdaptiveGlassSwitch(value: false, onChanged: (_) {}, semanticLabel: 'Alerts'),
    ])));
    await tester.pumpAndSettle();
    expect(find.byType(OhosView), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);
    await tester.tap(find.text('Save'));
    expect(presses, 1);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets('missing OHOS bridge keeps switches and dock in Flutter', (tester) async {
    bridge.install(_caps(), missing: true);
    await tester.pumpWidget(_host(
      AdaptiveGlassSwitchListTile(
        value: false, onChanged: (_) {}, title: const Text('Alerts'),
      ),
      dock: AdaptiveHomeDock(
        destinations: _destinations, selectedIndex: 0, onDestinationSelected: (_) {},
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(OhosView), findsNothing);
    expect(find.byType(SwitchListTile), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('independent switches restore rejected values and discard disposed events', (tester) async {
    bridge.install(_caps());
    final first = <bool>[];
    final second = <bool>[];
    await tester.pumpWidget(_host(Column(mainAxisSize: MainAxisSize.min, children: [
      AdaptiveGlassSwitch(value: false, onChanged: first.add, semanticLabel: 'First'),
      AdaptiveGlassSwitch(value: false, onChanged: second.add, semanticLabel: 'Second'),
    ])));
    await tester.pumpAndSettle();
    final firstId = bridge.control('First');
    final secondId = bridge.control('Second');
    await bridge.send(firstId, 'change', true);
    await tester.pumpAndSettle();
    expect(first, [true]);
    expect(second, isEmpty);
    expect(bridge.updates[firstId]!.last['value'], isFalse);
    await bridge.send(secondId, 'change', true);
    await tester.pumpAndSettle();
    expect(second, [true]);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    expect(bridge.disposed, containsAll([firstId, secondId]));
    await bridge.send(firstId, 'change', true);
    expect(first, [true]);
  });

  testWidgets('dock resolves current IDs after reordering and closes overlap on failure', (tester) async {
    bridge.install(_caps(floating: true));
    final selections = <int>[];
    final overlaps = <bool>[];
    Widget dock(List<HomeDockDestination> items) => AdaptiveHomeDock(
      destinations: items, selectedIndex: 0, onDestinationSelected: selections.add,
      onContentOverlapChanged: overlaps.add,
    );
    await tester.pumpWidget(_host(const SizedBox(), dock: dock(_destinations)));
    await tester.pumpAndSettle();
    final id = bridge.types.keys.single;
    expect(overlaps, [true]);
    await bridge.send(id, 'select', 'campus');
    expect(selections, [1]);
    await tester.pumpWidget(_host(const SizedBox(), dock: dock(_destinations.reversed.toList())));
    await tester.pumpAndSettle();
    expect(bridge.updates[id]!.last['selectedId'], 'campus');
    await bridge.send(id, 'select', 'course');
    await bridge.send(id, 'select', 'deleted');
    expect(selections, [1, 1]);
    bridge.failUpdates = true;
    await tester.pumpWidget(_host(const SizedBox(), dock: dock(_destinations)));
    await tester.pumpAndSettle();
    expect(find.byType(OhosView), findsNothing);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(overlaps.last, isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
