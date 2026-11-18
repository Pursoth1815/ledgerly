import 'dart:ui';

/// Reads the `d` text of an SVG path, as written in the mockups, into a
/// Flutter [Path], so icons can be drawn exactly as designed.
///
/// It supports what the mockups use: move, line, horizontal, vertical,
/// cubic and smooth cubic curves, elliptical arcs and close, in absolute
/// (capital) and relative (lower-case) form. Anything else throws a
/// [FormatException], so a typo fails in tests rather than drawing wrongly.
Path parseSvgPath(String data) {
  final path = Path();
  final tokens = _tokens(data);
  var i = 0;
  var command = '';
  var x = 0.0, y = 0.0; // the current point
  var startX = 0.0, startY = 0.0; // where the current figure began
  var controlX = 0.0, controlY = 0.0; // the last cubic's second control point
  var lastWasCubic = false;

  bool atNumber() => i < tokens.length && tokens[i] is double;
  double next() {
    if (!atNumber()) throw FormatException('A number is missing in "$data"');
    return tokens[i++] as double;
  }

  while (i < tokens.length) {
    if (tokens[i] is String) command = tokens[i++] as String;
    final relative = command == command.toLowerCase();
    final dx = relative ? x : 0.0, dy = relative ? y : 0.0;
    var cubic = false;
    switch (command.toUpperCase()) {
      case 'M':
        x = dx + next();
        y = dy + next();
        path.moveTo(x, y);
        (startX, startY) = (x, y);
        // Further pairs after a move are lines.
        command = relative ? 'l' : 'L';
      case 'L':
        x = dx + next();
        y = dy + next();
        path.lineTo(x, y);
      case 'H':
        x = dx + next();
        path.lineTo(x, y);
      case 'V':
        y = dy + next();
        path.lineTo(x, y);
      case 'C':
        final x1 = dx + next(), y1 = dy + next();
        controlX = dx + next();
        controlY = dy + next();
        x = dx + next();
        y = dy + next();
        path.cubicTo(x1, y1, controlX, controlY, x, y);
        cubic = true;
      case 'S':
        // The first control point mirrors the last cubic's second one.
        final x1 = lastWasCubic ? 2 * x - controlX : x;
        final y1 = lastWasCubic ? 2 * y - controlY : y;
        controlX = dx + next();
        controlY = dy + next();
        x = dx + next();
        y = dy + next();
        path.cubicTo(x1, y1, controlX, controlY, x, y);
        cubic = true;
      case 'A':
        final rx = next(), ry = next(), rotation = next();
        final largeArc = next() != 0, sweep = next() != 0;
        x = dx + next();
        y = dy + next();
        path.arcToPoint(
          Offset(x, y),
          radius: Radius.elliptical(rx, ry),
          rotation: rotation,
          largeArc: largeArc,
          clockwise: sweep,
        );
      case 'Z':
        path.close();
        (x, y) = (startX, startY);
        // A close takes no numbers; the next token must be a command.
        if (atNumber()) throw FormatException('Numbers after a close in "$data"');
      default:
        throw FormatException('Unsupported path command "$command" in "$data"');
    }
    lastWasCubic = cubic;
  }
  return path;
}

/// Commands as strings and numbers as doubles. Numbers may run together, as
/// in "1.5-2" or ".5.5". Commas and spaces only separate.
List<Object> _tokens(String data) {
  final out = <Object>[];
  // Any letter is read as a command, so one this reader does not know is
  // refused rather than skipped. Numbers are tried first, so the e of 1e3
  // stays part of its number.
  final pattern = RegExp(r'-?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?|[A-Za-z]');
  for (final match in pattern.allMatches(data)) {
    final text = match.group(0)!;
    out.add(RegExp('^[A-Za-z]').hasMatch(text) ? text : double.parse(text));
  }
  return out;
}
