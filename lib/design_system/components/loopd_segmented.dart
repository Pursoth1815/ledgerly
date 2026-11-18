import 'package:flutter/widgets.dart';

import '../loopd_colors.dart';
import '../loopd_motion.dart';
import '../loopd_spacing.dart';
import '../loopd_typography.dart';
import 'loopd_pressable.dart';

/// One choice in a [LoopdSegmented]: its value, label and the colour its
/// segment takes when chosen.
class LoopdSegment<T> {
  const LoopdSegment({required this.value, required this.label, required this.color});

  final T value;
  final String label;
  final Color color;
}

/// Two or three choices as one pill, such as Bank account / Credit card or
/// UPI / Credit Card / Cash (mockups: Add account, Add expense). The
/// coloured segment slides across to the one you tap and takes its colour on
/// the way.
class LoopdSegmented<T> extends StatelessWidget {
  const LoopdSegmented({required this.segments, required this.selected, required this.onChanged, super.key})
    : assert(segments.length >= 2);

  final List<LoopdSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final motion = LoopdMotion.of(context);
    final index = segments.indexWhere((segment) => segment.value == selected);
    final count = segments.length;
    // -1 is the left edge and 1 the right, so segment i sits at this x.
    final x = count == 1 || index < 0 ? -1.0 : -1 + 2 * index / (count - 1);
    return Container(
      padding: const EdgeInsets.all(LoopdSpace.xs),
      decoration: BoxDecoration(color: c.surfaceRaised, borderRadius: BorderRadius.circular(18)),
      child: Stack(
        children: [
          if (index >= 0)
            Positioned.fill(
              child: AnimatedAlign(
                alignment: Alignment(x, 0),
                duration: motion.emphasis,
                curve: Curves.easeOutCubic,
                child: FractionallySizedBox(
                  widthFactor: 1 / count,
                  heightFactor: 1,
                  child: AnimatedContainer(
                    duration: motion.emphasis,
                    decoration: BoxDecoration(
                      color: segments[index].color,
                      borderRadius: BorderRadius.circular(LoopdRadius.tile),
                    ),
                  ),
                ),
              ),
            ),
          Row(
            children: [
              for (final segment in segments)
                Expanded(
                  child: Semantics(
                    selected: segment.value == selected,
                    child: LoopdPressable(
                      onTap: () => onChanged(segment.value),
                      label: segment.label,
                      child: SizedBox(
                        height: 42,
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: motion.standard,
                            style: LoopdType.label.copyWith(
                              color: segment.value == selected ? c.onAccent : c.textSecondary,
                              fontWeight: FontWeight.w800,
                            ),
                            child: Text(segment.label, maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
