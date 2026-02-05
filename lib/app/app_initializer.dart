import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ledgerly/features/master_data/master_data.dart';

import '../config/environment.dart';
import '../core/utils/logger.dart';

class AppInitializer {
  AppInitializer._();

  static Future<void> initialize({required ProviderContainer container, required String flavor}) async {
    // 1️⃣ Load environment
    await _loadEnvironment(flavor);

    // Validate environment (fail fast)
    Environment.validate();

    // 3️⃣ Setup logging
    AppLogger.init(enableLogs: Environment.enableNetworkLogs);
    AppLogger.d('🚀 Ledgerly starting ($flavor)', tag: 'INIT');

    AppLogger.d('🚀 Ledgerly starting', tag: 'INIT');

    // 4️⃣ Prefetch critical data
    _preloadMasterData(container);

    // Future additions (when needed):
    // await SharedPreferences.getInstance();
  }

  static Future<void> _loadEnvironment(String flavor) async {
    final fileName = flavor == 'dev' || kDebugMode ? '.env.dev' : '.env.prod';

    await dotenv.load(fileName: fileName);
  }

  static Future<void> _preloadMasterData(ProviderContainer container) async {
    AppLogger.d('📦 Prefetching master data', tag: 'INIT');
    await container.read(masterDataProvider.future);
    AppLogger.d('✅ Master data loaded', tag: 'INIT');
  }
}
