import 'package:flutter/material.dart';

import '../loopd_colors.dart';
import '../loopd_spacing.dart';
import '../loopd_typography.dart';

/// Opens a Loopd bottom sheet (mockups: Add task, Add note, capture): 30 px
/// top corners, one grab handle, and room for the keyboard. [builder] gives
/// only the content; the sheet adds the handle and the optional [title].
///
/// Every sheet opens on the app's root navigator, over the tab bar, wherever
/// it is opened from: the tab bar cannot be tapped behind it, so a sheet never
/// stays open on a tab you left. Close the sheet to switch tabs.
///
/// A [tall] sheet, such as Accounts and cards or the expense form, keeps one
/// height from its first frame, so content that loads or changes never makes
/// it jump.
Future<T?> showLoopdSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  String? title,
  bool tall = false,
}) => showModalBottomSheet<T>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: false,
  backgroundColor: context.colors.surface,
  barrierColor: context.colors.scrim,
  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(LoopdRadius.sheet))),
  builder: (context) => LoopdSheet(title: title, tall: tall, child: builder(context)),
);

/// The inside of a sheet: the handle, an optional [title] and the content,
/// with the mockups' 10 / 20 / 28 padding. A tap on the sheet outside a
/// field or button closes the keyboard.
class LoopdSheet extends StatelessWidget {
  const LoopdSheet({required this.child, this.title, this.tall = false, super.key});

  /// The height of a tall sheet's content: most of the screen, leaving the
  /// top in view so it still reads as a sheet. A short screen gets what fits.
  static double tallHeight(BuildContext context) => MediaQuery.sizeOf(context).height * 0.88;

  /// Finds the grab handle in tests.
  static const handleKey = ValueKey('loopd-sheet-handle');

  final Widget child;
  final String? title;
  final bool tall;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // Fields and buttons win their own taps; only a tap on empty space
    // reaches this one.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(LoopdSpace.gutter, 10, LoopdSpace.gutter, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  key: LoopdSheet.handleKey,
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(color: colors.line, borderRadius: BorderRadius.circular(3)),
                ),
              ),
              const SizedBox(height: LoopdSpace.lg),
              if (title != null) ...[
                Text(title!, style: LoopdType.title.copyWith(color: colors.textPrimary)),
                const SizedBox(height: LoopdSpace.lg),
              ],
              Flexible(
                child: tall ? SizedBox(height: tallHeight(context), child: child) : child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
