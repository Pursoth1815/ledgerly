import 'package:flutter_test/flutter_test.dart';
import 'package:loopd/app/config/app_config.dart';

void main() {
  test('the personal flavour is the personal build', () {
    expect(AppConfig.fromFlavor('personal').distribution, Distribution.personal);
  });

  test('the store flavour, and no flavour at all, are the store build', () {
    expect(AppConfig.fromFlavor('store').distribution, Distribution.store);
    expect(AppConfig.fromFlavor(null).distribution, Distribution.store);
  });

  test('an unknown flavour is an error, not a silent default', () {
    expect(() => AppConfig.fromFlavor('beta'), throwsArgumentError);
  });
}
