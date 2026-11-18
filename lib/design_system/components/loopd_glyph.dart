import 'package:flutter/widgets.dart';

import '../svg_path.dart';

/// A line icon from the mockups (24 by 24, 2 px stroke, round caps and
/// joins), drawn from the mockup's own paths, such as a category's icon.
///
/// [name] is the key stored with a category, such as `food` or `bus`. An
/// unknown key draws a star, so an old backup can never break a screen.
class LoopdGlyph extends StatelessWidget {
  const LoopdGlyph(this.name, {required this.color, this.size = 20, super.key});

  final String name;
  final Color color;
  final double size;

  /// The expense category icons, in the order the category sheet shows them:
  /// key and spoken label. The first twelve are the mockup's
  /// (`CategorySheet.dc.html`); the rest are drawn the same way. Each
  /// belongs to one category at most, so there are as many as colours.
  static const expenseIcons = <(String, String)>[
    ('food', 'Food'),
    ('snack', 'Cup'),
    ('grocery', 'Basket'),
    ('bus', 'Bus'),
    ('bag', 'Bag'),
    ('bill', 'Receipt'),
    ('health', 'Health'),
    ('fuel', 'Fuel'),
    ('star', 'Star'),
    ('home', 'House'),
    ('repeat', 'Repeat'),
    ('gift', 'Gift'),
    // Added 18 Nov 2026, so every category has an icon of its own.
    ('phone', 'Phone'),
    ('car', 'Car'),
    ('plane', 'Plane'),
    ('film', 'Film'),
    ('book', 'Book'),
    ('cap', 'Graduation cap'),
    ('paw', 'Paw'),
    ('dumbbell', 'Dumbbell'),
    ('scissors', 'Scissors'),
    ('wifi', 'Wi-Fi'),
    ('bolt', 'Lightning'),
    ('shirt', 'Shirt'),
    // Misc's (version 7).
    ('dots', 'Dots'),
  ];

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(size: Size.square(size), painter: _GlyphPainter(_shapes[name] ?? _shapes['star']!, color)),
  );

  // Each icon as the mockup draws it: SVG path text, plus rectangles and
  // circles turned into paths.
  static final Map<String, List<Path>> _shapes = {
    'food': [parseSvgPath('M7 3v8a2 2 0 0 0 2 2v8M7 3v4M10 3v4M7 7h3M17 3c-2 0-3 2-3 5s1 4 3 4v9')],
    'snack': [
      parseSvgPath('M5 8h12v5a5 5 0 0 1-5 5h-2a5 5 0 0 1-5-5z'),
      parseSvgPath('M17 10h1.5a2.5 2.5 0 0 1 0 5H17M8 3v2M12 3v2'),
    ],
    'grocery': [
      parseSvgPath('M4 10h16l-1.5 9a2 2 0 0 1-2 1.7h-9a2 2 0 0 1-2-1.7z'),
      parseSvgPath('M8 10l3-6M16 10l-3-6M9 14v3M15 14v3'),
    ],
    'bus': [_rect(4, 3, 16, 15, 3), parseSvgPath('M4 11h16M8 18v3M16 18v3')],
    'bag': [parseSvgPath('M5 8h14l-1 12H6z'), parseSvgPath('M9 8V6a3 3 0 0 1 6 0v2')],
    'bill': [parseSvgPath('M6 3h12v18l-3-2-3 2-3-2-3 2z'), parseSvgPath('M9 8h6M9 12h6M9 16h3')],
    'health': [
      parseSvgPath('M12 20.5s-7.5-4.6-7.5-10.2A4.2 4.2 0 0 1 12 7.6a4.2 4.2 0 0 1 7.5 2.7c0 5.6-7.5 10.2-7.5 10.2z'),
      parseSvgPath('M12 10.5v5M9.5 13h5'),
    ],
    'fuel': [
      parseSvgPath('M5 21V5a2 2 0 0 1 2-2h6a2 2 0 0 1 2 2v16M4 21h12M8 8h4'),
      parseSvgPath('M15 9l3 2v6a1.5 1.5 0 0 0 3 0V9l-3-3'),
    ],
    'star': [parseSvgPath('M12 3l2.7 5.6 6.1.9-4.4 4.3 1 6.1L12 17l-5.4 2.9 1-6.1-4.4-4.3 6.1-.9z')],
    'home': [parseSvgPath('M4 10.5L12 4l8 6.5V20H4z'), parseSvgPath('M10 20v-5h4v5')],
    'repeat': [parseSvgPath('M17 2l3 3-3 3M4 11V9a4 4 0 0 1 4-4h12M7 22l-3-3 3-3M20 13v2a4 4 0 0 1-4 4H4')],
    'gift': [
      _rect(3, 8, 18, 5, 1),
      parseSvgPath('M5 13v8h14v-8M12 8v13M12 8S10.5 3 8 3a2.5 2.5 0 0 0 0 5zM12 8s1.5-5 4-5a2.5 2.5 0 0 1 0 5z'),
    ],
    'phone': [_rect(7, 2.5, 10, 19, 2.5), parseSvgPath('M11 18h2')],
    'car': [
      parseSvgPath('M3.5 17v-4.5l2-5A2 2 0 0 1 7.4 6h9.2a2 2 0 0 1 1.9 1.5l2 5V17z'),
      parseSvgPath('M3.5 12.5h17M7 17v2.5M17 17v2.5M7 14.8h1M16 14.8h1'),
    ],
    'plane': [
      parseSvgPath(
        'M12 2.5c.9 0 1.5 1 1.5 2.5v4.5l7 4.5v2l-7-2.2V18l2 1.5V21L12 20l-3.5 1v-1.5l2-1.5v-4.2l-7 2.2v-2l7-4.5V5'
        'c0-1.5.6-2.5 1.5-2.5z',
      ),
    ],
    'film': [_rect(3, 5, 18, 14, 2), parseSvgPath('M3 9.5h18M7.5 5l2 4.5M12.5 5l2 4.5M17.5 5l2 4.5')],
    'book': [
      parseSvgPath('M4.5 19V5a2 2 0 0 1 2-2h13v14h-13a2 2 0 0 0-2 2z'),
      parseSvgPath('M4.5 19a2 2 0 0 0 2 2h13M9 8h6'),
    ],
    'cap': [
      parseSvgPath('M2 9.5l10-5 10 5-10 5z'),
      parseSvgPath('M6 11.5V16c0 1.5 2.7 3 6 3s6-1.5 6-3v-4.5M22 9.5V15'),
    ],
    'paw': [
      _circle(5.5, 11, 1.8),
      _circle(9, 6.5, 1.8),
      _circle(15, 6.5, 1.8),
      _circle(18.5, 11, 1.8),
      parseSvgPath(
        'M12 12c-2.5 0-5 3.2-5 5.5 0 1.6 1.2 2.5 2.6 2.5 1 0 1.6-.6 2.4-.6s1.4.6 2.4.6c1.4 0 2.6-.9 2.6-2.5'
        ' 0-2.3-2.5-5.5-5-5.5z',
      ),
    ],
    'dumbbell': [parseSvgPath('M6.5 6.5v11M17.5 6.5v11M3.5 9.5v5M20.5 9.5v5M6.5 12h11')],
    'scissors': [_circle(6, 6, 3), _circle(6, 18, 3), parseSvgPath('M8.5 7.8L20 18M8.5 16.2L20 6')],
    'wifi': [
      parseSvgPath('M2.5 9a14 14 0 0 1 19 0M5.5 12.5a9.5 9.5 0 0 1 13 0M8.8 16a4.8 4.8 0 0 1 6.4 0M12 19.5h.01'),
    ],
    'bolt': [parseSvgPath('M13 2.5L4.5 13.5H11l-1 8 8.5-11H12z')],
    'dots': [_circle(5, 12, 1.4), _circle(12, 12, 1.4), _circle(19, 12, 1.4)],
    'shirt': [parseSvgPath('M8.5 3.5L3 6.5l2 4 2-1V21h10V9.5l2 1 2-4-5.5-3a3.5 3.5 0 0 1-7 0z')],
  };

  static Path _circle(double x, double y, double radius) =>
      Path()..addOval(Rect.fromCircle(center: Offset(x, y), radius: radius));

  static Path _rect(double x, double y, double width, double height, double radius) =>
      Path()..addRRect(RRect.fromLTRBR(x, y, x + width, y + height, Radius.circular(radius)));
}

class _GlyphPainter extends CustomPainter {
  _GlyphPainter(this.paths, this.color);

  final List<Path> paths;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final path in paths) {
      canvas.drawPath(path, stroke);
    }
  }

  @override
  bool shouldRepaint(_GlyphPainter oldDelegate) => oldDelegate.paths != paths || oldDelegate.color != color;
}
