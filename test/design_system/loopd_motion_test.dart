import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loopd/design_system/loopd_motion.dart';

void main() {
  Future<LoopdMotion> motionWith(WidgetTester tester, {required bool reduce}) async {
    late LoopdMotion motion;
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(disableAnimations: reduce),
        child: Builder(
          builder: (context) {
            motion = LoopdMotion.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    return motion;
  }

  testWidgets('uses the mockup durations normally', (tester) async {
    final motion = await motionWith(tester, reduce: false);
    expect(motion.standard, const Duration(milliseconds: 220));
    expect(motion.emphasis, const Duration(milliseconds: 260));
  });

  testWidgets('drops every animation when the phone asks to reduce motion', (tester) async {
    final motion = await motionWith(tester, reduce: true);
    expect([motion.quick, motion.standard, motion.emphasis, motion.tick, motion.sheet], everyElement(Duration.zero));
  });
}
