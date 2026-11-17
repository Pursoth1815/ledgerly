import 'package:flutter/foundation.dart';

import '../../core/background/background_job.dart';
import '../../core/background/self_test_job.dart';
import '../../core/database/app_database.dart';

/// Every background job the app can run (ADR 0013). Engines and features
/// add theirs here as they are built.
List<BackgroundJob> appJobs(AppDatabase database) => [
  // The Phase 0B spike lab only exists in profile builds.
  if (kProfileMode) ...selfTestJobs(database),
];
