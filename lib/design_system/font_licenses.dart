import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Adds the bundled fonts' licences to the app's licence list, as the SIL
/// Open Font License asks.
void registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final (family, path) in const [
      ('Plus Jakarta Sans', 'assets/fonts/plus_jakarta_sans/OFL.txt'),
      ('JetBrains Mono', 'assets/fonts/jetbrains_mono/OFL.txt'),
    ]) {
      yield LicenseEntryWithLineBreaks([family], await rootBundle.loadString(path));
    }
  });
}
