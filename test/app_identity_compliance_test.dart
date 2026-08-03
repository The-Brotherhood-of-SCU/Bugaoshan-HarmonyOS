import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:bugaoshan/widgets/eula_content.dart';

const _appName = '不高山上';
const _developer = '许盛凯';

Map<String, dynamic> _readJson(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

String _resourceValue(String path, String name) {
  final resources = _readJson(path)['string'] as List<dynamic>;
  final resource = resources.cast<Map<String, dynamic>>().singleWhere(
    (entry) => entry['name'] == name,
  );
  return resource['value'] as String;
}

void main() {
  test('OHOS application identity matches the AGC listing', () {
    expect(
      _resourceValue(
        'ohos/AppScope/resources/base/element/string.json',
        'app_name',
      ),
      _appName,
    );
    expect(
      _resourceValue(
        'ohos/entry/src/main/resources/base/element/string.json',
        'EntryAbility_label',
      ),
      _appName,
    );
    expect(
      _resourceValue(
        'ohos/entry/src/main/resources/zh_CN/element/string.json',
        'EntryAbility_label',
      ),
      _appName,
    );
    expect(
      _resourceValue(
        'ohos/entry/src/main/resources/en_US/element/string.json',
        'EntryAbility_label',
      ),
      _appName,
    );

    final englishArb = _readJson('lib/l10n/app_en.arb');
    expect(englishArb['bugaoshan'], _appName);

    final app = _readJson('ohos/AppScope/app.json5')['app'];
    expect(app['vendor'], _developer);

    final eula = File('assets/eula.md').readAsStringSync();
    expect(eula, contains('| **应用名称** | $_appName |'));
    expect(eula, contains('| **开发者及运营者** | $_developer |'));
    expect(eula, contains('| **协议版本** | 2.0 |'));
    expect(currentEulaVersion, 2);
  });

  test('OHOS launcher icons are identical opaque square RGB images', () {
    final appIcon = File(
      'ohos/AppScope/resources/base/media/app_icon.png',
    ).readAsBytesSync();
    final entryIcon = File(
      'ohos/entry/src/main/resources/base/media/icon.png',
    ).readAsBytesSync();
    expect(entryIcon, orderedEquals(appIcon));

    final icon = img.decodePng(appIcon);
    expect(icon, isNotNull);
    expect(icon!.width, 1024);
    expect(icon.height, 1024);
    expect(icon.hasAlpha, isFalse);
    expect(icon.numChannels, 3);
  });
}
