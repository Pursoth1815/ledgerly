import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/backup/backup_engine.dart';
import '../../../../core/ledger/ledger_engine.dart';
import '../../../../core/ledger/ledger_types.dart';

part 'today_providers.g.dart';

// Live reads for Today's cards. Each follows a watched query in an engine,
// so Today redraws by itself after any change; nothing here writes.

/// Spending in [month]'s calendar month so far, for the Spending card. Today's
/// own total is the part of it dated today.
@riverpod
Stream<SpendingReport> todayMonthSpending(Ref ref, DateTime month) => ref
    .watch(ledgerEngineProvider)
    .watchSpending(DateTime(month.year, month.month), DateTime(month.year, month.month + 1));

/// Where backup stands, for the Backup card.
@riverpod
Stream<BackupStatus> todayBackupStatus(Ref ref) => ref.watch(backupEngineProvider).watchStatus();
