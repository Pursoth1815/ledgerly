import 'package:flutter/material.dart';

import '../loopd_colors.dart';
import '../loopd_spacing.dart';
import '../loopd_typography.dart';

/// Opens a Loopd bottom sheet (mockups: Add task, Add note, capture): 30 px
/// top corners, one grab handle, and room for the keyboard. [builder] gives
/// only the content; the sheet adds the handle and the optional [title].
Future<T?> showLoopdSheet<T>({required BuildContext context, required WidgetBuilder builder, String? title}) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
      backgroundColor: context.colors.surface,
      barrierColor: context.colors.scrim,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(LoopdRadius.sheet))),
      builder: (context) => LoopdSheet(title: title, child: builder(context)),
    );

/// The inside of a sheet: the handle, an optional [title] and the content,
/// with the mockups' 10 / 20 / 28 padding.
class LoopdSheet extends StatelessWidget {
  const LoopdSheet({required this.child, this.title, super.key});

  /// Finds the grab handle in tests.
  static const handleKey = ValueKey('loopd-sheet-handle');

  final Widget child;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
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
            Flexible(child: child),
          ],
        ),
      ),
    );
  }
}
