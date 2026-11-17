import 'package:flutter/painting.dart';

/// Loopd's type scale, from the approved mockups (proposal section 18).
///
/// Plus Jakarta Sans for everything; JetBrains Mono for PNRs and the command
/// line. Both are bundled with the app (`assets/fonts/`, OFL licensed), so
/// nothing is downloaded. Styles carry no colour: the theme's default text
/// colour applies, and widgets add an accent where needed.
abstract final class LoopdType {
  static const sans = 'PlusJakartaSans';
  static const mono = 'JetBrainsMono';

  /// Tab page titles: Today, Money, Travel, Planner, More (34 px, ExtraBold,
  /// 44 px line).
  static const display = TextStyle(
    fontFamily: sans,
    fontSize: 34,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    height: 44 / 34,
  );

  /// Titles of pages opened from a tab, such as Accounts and cards, Review
  /// Inbox or Backup & restore (30 px, ExtraBold).
  static const pageTitle = TextStyle(
    fontFamily: sans,
    fontSize: 30,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    height: 1.2,
  );

  /// Big amounts on cards, such as today's spending (36 px, ExtraBold).
  static const amountLarge = TextStyle(
    fontFamily: sans,
    fontSize: 36,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.8,
    height: 1.15,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Sheet titles (22 px, ExtraBold).
  static const title = TextStyle(fontFamily: sans, fontSize: 22, fontWeight: FontWeight.w800, height: 1.25);

  /// Card headings (17 px, ExtraBold).
  static const heading = TextStyle(fontFamily: sans, fontSize: 17, fontWeight: FontWeight.w800, height: 1.3);

  /// Emphasised body text, such as a merchant name (15 px, Bold).
  static const bodyStrong = TextStyle(fontFamily: sans, fontSize: 15, fontWeight: FontWeight.w700, height: 1.35);

  /// Body text (15 px, SemiBold).
  static const body = TextStyle(fontFamily: sans, fontSize: 15, fontWeight: FontWeight.w600, height: 1.4);

  /// Row labels and buttons (14 px, Bold).
  static const label = TextStyle(fontFamily: sans, fontSize: 14, fontWeight: FontWeight.w700, height: 1.3);

  /// Secondary lines (13 px, Bold).
  static const small = TextStyle(fontFamily: sans, fontSize: 13, fontWeight: FontWeight.w700, height: 1.35);

  /// Captions and chip text (12 px, Bold).
  static const caption = TextStyle(fontFamily: sans, fontSize: 12, fontWeight: FontWeight.w700, height: 1.3);

  /// Small print, such as timestamps and tab labels (11 px, SemiBold).
  static const micro = TextStyle(fontFamily: sans, fontSize: 11, fontWeight: FontWeight.w600, height: 1.3);

  /// Amounts in lists, with tabular figures so columns line up (15 px, ExtraBold).
  static const amount = TextStyle(
    fontFamily: sans,
    fontSize: 15,
    fontWeight: FontWeight.w800,
    height: 1.3,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// PNRs and the command line (13 px, JetBrains Mono Medium).
  static const code = TextStyle(fontFamily: mono, fontSize: 13, fontWeight: FontWeight.w500, height: 1.4);
}
