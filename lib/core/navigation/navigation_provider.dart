import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'navigation_service.dart';

final navigationProvider = Provider<NavigationService>((ref) {
  return NavigationService();
});
