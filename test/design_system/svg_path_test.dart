import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loopd/design_system/components/loopd_glyph.dart';
import 'package:loopd/design_system/svg_path.dart';

void main() {
  group('parseSvgPath', () {
    test('lines, relative moves and closes land where the mockup puts them', () {
      final bounds = parseSvgPath('M4 10.5L12 4l8 6.5V20H4z').getBounds();
      expect(bounds, const Rect.fromLTRB(4, 4, 20, 20));
    });

    test('extra numbers repeat the last command, and lower case is relative', () {
      final bounds = parseSvgPath('M7 3v8h3 2 2').getBounds();
      expect(bounds, const Rect.fromLTRB(7, 3, 14, 11), reason: 'h3 2 2 is three steps right: 3, 2 and 2');
    });

    test('arcs and smooth curves stay inside the 24 px box', () {
      final bounds = parseSvgPath('M17 3c-2 0-3 2-3 5s1 4 3 4v9M12 8S10.5 3 8 3a2.5 2.5 0 0 0 0 5z').getBounds();
      expect(bounds.left, greaterThanOrEqualTo(0));
      expect(bounds.right, lessThanOrEqualTo(24));
      expect(bounds.bottom, 21);
    });

    test('numbers that run together are split', () {
      final bounds = parseSvgPath('M6.1.9l-4.4 4.3').getBounds();
      expect(bounds.left, closeTo(1.7, 1e-4));
      expect(bounds.top, closeTo(0.9, 1e-4));
      expect(bounds.right, closeTo(6.1, 1e-4));
      expect(bounds.bottom, closeTo(5.2, 1e-4));
    });

    test('an unknown command is refused', () {
      expect(() => parseSvgPath('M0 0Q1 1 2 2'), throwsFormatException);
      expect(() => parseSvgPath('M0'), throwsFormatException);
    });
  });

  testWidgets('every expense icon draws, and an unknown one falls back to the star', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Wrap(
          children: [
            for (final (key, _) in LoopdGlyph.expenseIcons) LoopdGlyph(key, color: const Color(0xFF000000)),
            const LoopdGlyph('missing', color: Color(0xFF000000)),
          ],
        ),
      ),
    );
    expect(find.byType(LoopdGlyph), findsNWidgets(LoopdGlyph.expenseIcons.length + 1));
    expect(tester.takeException(), isNull);
  });
}
