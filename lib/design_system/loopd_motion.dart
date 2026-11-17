import 'package:flutter/widgets.dart';

/// Motion from the approved mockups: short and purposeful (proposal section
/// 18). Honours the phone's reduce-motion setting: use [LoopdMotion.of] and
/// every duration becomes zero when animations are turned off.
@immutable
class LoopdMotion {
  const LoopdMotion._({required this.reduced});

  /// Reads the phone's "remove animations" setting.
  factory LoopdMotion.of(BuildContext context) =>
      LoopdMotion._(reduced: MediaQuery.maybeDisableAnimationsOf(context) ?? false);

  final bool reduced;

  /// Press states and colour changes (160 ms).
  Duration get quick => _d(const Duration(milliseconds: 160));

  /// Most transitions (220 ms).
  Duration get standard => _d(const Duration(milliseconds: 220));

  /// Switches and the press-in on a note (260 ms), with [spring].
  Duration get emphasis => _d(const Duration(milliseconds: 260));

  /// The task tick drawing itself (300 ms, after [tickDelay]).
  Duration get tick => _d(const Duration(milliseconds: 300));
  Duration get tickDelay => _d(const Duration(milliseconds: 120));

  /// Bottom sheets opening (300 ms).
  Duration get sheet => _d(const Duration(milliseconds: 300));

  Duration _d(Duration value) => reduced ? Duration.zero : value;

  /// A slight overshoot, as in the mockups' `cubic-bezier(.3, 1.4, .5, 1)`.
  static const spring = Cubic(0.3, 1.4, 0.5, 1);

  /// The mockups' plain `ease`.
  static const ease = Curves.ease;
}
