// Fails when code breaks the architecture rules (ADR 0001, ADR 0009, ADR 0017).
//
//   dart run tool/check_architecture.dart
//
// Checks:
//  1. Dart imports in lib/ follow the dependency directions and use each
//     feature's public file only.
//  2. A DAO is imported only inside the folder of the module that owns it.
//  3. packages/ never import the app.
//  4. Kotlin code never uses Tink APIs that can store keys unencrypted.
//  5. pubspec.yaml has no networking, analytics or font-download packages.
import 'dart:io';

import 'package:path/path.dart' as p;

void main() {
  final violations = <Violation>[
    ...checkDartImports(_readFiles(['lib', 'packages'], '.dart')),
    ...checkKotlinSources(_readFiles(['android/app/src'], '.kt')),
    ...checkPubspec(File('pubspec.yaml').readAsStringSync()),
  ];
  if (violations.isEmpty) {
    stdout.writeln('Architecture check passed.');
    return;
  }
  for (final violation in violations) {
    stderr.writeln('${violation.file}: ${violation.message}');
  }
  stderr.writeln('${violations.length} architecture violation(s).');
  exitCode = 1;
}

class Violation {
  const Violation(this.file, this.message);

  final String file;
  final String message;

  @override
  String toString() => '$file: $message';
}

/// [files] maps a path relative to the project root (with `/`) to its source.
List<Violation> checkDartImports(Map<String, String> files) {
  final violations = <Violation>[];
  final directive = RegExp(r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''', multiLine: true);
  for (final MapEntry(key: source, value: text) in files.entries) {
    if (source.endsWith('.g.dart')) continue;
    for (final match in directive.allMatches(text)) {
      final uri = match.group(1)!;
      if (source.startsWith('packages/')) {
        if (uri.startsWith('package:loopd/')) {
          violations.add(Violation(source, 'packages must not import the app ($uri)'));
        }
        continue;
      }
      final target = _resolve(source, uri);
      if (target == null) continue;
      final problem = _importProblem(source, target);
      if (problem != null) violations.add(Violation(source, '$problem ($uri)'));
    }
  }
  return violations;
}

/// Returns why [source] may not import [target], or null when it may.
String? _importProblem(String source, String target) {
  final from = _Module.of(source);
  final to = _Module.of(target);
  if (from == null || to == null) return null;

  if (from.layer == 'core' && const {'app', 'features', 'design_system'}.contains(to.layer)) {
    return 'core must not depend on ${to.layer}';
  }
  if (from.layer == 'design_system' && to.layer != 'design_system') {
    return 'design_system must not depend on ${to.layer}';
  }
  if (from.layer == 'features' && to.layer == 'app') {
    return 'features must not depend on app';
  }
  if (from.layer == 'features' && to.layer == 'features' && from.name != to.name) {
    final publicFile = 'lib/features/${to.name}/${to.name}.dart';
    if (target != publicFile) {
      return 'import only $publicFile from another feature';
    }
  }
  if (target.endsWith('_dao.dart') && from.owner != to.owner) {
    return 'a DAO is used only by the module that owns it (${to.owner})';
  }
  return null;
}

/// Kotlin APIs that can write or read keys unencrypted (ADR 0009).
const forbiddenKotlinApis = {
  'AndroidKeysetManager': 'falls back to unencrypted keysets',
  'CleartextKeysetHandle': 'reads and writes unencrypted keysets',
  'InsecureSecretKeyAccess': 'exposes raw key bytes; needs an explicit review',
  'serializeKeyset(': 'writes an unencrypted keyset; use serializeEncryptedKeyset',
  'parseKeyset(': 'reads an unencrypted keyset; use parseEncryptedKeyset',
  'doNotUseKeystore': 'disables Keystore protection',
};

List<Violation> checkKotlinSources(Map<String, String> files) {
  final violations = <Violation>[];
  for (final MapEntry(key: source, value: text) in files.entries) {
    final code = _stripKotlinComments(text);
    for (final MapEntry(key: api, value: reason) in forbiddenKotlinApis.entries) {
      if (code.contains(api)) {
        violations.add(Violation(source, 'uses $api: $reason'));
      }
    }
  }
  return violations;
}

/// Packages that would add a network path or download at run time.
final _forbiddenPackage = RegExp(
  r'^\s+(http|dio|google_fonts|connectivity_plus|firebase_\w+|sentry\w*|amplitude\w*|mixpanel\w*)\s*:',
  multiLine: true,
);

List<Violation> checkPubspec(String pubspec) => [
  for (final match in _forbiddenPackage.allMatches(pubspec))
    Violation('pubspec.yaml', 'package ${match.group(1)} is not allowed in an offline app'),
];

String _stripKotlinComments(String text) =>
    text.replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '').replaceAll(RegExp(r'//[^\n]*'), '');

String? _resolve(String source, String uri) {
  if (uri.startsWith('package:loopd/')) {
    return 'lib/${uri.substring('package:loopd/'.length)}';
  }
  if (uri.startsWith('package:') || uri.startsWith('dart:')) return null;
  return p.posix.normalize(p.posix.join(p.posix.dirname(source), uri));
}

class _Module {
  const _Module(this.layer, this.name);

  /// app, core, design_system or features.
  final String layer;

  /// The folder directly under the layer, for example `ledger` or `expenses`.
  final String? name;

  String get owner => name == null ? layer : '$layer/$name';

  static _Module? of(String path) {
    final parts = p.posix.split(path);
    if (parts.length < 2 || parts.first != 'lib') return null;
    final layer = parts[1];
    if (!const {'app', 'core', 'design_system', 'features'}.contains(layer)) {
      return null;
    }
    final name = parts.length > 3 ? parts[2] : null;
    return _Module(layer, name);
  }
}

Map<String, String> _readFiles(List<String> roots, String extension) => {
  for (final root in roots)
    if (Directory(root).existsSync())
      for (final entity in Directory(root).listSync(recursive: true))
        if (entity is File && entity.path.endsWith(extension))
          p.split(p.relative(entity.path)).join('/'): entity.readAsStringSync(),
};
