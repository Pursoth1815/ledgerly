import 'app/background/background_bootstrap.dart';
import 'app/bootstrap.dart';

Future<void> main() => bootstrap();

/// The headless engine's entry point, started by Kotlin's WorkManager
/// worker when the app is not running (ADR 0013).
@pragma('vm:entry-point')
Future<void> backgroundMain() => backgroundBootstrap();
