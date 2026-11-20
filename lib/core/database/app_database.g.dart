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

class $AppSettingsTable extends AppSettings with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  List<GeneratedColumn> get $columns => [key, value, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(Insertable<AppSetting> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(_keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(_valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta, updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      key: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}value'])!,
      updatedAt: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final String key;
  final String value;

  /// Milliseconds since the epoch, UTC.
  final int updatedAt;
  const AppSetting({required this.key, required this.value, required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(key: Value(key), value: Value(value), updatedAt: Value(updatedAt));
  }

  factory AppSetting.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  AppSetting copyWith({String? key, String? value, int? updatedAt}) =>
      AppSetting(key: key ?? this.key, value: value ?? this.value, updatedAt: updatedAt ?? this.updatedAt);
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting && other.key == this.key && other.value == this.value && other.updatedAt == this.updatedAt);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    required String value,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value),
       updatedAt = Value(updatedAt);
  static Insertable<AppSetting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith({Value<String>? key, Value<String>? value, Value<int>? updatedAt, Value<int>? rowid}) {
    return AppSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
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
    return (StringBuffer('AppSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AccountsTable extends Accounts with TableInfo<$AccountsTable, Account> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    check: () => kind.isIn(const [
      'bank',
      'credit_card',
      'cash',
      'category',
      'income',
      'loan',
      'adjustment',
      'write_off',
      'opening',
    ]),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bankNameMeta = const VerificationMeta('bankName');
  @override
  late final GeneratedColumn<String> bankName = GeneratedColumn<String>(
    'bank_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bankCodeMeta = const VerificationMeta('bankCode');
  @override
  late final GeneratedColumn<String> bankCode = GeneratedColumn<String>(
    'bank_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _last4Meta = const VerificationMeta('last4');
  @override
  late final GeneratedColumn<String> last4 = GeneratedColumn<String>(
    'last4',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDefaultMeta = const VerificationMeta('isDefault');
  @override
  late final GeneratedColumn<bool> isDefault = GeneratedColumn<bool>(
    'is_default',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("is_default" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _removedAtMeta = const VerificationMeta('removedAt');
  @override
  late final GeneratedColumn<int> removedAt = GeneratedColumn<int>(
    'removed_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, kind, name, bankName, bankCode, last4, isDefault, createdAt, removedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'accounts';
  @override
  VerificationContext validateIntegrity(Insertable<Account> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(_kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('name')) {
      context.handle(_nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('bank_name')) {
      context.handle(_bankNameMeta, bankName.isAcceptableOrUnknown(data['bank_name']!, _bankNameMeta));
    }
    if (data.containsKey('bank_code')) {
      context.handle(_bankCodeMeta, bankCode.isAcceptableOrUnknown(data['bank_code']!, _bankCodeMeta));
    }
    if (data.containsKey('last4')) {
      context.handle(_last4Meta, last4.isAcceptableOrUnknown(data['last4']!, _last4Meta));
    }
    if (data.containsKey('is_default')) {
      context.handle(_isDefaultMeta, isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('removed_at')) {
      context.handle(_removedAtMeta, removedAt.isAcceptableOrUnknown(data['removed_at']!, _removedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Account map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Account(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      kind: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      bankName: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}bank_name']),
      bankCode: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}bank_code']),
      last4: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}last4']),
      isDefault: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}is_default'])!,
      createdAt: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      removedAt: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}removed_at']),
    );
  }

  @override
  $AccountsTable createAlias(String alias) {
    return $AccountsTable(attachedDatabase, alias);
  }

  @override
  bool get isStrict => true;
}

class Account extends DataClass implements Insertable<Account> {
  final String id;

  /// bank, credit_card, cash, category, income, loan, adjustment, write_off,
  /// opening.
  final String kind;

  /// The nickname, such as Primary or Kiwi; the plain name for built-in
  /// accounts and categories.
  final String name;

  /// The bank as chosen from the list or typed, such as Federal Bank (banks
  /// and cards). Kept as text because two list entries can share one sender
  /// code, and a bank typed by hand has none.
  final String? bankName;

  /// The six-letter SMS sender code, such as FEDBNK (banks and cards).
  final String? bankCode;

  /// Last four digits of the account or card number.
  final String? last4;
  final bool isDefault;
  final int createdAt;

  /// Removed accounts keep their past transactions (no archived state).
  final int? removedAt;
  const Account({
    required this.id,
    required this.kind,
    required this.name,
    this.bankName,
    this.bankCode,
    this.last4,
    required this.isDefault,
    required this.createdAt,
    this.removedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['kind'] = Variable<String>(kind);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || bankName != null) {
      map['bank_name'] = Variable<String>(bankName);
    }
    if (!nullToAbsent || bankCode != null) {
      map['bank_code'] = Variable<String>(bankCode);
    }
    if (!nullToAbsent || last4 != null) {
      map['last4'] = Variable<String>(last4);
    }
    map['is_default'] = Variable<bool>(isDefault);
    map['created_at'] = Variable<int>(createdAt);
    if (!nullToAbsent || removedAt != null) {
      map['removed_at'] = Variable<int>(removedAt);
    }
    return map;
  }

  AccountsCompanion toCompanion(bool nullToAbsent) {
    return AccountsCompanion(
      id: Value(id),
      kind: Value(kind),
      name: Value(name),
      bankName: bankName == null && nullToAbsent ? const Value.absent() : Value(bankName),
      bankCode: bankCode == null && nullToAbsent ? const Value.absent() : Value(bankCode),
      last4: last4 == null && nullToAbsent ? const Value.absent() : Value(last4),
      isDefault: Value(isDefault),
      createdAt: Value(createdAt),
      removedAt: removedAt == null && nullToAbsent ? const Value.absent() : Value(removedAt),
    );
  }

  factory Account.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Account(
      id: serializer.fromJson<String>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      name: serializer.fromJson<String>(json['name']),
      bankName: serializer.fromJson<String?>(json['bankName']),
      bankCode: serializer.fromJson<String?>(json['bankCode']),
      last4: serializer.fromJson<String?>(json['last4']),
      isDefault: serializer.fromJson<bool>(json['isDefault']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      removedAt: serializer.fromJson<int?>(json['removedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'kind': serializer.toJson<String>(kind),
      'name': serializer.toJson<String>(name),
      'bankName': serializer.toJson<String?>(bankName),
      'bankCode': serializer.toJson<String?>(bankCode),
      'last4': serializer.toJson<String?>(last4),
      'isDefault': serializer.toJson<bool>(isDefault),
      'createdAt': serializer.toJson<int>(createdAt),
      'removedAt': serializer.toJson<int?>(removedAt),
    };
  }

  Account copyWith({
    String? id,
    String? kind,
    String? name,
    Value<String?> bankName = const Value.absent(),
    Value<String?> bankCode = const Value.absent(),
    Value<String?> last4 = const Value.absent(),
    bool? isDefault,
    int? createdAt,
    Value<int?> removedAt = const Value.absent(),
  }) => Account(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    name: name ?? this.name,
    bankName: bankName.present ? bankName.value : this.bankName,
    bankCode: bankCode.present ? bankCode.value : this.bankCode,
    last4: last4.present ? last4.value : this.last4,
    isDefault: isDefault ?? this.isDefault,
    createdAt: createdAt ?? this.createdAt,
    removedAt: removedAt.present ? removedAt.value : this.removedAt,
  );
  Account copyWithCompanion(AccountsCompanion data) {
    return Account(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      name: data.name.present ? data.name.value : this.name,
      bankName: data.bankName.present ? data.bankName.value : this.bankName,
      bankCode: data.bankCode.present ? data.bankCode.value : this.bankCode,
      last4: data.last4.present ? data.last4.value : this.last4,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      removedAt: data.removedAt.present ? data.removedAt.value : this.removedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Account(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('name: $name, ')
          ..write('bankName: $bankName, ')
          ..write('bankCode: $bankCode, ')
          ..write('last4: $last4, ')
          ..write('isDefault: $isDefault, ')
          ..write('createdAt: $createdAt, ')
          ..write('removedAt: $removedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, kind, name, bankName, bankCode, last4, isDefault, createdAt, removedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Account &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.name == this.name &&
          other.bankName == this.bankName &&
          other.bankCode == this.bankCode &&
          other.last4 == this.last4 &&
          other.isDefault == this.isDefault &&
          other.createdAt == this.createdAt &&
          other.removedAt == this.removedAt);
}

class AccountsCompanion extends UpdateCompanion<Account> {
  final Value<String> id;
  final Value<String> kind;
  final Value<String> name;
  final Value<String?> bankName;
  final Value<String?> bankCode;
  final Value<String?> last4;
  final Value<bool> isDefault;
  final Value<int> createdAt;
  final Value<int?> removedAt;
  final Value<int> rowid;
  const AccountsCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.name = const Value.absent(),
    this.bankName = const Value.absent(),
    this.bankCode = const Value.absent(),
    this.last4 = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.removedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AccountsCompanion.insert({
    required String id,
    required String kind,
    required String name,
    this.bankName = const Value.absent(),
    this.bankCode = const Value.absent(),
    this.last4 = const Value.absent(),
    this.isDefault = const Value.absent(),
    required int createdAt,
    this.removedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       kind = Value(kind),
       name = Value(name),
       createdAt = Value(createdAt);
  static Insertable<Account> custom({
    Expression<String>? id,
    Expression<String>? kind,
    Expression<String>? name,
    Expression<String>? bankName,
    Expression<String>? bankCode,
    Expression<String>? last4,
    Expression<bool>? isDefault,
    Expression<int>? createdAt,
    Expression<int>? removedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (name != null) 'name': name,
      if (bankName != null) 'bank_name': bankName,
      if (bankCode != null) 'bank_code': bankCode,
      if (last4 != null) 'last4': last4,
      if (isDefault != null) 'is_default': isDefault,
      if (createdAt != null) 'created_at': createdAt,
      if (removedAt != null) 'removed_at': removedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AccountsCompanion copyWith({
    Value<String>? id,
    Value<String>? kind,
    Value<String>? name,
    Value<String?>? bankName,
    Value<String?>? bankCode,
    Value<String?>? last4,
    Value<bool>? isDefault,
    Value<int>? createdAt,
    Value<int?>? removedAt,
    Value<int>? rowid,
  }) {
    return AccountsCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      name: name ?? this.name,
      bankName: bankName ?? this.bankName,
      bankCode: bankCode ?? this.bankCode,
      last4: last4 ?? this.last4,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      removedAt: removedAt ?? this.removedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (bankName.present) {
      map['bank_name'] = Variable<String>(bankName.value);
    }
    if (bankCode.present) {
      map['bank_code'] = Variable<String>(bankCode.value);
    }
    if (last4.present) {
      map['last4'] = Variable<String>(last4.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<bool>(isDefault.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (removedAt.present) {
      map['removed_at'] = Variable<int>(removedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountsCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('name: $name, ')
          ..write('bankName: $bankName, ')
          ..write('bankCode: $bankCode, ')
          ..write('last4: $last4, ')
          ..write('isDefault: $isDefault, ')
          ..write('createdAt: $createdAt, ')
          ..write('removedAt: $removedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CategoriesTable extends Categories with TableInfo<$CategoriesTable, Category> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _accountIdMeta = const VerificationMeta('accountId');
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES accounts (id)'),
  );
  static const VerificationMeta _colourMeta = const VerificationMeta('colour');
  @override
  late final GeneratedColumn<int> colour = GeneratedColumn<int>(
    'colour',
    aliasedName,
    false,
    check: () => ComparableExpr(colour).isBetweenValues(0, 24),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [accountId, colour, icon, sortOrder];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(Insertable<Category> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('account_id')) {
      context.handle(_accountIdMeta, accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta));
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('colour')) {
      context.handle(_colourMeta, colour.isAcceptableOrUnknown(data['colour']!, _colourMeta));
    } else if (isInserting) {
      context.missing(_colourMeta);
    }
    if (data.containsKey('icon')) {
      context.handle(_iconMeta, icon.isAcceptableOrUnknown(data['icon']!, _iconMeta));
    } else if (isInserting) {
      context.missing(_iconMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta, sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {accountId};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {colour},
    {icon},
  ];
  @override
  Category map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Category(
      accountId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}account_id'])!,
      colour: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}colour'])!,
      icon: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}icon'])!,
      sortOrder: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }

  @override
  bool get isStrict => true;
}

class Category extends DataClass implements Insertable<Category> {
  final String accountId;

  /// Index into the category palette (0 to 24).
  final int colour;

  /// Icon key, such as food or bus.
  final String icon;
  final int sortOrder;
  const Category({required this.accountId, required this.colour, required this.icon, required this.sortOrder});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['account_id'] = Variable<String>(accountId);
    map['colour'] = Variable<int>(colour);
    map['icon'] = Variable<String>(icon);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      accountId: Value(accountId),
      colour: Value(colour),
      icon: Value(icon),
      sortOrder: Value(sortOrder),
    );
  }

  factory Category.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Category(
      accountId: serializer.fromJson<String>(json['accountId']),
      colour: serializer.fromJson<int>(json['colour']),
      icon: serializer.fromJson<String>(json['icon']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'accountId': serializer.toJson<String>(accountId),
      'colour': serializer.toJson<int>(colour),
      'icon': serializer.toJson<String>(icon),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  Category copyWith({String? accountId, int? colour, String? icon, int? sortOrder}) => Category(
    accountId: accountId ?? this.accountId,
    colour: colour ?? this.colour,
    icon: icon ?? this.icon,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  Category copyWithCompanion(CategoriesCompanion data) {
    return Category(
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      colour: data.colour.present ? data.colour.value : this.colour,
      icon: data.icon.present ? data.icon.value : this.icon,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Category(')
          ..write('accountId: $accountId, ')
          ..write('colour: $colour, ')
          ..write('icon: $icon, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(accountId, colour, icon, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Category &&
          other.accountId == this.accountId &&
          other.colour == this.colour &&
          other.icon == this.icon &&
          other.sortOrder == this.sortOrder);
}

class CategoriesCompanion extends UpdateCompanion<Category> {
  final Value<String> accountId;
  final Value<int> colour;
  final Value<String> icon;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const CategoriesCompanion({
    this.accountId = const Value.absent(),
    this.colour = const Value.absent(),
    this.icon = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoriesCompanion.insert({
    required String accountId,
    required int colour,
    required String icon,
    required int sortOrder,
    this.rowid = const Value.absent(),
  }) : accountId = Value(accountId),
       colour = Value(colour),
       icon = Value(icon),
       sortOrder = Value(sortOrder);
  static Insertable<Category> custom({
    Expression<String>? accountId,
    Expression<int>? colour,
    Expression<String>? icon,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (accountId != null) 'account_id': accountId,
      if (colour != null) 'colour': colour,
      if (icon != null) 'icon': icon,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoriesCompanion copyWith({
    Value<String>? accountId,
    Value<int>? colour,
    Value<String>? icon,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return CategoriesCompanion(
      accountId: accountId ?? this.accountId,
      colour: colour ?? this.colour,
      icon: icon ?? this.icon,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (colour.present) {
      map['colour'] = Variable<int>(colour.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('accountId: $accountId, ')
          ..write('colour: $colour, ')
          ..write('icon: $icon, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LedgerTransactionsTable extends LedgerTransactions with TableInfo<$LedgerTransactionsTable, LedgerTransaction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LedgerTransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    check: () => kind.isIn(const [
      'expense',
      'refund',
      'income',
      'transfer',
      'card_payment',
      'loan',
      'repayment',
      'write_off',
      'adjustment',
      'opening_balance',
    ]),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paymentMethodMeta = const VerificationMeta('paymentMethod');
  @override
  late final GeneratedColumn<String> paymentMethod = GeneratedColumn<String>(
    'payment_method',
    aliasedName,
    true,
    check: () => paymentMethod.isIn(const ['upi', 'credit_card', 'cash', 'debit_card', 'net_banking', 'auto_debit']),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _channelMeta = const VerificationMeta('channel');
  @override
  late final GeneratedColumn<String> channel = GeneratedColumn<String>(
    'channel',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _occurredAtMeta = const VerificationMeta('occurredAt');
  @override
  late final GeneratedColumn<int> occurredAt = GeneratedColumn<int>(
    'occurred_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localDateMeta = const VerificationMeta('localDate');
  @override
  late final GeneratedColumn<String> localDate = GeneratedColumn<String>(
    'local_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _merchantMeta = const VerificationMeta('merchant');
  @override
  late final GeneratedColumn<String> merchant = GeneratedColumn<String>(
    'merchant',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _refundOfMeta = const VerificationMeta('refundOf');
  @override
  late final GeneratedColumn<String> refundOf = GeneratedColumn<String>(
    'refund_of',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES ledger_transactions (id)'),
  );
  static const VerificationMeta _revisionMeta = const VerificationMeta('revision');
  @override
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
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
  static const VerificationMeta _deletedAtMeta = const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    kind,
    paymentMethod,
    channel,
    occurredAt,
    localDate,
    merchant,
    note,
    refundOf,
    revision,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ledger_transactions';
  @override
  VerificationContext validateIntegrity(Insertable<LedgerTransaction> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(_kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('payment_method')) {
      context.handle(
        _paymentMethodMeta,
        paymentMethod.isAcceptableOrUnknown(data['payment_method']!, _paymentMethodMeta),
      );
    }
    if (data.containsKey('channel')) {
      context.handle(_channelMeta, channel.isAcceptableOrUnknown(data['channel']!, _channelMeta));
    }
    if (data.containsKey('occurred_at')) {
      context.handle(_occurredAtMeta, occurredAt.isAcceptableOrUnknown(data['occurred_at']!, _occurredAtMeta));
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    if (data.containsKey('local_date')) {
      context.handle(_localDateMeta, localDate.isAcceptableOrUnknown(data['local_date']!, _localDateMeta));
    } else if (isInserting) {
      context.missing(_localDateMeta);
    }
    if (data.containsKey('merchant')) {
      context.handle(_merchantMeta, merchant.isAcceptableOrUnknown(data['merchant']!, _merchantMeta));
    }
    if (data.containsKey('note')) {
      context.handle(_noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('refund_of')) {
      context.handle(_refundOfMeta, refundOf.isAcceptableOrUnknown(data['refund_of']!, _refundOfMeta));
    }
    if (data.containsKey('revision')) {
      context.handle(_revisionMeta, revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta));
    } else if (isInserting) {
      context.missing(_revisionMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta, updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta, deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LedgerTransaction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LedgerTransaction(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      kind: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      paymentMethod: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}payment_method']),
      channel: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}channel']),
      occurredAt: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}occurred_at'])!,
      localDate: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}local_date'])!,
      merchant: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}merchant']),
      note: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}note']),
      refundOf: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}refund_of']),
      revision: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}revision'])!,
      createdAt: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}deleted_at']),
    );
  }

  @override
  $LedgerTransactionsTable createAlias(String alias) {
    return $LedgerTransactionsTable(attachedDatabase, alias);
  }

  @override
  bool get isStrict => true;
}

class LedgerTransaction extends DataClass implements Insertable<LedgerTransaction> {
  final String id;
  final String kind;

  /// Required for expenses, refunds, loans and repayments; empty otherwise.
  final String? paymentMethod;

  /// How the SMS says it happened, such as upi_qr for a card paid by UPI QR.
  final String? channel;
  final int occurredAt;

  /// The local calendar day, YYYY-MM-DD, for totals by day.
  final String localDate;
  final String? merchant;
  final String? note;
  final String? refundOf;
  final int revision;
  final int createdAt;
  final int updatedAt;
  final int? deletedAt;
  const LedgerTransaction({
    required this.id,
    required this.kind,
    this.paymentMethod,
    this.channel,
    required this.occurredAt,
    required this.localDate,
    this.merchant,
    this.note,
    this.refundOf,
    required this.revision,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['kind'] = Variable<String>(kind);
    if (!nullToAbsent || paymentMethod != null) {
      map['payment_method'] = Variable<String>(paymentMethod);
    }
    if (!nullToAbsent || channel != null) {
      map['channel'] = Variable<String>(channel);
    }
    map['occurred_at'] = Variable<int>(occurredAt);
    map['local_date'] = Variable<String>(localDate);
    if (!nullToAbsent || merchant != null) {
      map['merchant'] = Variable<String>(merchant);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || refundOf != null) {
      map['refund_of'] = Variable<String>(refundOf);
    }
    map['revision'] = Variable<int>(revision);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  LedgerTransactionsCompanion toCompanion(bool nullToAbsent) {
    return LedgerTransactionsCompanion(
      id: Value(id),
      kind: Value(kind),
      paymentMethod: paymentMethod == null && nullToAbsent ? const Value.absent() : Value(paymentMethod),
      channel: channel == null && nullToAbsent ? const Value.absent() : Value(channel),
      occurredAt: Value(occurredAt),
      localDate: Value(localDate),
      merchant: merchant == null && nullToAbsent ? const Value.absent() : Value(merchant),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      refundOf: refundOf == null && nullToAbsent ? const Value.absent() : Value(refundOf),
      revision: Value(revision),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent ? const Value.absent() : Value(deletedAt),
    );
  }

  factory LedgerTransaction.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LedgerTransaction(
      id: serializer.fromJson<String>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      paymentMethod: serializer.fromJson<String?>(json['paymentMethod']),
      channel: serializer.fromJson<String?>(json['channel']),
      occurredAt: serializer.fromJson<int>(json['occurredAt']),
      localDate: serializer.fromJson<String>(json['localDate']),
      merchant: serializer.fromJson<String?>(json['merchant']),
      note: serializer.fromJson<String?>(json['note']),
      refundOf: serializer.fromJson<String?>(json['refundOf']),
      revision: serializer.fromJson<int>(json['revision']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'kind': serializer.toJson<String>(kind),
      'paymentMethod': serializer.toJson<String?>(paymentMethod),
      'channel': serializer.toJson<String?>(channel),
      'occurredAt': serializer.toJson<int>(occurredAt),
      'localDate': serializer.toJson<String>(localDate),
      'merchant': serializer.toJson<String?>(merchant),
      'note': serializer.toJson<String?>(note),
      'refundOf': serializer.toJson<String?>(refundOf),
      'revision': serializer.toJson<int>(revision),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  LedgerTransaction copyWith({
    String? id,
    String? kind,
    Value<String?> paymentMethod = const Value.absent(),
    Value<String?> channel = const Value.absent(),
    int? occurredAt,
    String? localDate,
    Value<String?> merchant = const Value.absent(),
    Value<String?> note = const Value.absent(),
    Value<String?> refundOf = const Value.absent(),
    int? revision,
    int? createdAt,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
  }) => LedgerTransaction(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    paymentMethod: paymentMethod.present ? paymentMethod.value : this.paymentMethod,
    channel: channel.present ? channel.value : this.channel,
    occurredAt: occurredAt ?? this.occurredAt,
    localDate: localDate ?? this.localDate,
    merchant: merchant.present ? merchant.value : this.merchant,
    note: note.present ? note.value : this.note,
    refundOf: refundOf.present ? refundOf.value : this.refundOf,
    revision: revision ?? this.revision,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  LedgerTransaction copyWithCompanion(LedgerTransactionsCompanion data) {
    return LedgerTransaction(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      paymentMethod: data.paymentMethod.present ? data.paymentMethod.value : this.paymentMethod,
      channel: data.channel.present ? data.channel.value : this.channel,
      occurredAt: data.occurredAt.present ? data.occurredAt.value : this.occurredAt,
      localDate: data.localDate.present ? data.localDate.value : this.localDate,
      merchant: data.merchant.present ? data.merchant.value : this.merchant,
      note: data.note.present ? data.note.value : this.note,
      refundOf: data.refundOf.present ? data.refundOf.value : this.refundOf,
      revision: data.revision.present ? data.revision.value : this.revision,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LedgerTransaction(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('channel: $channel, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('localDate: $localDate, ')
          ..write('merchant: $merchant, ')
          ..write('note: $note, ')
          ..write('refundOf: $refundOf, ')
          ..write('revision: $revision, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    kind,
    paymentMethod,
    channel,
    occurredAt,
    localDate,
    merchant,
    note,
    refundOf,
    revision,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LedgerTransaction &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.paymentMethod == this.paymentMethod &&
          other.channel == this.channel &&
          other.occurredAt == this.occurredAt &&
          other.localDate == this.localDate &&
          other.merchant == this.merchant &&
          other.note == this.note &&
          other.refundOf == this.refundOf &&
          other.revision == this.revision &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class LedgerTransactionsCompanion extends UpdateCompanion<LedgerTransaction> {
  final Value<String> id;
  final Value<String> kind;
  final Value<String?> paymentMethod;
  final Value<String?> channel;
  final Value<int> occurredAt;
  final Value<String> localDate;
  final Value<String?> merchant;
  final Value<String?> note;
  final Value<String?> refundOf;
  final Value<int> revision;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<int> rowid;
  const LedgerTransactionsCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.channel = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.localDate = const Value.absent(),
    this.merchant = const Value.absent(),
    this.note = const Value.absent(),
    this.refundOf = const Value.absent(),
    this.revision = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LedgerTransactionsCompanion.insert({
    required String id,
    required String kind,
    this.paymentMethod = const Value.absent(),
    this.channel = const Value.absent(),
    required int occurredAt,
    required String localDate,
    this.merchant = const Value.absent(),
    this.note = const Value.absent(),
    this.refundOf = const Value.absent(),
    required int revision,
    required int createdAt,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       kind = Value(kind),
       occurredAt = Value(occurredAt),
       localDate = Value(localDate),
       revision = Value(revision),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<LedgerTransaction> custom({
    Expression<String>? id,
    Expression<String>? kind,
    Expression<String>? paymentMethod,
    Expression<String>? channel,
    Expression<int>? occurredAt,
    Expression<String>? localDate,
    Expression<String>? merchant,
    Expression<String>? note,
    Expression<String>? refundOf,
    Expression<int>? revision,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (channel != null) 'channel': channel,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (localDate != null) 'local_date': localDate,
      if (merchant != null) 'merchant': merchant,
      if (note != null) 'note': note,
      if (refundOf != null) 'refund_of': refundOf,
      if (revision != null) 'revision': revision,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LedgerTransactionsCompanion copyWith({
    Value<String>? id,
    Value<String>? kind,
    Value<String?>? paymentMethod,
    Value<String?>? channel,
    Value<int>? occurredAt,
    Value<String>? localDate,
    Value<String?>? merchant,
    Value<String?>? note,
    Value<String?>? refundOf,
    Value<int>? revision,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<int>? rowid,
  }) {
    return LedgerTransactionsCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      channel: channel ?? this.channel,
      occurredAt: occurredAt ?? this.occurredAt,
      localDate: localDate ?? this.localDate,
      merchant: merchant ?? this.merchant,
      note: note ?? this.note,
      refundOf: refundOf ?? this.refundOf,
      revision: revision ?? this.revision,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (paymentMethod.present) {
      map['payment_method'] = Variable<String>(paymentMethod.value);
    }
    if (channel.present) {
      map['channel'] = Variable<String>(channel.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<int>(occurredAt.value);
    }
    if (localDate.present) {
      map['local_date'] = Variable<String>(localDate.value);
    }
    if (merchant.present) {
      map['merchant'] = Variable<String>(merchant.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (refundOf.present) {
      map['refund_of'] = Variable<String>(refundOf.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LedgerTransactionsCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('channel: $channel, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('localDate: $localDate, ')
          ..write('merchant: $merchant, ')
          ..write('note: $note, ')
          ..write('refundOf: $refundOf, ')
          ..write('revision: $revision, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PostingsTable extends Postings with TableInfo<$PostingsTable, Posting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PostingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _transactionIdMeta = const VerificationMeta('transactionId');
  @override
  late final GeneratedColumn<String> transactionId = GeneratedColumn<String>(
    'transaction_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES ledger_transactions (id)'),
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta('accountId');
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES accounts (id)'),
  );
  static const VerificationMeta _amountPaiseMeta = const VerificationMeta('amountPaise');
  @override
  late final GeneratedColumn<int> amountPaise = GeneratedColumn<int>(
    'amount_paise',
    aliasedName,
    false,
    check: () => BooleanExpressionOperators(amountPaise.equals(0)).not(),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, transactionId, accountId, amountPaise];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'postings';
  @override
  VerificationContext validateIntegrity(Insertable<Posting> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('transaction_id')) {
      context.handle(
        _transactionIdMeta,
        transactionId.isAcceptableOrUnknown(data['transaction_id']!, _transactionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_transactionIdMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(_accountIdMeta, accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta));
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('amount_paise')) {
      context.handle(_amountPaiseMeta, amountPaise.isAcceptableOrUnknown(data['amount_paise']!, _amountPaiseMeta));
    } else if (isInserting) {
      context.missing(_amountPaiseMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {transactionId, accountId},
  ];
  @override
  Posting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Posting(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      transactionId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}transaction_id'])!,
      accountId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}account_id'])!,
      amountPaise: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}amount_paise'])!,
    );
  }

  @override
  $PostingsTable createAlias(String alias) {
    return $PostingsTable(attachedDatabase, alias);
  }

  @override
  bool get isStrict => true;
}

class Posting extends DataClass implements Insertable<Posting> {
  final String id;
  final String transactionId;
  final String accountId;
  final int amountPaise;
  const Posting({required this.id, required this.transactionId, required this.accountId, required this.amountPaise});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['transaction_id'] = Variable<String>(transactionId);
    map['account_id'] = Variable<String>(accountId);
    map['amount_paise'] = Variable<int>(amountPaise);
    return map;
  }

  PostingsCompanion toCompanion(bool nullToAbsent) {
    return PostingsCompanion(
      id: Value(id),
      transactionId: Value(transactionId),
      accountId: Value(accountId),
      amountPaise: Value(amountPaise),
    );
  }

  factory Posting.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Posting(
      id: serializer.fromJson<String>(json['id']),
      transactionId: serializer.fromJson<String>(json['transactionId']),
      accountId: serializer.fromJson<String>(json['accountId']),
      amountPaise: serializer.fromJson<int>(json['amountPaise']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'transactionId': serializer.toJson<String>(transactionId),
      'accountId': serializer.toJson<String>(accountId),
      'amountPaise': serializer.toJson<int>(amountPaise),
    };
  }

  Posting copyWith({String? id, String? transactionId, String? accountId, int? amountPaise}) => Posting(
    id: id ?? this.id,
    transactionId: transactionId ?? this.transactionId,
    accountId: accountId ?? this.accountId,
    amountPaise: amountPaise ?? this.amountPaise,
  );
  Posting copyWithCompanion(PostingsCompanion data) {
    return Posting(
      id: data.id.present ? data.id.value : this.id,
      transactionId: data.transactionId.present ? data.transactionId.value : this.transactionId,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      amountPaise: data.amountPaise.present ? data.amountPaise.value : this.amountPaise,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Posting(')
          ..write('id: $id, ')
          ..write('transactionId: $transactionId, ')
          ..write('accountId: $accountId, ')
          ..write('amountPaise: $amountPaise')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, transactionId, accountId, amountPaise);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Posting &&
          other.id == this.id &&
          other.transactionId == this.transactionId &&
          other.accountId == this.accountId &&
          other.amountPaise == this.amountPaise);
}

class PostingsCompanion extends UpdateCompanion<Posting> {
  final Value<String> id;
  final Value<String> transactionId;
  final Value<String> accountId;
  final Value<int> amountPaise;
  final Value<int> rowid;
  const PostingsCompanion({
    this.id = const Value.absent(),
    this.transactionId = const Value.absent(),
    this.accountId = const Value.absent(),
    this.amountPaise = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PostingsCompanion.insert({
    required String id,
    required String transactionId,
    required String accountId,
    required int amountPaise,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       transactionId = Value(transactionId),
       accountId = Value(accountId),
       amountPaise = Value(amountPaise);
  static Insertable<Posting> custom({
    Expression<String>? id,
    Expression<String>? transactionId,
    Expression<String>? accountId,
    Expression<int>? amountPaise,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (transactionId != null) 'transaction_id': transactionId,
      if (accountId != null) 'account_id': accountId,
      if (amountPaise != null) 'amount_paise': amountPaise,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PostingsCompanion copyWith({
    Value<String>? id,
    Value<String>? transactionId,
    Value<String>? accountId,
    Value<int>? amountPaise,
    Value<int>? rowid,
  }) {
    return PostingsCompanion(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      accountId: accountId ?? this.accountId,
      amountPaise: amountPaise ?? this.amountPaise,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (transactionId.present) {
      map['transaction_id'] = Variable<String>(transactionId.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (amountPaise.present) {
      map['amount_paise'] = Variable<int>(amountPaise.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PostingsCompanion(')
          ..write('id: $id, ')
          ..write('transactionId: $transactionId, ')
          ..write('accountId: $accountId, ')
          ..write('amountPaise: $amountPaise, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TransactionRevisionsTable extends TransactionRevisions
    with TableInfo<$TransactionRevisionsTable, TransactionRevision> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionRevisionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _transactionIdMeta = const VerificationMeta('transactionId');
  @override
  late final GeneratedColumn<String> transactionId = GeneratedColumn<String>(
    'transaction_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES ledger_transactions (id)'),
  );
  static const VerificationMeta _revisionMeta = const VerificationMeta('revision');
  @override
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
    'action',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _snapshotJsonMeta = const VerificationMeta('snapshotJson');
  @override
  late final GeneratedColumn<String> snapshotJson = GeneratedColumn<String>(
    'snapshot_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _operationIdMeta = const VerificationMeta('operationId');
  @override
  late final GeneratedColumn<String> operationId = GeneratedColumn<String>(
    'operation_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _changedAtMeta = const VerificationMeta('changedAt');
  @override
  late final GeneratedColumn<int> changedAt = GeneratedColumn<int>(
    'changed_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    transactionId,
    revision,
    action,
    snapshotJson,
    reason,
    operationId,
    changedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transaction_revisions';
  @override
  VerificationContext validateIntegrity(Insertable<TransactionRevision> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('transaction_id')) {
      context.handle(
        _transactionIdMeta,
        transactionId.isAcceptableOrUnknown(data['transaction_id']!, _transactionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_transactionIdMeta);
    }
    if (data.containsKey('revision')) {
      context.handle(_revisionMeta, revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta));
    } else if (isInserting) {
      context.missing(_revisionMeta);
    }
    if (data.containsKey('action')) {
      context.handle(_actionMeta, action.isAcceptableOrUnknown(data['action']!, _actionMeta));
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('snapshot_json')) {
      context.handle(_snapshotJsonMeta, snapshotJson.isAcceptableOrUnknown(data['snapshot_json']!, _snapshotJsonMeta));
    } else if (isInserting) {
      context.missing(_snapshotJsonMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(_reasonMeta, reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta));
    }
    if (data.containsKey('operation_id')) {
      context.handle(_operationIdMeta, operationId.isAcceptableOrUnknown(data['operation_id']!, _operationIdMeta));
    }
    if (data.containsKey('changed_at')) {
      context.handle(_changedAtMeta, changedAt.isAcceptableOrUnknown(data['changed_at']!, _changedAtMeta));
    } else if (isInserting) {
      context.missing(_changedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {transactionId, revision},
  ];
  @override
  TransactionRevision map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransactionRevision(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      transactionId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}transaction_id'])!,
      revision: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}revision'])!,
      action: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}action'])!,
      snapshotJson: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}snapshot_json'])!,
      reason: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}reason']),
      operationId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}operation_id']),
      changedAt: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}changed_at'])!,
    );
  }

  @override
  $TransactionRevisionsTable createAlias(String alias) {
    return $TransactionRevisionsTable(attachedDatabase, alias);
  }

  @override
  bool get isStrict => true;
}

class TransactionRevision extends DataClass implements Insertable<TransactionRevision> {
  final int id;
  final String transactionId;
  final int revision;

  /// create, edit, delete or undo.
  final String action;
  final String snapshotJson;
  final String? reason;

  /// Groups the revisions written by one user action.
  final String? operationId;
  final int changedAt;
  const TransactionRevision({
    required this.id,
    required this.transactionId,
    required this.revision,
    required this.action,
    required this.snapshotJson,
    this.reason,
    this.operationId,
    required this.changedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['transaction_id'] = Variable<String>(transactionId);
    map['revision'] = Variable<int>(revision);
    map['action'] = Variable<String>(action);
    map['snapshot_json'] = Variable<String>(snapshotJson);
    if (!nullToAbsent || reason != null) {
      map['reason'] = Variable<String>(reason);
    }
    if (!nullToAbsent || operationId != null) {
      map['operation_id'] = Variable<String>(operationId);
    }
    map['changed_at'] = Variable<int>(changedAt);
    return map;
  }

  TransactionRevisionsCompanion toCompanion(bool nullToAbsent) {
    return TransactionRevisionsCompanion(
      id: Value(id),
      transactionId: Value(transactionId),
      revision: Value(revision),
      action: Value(action),
      snapshotJson: Value(snapshotJson),
      reason: reason == null && nullToAbsent ? const Value.absent() : Value(reason),
      operationId: operationId == null && nullToAbsent ? const Value.absent() : Value(operationId),
      changedAt: Value(changedAt),
    );
  }

  factory TransactionRevision.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransactionRevision(
      id: serializer.fromJson<int>(json['id']),
      transactionId: serializer.fromJson<String>(json['transactionId']),
      revision: serializer.fromJson<int>(json['revision']),
      action: serializer.fromJson<String>(json['action']),
      snapshotJson: serializer.fromJson<String>(json['snapshotJson']),
      reason: serializer.fromJson<String?>(json['reason']),
      operationId: serializer.fromJson<String?>(json['operationId']),
      changedAt: serializer.fromJson<int>(json['changedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'transactionId': serializer.toJson<String>(transactionId),
      'revision': serializer.toJson<int>(revision),
      'action': serializer.toJson<String>(action),
      'snapshotJson': serializer.toJson<String>(snapshotJson),
      'reason': serializer.toJson<String?>(reason),
      'operationId': serializer.toJson<String?>(operationId),
      'changedAt': serializer.toJson<int>(changedAt),
    };
  }

  TransactionRevision copyWith({
    int? id,
    String? transactionId,
    int? revision,
    String? action,
    String? snapshotJson,
    Value<String?> reason = const Value.absent(),
    Value<String?> operationId = const Value.absent(),
    int? changedAt,
  }) => TransactionRevision(
    id: id ?? this.id,
    transactionId: transactionId ?? this.transactionId,
    revision: revision ?? this.revision,
    action: action ?? this.action,
    snapshotJson: snapshotJson ?? this.snapshotJson,
    reason: reason.present ? reason.value : this.reason,
    operationId: operationId.present ? operationId.value : this.operationId,
    changedAt: changedAt ?? this.changedAt,
  );
  TransactionRevision copyWithCompanion(TransactionRevisionsCompanion data) {
    return TransactionRevision(
      id: data.id.present ? data.id.value : this.id,
      transactionId: data.transactionId.present ? data.transactionId.value : this.transactionId,
      revision: data.revision.present ? data.revision.value : this.revision,
      action: data.action.present ? data.action.value : this.action,
      snapshotJson: data.snapshotJson.present ? data.snapshotJson.value : this.snapshotJson,
      reason: data.reason.present ? data.reason.value : this.reason,
      operationId: data.operationId.present ? data.operationId.value : this.operationId,
      changedAt: data.changedAt.present ? data.changedAt.value : this.changedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransactionRevision(')
          ..write('id: $id, ')
          ..write('transactionId: $transactionId, ')
          ..write('revision: $revision, ')
          ..write('action: $action, ')
          ..write('snapshotJson: $snapshotJson, ')
          ..write('reason: $reason, ')
          ..write('operationId: $operationId, ')
          ..write('changedAt: $changedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, transactionId, revision, action, snapshotJson, reason, operationId, changedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionRevision &&
          other.id == this.id &&
          other.transactionId == this.transactionId &&
          other.revision == this.revision &&
          other.action == this.action &&
          other.snapshotJson == this.snapshotJson &&
          other.reason == this.reason &&
          other.operationId == this.operationId &&
          other.changedAt == this.changedAt);
}

class TransactionRevisionsCompanion extends UpdateCompanion<TransactionRevision> {
  final Value<int> id;
  final Value<String> transactionId;
  final Value<int> revision;
  final Value<String> action;
  final Value<String> snapshotJson;
  final Value<String?> reason;
  final Value<String?> operationId;
  final Value<int> changedAt;
  const TransactionRevisionsCompanion({
    this.id = const Value.absent(),
    this.transactionId = const Value.absent(),
    this.revision = const Value.absent(),
    this.action = const Value.absent(),
    this.snapshotJson = const Value.absent(),
    this.reason = const Value.absent(),
    this.operationId = const Value.absent(),
    this.changedAt = const Value.absent(),
  });
  TransactionRevisionsCompanion.insert({
    this.id = const Value.absent(),
    required String transactionId,
    required int revision,
    required String action,
    required String snapshotJson,
    this.reason = const Value.absent(),
    this.operationId = const Value.absent(),
    required int changedAt,
  }) : transactionId = Value(transactionId),
       revision = Value(revision),
       action = Value(action),
       snapshotJson = Value(snapshotJson),
       changedAt = Value(changedAt);
  static Insertable<TransactionRevision> custom({
    Expression<int>? id,
    Expression<String>? transactionId,
    Expression<int>? revision,
    Expression<String>? action,
    Expression<String>? snapshotJson,
    Expression<String>? reason,
    Expression<String>? operationId,
    Expression<int>? changedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (transactionId != null) 'transaction_id': transactionId,
      if (revision != null) 'revision': revision,
      if (action != null) 'action': action,
      if (snapshotJson != null) 'snapshot_json': snapshotJson,
      if (reason != null) 'reason': reason,
      if (operationId != null) 'operation_id': operationId,
      if (changedAt != null) 'changed_at': changedAt,
    });
  }

  TransactionRevisionsCompanion copyWith({
    Value<int>? id,
    Value<String>? transactionId,
    Value<int>? revision,
    Value<String>? action,
    Value<String>? snapshotJson,
    Value<String?>? reason,
    Value<String?>? operationId,
    Value<int>? changedAt,
  }) {
    return TransactionRevisionsCompanion(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      revision: revision ?? this.revision,
      action: action ?? this.action,
      snapshotJson: snapshotJson ?? this.snapshotJson,
      reason: reason ?? this.reason,
      operationId: operationId ?? this.operationId,
      changedAt: changedAt ?? this.changedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (transactionId.present) {
      map['transaction_id'] = Variable<String>(transactionId.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (snapshotJson.present) {
      map['snapshot_json'] = Variable<String>(snapshotJson.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (operationId.present) {
      map['operation_id'] = Variable<String>(operationId.value);
    }
    if (changedAt.present) {
      map['changed_at'] = Variable<int>(changedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionRevisionsCompanion(')
          ..write('id: $id, ')
          ..write('transactionId: $transactionId, ')
          ..write('revision: $revision, ')
          ..write('action: $action, ')
          ..write('snapshotJson: $snapshotJson, ')
          ..write('reason: $reason, ')
          ..write('operationId: $operationId, ')
          ..write('changedAt: $changedAt')
          ..write(')'))
        .toString();
  }
}

class $BalanceCheckpointsTable extends BalanceCheckpoints with TableInfo<$BalanceCheckpointsTable, BalanceCheckpoint> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BalanceCheckpointsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta('accountId');
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES accounts (id)'),
  );
  static const VerificationMeta _asOfMeta = const VerificationMeta('asOf');
  @override
  late final GeneratedColumn<int> asOf = GeneratedColumn<int>(
    'as_of',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actualPaiseMeta = const VerificationMeta('actualPaise');
  @override
  late final GeneratedColumn<int> actualPaise = GeneratedColumn<int>(
    'actual_paise',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _needsRecheckMeta = const VerificationMeta('needsRecheck');
  @override
  late final GeneratedColumn<bool> needsRecheck = GeneratedColumn<bool>(
    'needs_recheck',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("needs_recheck" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    accountId,
    asOf,
    actualPaise,
    source,
    note,
    needsRecheck,
    createdAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'balance_checkpoints';
  @override
  VerificationContext validateIntegrity(Insertable<BalanceCheckpoint> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(_accountIdMeta, accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta));
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('as_of')) {
      context.handle(_asOfMeta, asOf.isAcceptableOrUnknown(data['as_of']!, _asOfMeta));
    } else if (isInserting) {
      context.missing(_asOfMeta);
    }
    if (data.containsKey('actual_paise')) {
      context.handle(_actualPaiseMeta, actualPaise.isAcceptableOrUnknown(data['actual_paise']!, _actualPaiseMeta));
    } else if (isInserting) {
      context.missing(_actualPaiseMeta);
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta, source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('note')) {
      context.handle(_noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('needs_recheck')) {
      context.handle(_needsRecheckMeta, needsRecheck.isAcceptableOrUnknown(data['needs_recheck']!, _needsRecheckMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta, deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BalanceCheckpoint map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BalanceCheckpoint(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      accountId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}account_id'])!,
      asOf: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}as_of'])!,
      actualPaise: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}actual_paise'])!,
      source: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}source'])!,
      note: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}note']),
      needsRecheck: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}needs_recheck'])!,
      createdAt: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      deletedAt: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}deleted_at']),
    );
  }

  @override
  $BalanceCheckpointsTable createAlias(String alias) {
    return $BalanceCheckpointsTable(attachedDatabase, alias);
  }

  @override
  bool get isStrict => true;
}

class BalanceCheckpoint extends DataClass implements Insertable<BalanceCheckpoint> {
  final String id;
  final String accountId;
  final int asOf;
  final int actualPaise;

  /// manual for now; later sources arrive with their phases.
  final String source;
  final String? note;

  /// Set when something dated before this check is edited.
  final bool needsRecheck;
  final int createdAt;
  final int? deletedAt;
  const BalanceCheckpoint({
    required this.id,
    required this.accountId,
    required this.asOf,
    required this.actualPaise,
    required this.source,
    this.note,
    required this.needsRecheck,
    required this.createdAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['account_id'] = Variable<String>(accountId);
    map['as_of'] = Variable<int>(asOf);
    map['actual_paise'] = Variable<int>(actualPaise);
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['needs_recheck'] = Variable<bool>(needsRecheck);
    map['created_at'] = Variable<int>(createdAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  BalanceCheckpointsCompanion toCompanion(bool nullToAbsent) {
    return BalanceCheckpointsCompanion(
      id: Value(id),
      accountId: Value(accountId),
      asOf: Value(asOf),
      actualPaise: Value(actualPaise),
      source: Value(source),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      needsRecheck: Value(needsRecheck),
      createdAt: Value(createdAt),
      deletedAt: deletedAt == null && nullToAbsent ? const Value.absent() : Value(deletedAt),
    );
  }

  factory BalanceCheckpoint.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BalanceCheckpoint(
      id: serializer.fromJson<String>(json['id']),
      accountId: serializer.fromJson<String>(json['accountId']),
      asOf: serializer.fromJson<int>(json['asOf']),
      actualPaise: serializer.fromJson<int>(json['actualPaise']),
      source: serializer.fromJson<String>(json['source']),
      note: serializer.fromJson<String?>(json['note']),
      needsRecheck: serializer.fromJson<bool>(json['needsRecheck']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'accountId': serializer.toJson<String>(accountId),
      'asOf': serializer.toJson<int>(asOf),
      'actualPaise': serializer.toJson<int>(actualPaise),
      'source': serializer.toJson<String>(source),
      'note': serializer.toJson<String?>(note),
      'needsRecheck': serializer.toJson<bool>(needsRecheck),
      'createdAt': serializer.toJson<int>(createdAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  BalanceCheckpoint copyWith({
    String? id,
    String? accountId,
    int? asOf,
    int? actualPaise,
    String? source,
    Value<String?> note = const Value.absent(),
    bool? needsRecheck,
    int? createdAt,
    Value<int?> deletedAt = const Value.absent(),
  }) => BalanceCheckpoint(
    id: id ?? this.id,
    accountId: accountId ?? this.accountId,
    asOf: asOf ?? this.asOf,
    actualPaise: actualPaise ?? this.actualPaise,
    source: source ?? this.source,
    note: note.present ? note.value : this.note,
    needsRecheck: needsRecheck ?? this.needsRecheck,
    createdAt: createdAt ?? this.createdAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  BalanceCheckpoint copyWithCompanion(BalanceCheckpointsCompanion data) {
    return BalanceCheckpoint(
      id: data.id.present ? data.id.value : this.id,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      asOf: data.asOf.present ? data.asOf.value : this.asOf,
      actualPaise: data.actualPaise.present ? data.actualPaise.value : this.actualPaise,
      source: data.source.present ? data.source.value : this.source,
      note: data.note.present ? data.note.value : this.note,
      needsRecheck: data.needsRecheck.present ? data.needsRecheck.value : this.needsRecheck,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BalanceCheckpoint(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('asOf: $asOf, ')
          ..write('actualPaise: $actualPaise, ')
          ..write('source: $source, ')
          ..write('note: $note, ')
          ..write('needsRecheck: $needsRecheck, ')
          ..write('createdAt: $createdAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, accountId, asOf, actualPaise, source, note, needsRecheck, createdAt, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BalanceCheckpoint &&
          other.id == this.id &&
          other.accountId == this.accountId &&
          other.asOf == this.asOf &&
          other.actualPaise == this.actualPaise &&
          other.source == this.source &&
          other.note == this.note &&
          other.needsRecheck == this.needsRecheck &&
          other.createdAt == this.createdAt &&
          other.deletedAt == this.deletedAt);
}

class BalanceCheckpointsCompanion extends UpdateCompanion<BalanceCheckpoint> {
  final Value<String> id;
  final Value<String> accountId;
  final Value<int> asOf;
  final Value<int> actualPaise;
  final Value<String> source;
  final Value<String?> note;
  final Value<bool> needsRecheck;
  final Value<int> createdAt;
  final Value<int?> deletedAt;
  final Value<int> rowid;
  const BalanceCheckpointsCompanion({
    this.id = const Value.absent(),
    this.accountId = const Value.absent(),
    this.asOf = const Value.absent(),
    this.actualPaise = const Value.absent(),
    this.source = const Value.absent(),
    this.note = const Value.absent(),
    this.needsRecheck = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BalanceCheckpointsCompanion.insert({
    required String id,
    required String accountId,
    required int asOf,
    required int actualPaise,
    required String source,
    this.note = const Value.absent(),
    this.needsRecheck = const Value.absent(),
    required int createdAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       accountId = Value(accountId),
       asOf = Value(asOf),
       actualPaise = Value(actualPaise),
       source = Value(source),
       createdAt = Value(createdAt);
  static Insertable<BalanceCheckpoint> custom({
    Expression<String>? id,
    Expression<String>? accountId,
    Expression<int>? asOf,
    Expression<int>? actualPaise,
    Expression<String>? source,
    Expression<String>? note,
    Expression<bool>? needsRecheck,
    Expression<int>? createdAt,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (accountId != null) 'account_id': accountId,
      if (asOf != null) 'as_of': asOf,
      if (actualPaise != null) 'actual_paise': actualPaise,
      if (source != null) 'source': source,
      if (note != null) 'note': note,
      if (needsRecheck != null) 'needs_recheck': needsRecheck,
      if (createdAt != null) 'created_at': createdAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BalanceCheckpointsCompanion copyWith({
    Value<String>? id,
    Value<String>? accountId,
    Value<int>? asOf,
    Value<int>? actualPaise,
    Value<String>? source,
    Value<String?>? note,
    Value<bool>? needsRecheck,
    Value<int>? createdAt,
    Value<int?>? deletedAt,
    Value<int>? rowid,
  }) {
    return BalanceCheckpointsCompanion(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      asOf: asOf ?? this.asOf,
      actualPaise: actualPaise ?? this.actualPaise,
      source: source ?? this.source,
      note: note ?? this.note,
      needsRecheck: needsRecheck ?? this.needsRecheck,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (asOf.present) {
      map['as_of'] = Variable<int>(asOf.value);
    }
    if (actualPaise.present) {
      map['actual_paise'] = Variable<int>(actualPaise.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (needsRecheck.present) {
      map['needs_recheck'] = Variable<bool>(needsRecheck.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BalanceCheckpointsCompanion(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('asOf: $asOf, ')
          ..write('actualPaise: $actualPaise, ')
          ..write('source: $source, ')
          ..write('note: $note, ')
          ..write('needsRecheck: $needsRecheck, ')
          ..write('createdAt: $createdAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BackupConfigsTable extends BackupConfigs with TableInfo<$BackupConfigsTable, BackupConfig> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BackupConfigsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    check: () => id.equals(1),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _folderUriMeta = const VerificationMeta('folderUri');
  @override
  late final GeneratedColumn<String> folderUri = GeneratedColumn<String>(
    'folder_uri',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _folderNameMeta = const VerificationMeta('folderName');
  @override
  late final GeneratedColumn<String> folderName = GeneratedColumn<String>(
    'folder_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _setUpAtMeta = const VerificationMeta('setUpAt');
  @override
  late final GeneratedColumn<int> setUpAt = GeneratedColumn<int>(
    'set_up_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, folderUri, folderName, setUpAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'backup_configs';
  @override
  VerificationContext validateIntegrity(Insertable<BackupConfig> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('folder_uri')) {
      context.handle(_folderUriMeta, folderUri.isAcceptableOrUnknown(data['folder_uri']!, _folderUriMeta));
    } else if (isInserting) {
      context.missing(_folderUriMeta);
    }
    if (data.containsKey('folder_name')) {
      context.handle(_folderNameMeta, folderName.isAcceptableOrUnknown(data['folder_name']!, _folderNameMeta));
    } else if (isInserting) {
      context.missing(_folderNameMeta);
    }
    if (data.containsKey('set_up_at')) {
      context.handle(_setUpAtMeta, setUpAt.isAcceptableOrUnknown(data['set_up_at']!, _setUpAtMeta));
    } else if (isInserting) {
      context.missing(_setUpAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BackupConfig map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BackupConfig(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      folderUri: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}folder_uri'])!,
      folderName: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}folder_name'])!,
      setUpAt: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}set_up_at'])!,
    );
  }

  @override
  $BackupConfigsTable createAlias(String alias) {
    return $BackupConfigsTable(attachedDatabase, alias);
  }

  @override
  bool get isStrict => true;
}

class BackupConfig extends DataClass implements Insertable<BackupConfig> {
  final int id;

  /// The folder picked in the system picker (a tree URI), and what to show.
  final String folderUri;
  final String folderName;
  final int setUpAt;
  const BackupConfig({required this.id, required this.folderUri, required this.folderName, required this.setUpAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['folder_uri'] = Variable<String>(folderUri);
    map['folder_name'] = Variable<String>(folderName);
    map['set_up_at'] = Variable<int>(setUpAt);
    return map;
  }

  BackupConfigsCompanion toCompanion(bool nullToAbsent) {
    return BackupConfigsCompanion(
      id: Value(id),
      folderUri: Value(folderUri),
      folderName: Value(folderName),
      setUpAt: Value(setUpAt),
    );
  }

  factory BackupConfig.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BackupConfig(
      id: serializer.fromJson<int>(json['id']),
      folderUri: serializer.fromJson<String>(json['folderUri']),
      folderName: serializer.fromJson<String>(json['folderName']),
      setUpAt: serializer.fromJson<int>(json['setUpAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'folderUri': serializer.toJson<String>(folderUri),
      'folderName': serializer.toJson<String>(folderName),
      'setUpAt': serializer.toJson<int>(setUpAt),
    };
  }

  BackupConfig copyWith({int? id, String? folderUri, String? folderName, int? setUpAt}) => BackupConfig(
    id: id ?? this.id,
    folderUri: folderUri ?? this.folderUri,
    folderName: folderName ?? this.folderName,
    setUpAt: setUpAt ?? this.setUpAt,
  );
  BackupConfig copyWithCompanion(BackupConfigsCompanion data) {
    return BackupConfig(
      id: data.id.present ? data.id.value : this.id,
      folderUri: data.folderUri.present ? data.folderUri.value : this.folderUri,
      folderName: data.folderName.present ? data.folderName.value : this.folderName,
      setUpAt: data.setUpAt.present ? data.setUpAt.value : this.setUpAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BackupConfig(')
          ..write('id: $id, ')
          ..write('folderUri: $folderUri, ')
          ..write('folderName: $folderName, ')
          ..write('setUpAt: $setUpAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, folderUri, folderName, setUpAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BackupConfig &&
          other.id == this.id &&
          other.folderUri == this.folderUri &&
          other.folderName == this.folderName &&
          other.setUpAt == this.setUpAt);
}

class BackupConfigsCompanion extends UpdateCompanion<BackupConfig> {
  final Value<int> id;
  final Value<String> folderUri;
  final Value<String> folderName;
  final Value<int> setUpAt;
  const BackupConfigsCompanion({
    this.id = const Value.absent(),
    this.folderUri = const Value.absent(),
    this.folderName = const Value.absent(),
    this.setUpAt = const Value.absent(),
  });
  BackupConfigsCompanion.insert({
    this.id = const Value.absent(),
    required String folderUri,
    required String folderName,
    required int setUpAt,
  }) : folderUri = Value(folderUri),
       folderName = Value(folderName),
       setUpAt = Value(setUpAt);
  static Insertable<BackupConfig> custom({
    Expression<int>? id,
    Expression<String>? folderUri,
    Expression<String>? folderName,
    Expression<int>? setUpAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (folderUri != null) 'folder_uri': folderUri,
      if (folderName != null) 'folder_name': folderName,
      if (setUpAt != null) 'set_up_at': setUpAt,
    });
  }

  BackupConfigsCompanion copyWith({
    Value<int>? id,
    Value<String>? folderUri,
    Value<String>? folderName,
    Value<int>? setUpAt,
  }) {
    return BackupConfigsCompanion(
      id: id ?? this.id,
      folderUri: folderUri ?? this.folderUri,
      folderName: folderName ?? this.folderName,
      setUpAt: setUpAt ?? this.setUpAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (folderUri.present) {
      map['folder_uri'] = Variable<String>(folderUri.value);
    }
    if (folderName.present) {
      map['folder_name'] = Variable<String>(folderName.value);
    }
    if (setUpAt.present) {
      map['set_up_at'] = Variable<int>(setUpAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BackupConfigsCompanion(')
          ..write('id: $id, ')
          ..write('folderUri: $folderUri, ')
          ..write('folderName: $folderName, ')
          ..write('setUpAt: $setUpAt')
          ..write(')'))
        .toString();
  }
}

class $BackupRunsTable extends BackupRuns with TableInfo<$BackupRunsTable, BackupRun> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BackupRunsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _folderUriMeta = const VerificationMeta('folderUri');
  @override
  late final GeneratedColumn<String> folderUri = GeneratedColumn<String>(
    'folder_uri',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta('startedAt');
  @override
  late final GeneratedColumn<int> startedAt = GeneratedColumn<int>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    check: () => status.isIn(const ['written', 'verified', 'failed']),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _filesMeta = const VerificationMeta('files');
  @override
  late final GeneratedColumn<String> files = GeneratedColumn<String>(
    'files',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _totalBytesMeta = const VerificationMeta('totalBytes');
  @override
  late final GeneratedColumn<int> totalBytes = GeneratedColumn<int>(
    'total_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _finishedAtMeta = const VerificationMeta('finishedAt');
  @override
  late final GeneratedColumn<int> finishedAt = GeneratedColumn<int>(
    'finished_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, folderUri, startedAt, status, files, totalBytes, finishedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'backup_runs';
  @override
  VerificationContext validateIntegrity(Insertable<BackupRun> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('folder_uri')) {
      context.handle(_folderUriMeta, folderUri.isAcceptableOrUnknown(data['folder_uri']!, _folderUriMeta));
    } else if (isInserting) {
      context.missing(_folderUriMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(_startedAtMeta, startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta));
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta, status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('files')) {
      context.handle(_filesMeta, files.isAcceptableOrUnknown(data['files']!, _filesMeta));
    }
    if (data.containsKey('total_bytes')) {
      context.handle(_totalBytesMeta, totalBytes.isAcceptableOrUnknown(data['total_bytes']!, _totalBytesMeta));
    }
    if (data.containsKey('finished_at')) {
      context.handle(_finishedAtMeta, finishedAt.isAcceptableOrUnknown(data['finished_at']!, _finishedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BackupRun map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BackupRun(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      folderUri: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}folder_uri'])!,
      startedAt: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}started_at'])!,
      status: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      files: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}files'])!,
      totalBytes: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}total_bytes'])!,
      finishedAt: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}finished_at']),
    );
  }

  @override
  $BackupRunsTable createAlias(String alias) {
    return $BackupRunsTable(attachedDatabase, alias);
  }

  @override
  bool get isStrict => true;
}

class BackupRun extends DataClass implements Insertable<BackupRun> {
  /// Also in the file names: `loopd-<id>.lpdb`.
  final String id;
  final String folderUri;
  final int startedAt;

  /// written (not yet read back), verified, or failed.
  final String status;

  /// The files of the run, as a JSON list; empty until written.
  final String files;
  final int totalBytes;
  final int? finishedAt;
  const BackupRun({
    required this.id,
    required this.folderUri,
    required this.startedAt,
    required this.status,
    required this.files,
    required this.totalBytes,
    this.finishedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['folder_uri'] = Variable<String>(folderUri);
    map['started_at'] = Variable<int>(startedAt);
    map['status'] = Variable<String>(status);
    map['files'] = Variable<String>(files);
    map['total_bytes'] = Variable<int>(totalBytes);
    if (!nullToAbsent || finishedAt != null) {
      map['finished_at'] = Variable<int>(finishedAt);
    }
    return map;
  }

  BackupRunsCompanion toCompanion(bool nullToAbsent) {
    return BackupRunsCompanion(
      id: Value(id),
      folderUri: Value(folderUri),
      startedAt: Value(startedAt),
      status: Value(status),
      files: Value(files),
      totalBytes: Value(totalBytes),
      finishedAt: finishedAt == null && nullToAbsent ? const Value.absent() : Value(finishedAt),
    );
  }

  factory BackupRun.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BackupRun(
      id: serializer.fromJson<String>(json['id']),
      folderUri: serializer.fromJson<String>(json['folderUri']),
      startedAt: serializer.fromJson<int>(json['startedAt']),
      status: serializer.fromJson<String>(json['status']),
      files: serializer.fromJson<String>(json['files']),
      totalBytes: serializer.fromJson<int>(json['totalBytes']),
      finishedAt: serializer.fromJson<int?>(json['finishedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'folderUri': serializer.toJson<String>(folderUri),
      'startedAt': serializer.toJson<int>(startedAt),
      'status': serializer.toJson<String>(status),
      'files': serializer.toJson<String>(files),
      'totalBytes': serializer.toJson<int>(totalBytes),
      'finishedAt': serializer.toJson<int?>(finishedAt),
    };
  }

  BackupRun copyWith({
    String? id,
    String? folderUri,
    int? startedAt,
    String? status,
    String? files,
    int? totalBytes,
    Value<int?> finishedAt = const Value.absent(),
  }) => BackupRun(
    id: id ?? this.id,
    folderUri: folderUri ?? this.folderUri,
    startedAt: startedAt ?? this.startedAt,
    status: status ?? this.status,
    files: files ?? this.files,
    totalBytes: totalBytes ?? this.totalBytes,
    finishedAt: finishedAt.present ? finishedAt.value : this.finishedAt,
  );
  BackupRun copyWithCompanion(BackupRunsCompanion data) {
    return BackupRun(
      id: data.id.present ? data.id.value : this.id,
      folderUri: data.folderUri.present ? data.folderUri.value : this.folderUri,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      status: data.status.present ? data.status.value : this.status,
      files: data.files.present ? data.files.value : this.files,
      totalBytes: data.totalBytes.present ? data.totalBytes.value : this.totalBytes,
      finishedAt: data.finishedAt.present ? data.finishedAt.value : this.finishedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BackupRun(')
          ..write('id: $id, ')
          ..write('folderUri: $folderUri, ')
          ..write('startedAt: $startedAt, ')
          ..write('status: $status, ')
          ..write('files: $files, ')
          ..write('totalBytes: $totalBytes, ')
          ..write('finishedAt: $finishedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, folderUri, startedAt, status, files, totalBytes, finishedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BackupRun &&
          other.id == this.id &&
          other.folderUri == this.folderUri &&
          other.startedAt == this.startedAt &&
          other.status == this.status &&
          other.files == this.files &&
          other.totalBytes == this.totalBytes &&
          other.finishedAt == this.finishedAt);
}

class BackupRunsCompanion extends UpdateCompanion<BackupRun> {
  final Value<String> id;
  final Value<String> folderUri;
  final Value<int> startedAt;
  final Value<String> status;
  final Value<String> files;
  final Value<int> totalBytes;
  final Value<int?> finishedAt;
  final Value<int> rowid;
  const BackupRunsCompanion({
    this.id = const Value.absent(),
    this.folderUri = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.status = const Value.absent(),
    this.files = const Value.absent(),
    this.totalBytes = const Value.absent(),
    this.finishedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BackupRunsCompanion.insert({
    required String id,
    required String folderUri,
    required int startedAt,
    required String status,
    this.files = const Value.absent(),
    this.totalBytes = const Value.absent(),
    this.finishedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       folderUri = Value(folderUri),
       startedAt = Value(startedAt),
       status = Value(status);
  static Insertable<BackupRun> custom({
    Expression<String>? id,
    Expression<String>? folderUri,
    Expression<int>? startedAt,
    Expression<String>? status,
    Expression<String>? files,
    Expression<int>? totalBytes,
    Expression<int>? finishedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (folderUri != null) 'folder_uri': folderUri,
      if (startedAt != null) 'started_at': startedAt,
      if (status != null) 'status': status,
      if (files != null) 'files': files,
      if (totalBytes != null) 'total_bytes': totalBytes,
      if (finishedAt != null) 'finished_at': finishedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BackupRunsCompanion copyWith({
    Value<String>? id,
    Value<String>? folderUri,
    Value<int>? startedAt,
    Value<String>? status,
    Value<String>? files,
    Value<int>? totalBytes,
    Value<int?>? finishedAt,
    Value<int>? rowid,
  }) {
    return BackupRunsCompanion(
      id: id ?? this.id,
      folderUri: folderUri ?? this.folderUri,
      startedAt: startedAt ?? this.startedAt,
      status: status ?? this.status,
      files: files ?? this.files,
      totalBytes: totalBytes ?? this.totalBytes,
      finishedAt: finishedAt ?? this.finishedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (folderUri.present) {
      map['folder_uri'] = Variable<String>(folderUri.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<int>(startedAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (files.present) {
      map['files'] = Variable<String>(files.value);
    }
    if (totalBytes.present) {
      map['total_bytes'] = Variable<int>(totalBytes.value);
    }
    if (finishedAt.present) {
      map['finished_at'] = Variable<int>(finishedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BackupRunsCompanion(')
          ..write('id: $id, ')
          ..write('folderUri: $folderUri, ')
          ..write('startedAt: $startedAt, ')
          ..write('status: $status, ')
          ..write('files: $files, ')
          ..write('totalBytes: $totalBytes, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $JobCheckpointsTable jobCheckpoints = $JobCheckpointsTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $AccountsTable accounts = $AccountsTable(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $LedgerTransactionsTable ledgerTransactions = $LedgerTransactionsTable(this);
  late final $PostingsTable postings = $PostingsTable(this);
  late final $TransactionRevisionsTable transactionRevisions = $TransactionRevisionsTable(this);
  late final $BalanceCheckpointsTable balanceCheckpoints = $BalanceCheckpointsTable(this);
  late final $BackupConfigsTable backupConfigs = $BackupConfigsTable(this);
  late final $BackupRunsTable backupRuns = $BackupRunsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables => allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    jobCheckpoints,
    appSettings,
    accounts,
    categories,
    ledgerTransactions,
    postings,
    transactionRevisions,
    balanceCheckpoints,
    backupConfigs,
    backupRuns,
  ];
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
typedef $$AppSettingsTableCreateCompanionBuilder = AppSettingsCompanion Function({
  required String key,
  required String value,
  required int updatedAt,
  Value<int> rowid,
});
typedef $$AppSettingsTableUpdateCompanionBuilder = AppSettingsCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> updatedAt,
  Value<int> rowid,
});

class $$AppSettingsTableFilterComposer extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$AppSettingsTableOrderingComposer extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$AppSettingsTableAnnotationComposer extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key => $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value => $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<int> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSetting,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (AppSetting, BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>),
          AppSetting,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => AppSettingsCompanion(key: key, value: value, updatedAt: updatedAt, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            required String value,
            required int updatedAt,
            Value<int> rowid = const Value.absent(),
          }) => AppSettingsCompanion.insert(key: key, value: value, updatedAt: updatedAt, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AppSettingsTable, AppSetting>(table),
                  BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSetting,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (AppSetting, BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>),
      AppSetting,
      PrefetchHooks Function()
    >;
typedef $$AccountsTableCreateCompanionBuilder = AccountsCompanion Function({
  required String id,
  required String kind,
  required String name,
  Value<String?> bankName,
  Value<String?> bankCode,
  Value<String?> last4,
  Value<bool> isDefault,
  required int createdAt,
  Value<int?> removedAt,
  Value<int> rowid,
});
typedef $$AccountsTableUpdateCompanionBuilder = AccountsCompanion Function({
  Value<String> id,
  Value<String> kind,
  Value<String> name,
  Value<String?> bankName,
  Value<String?> bankCode,
  Value<String?> last4,
  Value<bool> isDefault,
  Value<int> createdAt,
  Value<int?> removedAt,
  Value<int> rowid,
});

final class $$AccountsTableReferences extends BaseReferences<_$AppDatabase, $AccountsTable, Account> {
  $$AccountsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$CategoriesTable, List<Category>> _categoriesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.categories, aliasName: 'accounts__id__categories__account_id');

  $$CategoriesTableProcessedTableManager get categoriesRefs {
    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.accountId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_categoriesRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$PostingsTable, List<Posting>> _postingsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.postings, aliasName: 'accounts__id__postings__account_id');

  $$PostingsTableProcessedTableManager get postingsRefs {
    final manager = $$PostingsTableTableManager(
      $_db,
      $_db.postings,
    ).filter((f) => f.accountId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_postingsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$BalanceCheckpointsTable, List<BalanceCheckpoint>> _balanceCheckpointsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(db.balanceCheckpoints, aliasName: 'accounts__id__balance_checkpoints__account_id');

  $$BalanceCheckpointsTableProcessedTableManager get balanceCheckpointsRefs {
    final manager = $$BalanceCheckpointsTableTableManager(
      $_db,
      $_db.balanceCheckpoints,
    ).filter((f) => f.accountId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_balanceCheckpointsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$AccountsTableFilterComposer extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get kind => $composableBuilder(column: $table.kind, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get bankName =>
      $composableBuilder(column: $table.bankName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get bankCode =>
      $composableBuilder(column: $table.bankCode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get last4 =>
      $composableBuilder(column: $table.last4, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get removedAt =>
      $composableBuilder(column: $table.removedAt, builder: (column) => ColumnFilters(column));

  Expression<bool> categoriesRefs(Expression<bool> Function($$CategoriesTableFilterComposer f) f) {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.accountId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> postingsRefs(Expression<bool> Function($$PostingsTableFilterComposer f) f) {
    final $$PostingsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.postings,
      getReferencedColumn: (t) => t.accountId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$PostingsTableFilterComposer(
            $db: $db,
            $table: $db.postings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> balanceCheckpointsRefs(Expression<bool> Function($$BalanceCheckpointsTableFilterComposer f) f) {
    final $$BalanceCheckpointsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.balanceCheckpoints,
      getReferencedColumn: (t) => t.accountId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$BalanceCheckpointsTableFilterComposer(
            $db: $db,
            $table: $db.balanceCheckpoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AccountsTableOrderingComposer extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get bankName =>
      $composableBuilder(column: $table.bankName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get bankCode =>
      $composableBuilder(column: $table.bankCode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get last4 =>
      $composableBuilder(column: $table.last4, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get removedAt =>
      $composableBuilder(column: $table.removedAt, builder: (column) => ColumnOrderings(column));
}

class $$AccountsTableAnnotationComposer extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind => $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get name => $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get bankName => $composableBuilder(column: $table.bankName, builder: (column) => column);

  GeneratedColumn<String> get bankCode => $composableBuilder(column: $table.bankCode, builder: (column) => column);

  GeneratedColumn<String> get last4 => $composableBuilder(column: $table.last4, builder: (column) => column);

  GeneratedColumn<bool> get isDefault => $composableBuilder(column: $table.isDefault, builder: (column) => column);

  GeneratedColumn<int> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get removedAt => $composableBuilder(column: $table.removedAt, builder: (column) => column);

  Expression<T> categoriesRefs<T extends Object>(Expression<T> Function($$CategoriesTableAnnotationComposer a) f) {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.accountId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> postingsRefs<T extends Object>(Expression<T> Function($$PostingsTableAnnotationComposer a) f) {
    final $$PostingsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.postings,
      getReferencedColumn: (t) => t.accountId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$PostingsTableAnnotationComposer(
            $db: $db,
            $table: $db.postings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> balanceCheckpointsRefs<T extends Object>(
    Expression<T> Function($$BalanceCheckpointsTableAnnotationComposer a) f,
  ) {
    final $$BalanceCheckpointsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.balanceCheckpoints,
      getReferencedColumn: (t) => t.accountId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$BalanceCheckpointsTableAnnotationComposer(
            $db: $db,
            $table: $db.balanceCheckpoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AccountsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AccountsTable,
          Account,
          $$AccountsTableFilterComposer,
          $$AccountsTableOrderingComposer,
          $$AccountsTableAnnotationComposer,
          $$AccountsTableCreateCompanionBuilder,
          $$AccountsTableUpdateCompanionBuilder,
          (Account, $$AccountsTableReferences),
          Account,
          PrefetchHooks Function({bool categoriesRefs, bool postingsRefs, bool balanceCheckpointsRefs})
        > {
  $$AccountsTableTableManager(_$AppDatabase db, $AccountsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$AccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$AccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$AccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> bankName = const Value.absent(),
                Value<String?> bankCode = const Value.absent(),
                Value<String?> last4 = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int?> removedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AccountsCompanion(
                id: id,
                kind: kind,
                name: name,
                bankName: bankName,
                bankCode: bankCode,
                last4: last4,
                isDefault: isDefault,
                createdAt: createdAt,
                removedAt: removedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String kind,
                required String name,
                Value<String?> bankName = const Value.absent(),
                Value<String?> bankCode = const Value.absent(),
                Value<String?> last4 = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                required int createdAt,
                Value<int?> removedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AccountsCompanion.insert(
                id: id,
                kind: kind,
                name: name,
                bankName: bankName,
                bankCode: bankCode,
                last4: last4,
                isDefault: isDefault,
                createdAt: createdAt,
                removedAt: removedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable<$AccountsTable, Account>(table), $$AccountsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({categoriesRefs = false, postingsRefs = false, balanceCheckpointsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (categoriesRefs) db.categories,
                if (postingsRefs) db.postings,
                if (balanceCheckpointsRefs) db.balanceCheckpoints,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (categoriesRefs)
                    await $_getPrefetchedDataByColumns<Account, $AccountsTable, Category, $CategoriesTable>(
                      currentTable: table,
                      referencedTable: $$AccountsTableReferences._categoriesRefsTable(db),
                      managerFromTypedResult: (p0) => $$AccountsTableReferences(db, table, p0).categoriesRefs,
                      currentColumn: 'id',
                      referencedColumn: 'account_id',
                      typedResults: items,
                    ),
                  if (postingsRefs)
                    await $_getPrefetchedDataByColumns<Account, $AccountsTable, Posting, $PostingsTable>(
                      currentTable: table,
                      referencedTable: $$AccountsTableReferences._postingsRefsTable(db),
                      managerFromTypedResult: (p0) => $$AccountsTableReferences(db, table, p0).postingsRefs,
                      currentColumn: 'id',
                      referencedColumn: 'account_id',
                      typedResults: items,
                    ),
                  if (balanceCheckpointsRefs)
                    await $_getPrefetchedDataByColumns<
                      Account,
                      $AccountsTable,
                      BalanceCheckpoint,
                      $BalanceCheckpointsTable
                    >(
                      currentTable: table,
                      referencedTable: $$AccountsTableReferences._balanceCheckpointsRefsTable(db),
                      managerFromTypedResult: (p0) => $$AccountsTableReferences(db, table, p0).balanceCheckpointsRefs,
                      currentColumn: 'id',
                      referencedColumn: 'account_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$AccountsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AccountsTable,
      Account,
      $$AccountsTableFilterComposer,
      $$AccountsTableOrderingComposer,
      $$AccountsTableAnnotationComposer,
      $$AccountsTableCreateCompanionBuilder,
      $$AccountsTableUpdateCompanionBuilder,
      (Account, $$AccountsTableReferences),
      Account,
      PrefetchHooks Function({bool categoriesRefs, bool postingsRefs, bool balanceCheckpointsRefs})
    >;
typedef $$CategoriesTableCreateCompanionBuilder = CategoriesCompanion Function({
  required String accountId,
  required int colour,
  required String icon,
  required int sortOrder,
  Value<int> rowid,
});
typedef $$CategoriesTableUpdateCompanionBuilder = CategoriesCompanion Function({
  Value<String> accountId,
  Value<int> colour,
  Value<String> icon,
  Value<int> sortOrder,
  Value<int> rowid,
});

final class $$CategoriesTableReferences extends BaseReferences<_$AppDatabase, $CategoriesTable, Category> {
  $$CategoriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AccountsTable _accountIdTable(_$AppDatabase db) =>
      db.accounts.createAlias('categories__account_id__accounts__id');

  $$AccountsTableProcessedTableManager get accountId {
    final $_column = $_itemColumn<String>('account_id')!;

    final manager = $$AccountsTableTableManager($_db, $_db.accounts).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$CategoriesTableFilterComposer extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get colour =>
      $composableBuilder(column: $table.colour, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get icon => $composableBuilder(column: $table.icon, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  $$AccountsTableFilterComposer get accountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$AccountsTableFilterComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CategoriesTableOrderingComposer extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get colour =>
      $composableBuilder(column: $table.colour, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  $$AccountsTableOrderingComposer get accountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$AccountsTableOrderingComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CategoriesTableAnnotationComposer extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get colour => $composableBuilder(column: $table.colour, builder: (column) => column);

  GeneratedColumn<String> get icon => $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<int> get sortOrder => $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  $$AccountsTableAnnotationComposer get accountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$AccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoriesTable,
          Category,
          $$CategoriesTableFilterComposer,
          $$CategoriesTableOrderingComposer,
          $$CategoriesTableAnnotationComposer,
          $$CategoriesTableCreateCompanionBuilder,
          $$CategoriesTableUpdateCompanionBuilder,
          (Category, $$CategoriesTableReferences),
          Category,
          PrefetchHooks Function({bool accountId})
        > {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> accountId = const Value.absent(),
                Value<int> colour = const Value.absent(),
                Value<String> icon = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion(
                accountId: accountId,
                colour: colour,
                icon: icon,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String accountId,
                required int colour,
                required String icon,
                required int sortOrder,
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion.insert(
                accountId: accountId,
                colour: colour,
                icon: icon,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable<$CategoriesTable, Category>(table), $$CategoriesTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({accountId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (accountId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.accountId,
                        referencedTable: $$CategoriesTableReferences._accountIdTable(db),
                        referencedColumn: $$CategoriesTableReferences._accountIdTable(db).id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoriesTable,
      Category,
      $$CategoriesTableFilterComposer,
      $$CategoriesTableOrderingComposer,
      $$CategoriesTableAnnotationComposer,
      $$CategoriesTableCreateCompanionBuilder,
      $$CategoriesTableUpdateCompanionBuilder,
      (Category, $$CategoriesTableReferences),
      Category,
      PrefetchHooks Function({bool accountId})
    >;
typedef $$LedgerTransactionsTableCreateCompanionBuilder = LedgerTransactionsCompanion Function({
  required String id,
  required String kind,
  Value<String?> paymentMethod,
  Value<String?> channel,
  required int occurredAt,
  required String localDate,
  Value<String?> merchant,
  Value<String?> note,
  Value<String?> refundOf,
  required int revision,
  required int createdAt,
  required int updatedAt,
  Value<int?> deletedAt,
  Value<int> rowid,
});
typedef $$LedgerTransactionsTableUpdateCompanionBuilder = LedgerTransactionsCompanion Function({
  Value<String> id,
  Value<String> kind,
  Value<String?> paymentMethod,
  Value<String?> channel,
  Value<int> occurredAt,
  Value<String> localDate,
  Value<String?> merchant,
  Value<String?> note,
  Value<String?> refundOf,
  Value<int> revision,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int?> deletedAt,
  Value<int> rowid,
});

final class $$LedgerTransactionsTableReferences
    extends BaseReferences<_$AppDatabase, $LedgerTransactionsTable, LedgerTransaction> {
  $$LedgerTransactionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $LedgerTransactionsTable _refundOfTable(_$AppDatabase db) =>
      db.ledgerTransactions.createAlias('ledger_transactions__refund_of__ledger_transactions__id');

  $$LedgerTransactionsTableProcessedTableManager? get refundOf {
    final $_column = $_itemColumn<String>('refund_of');
    if ($_column == null) return null;
    final manager = $$LedgerTransactionsTableTableManager(
      $_db,
      $_db.ledgerTransactions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_refundOfTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$PostingsTable, List<Posting>> _postingsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.postings, aliasName: 'ledger_transactions__id__postings__transaction_id');

  $$PostingsTableProcessedTableManager get postingsRefs {
    final manager = $$PostingsTableTableManager(
      $_db,
      $_db.postings,
    ).filter((f) => f.transactionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_postingsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$TransactionRevisionsTable, List<TransactionRevision>> _transactionRevisionsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.transactionRevisions,
    aliasName: 'ledger_transactions__id__transaction_revisions__transaction_id',
  );

  $$TransactionRevisionsTableProcessedTableManager get transactionRevisionsRefs {
    final manager = $$TransactionRevisionsTableTableManager(
      $_db,
      $_db.transactionRevisions,
    ).filter((f) => f.transactionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_transactionRevisionsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$LedgerTransactionsTableFilterComposer extends Composer<_$AppDatabase, $LedgerTransactionsTable> {
  $$LedgerTransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get kind => $composableBuilder(column: $table.kind, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get paymentMethod =>
      $composableBuilder(column: $table.paymentMethod, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get channel =>
      $composableBuilder(column: $table.channel, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get occurredAt =>
      $composableBuilder(column: $table.occurredAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get localDate =>
      $composableBuilder(column: $table.localDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get merchant =>
      $composableBuilder(column: $table.merchant, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  $$LedgerTransactionsTableFilterComposer get refundOf {
    final $$LedgerTransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.refundOf,
      referencedTable: $db.ledgerTransactions,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$LedgerTransactionsTableFilterComposer(
            $db: $db,
            $table: $db.ledgerTransactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> postingsRefs(Expression<bool> Function($$PostingsTableFilterComposer f) f) {
    final $$PostingsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.postings,
      getReferencedColumn: (t) => t.transactionId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$PostingsTableFilterComposer(
            $db: $db,
            $table: $db.postings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> transactionRevisionsRefs(Expression<bool> Function($$TransactionRevisionsTableFilterComposer f) f) {
    final $$TransactionRevisionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactionRevisions,
      getReferencedColumn: (t) => t.transactionId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$TransactionRevisionsTableFilterComposer(
            $db: $db,
            $table: $db.transactionRevisions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LedgerTransactionsTableOrderingComposer extends Composer<_$AppDatabase, $LedgerTransactionsTable> {
  $$LedgerTransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get paymentMethod =>
      $composableBuilder(column: $table.paymentMethod, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get channel =>
      $composableBuilder(column: $table.channel, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get occurredAt =>
      $composableBuilder(column: $table.occurredAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get localDate =>
      $composableBuilder(column: $table.localDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get merchant =>
      $composableBuilder(column: $table.merchant, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  $$LedgerTransactionsTableOrderingComposer get refundOf {
    final $$LedgerTransactionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.refundOf,
      referencedTable: $db.ledgerTransactions,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$LedgerTransactionsTableOrderingComposer(
            $db: $db,
            $table: $db.ledgerTransactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LedgerTransactionsTableAnnotationComposer extends Composer<_$AppDatabase, $LedgerTransactionsTable> {
  $$LedgerTransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind => $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get paymentMethod =>
      $composableBuilder(column: $table.paymentMethod, builder: (column) => column);

  GeneratedColumn<String> get channel => $composableBuilder(column: $table.channel, builder: (column) => column);

  GeneratedColumn<int> get occurredAt => $composableBuilder(column: $table.occurredAt, builder: (column) => column);

  GeneratedColumn<String> get localDate => $composableBuilder(column: $table.localDate, builder: (column) => column);

  GeneratedColumn<String> get merchant => $composableBuilder(column: $table.merchant, builder: (column) => column);

  GeneratedColumn<String> get note => $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get revision => $composableBuilder(column: $table.revision, builder: (column) => column);

  GeneratedColumn<int> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt => $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$LedgerTransactionsTableAnnotationComposer get refundOf {
    final $$LedgerTransactionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.refundOf,
      referencedTable: $db.ledgerTransactions,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$LedgerTransactionsTableAnnotationComposer(
            $db: $db,
            $table: $db.ledgerTransactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> postingsRefs<T extends Object>(Expression<T> Function($$PostingsTableAnnotationComposer a) f) {
    final $$PostingsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.postings,
      getReferencedColumn: (t) => t.transactionId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$PostingsTableAnnotationComposer(
            $db: $db,
            $table: $db.postings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> transactionRevisionsRefs<T extends Object>(
    Expression<T> Function($$TransactionRevisionsTableAnnotationComposer a) f,
  ) {
    final $$TransactionRevisionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactionRevisions,
      getReferencedColumn: (t) => t.transactionId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$TransactionRevisionsTableAnnotationComposer(
            $db: $db,
            $table: $db.transactionRevisions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LedgerTransactionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LedgerTransactionsTable,
          LedgerTransaction,
          $$LedgerTransactionsTableFilterComposer,
          $$LedgerTransactionsTableOrderingComposer,
          $$LedgerTransactionsTableAnnotationComposer,
          $$LedgerTransactionsTableCreateCompanionBuilder,
          $$LedgerTransactionsTableUpdateCompanionBuilder,
          (LedgerTransaction, $$LedgerTransactionsTableReferences),
          LedgerTransaction,
          PrefetchHooks Function({bool refundOf, bool postingsRefs, bool transactionRevisionsRefs})
        > {
  $$LedgerTransactionsTableTableManager(_$AppDatabase db, $LedgerTransactionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$LedgerTransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$LedgerTransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$LedgerTransactionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String?> paymentMethod = const Value.absent(),
                Value<String?> channel = const Value.absent(),
                Value<int> occurredAt = const Value.absent(),
                Value<String> localDate = const Value.absent(),
                Value<String?> merchant = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> refundOf = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LedgerTransactionsCompanion(
                id: id,
                kind: kind,
                paymentMethod: paymentMethod,
                channel: channel,
                occurredAt: occurredAt,
                localDate: localDate,
                merchant: merchant,
                note: note,
                refundOf: refundOf,
                revision: revision,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String kind,
                Value<String?> paymentMethod = const Value.absent(),
                Value<String?> channel = const Value.absent(),
                required int occurredAt,
                required String localDate,
                Value<String?> merchant = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> refundOf = const Value.absent(),
                required int revision,
                required int createdAt,
                required int updatedAt,
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LedgerTransactionsCompanion.insert(
                id: id,
                kind: kind,
                paymentMethod: paymentMethod,
                channel: channel,
                occurredAt: occurredAt,
                localDate: localDate,
                merchant: merchant,
                note: note,
                refundOf: refundOf,
                revision: revision,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LedgerTransactionsTable, LedgerTransaction>(table),
                  $$LedgerTransactionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({refundOf = false, postingsRefs = false, transactionRevisionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (postingsRefs) db.postings,
                if (transactionRevisionsRefs) db.transactionRevisions,
              ],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (refundOf) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.refundOf,
                        referencedTable: $$LedgerTransactionsTableReferences._refundOfTable(db),
                        referencedColumn: $$LedgerTransactionsTableReferences._refundOfTable(db).id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (postingsRefs)
                    await $_getPrefetchedDataByColumns<
                      LedgerTransaction,
                      $LedgerTransactionsTable,
                      Posting,
                      $PostingsTable
                    >(
                      currentTable: table,
                      referencedTable: $$LedgerTransactionsTableReferences._postingsRefsTable(db),
                      managerFromTypedResult: (p0) => $$LedgerTransactionsTableReferences(db, table, p0).postingsRefs,
                      currentColumn: 'id',
                      referencedColumn: 'transaction_id',
                      typedResults: items,
                    ),
                  if (transactionRevisionsRefs)
                    await $_getPrefetchedDataByColumns<
                      LedgerTransaction,
                      $LedgerTransactionsTable,
                      TransactionRevision,
                      $TransactionRevisionsTable
                    >(
                      currentTable: table,
                      referencedTable: $$LedgerTransactionsTableReferences._transactionRevisionsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$LedgerTransactionsTableReferences(db, table, p0).transactionRevisionsRefs,
                      currentColumn: 'id',
                      referencedColumn: 'transaction_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$LedgerTransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LedgerTransactionsTable,
      LedgerTransaction,
      $$LedgerTransactionsTableFilterComposer,
      $$LedgerTransactionsTableOrderingComposer,
      $$LedgerTransactionsTableAnnotationComposer,
      $$LedgerTransactionsTableCreateCompanionBuilder,
      $$LedgerTransactionsTableUpdateCompanionBuilder,
      (LedgerTransaction, $$LedgerTransactionsTableReferences),
      LedgerTransaction,
      PrefetchHooks Function({bool refundOf, bool postingsRefs, bool transactionRevisionsRefs})
    >;
typedef $$PostingsTableCreateCompanionBuilder = PostingsCompanion Function({
  required String id,
  required String transactionId,
  required String accountId,
  required int amountPaise,
  Value<int> rowid,
});
typedef $$PostingsTableUpdateCompanionBuilder = PostingsCompanion Function({
  Value<String> id,
  Value<String> transactionId,
  Value<String> accountId,
  Value<int> amountPaise,
  Value<int> rowid,
});

final class $$PostingsTableReferences extends BaseReferences<_$AppDatabase, $PostingsTable, Posting> {
  $$PostingsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $LedgerTransactionsTable _transactionIdTable(_$AppDatabase db) =>
      db.ledgerTransactions.createAlias('postings__transaction_id__ledger_transactions__id');

  $$LedgerTransactionsTableProcessedTableManager get transactionId {
    final $_column = $_itemColumn<String>('transaction_id')!;

    final manager = $$LedgerTransactionsTableTableManager(
      $_db,
      $_db.ledgerTransactions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_transactionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }

  static $AccountsTable _accountIdTable(_$AppDatabase db) =>
      db.accounts.createAlias('postings__account_id__accounts__id');

  $$AccountsTableProcessedTableManager get accountId {
    final $_column = $_itemColumn<String>('account_id')!;

    final manager = $$AccountsTableTableManager($_db, $_db.accounts).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$PostingsTableFilterComposer extends Composer<_$AppDatabase, $PostingsTable> {
  $$PostingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get amountPaise =>
      $composableBuilder(column: $table.amountPaise, builder: (column) => ColumnFilters(column));

  $$LedgerTransactionsTableFilterComposer get transactionId {
    final $$LedgerTransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.transactionId,
      referencedTable: $db.ledgerTransactions,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$LedgerTransactionsTableFilterComposer(
            $db: $db,
            $table: $db.ledgerTransactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableFilterComposer get accountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$AccountsTableFilterComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PostingsTableOrderingComposer extends Composer<_$AppDatabase, $PostingsTable> {
  $$PostingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get amountPaise =>
      $composableBuilder(column: $table.amountPaise, builder: (column) => ColumnOrderings(column));

  $$LedgerTransactionsTableOrderingComposer get transactionId {
    final $$LedgerTransactionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.transactionId,
      referencedTable: $db.ledgerTransactions,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$LedgerTransactionsTableOrderingComposer(
            $db: $db,
            $table: $db.ledgerTransactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableOrderingComposer get accountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$AccountsTableOrderingComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PostingsTableAnnotationComposer extends Composer<_$AppDatabase, $PostingsTable> {
  $$PostingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get amountPaise => $composableBuilder(column: $table.amountPaise, builder: (column) => column);

  $$LedgerTransactionsTableAnnotationComposer get transactionId {
    final $$LedgerTransactionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.transactionId,
      referencedTable: $db.ledgerTransactions,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$LedgerTransactionsTableAnnotationComposer(
            $db: $db,
            $table: $db.ledgerTransactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableAnnotationComposer get accountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$AccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PostingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PostingsTable,
          Posting,
          $$PostingsTableFilterComposer,
          $$PostingsTableOrderingComposer,
          $$PostingsTableAnnotationComposer,
          $$PostingsTableCreateCompanionBuilder,
          $$PostingsTableUpdateCompanionBuilder,
          (Posting, $$PostingsTableReferences),
          Posting,
          PrefetchHooks Function({bool transactionId, bool accountId})
        > {
  $$PostingsTableTableManager(_$AppDatabase db, $PostingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$PostingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$PostingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$PostingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> transactionId = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<int> amountPaise = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PostingsCompanion(
                id: id,
                transactionId: transactionId,
                accountId: accountId,
                amountPaise: amountPaise,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String transactionId,
                required String accountId,
                required int amountPaise,
                Value<int> rowid = const Value.absent(),
              }) => PostingsCompanion.insert(
                id: id,
                transactionId: transactionId,
                accountId: accountId,
                amountPaise: amountPaise,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable<$PostingsTable, Posting>(table), $$PostingsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({transactionId = false, accountId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (transactionId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.transactionId,
                        referencedTable: $$PostingsTableReferences._transactionIdTable(db),
                        referencedColumn: $$PostingsTableReferences._transactionIdTable(db).id,
                      ) as T;
                    }
                    if (accountId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.accountId,
                        referencedTable: $$PostingsTableReferences._accountIdTable(db),
                        referencedColumn: $$PostingsTableReferences._accountIdTable(db).id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PostingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PostingsTable,
      Posting,
      $$PostingsTableFilterComposer,
      $$PostingsTableOrderingComposer,
      $$PostingsTableAnnotationComposer,
      $$PostingsTableCreateCompanionBuilder,
      $$PostingsTableUpdateCompanionBuilder,
      (Posting, $$PostingsTableReferences),
      Posting,
      PrefetchHooks Function({bool transactionId, bool accountId})
    >;
typedef $$TransactionRevisionsTableCreateCompanionBuilder = TransactionRevisionsCompanion Function({
  Value<int> id,
  required String transactionId,
  required int revision,
  required String action,
  required String snapshotJson,
  Value<String?> reason,
  Value<String?> operationId,
  required int changedAt,
});
typedef $$TransactionRevisionsTableUpdateCompanionBuilder = TransactionRevisionsCompanion Function({
  Value<int> id,
  Value<String> transactionId,
  Value<int> revision,
  Value<String> action,
  Value<String> snapshotJson,
  Value<String?> reason,
  Value<String?> operationId,
  Value<int> changedAt,
});

final class $$TransactionRevisionsTableReferences
    extends BaseReferences<_$AppDatabase, $TransactionRevisionsTable, TransactionRevision> {
  $$TransactionRevisionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $LedgerTransactionsTable _transactionIdTable(_$AppDatabase db) =>
      db.ledgerTransactions.createAlias('transaction_revisions__transaction_id__ledger_transactions__id');

  $$LedgerTransactionsTableProcessedTableManager get transactionId {
    final $_column = $_itemColumn<String>('transaction_id')!;

    final manager = $$LedgerTransactionsTableTableManager(
      $_db,
      $_db.ledgerTransactions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_transactionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$TransactionRevisionsTableFilterComposer extends Composer<_$AppDatabase, $TransactionRevisionsTable> {
  $$TransactionRevisionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get action =>
      $composableBuilder(column: $table.action, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get snapshotJson =>
      $composableBuilder(column: $table.snapshotJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get operationId =>
      $composableBuilder(column: $table.operationId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get changedAt =>
      $composableBuilder(column: $table.changedAt, builder: (column) => ColumnFilters(column));

  $$LedgerTransactionsTableFilterComposer get transactionId {
    final $$LedgerTransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.transactionId,
      referencedTable: $db.ledgerTransactions,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$LedgerTransactionsTableFilterComposer(
            $db: $db,
            $table: $db.ledgerTransactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionRevisionsTableOrderingComposer extends Composer<_$AppDatabase, $TransactionRevisionsTable> {
  $$TransactionRevisionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get action =>
      $composableBuilder(column: $table.action, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get snapshotJson =>
      $composableBuilder(column: $table.snapshotJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get operationId =>
      $composableBuilder(column: $table.operationId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get changedAt =>
      $composableBuilder(column: $table.changedAt, builder: (column) => ColumnOrderings(column));

  $$LedgerTransactionsTableOrderingComposer get transactionId {
    final $$LedgerTransactionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.transactionId,
      referencedTable: $db.ledgerTransactions,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$LedgerTransactionsTableOrderingComposer(
            $db: $db,
            $table: $db.ledgerTransactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionRevisionsTableAnnotationComposer extends Composer<_$AppDatabase, $TransactionRevisionsTable> {
  $$TransactionRevisionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get revision => $composableBuilder(column: $table.revision, builder: (column) => column);

  GeneratedColumn<String> get action => $composableBuilder(column: $table.action, builder: (column) => column);

  GeneratedColumn<String> get snapshotJson =>
      $composableBuilder(column: $table.snapshotJson, builder: (column) => column);

  GeneratedColumn<String> get reason => $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<String> get operationId =>
      $composableBuilder(column: $table.operationId, builder: (column) => column);

  GeneratedColumn<int> get changedAt => $composableBuilder(column: $table.changedAt, builder: (column) => column);

  $$LedgerTransactionsTableAnnotationComposer get transactionId {
    final $$LedgerTransactionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.transactionId,
      referencedTable: $db.ledgerTransactions,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$LedgerTransactionsTableAnnotationComposer(
            $db: $db,
            $table: $db.ledgerTransactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionRevisionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransactionRevisionsTable,
          TransactionRevision,
          $$TransactionRevisionsTableFilterComposer,
          $$TransactionRevisionsTableOrderingComposer,
          $$TransactionRevisionsTableAnnotationComposer,
          $$TransactionRevisionsTableCreateCompanionBuilder,
          $$TransactionRevisionsTableUpdateCompanionBuilder,
          (TransactionRevision, $$TransactionRevisionsTableReferences),
          TransactionRevision,
          PrefetchHooks Function({bool transactionId})
        > {
  $$TransactionRevisionsTableTableManager(_$AppDatabase db, $TransactionRevisionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$TransactionRevisionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$TransactionRevisionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$TransactionRevisionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> transactionId = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<String> action = const Value.absent(),
                Value<String> snapshotJson = const Value.absent(),
                Value<String?> reason = const Value.absent(),
                Value<String?> operationId = const Value.absent(),
                Value<int> changedAt = const Value.absent(),
              }) => TransactionRevisionsCompanion(
                id: id,
                transactionId: transactionId,
                revision: revision,
                action: action,
                snapshotJson: snapshotJson,
                reason: reason,
                operationId: operationId,
                changedAt: changedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String transactionId,
                required int revision,
                required String action,
                required String snapshotJson,
                Value<String?> reason = const Value.absent(),
                Value<String?> operationId = const Value.absent(),
                required int changedAt,
              }) => TransactionRevisionsCompanion.insert(
                id: id,
                transactionId: transactionId,
                revision: revision,
                action: action,
                snapshotJson: snapshotJson,
                reason: reason,
                operationId: operationId,
                changedAt: changedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TransactionRevisionsTable, TransactionRevision>(table),
                  $$TransactionRevisionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({transactionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (transactionId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.transactionId,
                        referencedTable: $$TransactionRevisionsTableReferences._transactionIdTable(db),
                        referencedColumn: $$TransactionRevisionsTableReferences._transactionIdTable(db).id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TransactionRevisionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransactionRevisionsTable,
      TransactionRevision,
      $$TransactionRevisionsTableFilterComposer,
      $$TransactionRevisionsTableOrderingComposer,
      $$TransactionRevisionsTableAnnotationComposer,
      $$TransactionRevisionsTableCreateCompanionBuilder,
      $$TransactionRevisionsTableUpdateCompanionBuilder,
      (TransactionRevision, $$TransactionRevisionsTableReferences),
      TransactionRevision,
      PrefetchHooks Function({bool transactionId})
    >;
typedef $$BalanceCheckpointsTableCreateCompanionBuilder = BalanceCheckpointsCompanion Function({
  required String id,
  required String accountId,
  required int asOf,
  required int actualPaise,
  required String source,
  Value<String?> note,
  Value<bool> needsRecheck,
  required int createdAt,
  Value<int?> deletedAt,
  Value<int> rowid,
});
typedef $$BalanceCheckpointsTableUpdateCompanionBuilder = BalanceCheckpointsCompanion Function({
  Value<String> id,
  Value<String> accountId,
  Value<int> asOf,
  Value<int> actualPaise,
  Value<String> source,
  Value<String?> note,
  Value<bool> needsRecheck,
  Value<int> createdAt,
  Value<int?> deletedAt,
  Value<int> rowid,
});

final class $$BalanceCheckpointsTableReferences
    extends BaseReferences<_$AppDatabase, $BalanceCheckpointsTable, BalanceCheckpoint> {
  $$BalanceCheckpointsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AccountsTable _accountIdTable(_$AppDatabase db) =>
      db.accounts.createAlias('balance_checkpoints__account_id__accounts__id');

  $$AccountsTableProcessedTableManager get accountId {
    final $_column = $_itemColumn<String>('account_id')!;

    final manager = $$AccountsTableTableManager($_db, $_db.accounts).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$BalanceCheckpointsTableFilterComposer extends Composer<_$AppDatabase, $BalanceCheckpointsTable> {
  $$BalanceCheckpointsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get asOf => $composableBuilder(column: $table.asOf, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get actualPaise =>
      $composableBuilder(column: $table.actualPaise, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get needsRecheck =>
      $composableBuilder(column: $table.needsRecheck, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  $$AccountsTableFilterComposer get accountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$AccountsTableFilterComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BalanceCheckpointsTableOrderingComposer extends Composer<_$AppDatabase, $BalanceCheckpointsTable> {
  $$BalanceCheckpointsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get asOf =>
      $composableBuilder(column: $table.asOf, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get actualPaise =>
      $composableBuilder(column: $table.actualPaise, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get needsRecheck =>
      $composableBuilder(column: $table.needsRecheck, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  $$AccountsTableOrderingComposer get accountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$AccountsTableOrderingComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BalanceCheckpointsTableAnnotationComposer extends Composer<_$AppDatabase, $BalanceCheckpointsTable> {
  $$BalanceCheckpointsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get asOf => $composableBuilder(column: $table.asOf, builder: (column) => column);

  GeneratedColumn<int> get actualPaise => $composableBuilder(column: $table.actualPaise, builder: (column) => column);

  GeneratedColumn<String> get source => $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get note => $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<bool> get needsRecheck =>
      $composableBuilder(column: $table.needsRecheck, builder: (column) => column);

  GeneratedColumn<int> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt => $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$AccountsTableAnnotationComposer get accountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$AccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BalanceCheckpointsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BalanceCheckpointsTable,
          BalanceCheckpoint,
          $$BalanceCheckpointsTableFilterComposer,
          $$BalanceCheckpointsTableOrderingComposer,
          $$BalanceCheckpointsTableAnnotationComposer,
          $$BalanceCheckpointsTableCreateCompanionBuilder,
          $$BalanceCheckpointsTableUpdateCompanionBuilder,
          (BalanceCheckpoint, $$BalanceCheckpointsTableReferences),
          BalanceCheckpoint,
          PrefetchHooks Function({bool accountId})
        > {
  $$BalanceCheckpointsTableTableManager(_$AppDatabase db, $BalanceCheckpointsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$BalanceCheckpointsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$BalanceCheckpointsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$BalanceCheckpointsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<int> asOf = const Value.absent(),
                Value<int> actualPaise = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<bool> needsRecheck = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BalanceCheckpointsCompanion(
                id: id,
                accountId: accountId,
                asOf: asOf,
                actualPaise: actualPaise,
                source: source,
                note: note,
                needsRecheck: needsRecheck,
                createdAt: createdAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String accountId,
                required int asOf,
                required int actualPaise,
                required String source,
                Value<String?> note = const Value.absent(),
                Value<bool> needsRecheck = const Value.absent(),
                required int createdAt,
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BalanceCheckpointsCompanion.insert(
                id: id,
                accountId: accountId,
                asOf: asOf,
                actualPaise: actualPaise,
                source: source,
                note: note,
                needsRecheck: needsRecheck,
                createdAt: createdAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BalanceCheckpointsTable, BalanceCheckpoint>(table),
                  $$BalanceCheckpointsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({accountId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (accountId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.accountId,
                        referencedTable: $$BalanceCheckpointsTableReferences._accountIdTable(db),
                        referencedColumn: $$BalanceCheckpointsTableReferences._accountIdTable(db).id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$BalanceCheckpointsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BalanceCheckpointsTable,
      BalanceCheckpoint,
      $$BalanceCheckpointsTableFilterComposer,
      $$BalanceCheckpointsTableOrderingComposer,
      $$BalanceCheckpointsTableAnnotationComposer,
      $$BalanceCheckpointsTableCreateCompanionBuilder,
      $$BalanceCheckpointsTableUpdateCompanionBuilder,
      (BalanceCheckpoint, $$BalanceCheckpointsTableReferences),
      BalanceCheckpoint,
      PrefetchHooks Function({bool accountId})
    >;
typedef $$BackupConfigsTableCreateCompanionBuilder = BackupConfigsCompanion Function({
  Value<int> id,
  required String folderUri,
  required String folderName,
  required int setUpAt,
});
typedef $$BackupConfigsTableUpdateCompanionBuilder = BackupConfigsCompanion Function({
  Value<int> id,
  Value<String> folderUri,
  Value<String> folderName,
  Value<int> setUpAt,
});

class $$BackupConfigsTableFilterComposer extends Composer<_$AppDatabase, $BackupConfigsTable> {
  $$BackupConfigsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get folderUri =>
      $composableBuilder(column: $table.folderUri, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get folderName =>
      $composableBuilder(column: $table.folderName, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get setUpAt =>
      $composableBuilder(column: $table.setUpAt, builder: (column) => ColumnFilters(column));
}

class $$BackupConfigsTableOrderingComposer extends Composer<_$AppDatabase, $BackupConfigsTable> {
  $$BackupConfigsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get folderUri =>
      $composableBuilder(column: $table.folderUri, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get folderName =>
      $composableBuilder(column: $table.folderName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get setUpAt =>
      $composableBuilder(column: $table.setUpAt, builder: (column) => ColumnOrderings(column));
}

class $$BackupConfigsTableAnnotationComposer extends Composer<_$AppDatabase, $BackupConfigsTable> {
  $$BackupConfigsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get folderUri => $composableBuilder(column: $table.folderUri, builder: (column) => column);

  GeneratedColumn<String> get folderName => $composableBuilder(column: $table.folderName, builder: (column) => column);

  GeneratedColumn<int> get setUpAt => $composableBuilder(column: $table.setUpAt, builder: (column) => column);
}

class $$BackupConfigsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BackupConfigsTable,
          BackupConfig,
          $$BackupConfigsTableFilterComposer,
          $$BackupConfigsTableOrderingComposer,
          $$BackupConfigsTableAnnotationComposer,
          $$BackupConfigsTableCreateCompanionBuilder,
          $$BackupConfigsTableUpdateCompanionBuilder,
          (BackupConfig, BaseReferences<_$AppDatabase, $BackupConfigsTable, BackupConfig>),
          BackupConfig,
          PrefetchHooks Function()
        > {
  $$BackupConfigsTableTableManager(_$AppDatabase db, $BackupConfigsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$BackupConfigsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$BackupConfigsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$BackupConfigsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> folderUri = const Value.absent(),
            Value<String> folderName = const Value.absent(),
            Value<int> setUpAt = const Value.absent(),
          }) => BackupConfigsCompanion(id: id, folderUri: folderUri, folderName: folderName, setUpAt: setUpAt),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String folderUri,
            required String folderName,
            required int setUpAt,
          }) => BackupConfigsCompanion.insert(id: id, folderUri: folderUri, folderName: folderName, setUpAt: setUpAt),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BackupConfigsTable, BackupConfig>(table),
                  BaseReferences<_$AppDatabase, $BackupConfigsTable, BackupConfig>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BackupConfigsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BackupConfigsTable,
      BackupConfig,
      $$BackupConfigsTableFilterComposer,
      $$BackupConfigsTableOrderingComposer,
      $$BackupConfigsTableAnnotationComposer,
      $$BackupConfigsTableCreateCompanionBuilder,
      $$BackupConfigsTableUpdateCompanionBuilder,
      (BackupConfig, BaseReferences<_$AppDatabase, $BackupConfigsTable, BackupConfig>),
      BackupConfig,
      PrefetchHooks Function()
    >;
typedef $$BackupRunsTableCreateCompanionBuilder = BackupRunsCompanion Function({
  required String id,
  required String folderUri,
  required int startedAt,
  required String status,
  Value<String> files,
  Value<int> totalBytes,
  Value<int?> finishedAt,
  Value<int> rowid,
});
typedef $$BackupRunsTableUpdateCompanionBuilder = BackupRunsCompanion Function({
  Value<String> id,
  Value<String> folderUri,
  Value<int> startedAt,
  Value<String> status,
  Value<String> files,
  Value<int> totalBytes,
  Value<int?> finishedAt,
  Value<int> rowid,
});

class $$BackupRunsTableFilterComposer extends Composer<_$AppDatabase, $BackupRunsTable> {
  $$BackupRunsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get folderUri =>
      $composableBuilder(column: $table.folderUri, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get files =>
      $composableBuilder(column: $table.files, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalBytes =>
      $composableBuilder(column: $table.totalBytes, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get finishedAt =>
      $composableBuilder(column: $table.finishedAt, builder: (column) => ColumnFilters(column));
}

class $$BackupRunsTableOrderingComposer extends Composer<_$AppDatabase, $BackupRunsTable> {
  $$BackupRunsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get folderUri =>
      $composableBuilder(column: $table.folderUri, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get files =>
      $composableBuilder(column: $table.files, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalBytes =>
      $composableBuilder(column: $table.totalBytes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get finishedAt =>
      $composableBuilder(column: $table.finishedAt, builder: (column) => ColumnOrderings(column));
}

class $$BackupRunsTableAnnotationComposer extends Composer<_$AppDatabase, $BackupRunsTable> {
  $$BackupRunsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get folderUri => $composableBuilder(column: $table.folderUri, builder: (column) => column);

  GeneratedColumn<int> get startedAt => $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<String> get status => $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get files => $composableBuilder(column: $table.files, builder: (column) => column);

  GeneratedColumn<int> get totalBytes => $composableBuilder(column: $table.totalBytes, builder: (column) => column);

  GeneratedColumn<int> get finishedAt => $composableBuilder(column: $table.finishedAt, builder: (column) => column);
}

class $$BackupRunsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BackupRunsTable,
          BackupRun,
          $$BackupRunsTableFilterComposer,
          $$BackupRunsTableOrderingComposer,
          $$BackupRunsTableAnnotationComposer,
          $$BackupRunsTableCreateCompanionBuilder,
          $$BackupRunsTableUpdateCompanionBuilder,
          (BackupRun, BaseReferences<_$AppDatabase, $BackupRunsTable, BackupRun>),
          BackupRun,
          PrefetchHooks Function()
        > {
  $$BackupRunsTableTableManager(_$AppDatabase db, $BackupRunsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$BackupRunsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$BackupRunsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$BackupRunsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> folderUri = const Value.absent(),
                Value<int> startedAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> files = const Value.absent(),
                Value<int> totalBytes = const Value.absent(),
                Value<int?> finishedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BackupRunsCompanion(
                id: id,
                folderUri: folderUri,
                startedAt: startedAt,
                status: status,
                files: files,
                totalBytes: totalBytes,
                finishedAt: finishedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String folderUri,
                required int startedAt,
                required String status,
                Value<String> files = const Value.absent(),
                Value<int> totalBytes = const Value.absent(),
                Value<int?> finishedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BackupRunsCompanion.insert(
                id: id,
                folderUri: folderUri,
                startedAt: startedAt,
                status: status,
                files: files,
                totalBytes: totalBytes,
                finishedAt: finishedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BackupRunsTable, BackupRun>(table),
                  BaseReferences<_$AppDatabase, $BackupRunsTable, BackupRun>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BackupRunsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BackupRunsTable,
      BackupRun,
      $$BackupRunsTableFilterComposer,
      $$BackupRunsTableOrderingComposer,
      $$BackupRunsTableAnnotationComposer,
      $$BackupRunsTableCreateCompanionBuilder,
      $$BackupRunsTableUpdateCompanionBuilder,
      (BackupRun, BaseReferences<_$AppDatabase, $BackupRunsTable, BackupRun>),
      BackupRun,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$JobCheckpointsTableTableManager get jobCheckpoints => $$JobCheckpointsTableTableManager(_db, _db.jobCheckpoints);
  $$AppSettingsTableTableManager get appSettings => $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$AccountsTableTableManager get accounts => $$AccountsTableTableManager(_db, _db.accounts);
  $$CategoriesTableTableManager get categories => $$CategoriesTableTableManager(_db, _db.categories);
  $$LedgerTransactionsTableTableManager get ledgerTransactions =>
      $$LedgerTransactionsTableTableManager(_db, _db.ledgerTransactions);
  $$PostingsTableTableManager get postings => $$PostingsTableTableManager(_db, _db.postings);
  $$TransactionRevisionsTableTableManager get transactionRevisions =>
      $$TransactionRevisionsTableTableManager(_db, _db.transactionRevisions);
  $$BalanceCheckpointsTableTableManager get balanceCheckpoints =>
      $$BalanceCheckpointsTableTableManager(_db, _db.balanceCheckpoints);
  $$BackupConfigsTableTableManager get backupConfigs => $$BackupConfigsTableTableManager(_db, _db.backupConfigs);
  $$BackupRunsTableTableManager get backupRuns => $$BackupRunsTableTableManager(_db, _db.backupRuns);
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
