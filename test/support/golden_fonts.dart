import 'dart:io';

import 'package:flutter/services.dart';
import 'package:loopd/design_system/loopd_typography.dart';

/// Loads the bundled fonts and the SDK's Material icons, so visual tests draw
/// real text and icons instead of placeholder boxes.
Future<void> loadGoldenFonts() async {
  Future<void> load(String family, Iterable<File> files) async {
    final loader = FontLoader(family);
    for (final file in files) {
      loader.addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
    }
    await loader.load();
  }

  Iterable<File> ttfs(String folder) =>
      Directory('assets/fonts/$folder').listSync().whereType<File>().where((f) => f.path.endsWith('.ttf'));

  await load(LoopdType.sans, ttfs('plus_jakarta_sans'));
  await load(LoopdType.mono, ttfs('jetbrains_mono'));
  final sdk = Platform.environment['FLUTTER_ROOT'];
  final icons = File('$sdk/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  if (sdk != null && icons.existsSync()) await load('MaterialIcons', [icons]);
}
