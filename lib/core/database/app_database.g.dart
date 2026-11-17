// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $JobCheckpointsTable extends JobCheckpoints with TableInfo<$JobCheckpointsTable, JobCheckpoint> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $JobCheckpointsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stepMeta = const VerificationMeta('step');
  @override
  late final GeneratedColumn<int> step = GeneratedColumn<int>(
    'step',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _resumesMeta = const VerificationMeta('resumes');
  @override
  late final GeneratedColumn<int> resumes = GeneratedColumn<int>(
    'resumes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [kind, step, resumes, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'job_checkpoints';
  @override
  VerificationContext validateIntegrity(Insertable<JobCheckpoint> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('kind')) {
      context.handle(_kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('step')) {
      context.handle(_stepMeta, step.isAcceptableOrUnknown(data['step']!, _stepMeta));
    } else if (isInserting) {
      context.missing(_stepMeta);
    }
    if (data.containsKey('resumes')) {
      context.handle(_resumesMeta, resumes.isAcceptableOrUnknown(data['resumes']!, _resumesMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta, updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {kind};
  @override
  JobCheckpoint map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return JobCheckpoint(
      kind: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      step: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}step'])!,
      resumes: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}resumes'])!,
      updatedAt: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $JobCheckpointsTable createAlias(String alias) {
    return $JobCheckpointsTable(attachedDatabase, alias);
  }
}

class JobCheckpoint extends DataClass implements Insertable<JobCheckpoint> {
  /// The job kind, for example `self_test.long`.
  final String kind;

  /// The last finished step.
  final int step;

  /// How many times the job has continued from a checkpoint.
  final int resumes;

  /// Milliseconds since the epoch, UTC.
  final int updatedAt;
  const JobCheckpoint({required this.kind, required this.step, required this.resumes, required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['kind'] = Variable<String>(kind);
    map['step'] = Variable<int>(step);
    map['resumes'] = Variable<int>(resumes);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  JobCheckpointsCompanion toCompanion(bool nullToAbsent) {
    return JobCheckpointsCompanion(
      kind: Value(kind),
      step: Value(step),
      resumes: Value(resumes),
      updatedAt: Value(updatedAt),
    );
  }

  factory JobCheckpoint.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return JobCheckpoint(
      kind: serializer.fromJson<String>(json['kind']),
      step: serializer.fromJson<int>(json['step']),
      resumes: serializer.fromJson<int>(json['resumes']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'kind': serializer.toJson<String>(kind),
      'step': serializer.toJson<int>(step),
      'resumes': serializer.toJson<int>(resumes),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  JobCheckpoint copyWith({String? kind, int? step, int? resumes, int? updatedAt}) => JobCheckpoint(
    kind: kind ?? this.kind,
    step: step ?? this.step,
    resumes: resumes ?? this.resumes,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  JobCheckpoint copyWithCompanion(JobCheckpointsCompanion data) {
    return JobCheckpoint(
      kind: data.kind.present ? data.kind.value : this.kind,
      step: data.step.present ? data.step.value : this.step,
      resumes: data.resumes.present ? data.resumes.value : this.resumes,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('JobCheckpoint(')
          ..write('kind: $kind, ')
          ..write('step: $step, ')
          ..write('resumes: $resumes, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(kind, step, resumes, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is JobCheckpoint &&
          other.kind == this.kind &&
          other.step == this.step &&
          other.resumes == this.resumes &&
          other.updatedAt == this.updatedAt);
}

class JobCheckpointsCompanion extends UpdateCompanion<JobCheckpoint> {
  final Value<String> kind;
  final Value<int> step;
  final Value<int> resumes;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const JobCheckpointsCompanion({
    this.kind = const Value.absent(),
    this.step = const Value.absent(),
    this.resumes = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  JobCheckpointsCompanion.insert({
    required String kind,
    required int step,
    this.resumes = const Value.absent(),
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : kind = Value(kind),
       step = Value(step),
       updatedAt = Value(updatedAt);
  static Insertable<JobCheckpoint> custom({
    Expression<String>? kind,
    Expression<int>? step,
    Expression<int>? resumes,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (kind != null) 'kind': kind,
      if (step != null) 'step': step,
      if (resumes != null) 'resumes': resumes,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  JobCheckpointsCompanion copyWith({
    Value<String>? kind,
    Value<int>? step,
    Value<int>? resumes,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return JobCheckpointsCompanion(
      kind: kind ?? this.kind,
      step: step ?? this.step,
      resumes: resumes ?? this.resumes,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (step.present) {
      map['step'] = Variable<int>(step.value);
    }
    if (resumes.present) {
      map['resumes'] = Variable<int>(resumes.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('JobCheckpointsCompanion(')
          ..write('kind: $kind, ')
          ..write('step: $step, ')
          ..write('resumes: $resumes, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $JobCheckpointsTable jobCheckpoints = $JobCheckpointsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables => allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [jobCheckpoints];
}

typedef $$JobCheckpointsTableCreateCompanionBuilder = JobCheckpointsCompanion Function({
  required String kind,
  required int step,
  Value<int> resumes,
  required int updatedAt,
  Value<int> rowid,
});
typedef $$JobCheckpointsTableUpdateCompanionBuilder = JobCheckpointsCompanion Function({
  Value<String> kind,
  Value<int> step,
  Value<int> resumes,
  Value<int> updatedAt,
  Value<int> rowid,
});

class $$JobCheckpointsTableFilterComposer extends Composer<_$AppDatabase, $JobCheckpointsTable> {
  $$JobCheckpointsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get kind => $composableBuilder(column: $table.kind, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get step => $composableBuilder(column: $table.step, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get resumes =>
      $composableBuilder(column: $table.resumes, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$JobCheckpointsTableOrderingComposer extends Composer<_$AppDatabase, $JobCheckpointsTable> {
  $$JobCheckpointsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get step =>
      $composableBuilder(column: $table.step, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get resumes =>
      $composableBuilder(column: $table.resumes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$JobCheckpointsTableAnnotationComposer extends Composer<_$AppDatabase, $JobCheckpointsTable> {
  $$JobCheckpointsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get kind => $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get step => $composableBuilder(column: $table.step, builder: (column) => column);

  GeneratedColumn<int> get resumes => $composableBuilder(column: $table.resumes, builder: (column) => column);

  GeneratedColumn<int> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$JobCheckpointsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $JobCheckpointsTable,
          JobCheckpoint,
          $$JobCheckpointsTableFilterComposer,
          $$JobCheckpointsTableOrderingComposer,
          $$JobCheckpointsTableAnnotationComposer,
          $$JobCheckpointsTableCreateCompanionBuilder,
          $$JobCheckpointsTableUpdateCompanionBuilder,
          (JobCheckpoint, BaseReferences<_$AppDatabase, $JobCheckpointsTable, JobCheckpoint>),
          JobCheckpoint,
          PrefetchHooks Function()
        > {
  $$JobCheckpointsTableTableManager(_$AppDatabase db, $JobCheckpointsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$JobCheckpointsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$JobCheckpointsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$JobCheckpointsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> kind = const Value.absent(),
            Value<int> step = const Value.absent(),
            Value<int> resumes = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => JobCheckpointsCompanion(kind: kind, step: step, resumes: resumes, updatedAt: updatedAt, rowid: rowid),
          createCompanionCallback:
              ({
                required String kind,
                required int step,
                Value<int> resumes = const Value.absent(),
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => JobCheckpointsCompanion.insert(
                kind: kind,
                step: step,
                resumes: resumes,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$JobCheckpointsTable, JobCheckpoint>(table),
                  BaseReferences<_$AppDatabase, $JobCheckpointsTable, JobCheckpoint>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$JobCheckpointsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $JobCheckpointsTable,
      JobCheckpoint,
      $$JobCheckpointsTableFilterComposer,
      $$JobCheckpointsTableOrderingComposer,
      $$JobCheckpointsTableAnnotationComposer,
      $$JobCheckpointsTableCreateCompanionBuilder,
      $$JobCheckpointsTableUpdateCompanionBuilder,
      (JobCheckpoint, BaseReferences<_$AppDatabase, $JobCheckpointsTable, JobCheckpoint>),
      JobCheckpoint,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$JobCheckpointsTableTableManager get jobCheckpoints => $$JobCheckpointsTableTableManager(_db, _db.jobCheckpoints);
}

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The open database. Opened in `bootstrap()` before the first frame and
/// injected by overriding this provider.

@ProviderFor(appDatabase)
final appDatabaseProvider = AppDatabaseProvider._();

/// The open database. Opened in `bootstrap()` before the first frame and
/// injected by overriding this provider.

final class AppDatabaseProvider extends $FunctionalProvider<AppDatabase, AppDatabase, AppDatabase>
    with $Provider<AppDatabase> {
  /// The open database. Opened in `bootstrap()` before the first frame and
  /// injected by overriding this provider.
  AppDatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appDatabaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appDatabaseHash();

  @$internal
  @override
  $ProviderElement<AppDatabase> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  AppDatabase create(Ref ref) {
    return appDatabase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppDatabase value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<AppDatabase>(value));
  }
}

String _$appDatabaseHash() => r'fbd240c8e363c6240a96c362d3e339f5fb6b81a8';
