import '../../core/routing/route_paths.dart';

/// The five tabs (proposal section 3). Tabs are navigation only; the business
/// modules behind them are separate features (ADR 0001).
enum AppTab {
  today('Today', RoutePaths.today, 1),
  money('Money', RoutePaths.money, 2),
  travel('Travel', RoutePaths.travel, 5),
  planner('Planner', RoutePaths.planner, 6),
  more('More', RoutePaths.more, 1);

  const AppTab(this.label, this.path, this.builtInPhase);

  final String label;
  final String path;

  /// The roadmap phase that replaces this tab's placeholder page.
  final int builtInPhase;
}
