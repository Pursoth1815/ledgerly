/// Route paths, shared so that features navigate without importing each
/// other's screens (ADR 0003). The app router maps them to screens.
abstract final class RoutePaths {
  static const today = '/today';
  static const money = '/money';
  static const travel = '/travel';
  static const planner = '/planner';
  static const more = '/more';

  /// The component gallery; debug and profile builds only.
  static const gallery = '/gallery';
}
