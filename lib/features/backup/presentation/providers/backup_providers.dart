import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/backup/backup_engine.dart';

part 'backup_providers.g.dart';

/// Where backup stands, for the Backup & restore page.
@riverpod
Stream<BackupStatus> backupStatus(Ref ref) => ref.watch(backupEngineProvider).watchStatus();
