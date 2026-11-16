import 'package:flutter/material.dart';

import '../../design_system/loopd_colors.dart';
import 'app_tab.dart';
import 'tab_icon.dart';

/// The bottom tab bar from the mockups (`docs/mockups/Main.dc.html`): no
/// highlight pill. The active tab is bright with a bold label; the others are
/// muted.
class LoopdTabBar extends StatelessWidget {
  const LoopdTabBar({required this.currentIndex, required this.onSelected, super.key});

  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = LoopdColors.forBrightness(Theme.of(context).brightness);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.line)),
      ),
      child: SafeArea(
        top: false,
        // 20 below the labels, or the system gesture area if that is taller.
        minimum: const EdgeInsets.only(bottom: 20),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (final tab in AppTab.values)
                _TabButton(
                  tab: tab,
                  selected: tab.index == currentIndex,
                  colors: colors,
                  onTap: () => onSelected(tab.index),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({required this.tab, required this.selected, required this.colors, required this.onTap});

  final AppTab tab;
  final bool selected;
  final LoopdColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? colors.textPrimary : colors.textMuted;
    return Semantics(
      button: true,
      selected: selected,
      label: tab.label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 32,
        child: SizedBox(
          width: 64,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TabIcon(tab: tab, color: color),
              const SizedBox(height: 4),
              Text(
                tab.label,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
