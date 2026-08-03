// Run with: dart run tool/generate_ohos_icons.dart
// ignore_for_file: avoid_print

import 'dart:io';

import 'package:image/image.dart' as img;

const _sourcePath = 'assets/icon.png';
const _outputPaths = [
  'ohos/AppScope/resources/base/media/app_icon.png',
  'ohos/entry/src/main/resources/base/media/icon.png',
];

void main() {
  final source = img.decodeImage(File(_sourcePath).readAsBytesSync());
  if (source == null) {
    throw StateError('Unable to decode $_sourcePath');
  }

  final resized = img.copyResize(source, width: 1024, height: 1024);
  final flattened = img.Image(width: 1024, height: 1024, numChannels: 3);
  img.fill(flattened, color: img.ColorRgb8(255, 255, 255));
  img.compositeImage(flattened, resized);
  final bytes = img.encodePng(flattened);

  for (final outputPath in _outputPaths) {
    File(outputPath).writeAsBytesSync(bytes);
    print('Generated $outputPath (1024x1024 RGB)');
  }
}
