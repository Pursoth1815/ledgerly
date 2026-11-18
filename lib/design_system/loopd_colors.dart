import 'package:flutter/material.dart';

/// Every colour in Loopd, from the approved mockups (`docs/mockups/`), in dark
/// (designed first) and light. Proposal section 18: neutral surfaces, text in
/// three strengths, one accent per module. Red is only for overdue and
/// delete; orange only for "needs review"; green for Save and Looks Good.
///
/// Each accent has a soft tint (`…Tint`) used behind it for chips and icons.
/// Widgets read the palette with `context.colors`, never with raw hex values.
@immutable
class LoopdColors extends ThemeExtension<LoopdColors> {
  const LoopdColors({
    required this.background,
    required this.surface,
    required this.surfaceRaised,
    required this.line,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.onAccent,
    required this.buttonFill,
    required this.onButton,
    required this.pressOverlay,
    required this.scrim,
    required this.switchOff,
    required this.themeSwitch,
    required this.money,
    required this.moneyTint,
    required this.creditCard,
    required this.creditCardTint,
    required this.cash,
    required this.cashTint,
    required this.cardBlank,
    required this.lending,
    required this.lendingTint,
    required this.travel,
    required this.travelTint,
    required this.travelPass,
    required this.notes,
    required this.notesTint,
    required this.task,
    required this.taskTint,
    required this.vault,
    required this.vaultTint,
    required this.vaultSolid,
    required this.wellbeing,
    required this.wellbeingTint,
    required this.wellbeingSoft,
    required this.danger,
    required this.dangerTint,
    required this.review,
    required this.reviewTint,
    required this.warning,
    required this.warningTint,
  });

  // Neutrals (mockup tokens bg, s1, s2, line, t1, t2, t3).
  final Color background;
  final Color surface;
  final Color surfaceRaised;
  final Color line;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  /// Text and icons on a filled accent.
  final Color onAccent;

  /// The plain filled button, and its label.
  final Color buttonFill;
  final Color onButton;

  /// Laid over a pressed surface instead of a Material ripple.
  final Color pressOverlay;
  final Color scrim;
  final Color switchOff;

  /// The Dark theme switch when on: medium purple (review round 6).
  final Color themeSwitch;

  // Module accents.
  final Color money;
  final Color moneyTint;
  final Color creditCard;
  final Color creditCardTint;
  final Color cash;
  final Color cashTint;

  /// The face of a card preview before a bank is chosen, and of a bank typed
  /// by hand (mockup `AddAccount.dc.html`).
  final Color cardBlank;
  final Color lending;
  final Color lendingTint;
  final Color travel;
  final Color travelTint;

  /// The solid background of a pass-style ticket card.
  final Color travelPass;
  final Color notes;
  final Color notesTint;

  /// The Task shortcut in the capture sheet: blue, so it is not mistaken for
  /// Expense green (owner's choice, 17 Nov 2026, over teal and rose).
  final Color task;
  final Color taskTint;
  final Color vault;
  final Color vaultTint;

  /// Solid Vault and More tiles.
  final Color vaultSolid;
  final Color wellbeing;
  final Color wellbeingTint;
  final Color wellbeingSoft;

  // Reserved colours.
  final Color danger;
  final Color dangerTint;
  final Color review;
  final Color reviewTint;
  final Color warning;
  final Color warningTint;

  static const dark = LoopdColors(
    background: Color(0xFF0D0F14),
    surface: Color(0xFF161922),
    surfaceRaised: Color(0xFF1F2330),
    line: Color(0xFF2B3040),
    textPrimary: Color(0xFFF3F5F9),
    textSecondary: Color(0xFFB6BCC9),
    textMuted: Color(0xFF8F96A6),
    onAccent: Color(0xFF0D0F14),
    buttonFill: Color(0xFFF3F5F9),
    onButton: Color(0xFF0D0F14),
    pressOverlay: Color(0x12FFFFFF),
    scrim: Color(0x99000000),
    switchOff: Color(0xFF3A4050),
    themeSwitch: Color(0xFF7C3AED),
    money: Color(0xFF34D399),
    moneyTint: Color(0x2434D399),
    creditCard: Color(0xFFC4A5FF),
    creditCardTint: Color(0x26C4A5FF),
    cash: Color(0xFF38BDF8),
    cashTint: Color(0x2438BDF8),
    cardBlank: Color(0xFF3A4050),
    lending: Color(0xFFFBBF24),
    lendingTint: Color(0x21FBBF24),
    travel: Color(0xFF8F98FF),
    travelTint: Color(0x298F98FF),
    travelPass: Color(0xFF4F46E5),
    notes: Color(0xFFE6CDA3),
    notesTint: Color(0x21E6CDA3),
    task: Color(0xFF60A5FA),
    taskTint: Color(0x2960A5FA),
    vault: Color(0xFF7C9BFF),
    vaultTint: Color(0x297C9BFF),
    vaultSolid: Color(0xFF3B5BDB),
    wellbeing: Color(0xFF2DD4BF),
    wellbeingTint: Color(0x242DD4BF),
    wellbeingSoft: Color(0xFF1F6B63),
    danger: Color(0xFFFF7B7B),
    dangerTint: Color(0x29FF7B7B),
    review: Color(0xFFFF9F5A),
    reviewTint: Color(0x26FF9F5A),
    warning: Color(0xFFFBBF24),
    warningTint: Color(0x1FFBBF24),
  );

  static const light = LoopdColors(
    background: Color(0xFFF3F4F8),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFECEEF3),
    line: Color(0xFFDDE1E9),
    textPrimary: Color(0xFF11141B),
    textSecondary: Color(0xFF434A58),
    textMuted: Color(0xFF5D6474),
    onAccent: Color(0xFFFFFFFF),
    buttonFill: Color(0xFF11141B),
    onButton: Color(0xFFFFFFFF),
    pressOverlay: Color(0x0F11141B),
    scrim: Color(0x7311141B),
    switchOff: Color(0xFFC3C8D2),
    themeSwitch: Color(0xFF7C3AED),
    money: Color(0xFF047857),
    moneyTint: Color(0xFFE1F4EA),
    creditCard: Color(0xFF6D28D9),
    creditCardTint: Color(0xFFEFE7FD),
    cash: Color(0xFF0369A1),
    cashTint: Color(0xFFE0F2FE),
    cardBlank: Color(0xFF64748B),
    lending: Color(0xFFA14A06),
    lendingTint: Color(0xFFFDF0D8),
    travel: Color(0xFF4338CA),
    travelTint: Color(0xFFE8E9FD),
    travelPass: Color(0xFF4338CA),
    notes: Color(0xFF735E3B),
    notesTint: Color(0xFFF3ECE0),
    task: Color(0xFF1D4ED8),
    taskTint: Color(0xFFDBEAFE),
    vault: Color(0xFF3B5BDB),
    vaultTint: Color(0xFFE3E9FC),
    vaultSolid: Color(0xFF3B5BDB),
    wellbeing: Color(0xFF0F766E),
    wellbeingTint: Color(0xFFDBF3EF),
    wellbeingSoft: Color(0xFF9ED9D0),
    danger: Color(0xFFB91C1C),
    dangerTint: Color(0xFFFBE3E3),
    review: Color(0xFFB03A0A),
    reviewTint: Color(0xFFFDEADB),
    warning: Color(0xFFA14A06),
    warningTint: Color(0xFFFDF0D8),
  );

  static LoopdColors forBrightness(Brightness brightness) => brightness == Brightness.dark ? dark : light;

  /// Theme switches are instant (proposal: "switches the screen live"), so
  /// colours are swapped, not blended.
  @override
  LoopdColors lerp(covariant LoopdColors? other, double t) => t < 0.5 || other == null ? this : other;

  @override
  LoopdColors copyWith() => this;
}

/// The eight category colours (mockup `CategorySheet.dc.html`). A category
/// stores an index (0 to 7) into one of these. They are the same in both
/// themes; a chip shows them as a dot or a ring, never as text.
abstract final class LoopdCategoryColours {
  /// Expense categories: bright, so they read on dark and light.
  static const expense = <Color>[
    Color(0xFFFF8A4C),
    Color(0xFFF472B6),
    Color(0xFFEAB308),
    Color(0xFF60A5FA),
    Color(0xFFA78BFA),
    Color(0xFF22D3EE),
    Color(0xFF2DD4BF),
    Color(0xFFF97316),
  ];

  /// The colour for a stored [index]; an index out of range falls back to
  /// the first colour.
  static Color expenseAt(int index) => expense[index >= 0 && index < expense.length ? index : 0];
}

extension LoopdColorsContext on BuildContext {
  /// The Loopd palette for the current theme.
  LoopdColors get colors => Theme.of(this).extension<LoopdColors>()!;
}
