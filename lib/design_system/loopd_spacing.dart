/// Spacing, corner radii and sizes from the approved mockups.
///
/// The mockups step in 2 px for small gaps and 4 px beyond that. Use these
/// names instead of numbers, so a later adjustment happens in one place.
abstract final class LoopdSpace {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  /// Left and right margin of a page.
  static const double gutter = 20;
}

abstract final class LoopdRadius {
  /// Mini cards and small tiles.
  static const double tile = 14;

  /// Cards inside cards, inputs.
  static const double inner = 16;

  /// Standard cards.
  static const double card = 20;

  /// Large cards.
  static const double cardLarge = 22;

  /// Today's section cards, the review card and full-width buttons.
  static const double section = 24;

  /// Bottom sheets (top corners).
  static const double sheet = 30;

  /// Chips, pills and round buttons.
  static const double pill = 999;
}

abstract final class LoopdSize {
  /// The smallest tappable area (proposal section 18: 44 to 48 dp).
  static const double minTouch = 44;

  /// The task checkbox circle (review round 1: 20 px).
  static const double checkCircle = 20;

  /// Full-width buttons, such as Review and Looks Good.
  static const double button = 48;

  /// Chips with a label, such as a category.
  static const double chip = 30;
}
