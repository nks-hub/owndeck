// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $StoredAccountsTable extends StoredAccounts
    with TableInfo<$StoredAccountsTable, StoredAccount> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StoredAccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverMeta = const VerificationMeta('server');
  @override
  late final GeneratedColumn<String> server = GeneratedColumn<String>(
    'server',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _loginNameMeta = const VerificationMeta(
    'loginName',
  );
  @override
  late final GeneratedColumn<String> loginName = GeneratedColumn<String>(
    'login_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _certificateFingerprintMeta =
      const VerificationMeta('certificateFingerprint');
  @override
  late final GeneratedColumn<String> certificateFingerprint =
      GeneratedColumn<String>(
        'certificate_fingerprint',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _syncNotBeforeMeta = const VerificationMeta(
    'syncNotBefore',
  );
  @override
  late final GeneratedColumn<DateTime> syncNotBefore =
      GeneratedColumn<DateTime>(
        'sync_not_before',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _credentialRefMeta = const VerificationMeta(
    'credentialRef',
  );
  @override
  late final GeneratedColumn<String> credentialRef = GeneratedColumn<String>(
    'credential_ref',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('active'),
  );
  static const VerificationMeta _generationMeta = const VerificationMeta(
    'generation',
  );
  @override
  late final GeneratedColumn<int> generation = GeneratedColumn<int>(
    'generation',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _capabilitiesMeta = const VerificationMeta(
    'capabilities',
  );
  @override
  late final GeneratedColumn<String> capabilities = GeneratedColumn<String>(
    'capabilities',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contentEpochMeta = const VerificationMeta(
    'contentEpoch',
  );
  @override
  late final GeneratedColumn<int> contentEpoch = GeneratedColumn<int>(
    'content_epoch',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _selectedMeta = const VerificationMeta(
    'selected',
  );
  @override
  late final GeneratedColumn<bool> selected = GeneratedColumn<bool>(
    'selected',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("selected" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    server,
    loginName,
    userId,
    certificateFingerprint,
    syncNotBefore,
    credentialRef,
    state,
    generation,
    capabilities,
    contentEpoch,
    selected,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stored_accounts';
  @override
  VerificationContext validateIntegrity(
    Insertable<StoredAccount> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('server')) {
      context.handle(
        _serverMeta,
        server.isAcceptableOrUnknown(data['server']!, _serverMeta),
      );
    } else if (isInserting) {
      context.missing(_serverMeta);
    }
    if (data.containsKey('login_name')) {
      context.handle(
        _loginNameMeta,
        loginName.isAcceptableOrUnknown(data['login_name']!, _loginNameMeta),
      );
    } else if (isInserting) {
      context.missing(_loginNameMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('certificate_fingerprint')) {
      context.handle(
        _certificateFingerprintMeta,
        certificateFingerprint.isAcceptableOrUnknown(
          data['certificate_fingerprint']!,
          _certificateFingerprintMeta,
        ),
      );
    }
    if (data.containsKey('sync_not_before')) {
      context.handle(
        _syncNotBeforeMeta,
        syncNotBefore.isAcceptableOrUnknown(
          data['sync_not_before']!,
          _syncNotBeforeMeta,
        ),
      );
    }
    if (data.containsKey('credential_ref')) {
      context.handle(
        _credentialRefMeta,
        credentialRef.isAcceptableOrUnknown(
          data['credential_ref']!,
          _credentialRefMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_credentialRefMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    }
    if (data.containsKey('generation')) {
      context.handle(
        _generationMeta,
        generation.isAcceptableOrUnknown(data['generation']!, _generationMeta),
      );
    }
    if (data.containsKey('capabilities')) {
      context.handle(
        _capabilitiesMeta,
        capabilities.isAcceptableOrUnknown(
          data['capabilities']!,
          _capabilitiesMeta,
        ),
      );
    }
    if (data.containsKey('content_epoch')) {
      context.handle(
        _contentEpochMeta,
        contentEpoch.isAcceptableOrUnknown(
          data['content_epoch']!,
          _contentEpochMeta,
        ),
      );
    }
    if (data.containsKey('selected')) {
      context.handle(
        _selectedMeta,
        selected.isAcceptableOrUnknown(data['selected']!, _selectedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {server, loginName},
  ];
  @override
  StoredAccount map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoredAccount(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      server: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server'],
      )!,
      loginName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}login_name'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      ),
      certificateFingerprint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}certificate_fingerprint'],
      ),
      syncNotBefore: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}sync_not_before'],
      ),
      credentialRef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}credential_ref'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      generation: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}generation'],
      )!,
      capabilities: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}capabilities'],
      ),
      contentEpoch: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}content_epoch'],
      )!,
      selected: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}selected'],
      )!,
    );
  }

  @override
  $StoredAccountsTable createAlias(String alias) {
    return $StoredAccountsTable(attachedDatabase, alias);
  }
}

class StoredAccount extends DataClass implements Insertable<StoredAccount> {
  final String id;
  final String server;
  final String loginName;
  final String? userId;
  final String? certificateFingerprint;
  final DateTime? syncNotBefore;
  final String credentialRef;
  final String state;
  final int generation;
  final String? capabilities;
  final int contentEpoch;
  final bool selected;
  const StoredAccount({
    required this.id,
    required this.server,
    required this.loginName,
    this.userId,
    this.certificateFingerprint,
    this.syncNotBefore,
    required this.credentialRef,
    required this.state,
    required this.generation,
    this.capabilities,
    required this.contentEpoch,
    required this.selected,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['server'] = Variable<String>(server);
    map['login_name'] = Variable<String>(loginName);
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    if (!nullToAbsent || certificateFingerprint != null) {
      map['certificate_fingerprint'] = Variable<String>(certificateFingerprint);
    }
    if (!nullToAbsent || syncNotBefore != null) {
      map['sync_not_before'] = Variable<DateTime>(syncNotBefore);
    }
    map['credential_ref'] = Variable<String>(credentialRef);
    map['state'] = Variable<String>(state);
    map['generation'] = Variable<int>(generation);
    if (!nullToAbsent || capabilities != null) {
      map['capabilities'] = Variable<String>(capabilities);
    }
    map['content_epoch'] = Variable<int>(contentEpoch);
    map['selected'] = Variable<bool>(selected);
    return map;
  }

  StoredAccountsCompanion toCompanion(bool nullToAbsent) {
    return StoredAccountsCompanion(
      id: Value(id),
      server: Value(server),
      loginName: Value(loginName),
      userId: userId == null && nullToAbsent
          ? const Value.absent()
          : Value(userId),
      certificateFingerprint: certificateFingerprint == null && nullToAbsent
          ? const Value.absent()
          : Value(certificateFingerprint),
      syncNotBefore: syncNotBefore == null && nullToAbsent
          ? const Value.absent()
          : Value(syncNotBefore),
      credentialRef: Value(credentialRef),
      state: Value(state),
      generation: Value(generation),
      capabilities: capabilities == null && nullToAbsent
          ? const Value.absent()
          : Value(capabilities),
      contentEpoch: Value(contentEpoch),
      selected: Value(selected),
    );
  }

  factory StoredAccount.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoredAccount(
      id: serializer.fromJson<String>(json['id']),
      server: serializer.fromJson<String>(json['server']),
      loginName: serializer.fromJson<String>(json['loginName']),
      userId: serializer.fromJson<String?>(json['userId']),
      certificateFingerprint: serializer.fromJson<String?>(
        json['certificateFingerprint'],
      ),
      syncNotBefore: serializer.fromJson<DateTime?>(json['syncNotBefore']),
      credentialRef: serializer.fromJson<String>(json['credentialRef']),
      state: serializer.fromJson<String>(json['state']),
      generation: serializer.fromJson<int>(json['generation']),
      capabilities: serializer.fromJson<String?>(json['capabilities']),
      contentEpoch: serializer.fromJson<int>(json['contentEpoch']),
      selected: serializer.fromJson<bool>(json['selected']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'server': serializer.toJson<String>(server),
      'loginName': serializer.toJson<String>(loginName),
      'userId': serializer.toJson<String?>(userId),
      'certificateFingerprint': serializer.toJson<String?>(
        certificateFingerprint,
      ),
      'syncNotBefore': serializer.toJson<DateTime?>(syncNotBefore),
      'credentialRef': serializer.toJson<String>(credentialRef),
      'state': serializer.toJson<String>(state),
      'generation': serializer.toJson<int>(generation),
      'capabilities': serializer.toJson<String?>(capabilities),
      'contentEpoch': serializer.toJson<int>(contentEpoch),
      'selected': serializer.toJson<bool>(selected),
    };
  }

  StoredAccount copyWith({
    String? id,
    String? server,
    String? loginName,
    Value<String?> userId = const Value.absent(),
    Value<String?> certificateFingerprint = const Value.absent(),
    Value<DateTime?> syncNotBefore = const Value.absent(),
    String? credentialRef,
    String? state,
    int? generation,
    Value<String?> capabilities = const Value.absent(),
    int? contentEpoch,
    bool? selected,
  }) => StoredAccount(
    id: id ?? this.id,
    server: server ?? this.server,
    loginName: loginName ?? this.loginName,
    userId: userId.present ? userId.value : this.userId,
    certificateFingerprint: certificateFingerprint.present
        ? certificateFingerprint.value
        : this.certificateFingerprint,
    syncNotBefore: syncNotBefore.present
        ? syncNotBefore.value
        : this.syncNotBefore,
    credentialRef: credentialRef ?? this.credentialRef,
    state: state ?? this.state,
    generation: generation ?? this.generation,
    capabilities: capabilities.present ? capabilities.value : this.capabilities,
    contentEpoch: contentEpoch ?? this.contentEpoch,
    selected: selected ?? this.selected,
  );
  StoredAccount copyWithCompanion(StoredAccountsCompanion data) {
    return StoredAccount(
      id: data.id.present ? data.id.value : this.id,
      server: data.server.present ? data.server.value : this.server,
      loginName: data.loginName.present ? data.loginName.value : this.loginName,
      userId: data.userId.present ? data.userId.value : this.userId,
      certificateFingerprint: data.certificateFingerprint.present
          ? data.certificateFingerprint.value
          : this.certificateFingerprint,
      syncNotBefore: data.syncNotBefore.present
          ? data.syncNotBefore.value
          : this.syncNotBefore,
      credentialRef: data.credentialRef.present
          ? data.credentialRef.value
          : this.credentialRef,
      state: data.state.present ? data.state.value : this.state,
      generation: data.generation.present
          ? data.generation.value
          : this.generation,
      capabilities: data.capabilities.present
          ? data.capabilities.value
          : this.capabilities,
      contentEpoch: data.contentEpoch.present
          ? data.contentEpoch.value
          : this.contentEpoch,
      selected: data.selected.present ? data.selected.value : this.selected,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoredAccount(')
          ..write('id: $id, ')
          ..write('server: $server, ')
          ..write('loginName: $loginName, ')
          ..write('userId: $userId, ')
          ..write('certificateFingerprint: $certificateFingerprint, ')
          ..write('syncNotBefore: $syncNotBefore, ')
          ..write('credentialRef: $credentialRef, ')
          ..write('state: $state, ')
          ..write('generation: $generation, ')
          ..write('capabilities: $capabilities, ')
          ..write('contentEpoch: $contentEpoch, ')
          ..write('selected: $selected')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    server,
    loginName,
    userId,
    certificateFingerprint,
    syncNotBefore,
    credentialRef,
    state,
    generation,
    capabilities,
    contentEpoch,
    selected,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoredAccount &&
          other.id == this.id &&
          other.server == this.server &&
          other.loginName == this.loginName &&
          other.userId == this.userId &&
          other.certificateFingerprint == this.certificateFingerprint &&
          other.syncNotBefore == this.syncNotBefore &&
          other.credentialRef == this.credentialRef &&
          other.state == this.state &&
          other.generation == this.generation &&
          other.capabilities == this.capabilities &&
          other.contentEpoch == this.contentEpoch &&
          other.selected == this.selected);
}

class StoredAccountsCompanion extends UpdateCompanion<StoredAccount> {
  final Value<String> id;
  final Value<String> server;
  final Value<String> loginName;
  final Value<String?> userId;
  final Value<String?> certificateFingerprint;
  final Value<DateTime?> syncNotBefore;
  final Value<String> credentialRef;
  final Value<String> state;
  final Value<int> generation;
  final Value<String?> capabilities;
  final Value<int> contentEpoch;
  final Value<bool> selected;
  final Value<int> rowid;
  const StoredAccountsCompanion({
    this.id = const Value.absent(),
    this.server = const Value.absent(),
    this.loginName = const Value.absent(),
    this.userId = const Value.absent(),
    this.certificateFingerprint = const Value.absent(),
    this.syncNotBefore = const Value.absent(),
    this.credentialRef = const Value.absent(),
    this.state = const Value.absent(),
    this.generation = const Value.absent(),
    this.capabilities = const Value.absent(),
    this.contentEpoch = const Value.absent(),
    this.selected = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StoredAccountsCompanion.insert({
    required String id,
    required String server,
    required String loginName,
    this.userId = const Value.absent(),
    this.certificateFingerprint = const Value.absent(),
    this.syncNotBefore = const Value.absent(),
    required String credentialRef,
    this.state = const Value.absent(),
    this.generation = const Value.absent(),
    this.capabilities = const Value.absent(),
    this.contentEpoch = const Value.absent(),
    this.selected = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       server = Value(server),
       loginName = Value(loginName),
       credentialRef = Value(credentialRef);
  static Insertable<StoredAccount> custom({
    Expression<String>? id,
    Expression<String>? server,
    Expression<String>? loginName,
    Expression<String>? userId,
    Expression<String>? certificateFingerprint,
    Expression<DateTime>? syncNotBefore,
    Expression<String>? credentialRef,
    Expression<String>? state,
    Expression<int>? generation,
    Expression<String>? capabilities,
    Expression<int>? contentEpoch,
    Expression<bool>? selected,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (server != null) 'server': server,
      if (loginName != null) 'login_name': loginName,
      if (userId != null) 'user_id': userId,
      if (certificateFingerprint != null)
        'certificate_fingerprint': certificateFingerprint,
      if (syncNotBefore != null) 'sync_not_before': syncNotBefore,
      if (credentialRef != null) 'credential_ref': credentialRef,
      if (state != null) 'state': state,
      if (generation != null) 'generation': generation,
      if (capabilities != null) 'capabilities': capabilities,
      if (contentEpoch != null) 'content_epoch': contentEpoch,
      if (selected != null) 'selected': selected,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StoredAccountsCompanion copyWith({
    Value<String>? id,
    Value<String>? server,
    Value<String>? loginName,
    Value<String?>? userId,
    Value<String?>? certificateFingerprint,
    Value<DateTime?>? syncNotBefore,
    Value<String>? credentialRef,
    Value<String>? state,
    Value<int>? generation,
    Value<String?>? capabilities,
    Value<int>? contentEpoch,
    Value<bool>? selected,
    Value<int>? rowid,
  }) {
    return StoredAccountsCompanion(
      id: id ?? this.id,
      server: server ?? this.server,
      loginName: loginName ?? this.loginName,
      userId: userId ?? this.userId,
      certificateFingerprint:
          certificateFingerprint ?? this.certificateFingerprint,
      syncNotBefore: syncNotBefore ?? this.syncNotBefore,
      credentialRef: credentialRef ?? this.credentialRef,
      state: state ?? this.state,
      generation: generation ?? this.generation,
      capabilities: capabilities ?? this.capabilities,
      contentEpoch: contentEpoch ?? this.contentEpoch,
      selected: selected ?? this.selected,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (server.present) {
      map['server'] = Variable<String>(server.value);
    }
    if (loginName.present) {
      map['login_name'] = Variable<String>(loginName.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (certificateFingerprint.present) {
      map['certificate_fingerprint'] = Variable<String>(
        certificateFingerprint.value,
      );
    }
    if (syncNotBefore.present) {
      map['sync_not_before'] = Variable<DateTime>(syncNotBefore.value);
    }
    if (credentialRef.present) {
      map['credential_ref'] = Variable<String>(credentialRef.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (generation.present) {
      map['generation'] = Variable<int>(generation.value);
    }
    if (capabilities.present) {
      map['capabilities'] = Variable<String>(capabilities.value);
    }
    if (contentEpoch.present) {
      map['content_epoch'] = Variable<int>(contentEpoch.value);
    }
    if (selected.present) {
      map['selected'] = Variable<bool>(selected.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StoredAccountsCompanion(')
          ..write('id: $id, ')
          ..write('server: $server, ')
          ..write('loginName: $loginName, ')
          ..write('userId: $userId, ')
          ..write('certificateFingerprint: $certificateFingerprint, ')
          ..write('syncNotBefore: $syncNotBefore, ')
          ..write('credentialRef: $credentialRef, ')
          ..write('state: $state, ')
          ..write('generation: $generation, ')
          ..write('capabilities: $capabilities, ')
          ..write('contentEpoch: $contentEpoch, ')
          ..write('selected: $selected, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StoredBoardsTable extends StoredBoards
    with TableInfo<$StoredBoardsTable, StoredBoard> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StoredBoardsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES stored_accounts (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<int> remoteId = GeneratedColumn<int>(
    'remote_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [accountId, remoteId, payload];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stored_boards';
  @override
  VerificationContext validateIntegrity(
    Insertable<StoredBoard> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_remoteIdMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {accountId, remoteId};
  @override
  StoredBoard map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoredBoard(
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}remote_id'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
    );
  }

  @override
  $StoredBoardsTable createAlias(String alias) {
    return $StoredBoardsTable(attachedDatabase, alias);
  }
}

class StoredBoard extends DataClass implements Insertable<StoredBoard> {
  final String accountId;
  final int remoteId;
  final String payload;
  const StoredBoard({
    required this.accountId,
    required this.remoteId,
    required this.payload,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['account_id'] = Variable<String>(accountId);
    map['remote_id'] = Variable<int>(remoteId);
    map['payload'] = Variable<String>(payload);
    return map;
  }

  StoredBoardsCompanion toCompanion(bool nullToAbsent) {
    return StoredBoardsCompanion(
      accountId: Value(accountId),
      remoteId: Value(remoteId),
      payload: Value(payload),
    );
  }

  factory StoredBoard.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoredBoard(
      accountId: serializer.fromJson<String>(json['accountId']),
      remoteId: serializer.fromJson<int>(json['remoteId']),
      payload: serializer.fromJson<String>(json['payload']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'accountId': serializer.toJson<String>(accountId),
      'remoteId': serializer.toJson<int>(remoteId),
      'payload': serializer.toJson<String>(payload),
    };
  }

  StoredBoard copyWith({String? accountId, int? remoteId, String? payload}) =>
      StoredBoard(
        accountId: accountId ?? this.accountId,
        remoteId: remoteId ?? this.remoteId,
        payload: payload ?? this.payload,
      );
  StoredBoard copyWithCompanion(StoredBoardsCompanion data) {
    return StoredBoard(
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      payload: data.payload.present ? data.payload.value : this.payload,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoredBoard(')
          ..write('accountId: $accountId, ')
          ..write('remoteId: $remoteId, ')
          ..write('payload: $payload')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(accountId, remoteId, payload);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoredBoard &&
          other.accountId == this.accountId &&
          other.remoteId == this.remoteId &&
          other.payload == this.payload);
}

class StoredBoardsCompanion extends UpdateCompanion<StoredBoard> {
  final Value<String> accountId;
  final Value<int> remoteId;
  final Value<String> payload;
  final Value<int> rowid;
  const StoredBoardsCompanion({
    this.accountId = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.payload = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StoredBoardsCompanion.insert({
    required String accountId,
    required int remoteId,
    required String payload,
    this.rowid = const Value.absent(),
  }) : accountId = Value(accountId),
       remoteId = Value(remoteId),
       payload = Value(payload);
  static Insertable<StoredBoard> custom({
    Expression<String>? accountId,
    Expression<int>? remoteId,
    Expression<String>? payload,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (accountId != null) 'account_id': accountId,
      if (remoteId != null) 'remote_id': remoteId,
      if (payload != null) 'payload': payload,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StoredBoardsCompanion copyWith({
    Value<String>? accountId,
    Value<int>? remoteId,
    Value<String>? payload,
    Value<int>? rowid,
  }) {
    return StoredBoardsCompanion(
      accountId: accountId ?? this.accountId,
      remoteId: remoteId ?? this.remoteId,
      payload: payload ?? this.payload,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<int>(remoteId.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StoredBoardsCompanion(')
          ..write('accountId: $accountId, ')
          ..write('remoteId: $remoteId, ')
          ..write('payload: $payload, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StoredStacksTable extends StoredStacks
    with TableInfo<$StoredStacksTable, StoredStack> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StoredStacksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES stored_accounts (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<int> remoteId = GeneratedColumn<int>(
    'remote_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _boardIdMeta = const VerificationMeta(
    'boardId',
  );
  @override
  late final GeneratedColumn<int> boardId = GeneratedColumn<int>(
    'board_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    accountId,
    remoteId,
    boardId,
    position,
    payload,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stored_stacks';
  @override
  VerificationContext validateIntegrity(
    Insertable<StoredStack> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_remoteIdMeta);
    }
    if (data.containsKey('board_id')) {
      context.handle(
        _boardIdMeta,
        boardId.isAcceptableOrUnknown(data['board_id']!, _boardIdMeta),
      );
    } else if (isInserting) {
      context.missing(_boardIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {accountId, remoteId};
  @override
  StoredStack map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoredStack(
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}remote_id'],
      )!,
      boardId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}board_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
    );
  }

  @override
  $StoredStacksTable createAlias(String alias) {
    return $StoredStacksTable(attachedDatabase, alias);
  }
}

class StoredStack extends DataClass implements Insertable<StoredStack> {
  final String accountId;
  final int remoteId;
  final int boardId;
  final int position;
  final String payload;
  const StoredStack({
    required this.accountId,
    required this.remoteId,
    required this.boardId,
    required this.position,
    required this.payload,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['account_id'] = Variable<String>(accountId);
    map['remote_id'] = Variable<int>(remoteId);
    map['board_id'] = Variable<int>(boardId);
    map['position'] = Variable<int>(position);
    map['payload'] = Variable<String>(payload);
    return map;
  }

  StoredStacksCompanion toCompanion(bool nullToAbsent) {
    return StoredStacksCompanion(
      accountId: Value(accountId),
      remoteId: Value(remoteId),
      boardId: Value(boardId),
      position: Value(position),
      payload: Value(payload),
    );
  }

  factory StoredStack.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoredStack(
      accountId: serializer.fromJson<String>(json['accountId']),
      remoteId: serializer.fromJson<int>(json['remoteId']),
      boardId: serializer.fromJson<int>(json['boardId']),
      position: serializer.fromJson<int>(json['position']),
      payload: serializer.fromJson<String>(json['payload']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'accountId': serializer.toJson<String>(accountId),
      'remoteId': serializer.toJson<int>(remoteId),
      'boardId': serializer.toJson<int>(boardId),
      'position': serializer.toJson<int>(position),
      'payload': serializer.toJson<String>(payload),
    };
  }

  StoredStack copyWith({
    String? accountId,
    int? remoteId,
    int? boardId,
    int? position,
    String? payload,
  }) => StoredStack(
    accountId: accountId ?? this.accountId,
    remoteId: remoteId ?? this.remoteId,
    boardId: boardId ?? this.boardId,
    position: position ?? this.position,
    payload: payload ?? this.payload,
  );
  StoredStack copyWithCompanion(StoredStacksCompanion data) {
    return StoredStack(
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      boardId: data.boardId.present ? data.boardId.value : this.boardId,
      position: data.position.present ? data.position.value : this.position,
      payload: data.payload.present ? data.payload.value : this.payload,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoredStack(')
          ..write('accountId: $accountId, ')
          ..write('remoteId: $remoteId, ')
          ..write('boardId: $boardId, ')
          ..write('position: $position, ')
          ..write('payload: $payload')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(accountId, remoteId, boardId, position, payload);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoredStack &&
          other.accountId == this.accountId &&
          other.remoteId == this.remoteId &&
          other.boardId == this.boardId &&
          other.position == this.position &&
          other.payload == this.payload);
}

class StoredStacksCompanion extends UpdateCompanion<StoredStack> {
  final Value<String> accountId;
  final Value<int> remoteId;
  final Value<int> boardId;
  final Value<int> position;
  final Value<String> payload;
  final Value<int> rowid;
  const StoredStacksCompanion({
    this.accountId = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.boardId = const Value.absent(),
    this.position = const Value.absent(),
    this.payload = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StoredStacksCompanion.insert({
    required String accountId,
    required int remoteId,
    required int boardId,
    required int position,
    required String payload,
    this.rowid = const Value.absent(),
  }) : accountId = Value(accountId),
       remoteId = Value(remoteId),
       boardId = Value(boardId),
       position = Value(position),
       payload = Value(payload);
  static Insertable<StoredStack> custom({
    Expression<String>? accountId,
    Expression<int>? remoteId,
    Expression<int>? boardId,
    Expression<int>? position,
    Expression<String>? payload,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (accountId != null) 'account_id': accountId,
      if (remoteId != null) 'remote_id': remoteId,
      if (boardId != null) 'board_id': boardId,
      if (position != null) 'position': position,
      if (payload != null) 'payload': payload,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StoredStacksCompanion copyWith({
    Value<String>? accountId,
    Value<int>? remoteId,
    Value<int>? boardId,
    Value<int>? position,
    Value<String>? payload,
    Value<int>? rowid,
  }) {
    return StoredStacksCompanion(
      accountId: accountId ?? this.accountId,
      remoteId: remoteId ?? this.remoteId,
      boardId: boardId ?? this.boardId,
      position: position ?? this.position,
      payload: payload ?? this.payload,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<int>(remoteId.value);
    }
    if (boardId.present) {
      map['board_id'] = Variable<int>(boardId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StoredStacksCompanion(')
          ..write('accountId: $accountId, ')
          ..write('remoteId: $remoteId, ')
          ..write('boardId: $boardId, ')
          ..write('position: $position, ')
          ..write('payload: $payload, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StoredCardsTable extends StoredCards
    with TableInfo<$StoredCardsTable, StoredCard> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StoredCardsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES stored_accounts (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<int> remoteId = GeneratedColumn<int>(
    'remote_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _boardIdMeta = const VerificationMeta(
    'boardId',
  );
  @override
  late final GeneratedColumn<int> boardId = GeneratedColumn<int>(
    'board_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stackIdMeta = const VerificationMeta(
    'stackId',
  );
  @override
  late final GeneratedColumn<int> stackId = GeneratedColumn<int>(
    'stack_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    accountId,
    remoteId,
    boardId,
    stackId,
    position,
    payload,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stored_cards';
  @override
  VerificationContext validateIntegrity(
    Insertable<StoredCard> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_remoteIdMeta);
    }
    if (data.containsKey('board_id')) {
      context.handle(
        _boardIdMeta,
        boardId.isAcceptableOrUnknown(data['board_id']!, _boardIdMeta),
      );
    } else if (isInserting) {
      context.missing(_boardIdMeta);
    }
    if (data.containsKey('stack_id')) {
      context.handle(
        _stackIdMeta,
        stackId.isAcceptableOrUnknown(data['stack_id']!, _stackIdMeta),
      );
    } else if (isInserting) {
      context.missing(_stackIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {accountId, remoteId};
  @override
  StoredCard map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoredCard(
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}remote_id'],
      )!,
      boardId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}board_id'],
      )!,
      stackId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stack_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
    );
  }

  @override
  $StoredCardsTable createAlias(String alias) {
    return $StoredCardsTable(attachedDatabase, alias);
  }
}

class StoredCard extends DataClass implements Insertable<StoredCard> {
  final String accountId;
  final int remoteId;
  final int boardId;
  final int stackId;
  final int position;
  final String payload;
  const StoredCard({
    required this.accountId,
    required this.remoteId,
    required this.boardId,
    required this.stackId,
    required this.position,
    required this.payload,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['account_id'] = Variable<String>(accountId);
    map['remote_id'] = Variable<int>(remoteId);
    map['board_id'] = Variable<int>(boardId);
    map['stack_id'] = Variable<int>(stackId);
    map['position'] = Variable<int>(position);
    map['payload'] = Variable<String>(payload);
    return map;
  }

  StoredCardsCompanion toCompanion(bool nullToAbsent) {
    return StoredCardsCompanion(
      accountId: Value(accountId),
      remoteId: Value(remoteId),
      boardId: Value(boardId),
      stackId: Value(stackId),
      position: Value(position),
      payload: Value(payload),
    );
  }

  factory StoredCard.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoredCard(
      accountId: serializer.fromJson<String>(json['accountId']),
      remoteId: serializer.fromJson<int>(json['remoteId']),
      boardId: serializer.fromJson<int>(json['boardId']),
      stackId: serializer.fromJson<int>(json['stackId']),
      position: serializer.fromJson<int>(json['position']),
      payload: serializer.fromJson<String>(json['payload']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'accountId': serializer.toJson<String>(accountId),
      'remoteId': serializer.toJson<int>(remoteId),
      'boardId': serializer.toJson<int>(boardId),
      'stackId': serializer.toJson<int>(stackId),
      'position': serializer.toJson<int>(position),
      'payload': serializer.toJson<String>(payload),
    };
  }

  StoredCard copyWith({
    String? accountId,
    int? remoteId,
    int? boardId,
    int? stackId,
    int? position,
    String? payload,
  }) => StoredCard(
    accountId: accountId ?? this.accountId,
    remoteId: remoteId ?? this.remoteId,
    boardId: boardId ?? this.boardId,
    stackId: stackId ?? this.stackId,
    position: position ?? this.position,
    payload: payload ?? this.payload,
  );
  StoredCard copyWithCompanion(StoredCardsCompanion data) {
    return StoredCard(
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      boardId: data.boardId.present ? data.boardId.value : this.boardId,
      stackId: data.stackId.present ? data.stackId.value : this.stackId,
      position: data.position.present ? data.position.value : this.position,
      payload: data.payload.present ? data.payload.value : this.payload,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoredCard(')
          ..write('accountId: $accountId, ')
          ..write('remoteId: $remoteId, ')
          ..write('boardId: $boardId, ')
          ..write('stackId: $stackId, ')
          ..write('position: $position, ')
          ..write('payload: $payload')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(accountId, remoteId, boardId, stackId, position, payload);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoredCard &&
          other.accountId == this.accountId &&
          other.remoteId == this.remoteId &&
          other.boardId == this.boardId &&
          other.stackId == this.stackId &&
          other.position == this.position &&
          other.payload == this.payload);
}

class StoredCardsCompanion extends UpdateCompanion<StoredCard> {
  final Value<String> accountId;
  final Value<int> remoteId;
  final Value<int> boardId;
  final Value<int> stackId;
  final Value<int> position;
  final Value<String> payload;
  final Value<int> rowid;
  const StoredCardsCompanion({
    this.accountId = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.boardId = const Value.absent(),
    this.stackId = const Value.absent(),
    this.position = const Value.absent(),
    this.payload = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StoredCardsCompanion.insert({
    required String accountId,
    required int remoteId,
    required int boardId,
    required int stackId,
    required int position,
    required String payload,
    this.rowid = const Value.absent(),
  }) : accountId = Value(accountId),
       remoteId = Value(remoteId),
       boardId = Value(boardId),
       stackId = Value(stackId),
       position = Value(position),
       payload = Value(payload);
  static Insertable<StoredCard> custom({
    Expression<String>? accountId,
    Expression<int>? remoteId,
    Expression<int>? boardId,
    Expression<int>? stackId,
    Expression<int>? position,
    Expression<String>? payload,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (accountId != null) 'account_id': accountId,
      if (remoteId != null) 'remote_id': remoteId,
      if (boardId != null) 'board_id': boardId,
      if (stackId != null) 'stack_id': stackId,
      if (position != null) 'position': position,
      if (payload != null) 'payload': payload,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StoredCardsCompanion copyWith({
    Value<String>? accountId,
    Value<int>? remoteId,
    Value<int>? boardId,
    Value<int>? stackId,
    Value<int>? position,
    Value<String>? payload,
    Value<int>? rowid,
  }) {
    return StoredCardsCompanion(
      accountId: accountId ?? this.accountId,
      remoteId: remoteId ?? this.remoteId,
      boardId: boardId ?? this.boardId,
      stackId: stackId ?? this.stackId,
      position: position ?? this.position,
      payload: payload ?? this.payload,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<int>(remoteId.value);
    }
    if (boardId.present) {
      map['board_id'] = Variable<int>(boardId.value);
    }
    if (stackId.present) {
      map['stack_id'] = Variable<int>(stackId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StoredCardsCompanion(')
          ..write('accountId: $accountId, ')
          ..write('remoteId: $remoteId, ')
          ..write('boardId: $boardId, ')
          ..write('stackId: $stackId, ')
          ..write('position: $position, ')
          ..write('payload: $payload, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncCheckpointsTable extends SyncCheckpoints
    with TableInfo<$SyncCheckpointsTable, SyncCheckpoint> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncCheckpointsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES stored_accounts (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _scopeMeta = const VerificationMeta('scope');
  @override
  late final GeneratedColumn<String> scope = GeneratedColumn<String>(
    'scope',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _etagMeta = const VerificationMeta('etag');
  @override
  late final GeneratedColumn<String> etag = GeneratedColumn<String>(
    'etag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [accountId, scope, etag, fetchedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_checkpoints';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncCheckpoint> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('scope')) {
      context.handle(
        _scopeMeta,
        scope.isAcceptableOrUnknown(data['scope']!, _scopeMeta),
      );
    } else if (isInserting) {
      context.missing(_scopeMeta);
    }
    if (data.containsKey('etag')) {
      context.handle(
        _etagMeta,
        etag.isAcceptableOrUnknown(data['etag']!, _etagMeta),
      );
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {accountId, scope};
  @override
  SyncCheckpoint map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncCheckpoint(
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      scope: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scope'],
      )!,
      etag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}etag'],
      ),
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      )!,
    );
  }

  @override
  $SyncCheckpointsTable createAlias(String alias) {
    return $SyncCheckpointsTable(attachedDatabase, alias);
  }
}

class SyncCheckpoint extends DataClass implements Insertable<SyncCheckpoint> {
  final String accountId;
  final String scope;
  final String? etag;
  final DateTime fetchedAt;
  const SyncCheckpoint({
    required this.accountId,
    required this.scope,
    this.etag,
    required this.fetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['account_id'] = Variable<String>(accountId);
    map['scope'] = Variable<String>(scope);
    if (!nullToAbsent || etag != null) {
      map['etag'] = Variable<String>(etag);
    }
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    return map;
  }

  SyncCheckpointsCompanion toCompanion(bool nullToAbsent) {
    return SyncCheckpointsCompanion(
      accountId: Value(accountId),
      scope: Value(scope),
      etag: etag == null && nullToAbsent ? const Value.absent() : Value(etag),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory SyncCheckpoint.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncCheckpoint(
      accountId: serializer.fromJson<String>(json['accountId']),
      scope: serializer.fromJson<String>(json['scope']),
      etag: serializer.fromJson<String?>(json['etag']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'accountId': serializer.toJson<String>(accountId),
      'scope': serializer.toJson<String>(scope),
      'etag': serializer.toJson<String?>(etag),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
    };
  }

  SyncCheckpoint copyWith({
    String? accountId,
    String? scope,
    Value<String?> etag = const Value.absent(),
    DateTime? fetchedAt,
  }) => SyncCheckpoint(
    accountId: accountId ?? this.accountId,
    scope: scope ?? this.scope,
    etag: etag.present ? etag.value : this.etag,
    fetchedAt: fetchedAt ?? this.fetchedAt,
  );
  SyncCheckpoint copyWithCompanion(SyncCheckpointsCompanion data) {
    return SyncCheckpoint(
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      scope: data.scope.present ? data.scope.value : this.scope,
      etag: data.etag.present ? data.etag.value : this.etag,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncCheckpoint(')
          ..write('accountId: $accountId, ')
          ..write('scope: $scope, ')
          ..write('etag: $etag, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(accountId, scope, etag, fetchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncCheckpoint &&
          other.accountId == this.accountId &&
          other.scope == this.scope &&
          other.etag == this.etag &&
          other.fetchedAt == this.fetchedAt);
}

class SyncCheckpointsCompanion extends UpdateCompanion<SyncCheckpoint> {
  final Value<String> accountId;
  final Value<String> scope;
  final Value<String?> etag;
  final Value<DateTime> fetchedAt;
  final Value<int> rowid;
  const SyncCheckpointsCompanion({
    this.accountId = const Value.absent(),
    this.scope = const Value.absent(),
    this.etag = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncCheckpointsCompanion.insert({
    required String accountId,
    required String scope,
    this.etag = const Value.absent(),
    required DateTime fetchedAt,
    this.rowid = const Value.absent(),
  }) : accountId = Value(accountId),
       scope = Value(scope),
       fetchedAt = Value(fetchedAt);
  static Insertable<SyncCheckpoint> custom({
    Expression<String>? accountId,
    Expression<String>? scope,
    Expression<String>? etag,
    Expression<DateTime>? fetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (accountId != null) 'account_id': accountId,
      if (scope != null) 'scope': scope,
      if (etag != null) 'etag': etag,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncCheckpointsCompanion copyWith({
    Value<String>? accountId,
    Value<String>? scope,
    Value<String?>? etag,
    Value<DateTime>? fetchedAt,
    Value<int>? rowid,
  }) {
    return SyncCheckpointsCompanion(
      accountId: accountId ?? this.accountId,
      scope: scope ?? this.scope,
      etag: etag ?? this.etag,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (scope.present) {
      map['scope'] = Variable<String>(scope.value);
    }
    if (etag.present) {
      map['etag'] = Variable<String>(etag.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncCheckpointsCompanion(')
          ..write('accountId: $accountId, ')
          ..write('scope: $scope, ')
          ..write('etag: $etag, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PendingWritesTable extends PendingWrites
    with TableInfo<$PendingWritesTable, PendingWrite> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingWritesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sequenceMeta = const VerificationMeta(
    'sequence',
  );
  @override
  late final GeneratedColumn<int> sequence = GeneratedColumn<int>(
    'sequence',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES stored_accounts (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _boardIdMeta = const VerificationMeta(
    'boardId',
  );
  @override
  late final GeneratedColumn<int> boardId = GeneratedColumn<int>(
    'board_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stackIdMeta = const VerificationMeta(
    'stackId',
  );
  @override
  late final GeneratedColumn<int> stackId = GeneratedColumn<int>(
    'stack_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cardIdMeta = const VerificationMeta('cardId');
  @override
  late final GeneratedColumn<int> cardId = GeneratedColumn<int>(
    'card_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _proposalMeta = const VerificationMeta(
    'proposal',
  );
  @override
  late final GeneratedColumn<String> proposal = GeneratedColumn<String>(
    'proposal',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _baseMeta = const VerificationMeta('base');
  @override
  late final GeneratedColumn<String> base = GeneratedColumn<String>(
    'base',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _remoteMeta = const VerificationMeta('remote');
  @override
  late final GeneratedColumn<String> remote = GeneratedColumn<String>(
    'remote',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('queued'),
  );
  static const VerificationMeta _errorMeta = const VerificationMeta('error');
  @override
  late final GeneratedColumn<String> error = GeneratedColumn<String>(
    'error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    sequence,
    id,
    accountId,
    kind,
    boardId,
    stackId,
    cardId,
    proposal,
    base,
    remote,
    state,
    error,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_writes';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingWrite> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('sequence')) {
      context.handle(
        _sequenceMeta,
        sequence.isAcceptableOrUnknown(data['sequence']!, _sequenceMeta),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('board_id')) {
      context.handle(
        _boardIdMeta,
        boardId.isAcceptableOrUnknown(data['board_id']!, _boardIdMeta),
      );
    } else if (isInserting) {
      context.missing(_boardIdMeta);
    }
    if (data.containsKey('stack_id')) {
      context.handle(
        _stackIdMeta,
        stackId.isAcceptableOrUnknown(data['stack_id']!, _stackIdMeta),
      );
    } else if (isInserting) {
      context.missing(_stackIdMeta);
    }
    if (data.containsKey('card_id')) {
      context.handle(
        _cardIdMeta,
        cardId.isAcceptableOrUnknown(data['card_id']!, _cardIdMeta),
      );
    }
    if (data.containsKey('proposal')) {
      context.handle(
        _proposalMeta,
        proposal.isAcceptableOrUnknown(data['proposal']!, _proposalMeta),
      );
    } else if (isInserting) {
      context.missing(_proposalMeta);
    }
    if (data.containsKey('base')) {
      context.handle(
        _baseMeta,
        base.isAcceptableOrUnknown(data['base']!, _baseMeta),
      );
    }
    if (data.containsKey('remote')) {
      context.handle(
        _remoteMeta,
        remote.isAcceptableOrUnknown(data['remote']!, _remoteMeta),
      );
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    }
    if (data.containsKey('error')) {
      context.handle(
        _errorMeta,
        error.isAcceptableOrUnknown(data['error']!, _errorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sequence};
  @override
  PendingWrite map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingWrite(
      sequence: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sequence'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      boardId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}board_id'],
      )!,
      stackId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stack_id'],
      )!,
      cardId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}card_id'],
      ),
      proposal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}proposal'],
      )!,
      base: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}base'],
      ),
      remote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote'],
      ),
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      error: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error'],
      ),
    );
  }

  @override
  $PendingWritesTable createAlias(String alias) {
    return $PendingWritesTable(attachedDatabase, alias);
  }
}

class PendingWrite extends DataClass implements Insertable<PendingWrite> {
  final int sequence;
  final String id;
  final String accountId;
  final String kind;
  final int boardId;
  final int stackId;
  final int? cardId;
  final String proposal;
  final String? base;
  final String? remote;
  final String state;
  final String? error;
  const PendingWrite({
    required this.sequence,
    required this.id,
    required this.accountId,
    required this.kind,
    required this.boardId,
    required this.stackId,
    this.cardId,
    required this.proposal,
    this.base,
    this.remote,
    required this.state,
    this.error,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['sequence'] = Variable<int>(sequence);
    map['id'] = Variable<String>(id);
    map['account_id'] = Variable<String>(accountId);
    map['kind'] = Variable<String>(kind);
    map['board_id'] = Variable<int>(boardId);
    map['stack_id'] = Variable<int>(stackId);
    if (!nullToAbsent || cardId != null) {
      map['card_id'] = Variable<int>(cardId);
    }
    map['proposal'] = Variable<String>(proposal);
    if (!nullToAbsent || base != null) {
      map['base'] = Variable<String>(base);
    }
    if (!nullToAbsent || remote != null) {
      map['remote'] = Variable<String>(remote);
    }
    map['state'] = Variable<String>(state);
    if (!nullToAbsent || error != null) {
      map['error'] = Variable<String>(error);
    }
    return map;
  }

  PendingWritesCompanion toCompanion(bool nullToAbsent) {
    return PendingWritesCompanion(
      sequence: Value(sequence),
      id: Value(id),
      accountId: Value(accountId),
      kind: Value(kind),
      boardId: Value(boardId),
      stackId: Value(stackId),
      cardId: cardId == null && nullToAbsent
          ? const Value.absent()
          : Value(cardId),
      proposal: Value(proposal),
      base: base == null && nullToAbsent ? const Value.absent() : Value(base),
      remote: remote == null && nullToAbsent
          ? const Value.absent()
          : Value(remote),
      state: Value(state),
      error: error == null && nullToAbsent
          ? const Value.absent()
          : Value(error),
    );
  }

  factory PendingWrite.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingWrite(
      sequence: serializer.fromJson<int>(json['sequence']),
      id: serializer.fromJson<String>(json['id']),
      accountId: serializer.fromJson<String>(json['accountId']),
      kind: serializer.fromJson<String>(json['kind']),
      boardId: serializer.fromJson<int>(json['boardId']),
      stackId: serializer.fromJson<int>(json['stackId']),
      cardId: serializer.fromJson<int?>(json['cardId']),
      proposal: serializer.fromJson<String>(json['proposal']),
      base: serializer.fromJson<String?>(json['base']),
      remote: serializer.fromJson<String?>(json['remote']),
      state: serializer.fromJson<String>(json['state']),
      error: serializer.fromJson<String?>(json['error']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sequence': serializer.toJson<int>(sequence),
      'id': serializer.toJson<String>(id),
      'accountId': serializer.toJson<String>(accountId),
      'kind': serializer.toJson<String>(kind),
      'boardId': serializer.toJson<int>(boardId),
      'stackId': serializer.toJson<int>(stackId),
      'cardId': serializer.toJson<int?>(cardId),
      'proposal': serializer.toJson<String>(proposal),
      'base': serializer.toJson<String?>(base),
      'remote': serializer.toJson<String?>(remote),
      'state': serializer.toJson<String>(state),
      'error': serializer.toJson<String?>(error),
    };
  }

  PendingWrite copyWith({
    int? sequence,
    String? id,
    String? accountId,
    String? kind,
    int? boardId,
    int? stackId,
    Value<int?> cardId = const Value.absent(),
    String? proposal,
    Value<String?> base = const Value.absent(),
    Value<String?> remote = const Value.absent(),
    String? state,
    Value<String?> error = const Value.absent(),
  }) => PendingWrite(
    sequence: sequence ?? this.sequence,
    id: id ?? this.id,
    accountId: accountId ?? this.accountId,
    kind: kind ?? this.kind,
    boardId: boardId ?? this.boardId,
    stackId: stackId ?? this.stackId,
    cardId: cardId.present ? cardId.value : this.cardId,
    proposal: proposal ?? this.proposal,
    base: base.present ? base.value : this.base,
    remote: remote.present ? remote.value : this.remote,
    state: state ?? this.state,
    error: error.present ? error.value : this.error,
  );
  PendingWrite copyWithCompanion(PendingWritesCompanion data) {
    return PendingWrite(
      sequence: data.sequence.present ? data.sequence.value : this.sequence,
      id: data.id.present ? data.id.value : this.id,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      kind: data.kind.present ? data.kind.value : this.kind,
      boardId: data.boardId.present ? data.boardId.value : this.boardId,
      stackId: data.stackId.present ? data.stackId.value : this.stackId,
      cardId: data.cardId.present ? data.cardId.value : this.cardId,
      proposal: data.proposal.present ? data.proposal.value : this.proposal,
      base: data.base.present ? data.base.value : this.base,
      remote: data.remote.present ? data.remote.value : this.remote,
      state: data.state.present ? data.state.value : this.state,
      error: data.error.present ? data.error.value : this.error,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingWrite(')
          ..write('sequence: $sequence, ')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('kind: $kind, ')
          ..write('boardId: $boardId, ')
          ..write('stackId: $stackId, ')
          ..write('cardId: $cardId, ')
          ..write('proposal: $proposal, ')
          ..write('base: $base, ')
          ..write('remote: $remote, ')
          ..write('state: $state, ')
          ..write('error: $error')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    sequence,
    id,
    accountId,
    kind,
    boardId,
    stackId,
    cardId,
    proposal,
    base,
    remote,
    state,
    error,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingWrite &&
          other.sequence == this.sequence &&
          other.id == this.id &&
          other.accountId == this.accountId &&
          other.kind == this.kind &&
          other.boardId == this.boardId &&
          other.stackId == this.stackId &&
          other.cardId == this.cardId &&
          other.proposal == this.proposal &&
          other.base == this.base &&
          other.remote == this.remote &&
          other.state == this.state &&
          other.error == this.error);
}

class PendingWritesCompanion extends UpdateCompanion<PendingWrite> {
  final Value<int> sequence;
  final Value<String> id;
  final Value<String> accountId;
  final Value<String> kind;
  final Value<int> boardId;
  final Value<int> stackId;
  final Value<int?> cardId;
  final Value<String> proposal;
  final Value<String?> base;
  final Value<String?> remote;
  final Value<String> state;
  final Value<String?> error;
  const PendingWritesCompanion({
    this.sequence = const Value.absent(),
    this.id = const Value.absent(),
    this.accountId = const Value.absent(),
    this.kind = const Value.absent(),
    this.boardId = const Value.absent(),
    this.stackId = const Value.absent(),
    this.cardId = const Value.absent(),
    this.proposal = const Value.absent(),
    this.base = const Value.absent(),
    this.remote = const Value.absent(),
    this.state = const Value.absent(),
    this.error = const Value.absent(),
  });
  PendingWritesCompanion.insert({
    this.sequence = const Value.absent(),
    required String id,
    required String accountId,
    required String kind,
    required int boardId,
    required int stackId,
    this.cardId = const Value.absent(),
    required String proposal,
    this.base = const Value.absent(),
    this.remote = const Value.absent(),
    this.state = const Value.absent(),
    this.error = const Value.absent(),
  }) : id = Value(id),
       accountId = Value(accountId),
       kind = Value(kind),
       boardId = Value(boardId),
       stackId = Value(stackId),
       proposal = Value(proposal);
  static Insertable<PendingWrite> custom({
    Expression<int>? sequence,
    Expression<String>? id,
    Expression<String>? accountId,
    Expression<String>? kind,
    Expression<int>? boardId,
    Expression<int>? stackId,
    Expression<int>? cardId,
    Expression<String>? proposal,
    Expression<String>? base,
    Expression<String>? remote,
    Expression<String>? state,
    Expression<String>? error,
  }) {
    return RawValuesInsertable({
      if (sequence != null) 'sequence': sequence,
      if (id != null) 'id': id,
      if (accountId != null) 'account_id': accountId,
      if (kind != null) 'kind': kind,
      if (boardId != null) 'board_id': boardId,
      if (stackId != null) 'stack_id': stackId,
      if (cardId != null) 'card_id': cardId,
      if (proposal != null) 'proposal': proposal,
      if (base != null) 'base': base,
      if (remote != null) 'remote': remote,
      if (state != null) 'state': state,
      if (error != null) 'error': error,
    });
  }

  PendingWritesCompanion copyWith({
    Value<int>? sequence,
    Value<String>? id,
    Value<String>? accountId,
    Value<String>? kind,
    Value<int>? boardId,
    Value<int>? stackId,
    Value<int?>? cardId,
    Value<String>? proposal,
    Value<String?>? base,
    Value<String?>? remote,
    Value<String>? state,
    Value<String?>? error,
  }) {
    return PendingWritesCompanion(
      sequence: sequence ?? this.sequence,
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      kind: kind ?? this.kind,
      boardId: boardId ?? this.boardId,
      stackId: stackId ?? this.stackId,
      cardId: cardId ?? this.cardId,
      proposal: proposal ?? this.proposal,
      base: base ?? this.base,
      remote: remote ?? this.remote,
      state: state ?? this.state,
      error: error ?? this.error,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sequence.present) {
      map['sequence'] = Variable<int>(sequence.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (boardId.present) {
      map['board_id'] = Variable<int>(boardId.value);
    }
    if (stackId.present) {
      map['stack_id'] = Variable<int>(stackId.value);
    }
    if (cardId.present) {
      map['card_id'] = Variable<int>(cardId.value);
    }
    if (proposal.present) {
      map['proposal'] = Variable<String>(proposal.value);
    }
    if (base.present) {
      map['base'] = Variable<String>(base.value);
    }
    if (remote.present) {
      map['remote'] = Variable<String>(remote.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (error.present) {
      map['error'] = Variable<String>(error.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingWritesCompanion(')
          ..write('sequence: $sequence, ')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('kind: $kind, ')
          ..write('boardId: $boardId, ')
          ..write('stackId: $stackId, ')
          ..write('cardId: $cardId, ')
          ..write('proposal: $proposal, ')
          ..write('base: $base, ')
          ..write('remote: $remote, ')
          ..write('state: $state, ')
          ..write('error: $error')
          ..write(')'))
        .toString();
  }
}

class $SyncLeasesTable extends SyncLeases
    with TableInfo<$SyncLeasesTable, SyncLease> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncLeasesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES stored_accounts (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _ownerMeta = const VerificationMeta('owner');
  @override
  late final GeneratedColumn<String> owner = GeneratedColumn<String>(
    'owner',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expiresMeta = const VerificationMeta(
    'expires',
  );
  @override
  late final GeneratedColumn<DateTime> expires = GeneratedColumn<DateTime>(
    'expires',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [accountId, owner, expires];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_leases';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncLease> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('owner')) {
      context.handle(
        _ownerMeta,
        owner.isAcceptableOrUnknown(data['owner']!, _ownerMeta),
      );
    } else if (isInserting) {
      context.missing(_ownerMeta);
    }
    if (data.containsKey('expires')) {
      context.handle(
        _expiresMeta,
        expires.isAcceptableOrUnknown(data['expires']!, _expiresMeta),
      );
    } else if (isInserting) {
      context.missing(_expiresMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {accountId};
  @override
  SyncLease map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncLease(
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      owner: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner'],
      )!,
      expires: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expires'],
      )!,
    );
  }

  @override
  $SyncLeasesTable createAlias(String alias) {
    return $SyncLeasesTable(attachedDatabase, alias);
  }
}

class SyncLease extends DataClass implements Insertable<SyncLease> {
  final String accountId;
  final String owner;
  final DateTime expires;
  const SyncLease({
    required this.accountId,
    required this.owner,
    required this.expires,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['account_id'] = Variable<String>(accountId);
    map['owner'] = Variable<String>(owner);
    map['expires'] = Variable<DateTime>(expires);
    return map;
  }

  SyncLeasesCompanion toCompanion(bool nullToAbsent) {
    return SyncLeasesCompanion(
      accountId: Value(accountId),
      owner: Value(owner),
      expires: Value(expires),
    );
  }

  factory SyncLease.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncLease(
      accountId: serializer.fromJson<String>(json['accountId']),
      owner: serializer.fromJson<String>(json['owner']),
      expires: serializer.fromJson<DateTime>(json['expires']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'accountId': serializer.toJson<String>(accountId),
      'owner': serializer.toJson<String>(owner),
      'expires': serializer.toJson<DateTime>(expires),
    };
  }

  SyncLease copyWith({String? accountId, String? owner, DateTime? expires}) =>
      SyncLease(
        accountId: accountId ?? this.accountId,
        owner: owner ?? this.owner,
        expires: expires ?? this.expires,
      );
  SyncLease copyWithCompanion(SyncLeasesCompanion data) {
    return SyncLease(
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      owner: data.owner.present ? data.owner.value : this.owner,
      expires: data.expires.present ? data.expires.value : this.expires,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncLease(')
          ..write('accountId: $accountId, ')
          ..write('owner: $owner, ')
          ..write('expires: $expires')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(accountId, owner, expires);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncLease &&
          other.accountId == this.accountId &&
          other.owner == this.owner &&
          other.expires == this.expires);
}

class SyncLeasesCompanion extends UpdateCompanion<SyncLease> {
  final Value<String> accountId;
  final Value<String> owner;
  final Value<DateTime> expires;
  final Value<int> rowid;
  const SyncLeasesCompanion({
    this.accountId = const Value.absent(),
    this.owner = const Value.absent(),
    this.expires = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncLeasesCompanion.insert({
    required String accountId,
    required String owner,
    required DateTime expires,
    this.rowid = const Value.absent(),
  }) : accountId = Value(accountId),
       owner = Value(owner),
       expires = Value(expires);
  static Insertable<SyncLease> custom({
    Expression<String>? accountId,
    Expression<String>? owner,
    Expression<DateTime>? expires,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (accountId != null) 'account_id': accountId,
      if (owner != null) 'owner': owner,
      if (expires != null) 'expires': expires,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncLeasesCompanion copyWith({
    Value<String>? accountId,
    Value<String>? owner,
    Value<DateTime>? expires,
    Value<int>? rowid,
  }) {
    return SyncLeasesCompanion(
      accountId: accountId ?? this.accountId,
      owner: owner ?? this.owner,
      expires: expires ?? this.expires,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (owner.present) {
      map['owner'] = Variable<String>(owner.value);
    }
    if (expires.present) {
      map['expires'] = Variable<DateTime>(expires.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncLeasesCompanion(')
          ..write('accountId: $accountId, ')
          ..write('owner: $owner, ')
          ..write('expires: $expires, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EditorDraftsTable extends EditorDrafts
    with TableInfo<$EditorDraftsTable, EditorDraft> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EditorDraftsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('card'),
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES stored_accounts (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _draftKeyMeta = const VerificationMeta(
    'draftKey',
  );
  @override
  late final GeneratedColumn<String> draftKey = GeneratedColumn<String>(
    'draft_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _boardIdMeta = const VerificationMeta(
    'boardId',
  );
  @override
  late final GeneratedColumn<int> boardId = GeneratedColumn<int>(
    'board_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stackIdMeta = const VerificationMeta(
    'stackId',
  );
  @override
  late final GeneratedColumn<int> stackId = GeneratedColumn<int>(
    'stack_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cardIdMeta = const VerificationMeta('cardId');
  @override
  late final GeneratedColumn<int> cardId = GeneratedColumn<int>(
    'card_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _baseMeta = const VerificationMeta('base');
  @override
  late final GeneratedColumn<String> base = GeneratedColumn<String>(
    'base',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    kind,
    accountId,
    draftKey,
    boardId,
    stackId,
    cardId,
    payload,
    base,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'editor_drafts';
  @override
  VerificationContext validateIntegrity(
    Insertable<EditorDraft> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('draft_key')) {
      context.handle(
        _draftKeyMeta,
        draftKey.isAcceptableOrUnknown(data['draft_key']!, _draftKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_draftKeyMeta);
    }
    if (data.containsKey('board_id')) {
      context.handle(
        _boardIdMeta,
        boardId.isAcceptableOrUnknown(data['board_id']!, _boardIdMeta),
      );
    } else if (isInserting) {
      context.missing(_boardIdMeta);
    }
    if (data.containsKey('stack_id')) {
      context.handle(
        _stackIdMeta,
        stackId.isAcceptableOrUnknown(data['stack_id']!, _stackIdMeta),
      );
    } else if (isInserting) {
      context.missing(_stackIdMeta);
    }
    if (data.containsKey('card_id')) {
      context.handle(
        _cardIdMeta,
        cardId.isAcceptableOrUnknown(data['card_id']!, _cardIdMeta),
      );
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('base')) {
      context.handle(
        _baseMeta,
        base.isAcceptableOrUnknown(data['base']!, _baseMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {accountId, draftKey};
  @override
  EditorDraft map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EditorDraft(
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      draftKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}draft_key'],
      )!,
      boardId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}board_id'],
      )!,
      stackId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stack_id'],
      )!,
      cardId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}card_id'],
      ),
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      base: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}base'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $EditorDraftsTable createAlias(String alias) {
    return $EditorDraftsTable(attachedDatabase, alias);
  }
}

class EditorDraft extends DataClass implements Insertable<EditorDraft> {
  final String kind;
  final String accountId;
  final String draftKey;
  final int boardId;
  final int stackId;
  final int? cardId;
  final String payload;
  final String? base;
  final DateTime updatedAt;
  const EditorDraft({
    required this.kind,
    required this.accountId,
    required this.draftKey,
    required this.boardId,
    required this.stackId,
    this.cardId,
    required this.payload,
    this.base,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['kind'] = Variable<String>(kind);
    map['account_id'] = Variable<String>(accountId);
    map['draft_key'] = Variable<String>(draftKey);
    map['board_id'] = Variable<int>(boardId);
    map['stack_id'] = Variable<int>(stackId);
    if (!nullToAbsent || cardId != null) {
      map['card_id'] = Variable<int>(cardId);
    }
    map['payload'] = Variable<String>(payload);
    if (!nullToAbsent || base != null) {
      map['base'] = Variable<String>(base);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  EditorDraftsCompanion toCompanion(bool nullToAbsent) {
    return EditorDraftsCompanion(
      kind: Value(kind),
      accountId: Value(accountId),
      draftKey: Value(draftKey),
      boardId: Value(boardId),
      stackId: Value(stackId),
      cardId: cardId == null && nullToAbsent
          ? const Value.absent()
          : Value(cardId),
      payload: Value(payload),
      base: base == null && nullToAbsent ? const Value.absent() : Value(base),
      updatedAt: Value(updatedAt),
    );
  }

  factory EditorDraft.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EditorDraft(
      kind: serializer.fromJson<String>(json['kind']),
      accountId: serializer.fromJson<String>(json['accountId']),
      draftKey: serializer.fromJson<String>(json['draftKey']),
      boardId: serializer.fromJson<int>(json['boardId']),
      stackId: serializer.fromJson<int>(json['stackId']),
      cardId: serializer.fromJson<int?>(json['cardId']),
      payload: serializer.fromJson<String>(json['payload']),
      base: serializer.fromJson<String?>(json['base']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'kind': serializer.toJson<String>(kind),
      'accountId': serializer.toJson<String>(accountId),
      'draftKey': serializer.toJson<String>(draftKey),
      'boardId': serializer.toJson<int>(boardId),
      'stackId': serializer.toJson<int>(stackId),
      'cardId': serializer.toJson<int?>(cardId),
      'payload': serializer.toJson<String>(payload),
      'base': serializer.toJson<String?>(base),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  EditorDraft copyWith({
    String? kind,
    String? accountId,
    String? draftKey,
    int? boardId,
    int? stackId,
    Value<int?> cardId = const Value.absent(),
    String? payload,
    Value<String?> base = const Value.absent(),
    DateTime? updatedAt,
  }) => EditorDraft(
    kind: kind ?? this.kind,
    accountId: accountId ?? this.accountId,
    draftKey: draftKey ?? this.draftKey,
    boardId: boardId ?? this.boardId,
    stackId: stackId ?? this.stackId,
    cardId: cardId.present ? cardId.value : this.cardId,
    payload: payload ?? this.payload,
    base: base.present ? base.value : this.base,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  EditorDraft copyWithCompanion(EditorDraftsCompanion data) {
    return EditorDraft(
      kind: data.kind.present ? data.kind.value : this.kind,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      draftKey: data.draftKey.present ? data.draftKey.value : this.draftKey,
      boardId: data.boardId.present ? data.boardId.value : this.boardId,
      stackId: data.stackId.present ? data.stackId.value : this.stackId,
      cardId: data.cardId.present ? data.cardId.value : this.cardId,
      payload: data.payload.present ? data.payload.value : this.payload,
      base: data.base.present ? data.base.value : this.base,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EditorDraft(')
          ..write('kind: $kind, ')
          ..write('accountId: $accountId, ')
          ..write('draftKey: $draftKey, ')
          ..write('boardId: $boardId, ')
          ..write('stackId: $stackId, ')
          ..write('cardId: $cardId, ')
          ..write('payload: $payload, ')
          ..write('base: $base, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    kind,
    accountId,
    draftKey,
    boardId,
    stackId,
    cardId,
    payload,
    base,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EditorDraft &&
          other.kind == this.kind &&
          other.accountId == this.accountId &&
          other.draftKey == this.draftKey &&
          other.boardId == this.boardId &&
          other.stackId == this.stackId &&
          other.cardId == this.cardId &&
          other.payload == this.payload &&
          other.base == this.base &&
          other.updatedAt == this.updatedAt);
}

class EditorDraftsCompanion extends UpdateCompanion<EditorDraft> {
  final Value<String> kind;
  final Value<String> accountId;
  final Value<String> draftKey;
  final Value<int> boardId;
  final Value<int> stackId;
  final Value<int?> cardId;
  final Value<String> payload;
  final Value<String?> base;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const EditorDraftsCompanion({
    this.kind = const Value.absent(),
    this.accountId = const Value.absent(),
    this.draftKey = const Value.absent(),
    this.boardId = const Value.absent(),
    this.stackId = const Value.absent(),
    this.cardId = const Value.absent(),
    this.payload = const Value.absent(),
    this.base = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EditorDraftsCompanion.insert({
    this.kind = const Value.absent(),
    required String accountId,
    required String draftKey,
    required int boardId,
    required int stackId,
    this.cardId = const Value.absent(),
    required String payload,
    this.base = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : accountId = Value(accountId),
       draftKey = Value(draftKey),
       boardId = Value(boardId),
       stackId = Value(stackId),
       payload = Value(payload),
       updatedAt = Value(updatedAt);
  static Insertable<EditorDraft> custom({
    Expression<String>? kind,
    Expression<String>? accountId,
    Expression<String>? draftKey,
    Expression<int>? boardId,
    Expression<int>? stackId,
    Expression<int>? cardId,
    Expression<String>? payload,
    Expression<String>? base,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (kind != null) 'kind': kind,
      if (accountId != null) 'account_id': accountId,
      if (draftKey != null) 'draft_key': draftKey,
      if (boardId != null) 'board_id': boardId,
      if (stackId != null) 'stack_id': stackId,
      if (cardId != null) 'card_id': cardId,
      if (payload != null) 'payload': payload,
      if (base != null) 'base': base,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EditorDraftsCompanion copyWith({
    Value<String>? kind,
    Value<String>? accountId,
    Value<String>? draftKey,
    Value<int>? boardId,
    Value<int>? stackId,
    Value<int?>? cardId,
    Value<String>? payload,
    Value<String?>? base,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return EditorDraftsCompanion(
      kind: kind ?? this.kind,
      accountId: accountId ?? this.accountId,
      draftKey: draftKey ?? this.draftKey,
      boardId: boardId ?? this.boardId,
      stackId: stackId ?? this.stackId,
      cardId: cardId ?? this.cardId,
      payload: payload ?? this.payload,
      base: base ?? this.base,
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
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (draftKey.present) {
      map['draft_key'] = Variable<String>(draftKey.value);
    }
    if (boardId.present) {
      map['board_id'] = Variable<int>(boardId.value);
    }
    if (stackId.present) {
      map['stack_id'] = Variable<int>(stackId.value);
    }
    if (cardId.present) {
      map['card_id'] = Variable<int>(cardId.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (base.present) {
      map['base'] = Variable<String>(base.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EditorDraftsCompanion(')
          ..write('kind: $kind, ')
          ..write('accountId: $accountId, ')
          ..write('draftKey: $draftKey, ')
          ..write('boardId: $boardId, ')
          ..write('stackId: $stackId, ')
          ..write('cardId: $cardId, ')
          ..write('payload: $payload, ')
          ..write('base: $base, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StoredCommentsTable extends StoredComments
    with TableInfo<$StoredCommentsTable, StoredComment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StoredCommentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES stored_accounts (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _cardIdMeta = const VerificationMeta('cardId');
  @override
  late final GeneratedColumn<int> cardId = GeneratedColumn<int>(
    'card_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<int> remoteId = GeneratedColumn<int>(
    'remote_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [accountId, cardId, remoteId, payload];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stored_comments';
  @override
  VerificationContext validateIntegrity(
    Insertable<StoredComment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('card_id')) {
      context.handle(
        _cardIdMeta,
        cardId.isAcceptableOrUnknown(data['card_id']!, _cardIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cardIdMeta);
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_remoteIdMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {accountId, remoteId};
  @override
  StoredComment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoredComment(
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      cardId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}card_id'],
      )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}remote_id'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
    );
  }

  @override
  $StoredCommentsTable createAlias(String alias) {
    return $StoredCommentsTable(attachedDatabase, alias);
  }
}

class StoredComment extends DataClass implements Insertable<StoredComment> {
  final String accountId;
  final int cardId;
  final int remoteId;
  final String payload;
  const StoredComment({
    required this.accountId,
    required this.cardId,
    required this.remoteId,
    required this.payload,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['account_id'] = Variable<String>(accountId);
    map['card_id'] = Variable<int>(cardId);
    map['remote_id'] = Variable<int>(remoteId);
    map['payload'] = Variable<String>(payload);
    return map;
  }

  StoredCommentsCompanion toCompanion(bool nullToAbsent) {
    return StoredCommentsCompanion(
      accountId: Value(accountId),
      cardId: Value(cardId),
      remoteId: Value(remoteId),
      payload: Value(payload),
    );
  }

  factory StoredComment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoredComment(
      accountId: serializer.fromJson<String>(json['accountId']),
      cardId: serializer.fromJson<int>(json['cardId']),
      remoteId: serializer.fromJson<int>(json['remoteId']),
      payload: serializer.fromJson<String>(json['payload']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'accountId': serializer.toJson<String>(accountId),
      'cardId': serializer.toJson<int>(cardId),
      'remoteId': serializer.toJson<int>(remoteId),
      'payload': serializer.toJson<String>(payload),
    };
  }

  StoredComment copyWith({
    String? accountId,
    int? cardId,
    int? remoteId,
    String? payload,
  }) => StoredComment(
    accountId: accountId ?? this.accountId,
    cardId: cardId ?? this.cardId,
    remoteId: remoteId ?? this.remoteId,
    payload: payload ?? this.payload,
  );
  StoredComment copyWithCompanion(StoredCommentsCompanion data) {
    return StoredComment(
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      cardId: data.cardId.present ? data.cardId.value : this.cardId,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      payload: data.payload.present ? data.payload.value : this.payload,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoredComment(')
          ..write('accountId: $accountId, ')
          ..write('cardId: $cardId, ')
          ..write('remoteId: $remoteId, ')
          ..write('payload: $payload')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(accountId, cardId, remoteId, payload);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoredComment &&
          other.accountId == this.accountId &&
          other.cardId == this.cardId &&
          other.remoteId == this.remoteId &&
          other.payload == this.payload);
}

class StoredCommentsCompanion extends UpdateCompanion<StoredComment> {
  final Value<String> accountId;
  final Value<int> cardId;
  final Value<int> remoteId;
  final Value<String> payload;
  final Value<int> rowid;
  const StoredCommentsCompanion({
    this.accountId = const Value.absent(),
    this.cardId = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.payload = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StoredCommentsCompanion.insert({
    required String accountId,
    required int cardId,
    required int remoteId,
    required String payload,
    this.rowid = const Value.absent(),
  }) : accountId = Value(accountId),
       cardId = Value(cardId),
       remoteId = Value(remoteId),
       payload = Value(payload);
  static Insertable<StoredComment> custom({
    Expression<String>? accountId,
    Expression<int>? cardId,
    Expression<int>? remoteId,
    Expression<String>? payload,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (accountId != null) 'account_id': accountId,
      if (cardId != null) 'card_id': cardId,
      if (remoteId != null) 'remote_id': remoteId,
      if (payload != null) 'payload': payload,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StoredCommentsCompanion copyWith({
    Value<String>? accountId,
    Value<int>? cardId,
    Value<int>? remoteId,
    Value<String>? payload,
    Value<int>? rowid,
  }) {
    return StoredCommentsCompanion(
      accountId: accountId ?? this.accountId,
      cardId: cardId ?? this.cardId,
      remoteId: remoteId ?? this.remoteId,
      payload: payload ?? this.payload,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (cardId.present) {
      map['card_id'] = Variable<int>(cardId.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<int>(remoteId.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StoredCommentsCompanion(')
          ..write('accountId: $accountId, ')
          ..write('cardId: $cardId, ')
          ..write('remoteId: $remoteId, ')
          ..write('payload: $payload, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StoredAttachmentsTable extends StoredAttachments
    with TableInfo<$StoredAttachmentsTable, StoredAttachment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StoredAttachmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES stored_accounts (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _boardIdMeta = const VerificationMeta(
    'boardId',
  );
  @override
  late final GeneratedColumn<int> boardId = GeneratedColumn<int>(
    'board_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cardIdMeta = const VerificationMeta('cardId');
  @override
  late final GeneratedColumn<int> cardId = GeneratedColumn<int>(
    'card_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<int> remoteId = GeneratedColumn<int>(
    'remote_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    accountId,
    boardId,
    cardId,
    type,
    remoteId,
    payload,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stored_attachments';
  @override
  VerificationContext validateIntegrity(
    Insertable<StoredAttachment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('board_id')) {
      context.handle(
        _boardIdMeta,
        boardId.isAcceptableOrUnknown(data['board_id']!, _boardIdMeta),
      );
    } else if (isInserting) {
      context.missing(_boardIdMeta);
    }
    if (data.containsKey('card_id')) {
      context.handle(
        _cardIdMeta,
        cardId.isAcceptableOrUnknown(data['card_id']!, _cardIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cardIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_remoteIdMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {accountId, cardId, type, remoteId};
  @override
  StoredAttachment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoredAttachment(
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      boardId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}board_id'],
      )!,
      cardId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}card_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}remote_id'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
    );
  }

  @override
  $StoredAttachmentsTable createAlias(String alias) {
    return $StoredAttachmentsTable(attachedDatabase, alias);
  }
}

class StoredAttachment extends DataClass
    implements Insertable<StoredAttachment> {
  final String accountId;
  final int boardId;
  final int cardId;
  final String type;
  final int remoteId;
  final String payload;
  const StoredAttachment({
    required this.accountId,
    required this.boardId,
    required this.cardId,
    required this.type,
    required this.remoteId,
    required this.payload,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['account_id'] = Variable<String>(accountId);
    map['board_id'] = Variable<int>(boardId);
    map['card_id'] = Variable<int>(cardId);
    map['type'] = Variable<String>(type);
    map['remote_id'] = Variable<int>(remoteId);
    map['payload'] = Variable<String>(payload);
    return map;
  }

  StoredAttachmentsCompanion toCompanion(bool nullToAbsent) {
    return StoredAttachmentsCompanion(
      accountId: Value(accountId),
      boardId: Value(boardId),
      cardId: Value(cardId),
      type: Value(type),
      remoteId: Value(remoteId),
      payload: Value(payload),
    );
  }

  factory StoredAttachment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoredAttachment(
      accountId: serializer.fromJson<String>(json['accountId']),
      boardId: serializer.fromJson<int>(json['boardId']),
      cardId: serializer.fromJson<int>(json['cardId']),
      type: serializer.fromJson<String>(json['type']),
      remoteId: serializer.fromJson<int>(json['remoteId']),
      payload: serializer.fromJson<String>(json['payload']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'accountId': serializer.toJson<String>(accountId),
      'boardId': serializer.toJson<int>(boardId),
      'cardId': serializer.toJson<int>(cardId),
      'type': serializer.toJson<String>(type),
      'remoteId': serializer.toJson<int>(remoteId),
      'payload': serializer.toJson<String>(payload),
    };
  }

  StoredAttachment copyWith({
    String? accountId,
    int? boardId,
    int? cardId,
    String? type,
    int? remoteId,
    String? payload,
  }) => StoredAttachment(
    accountId: accountId ?? this.accountId,
    boardId: boardId ?? this.boardId,
    cardId: cardId ?? this.cardId,
    type: type ?? this.type,
    remoteId: remoteId ?? this.remoteId,
    payload: payload ?? this.payload,
  );
  StoredAttachment copyWithCompanion(StoredAttachmentsCompanion data) {
    return StoredAttachment(
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      boardId: data.boardId.present ? data.boardId.value : this.boardId,
      cardId: data.cardId.present ? data.cardId.value : this.cardId,
      type: data.type.present ? data.type.value : this.type,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      payload: data.payload.present ? data.payload.value : this.payload,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoredAttachment(')
          ..write('accountId: $accountId, ')
          ..write('boardId: $boardId, ')
          ..write('cardId: $cardId, ')
          ..write('type: $type, ')
          ..write('remoteId: $remoteId, ')
          ..write('payload: $payload')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(accountId, boardId, cardId, type, remoteId, payload);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoredAttachment &&
          other.accountId == this.accountId &&
          other.boardId == this.boardId &&
          other.cardId == this.cardId &&
          other.type == this.type &&
          other.remoteId == this.remoteId &&
          other.payload == this.payload);
}

class StoredAttachmentsCompanion extends UpdateCompanion<StoredAttachment> {
  final Value<String> accountId;
  final Value<int> boardId;
  final Value<int> cardId;
  final Value<String> type;
  final Value<int> remoteId;
  final Value<String> payload;
  final Value<int> rowid;
  const StoredAttachmentsCompanion({
    this.accountId = const Value.absent(),
    this.boardId = const Value.absent(),
    this.cardId = const Value.absent(),
    this.type = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.payload = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StoredAttachmentsCompanion.insert({
    required String accountId,
    required int boardId,
    required int cardId,
    required String type,
    required int remoteId,
    required String payload,
    this.rowid = const Value.absent(),
  }) : accountId = Value(accountId),
       boardId = Value(boardId),
       cardId = Value(cardId),
       type = Value(type),
       remoteId = Value(remoteId),
       payload = Value(payload);
  static Insertable<StoredAttachment> custom({
    Expression<String>? accountId,
    Expression<int>? boardId,
    Expression<int>? cardId,
    Expression<String>? type,
    Expression<int>? remoteId,
    Expression<String>? payload,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (accountId != null) 'account_id': accountId,
      if (boardId != null) 'board_id': boardId,
      if (cardId != null) 'card_id': cardId,
      if (type != null) 'type': type,
      if (remoteId != null) 'remote_id': remoteId,
      if (payload != null) 'payload': payload,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StoredAttachmentsCompanion copyWith({
    Value<String>? accountId,
    Value<int>? boardId,
    Value<int>? cardId,
    Value<String>? type,
    Value<int>? remoteId,
    Value<String>? payload,
    Value<int>? rowid,
  }) {
    return StoredAttachmentsCompanion(
      accountId: accountId ?? this.accountId,
      boardId: boardId ?? this.boardId,
      cardId: cardId ?? this.cardId,
      type: type ?? this.type,
      remoteId: remoteId ?? this.remoteId,
      payload: payload ?? this.payload,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (boardId.present) {
      map['board_id'] = Variable<int>(boardId.value);
    }
    if (cardId.present) {
      map['card_id'] = Variable<int>(cardId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<int>(remoteId.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StoredAttachmentsCompanion(')
          ..write('accountId: $accountId, ')
          ..write('boardId: $boardId, ')
          ..write('cardId: $cardId, ')
          ..write('type: $type, ')
          ..write('remoteId: $remoteId, ')
          ..write('payload: $payload, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$DeckDatabase extends GeneratedDatabase {
  _$DeckDatabase(QueryExecutor e) : super(e);
  $DeckDatabaseManager get managers => $DeckDatabaseManager(this);
  late final $StoredAccountsTable storedAccounts = $StoredAccountsTable(this);
  late final $StoredBoardsTable storedBoards = $StoredBoardsTable(this);
  late final $StoredStacksTable storedStacks = $StoredStacksTable(this);
  late final $StoredCardsTable storedCards = $StoredCardsTable(this);
  late final $SyncCheckpointsTable syncCheckpoints = $SyncCheckpointsTable(
    this,
  );
  late final $PendingWritesTable pendingWrites = $PendingWritesTable(this);
  late final $SyncLeasesTable syncLeases = $SyncLeasesTable(this);
  late final $EditorDraftsTable editorDrafts = $EditorDraftsTable(this);
  late final $StoredCommentsTable storedComments = $StoredCommentsTable(this);
  late final $StoredAttachmentsTable storedAttachments =
      $StoredAttachmentsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    storedAccounts,
    storedBoards,
    storedStacks,
    storedCards,
    syncCheckpoints,
    pendingWrites,
    syncLeases,
    editorDrafts,
    storedComments,
    storedAttachments,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'stored_accounts',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('stored_boards', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'stored_accounts',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('stored_stacks', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'stored_accounts',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('stored_cards', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'stored_accounts',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('sync_checkpoints', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'stored_accounts',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('pending_writes', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'stored_accounts',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('sync_leases', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'stored_accounts',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('editor_drafts', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'stored_accounts',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('stored_comments', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'stored_accounts',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('stored_attachments', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$StoredAccountsTableCreateCompanionBuilder =
    StoredAccountsCompanion Function({
      required String id,
      required String server,
      required String loginName,
      Value<String?> userId,
      Value<String?> certificateFingerprint,
      Value<DateTime?> syncNotBefore,
      required String credentialRef,
      Value<String> state,
      Value<int> generation,
      Value<String?> capabilities,
      Value<int> contentEpoch,
      Value<bool> selected,
      Value<int> rowid,
    });
typedef $$StoredAccountsTableUpdateCompanionBuilder =
    StoredAccountsCompanion Function({
      Value<String> id,
      Value<String> server,
      Value<String> loginName,
      Value<String?> userId,
      Value<String?> certificateFingerprint,
      Value<DateTime?> syncNotBefore,
      Value<String> credentialRef,
      Value<String> state,
      Value<int> generation,
      Value<String?> capabilities,
      Value<int> contentEpoch,
      Value<bool> selected,
      Value<int> rowid,
    });

final class $$StoredAccountsTableReferences
    extends
        BaseReferences<_$DeckDatabase, $StoredAccountsTable, StoredAccount> {
  $$StoredAccountsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$StoredBoardsTable, List<StoredBoard>>
  _storedBoardsRefsTable(_$DeckDatabase db) => MultiTypedResultKey.fromTable(
    db.storedBoards,
    aliasName: 'stored_accounts__id__stored_boards__account_id',
  );

  $$StoredBoardsTableProcessedTableManager get storedBoardsRefs {
    final manager = $$StoredBoardsTableTableManager(
      $_db,
      $_db.storedBoards,
    ).filter((f) => f.accountId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_storedBoardsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$StoredStacksTable, List<StoredStack>>
  _storedStacksRefsTable(_$DeckDatabase db) => MultiTypedResultKey.fromTable(
    db.storedStacks,
    aliasName: 'stored_accounts__id__stored_stacks__account_id',
  );

  $$StoredStacksTableProcessedTableManager get storedStacksRefs {
    final manager = $$StoredStacksTableTableManager(
      $_db,
      $_db.storedStacks,
    ).filter((f) => f.accountId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_storedStacksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$StoredCardsTable, List<StoredCard>>
  _storedCardsRefsTable(_$DeckDatabase db) => MultiTypedResultKey.fromTable(
    db.storedCards,
    aliasName: 'stored_accounts__id__stored_cards__account_id',
  );

  $$StoredCardsTableProcessedTableManager get storedCardsRefs {
    final manager = $$StoredCardsTableTableManager(
      $_db,
      $_db.storedCards,
    ).filter((f) => f.accountId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_storedCardsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SyncCheckpointsTable, List<SyncCheckpoint>>
  _syncCheckpointsRefsTable(_$DeckDatabase db) => MultiTypedResultKey.fromTable(
    db.syncCheckpoints,
    aliasName: 'stored_accounts__id__sync_checkpoints__account_id',
  );

  $$SyncCheckpointsTableProcessedTableManager get syncCheckpointsRefs {
    final manager = $$SyncCheckpointsTableTableManager(
      $_db,
      $_db.syncCheckpoints,
    ).filter((f) => f.accountId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _syncCheckpointsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PendingWritesTable, List<PendingWrite>>
  _pendingWritesRefsTable(_$DeckDatabase db) => MultiTypedResultKey.fromTable(
    db.pendingWrites,
    aliasName: 'stored_accounts__id__pending_writes__account_id',
  );

  $$PendingWritesTableProcessedTableManager get pendingWritesRefs {
    final manager = $$PendingWritesTableTableManager(
      $_db,
      $_db.pendingWrites,
    ).filter((f) => f.accountId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_pendingWritesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SyncLeasesTable, List<SyncLease>>
  _syncLeasesRefsTable(_$DeckDatabase db) => MultiTypedResultKey.fromTable(
    db.syncLeases,
    aliasName: 'stored_accounts__id__sync_leases__account_id',
  );

  $$SyncLeasesTableProcessedTableManager get syncLeasesRefs {
    final manager = $$SyncLeasesTableTableManager(
      $_db,
      $_db.syncLeases,
    ).filter((f) => f.accountId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_syncLeasesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$EditorDraftsTable, List<EditorDraft>>
  _editorDraftsRefsTable(_$DeckDatabase db) => MultiTypedResultKey.fromTable(
    db.editorDrafts,
    aliasName: 'stored_accounts__id__editor_drafts__account_id',
  );

  $$EditorDraftsTableProcessedTableManager get editorDraftsRefs {
    final manager = $$EditorDraftsTableTableManager(
      $_db,
      $_db.editorDrafts,
    ).filter((f) => f.accountId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_editorDraftsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$StoredCommentsTable, List<StoredComment>>
  _storedCommentsRefsTable(_$DeckDatabase db) => MultiTypedResultKey.fromTable(
    db.storedComments,
    aliasName: 'stored_accounts__id__stored_comments__account_id',
  );

  $$StoredCommentsTableProcessedTableManager get storedCommentsRefs {
    final manager = $$StoredCommentsTableTableManager(
      $_db,
      $_db.storedComments,
    ).filter((f) => f.accountId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_storedCommentsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$StoredAttachmentsTable, List<StoredAttachment>>
  _storedAttachmentsRefsTable(_$DeckDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.storedAttachments,
        aliasName: 'stored_accounts__id__stored_attachments__account_id',
      );

  $$StoredAttachmentsTableProcessedTableManager get storedAttachmentsRefs {
    final manager = $$StoredAttachmentsTableTableManager(
      $_db,
      $_db.storedAttachments,
    ).filter((f) => f.accountId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _storedAttachmentsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$StoredAccountsTableFilterComposer
    extends Composer<_$DeckDatabase, $StoredAccountsTable> {
  $$StoredAccountsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get server => $composableBuilder(
    column: $table.server,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get loginName => $composableBuilder(
    column: $table.loginName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get certificateFingerprint => $composableBuilder(
    column: $table.certificateFingerprint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncNotBefore => $composableBuilder(
    column: $table.syncNotBefore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get credentialRef => $composableBuilder(
    column: $table.credentialRef,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get generation => $composableBuilder(
    column: $table.generation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get capabilities => $composableBuilder(
    column: $table.capabilities,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get contentEpoch => $composableBuilder(
    column: $table.contentEpoch,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get selected => $composableBuilder(
    column: $table.selected,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> storedBoardsRefs(
    Expression<bool> Function($$StoredBoardsTableFilterComposer f) f,
  ) {
    final $$StoredBoardsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.storedBoards,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoredBoardsTableFilterComposer(
            $db: $db,
            $table: $db.storedBoards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> storedStacksRefs(
    Expression<bool> Function($$StoredStacksTableFilterComposer f) f,
  ) {
    final $$StoredStacksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.storedStacks,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoredStacksTableFilterComposer(
            $db: $db,
            $table: $db.storedStacks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> storedCardsRefs(
    Expression<bool> Function($$StoredCardsTableFilterComposer f) f,
  ) {
    final $$StoredCardsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.storedCards,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoredCardsTableFilterComposer(
            $db: $db,
            $table: $db.storedCards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> syncCheckpointsRefs(
    Expression<bool> Function($$SyncCheckpointsTableFilterComposer f) f,
  ) {
    final $$SyncCheckpointsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.syncCheckpoints,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyncCheckpointsTableFilterComposer(
            $db: $db,
            $table: $db.syncCheckpoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> pendingWritesRefs(
    Expression<bool> Function($$PendingWritesTableFilterComposer f) f,
  ) {
    final $$PendingWritesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pendingWrites,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PendingWritesTableFilterComposer(
            $db: $db,
            $table: $db.pendingWrites,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> syncLeasesRefs(
    Expression<bool> Function($$SyncLeasesTableFilterComposer f) f,
  ) {
    final $$SyncLeasesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.syncLeases,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyncLeasesTableFilterComposer(
            $db: $db,
            $table: $db.syncLeases,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> editorDraftsRefs(
    Expression<bool> Function($$EditorDraftsTableFilterComposer f) f,
  ) {
    final $$EditorDraftsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.editorDrafts,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EditorDraftsTableFilterComposer(
            $db: $db,
            $table: $db.editorDrafts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> storedCommentsRefs(
    Expression<bool> Function($$StoredCommentsTableFilterComposer f) f,
  ) {
    final $$StoredCommentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.storedComments,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoredCommentsTableFilterComposer(
            $db: $db,
            $table: $db.storedComments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> storedAttachmentsRefs(
    Expression<bool> Function($$StoredAttachmentsTableFilterComposer f) f,
  ) {
    final $$StoredAttachmentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.storedAttachments,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoredAttachmentsTableFilterComposer(
            $db: $db,
            $table: $db.storedAttachments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$StoredAccountsTableOrderingComposer
    extends Composer<_$DeckDatabase, $StoredAccountsTable> {
  $$StoredAccountsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get server => $composableBuilder(
    column: $table.server,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get loginName => $composableBuilder(
    column: $table.loginName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get certificateFingerprint => $composableBuilder(
    column: $table.certificateFingerprint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncNotBefore => $composableBuilder(
    column: $table.syncNotBefore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get credentialRef => $composableBuilder(
    column: $table.credentialRef,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get generation => $composableBuilder(
    column: $table.generation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get capabilities => $composableBuilder(
    column: $table.capabilities,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get contentEpoch => $composableBuilder(
    column: $table.contentEpoch,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get selected => $composableBuilder(
    column: $table.selected,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StoredAccountsTableAnnotationComposer
    extends Composer<_$DeckDatabase, $StoredAccountsTable> {
  $$StoredAccountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get server =>
      $composableBuilder(column: $table.server, builder: (column) => column);

  GeneratedColumn<String> get loginName =>
      $composableBuilder(column: $table.loginName, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get certificateFingerprint => $composableBuilder(
    column: $table.certificateFingerprint,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get syncNotBefore => $composableBuilder(
    column: $table.syncNotBefore,
    builder: (column) => column,
  );

  GeneratedColumn<String> get credentialRef => $composableBuilder(
    column: $table.credentialRef,
    builder: (column) => column,
  );

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<int> get generation => $composableBuilder(
    column: $table.generation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get capabilities => $composableBuilder(
    column: $table.capabilities,
    builder: (column) => column,
  );

  GeneratedColumn<int> get contentEpoch => $composableBuilder(
    column: $table.contentEpoch,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get selected =>
      $composableBuilder(column: $table.selected, builder: (column) => column);

  Expression<T> storedBoardsRefs<T extends Object>(
    Expression<T> Function($$StoredBoardsTableAnnotationComposer a) f,
  ) {
    final $$StoredBoardsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.storedBoards,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoredBoardsTableAnnotationComposer(
            $db: $db,
            $table: $db.storedBoards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> storedStacksRefs<T extends Object>(
    Expression<T> Function($$StoredStacksTableAnnotationComposer a) f,
  ) {
    final $$StoredStacksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.storedStacks,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoredStacksTableAnnotationComposer(
            $db: $db,
            $table: $db.storedStacks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> storedCardsRefs<T extends Object>(
    Expression<T> Function($$StoredCardsTableAnnotationComposer a) f,
  ) {
    final $$StoredCardsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.storedCards,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoredCardsTableAnnotationComposer(
            $db: $db,
            $table: $db.storedCards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> syncCheckpointsRefs<T extends Object>(
    Expression<T> Function($$SyncCheckpointsTableAnnotationComposer a) f,
  ) {
    final $$SyncCheckpointsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.syncCheckpoints,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyncCheckpointsTableAnnotationComposer(
            $db: $db,
            $table: $db.syncCheckpoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> pendingWritesRefs<T extends Object>(
    Expression<T> Function($$PendingWritesTableAnnotationComposer a) f,
  ) {
    final $$PendingWritesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pendingWrites,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PendingWritesTableAnnotationComposer(
            $db: $db,
            $table: $db.pendingWrites,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> syncLeasesRefs<T extends Object>(
    Expression<T> Function($$SyncLeasesTableAnnotationComposer a) f,
  ) {
    final $$SyncLeasesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.syncLeases,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyncLeasesTableAnnotationComposer(
            $db: $db,
            $table: $db.syncLeases,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> editorDraftsRefs<T extends Object>(
    Expression<T> Function($$EditorDraftsTableAnnotationComposer a) f,
  ) {
    final $$EditorDraftsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.editorDrafts,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EditorDraftsTableAnnotationComposer(
            $db: $db,
            $table: $db.editorDrafts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> storedCommentsRefs<T extends Object>(
    Expression<T> Function($$StoredCommentsTableAnnotationComposer a) f,
  ) {
    final $$StoredCommentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.storedComments,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoredCommentsTableAnnotationComposer(
            $db: $db,
            $table: $db.storedComments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> storedAttachmentsRefs<T extends Object>(
    Expression<T> Function($$StoredAttachmentsTableAnnotationComposer a) f,
  ) {
    final $$StoredAttachmentsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.storedAttachments,
          getReferencedColumn: (t) => t.accountId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$StoredAttachmentsTableAnnotationComposer(
                $db: $db,
                $table: $db.storedAttachments,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$StoredAccountsTableTableManager
    extends
        RootTableManager<
          _$DeckDatabase,
          $StoredAccountsTable,
          StoredAccount,
          $$StoredAccountsTableFilterComposer,
          $$StoredAccountsTableOrderingComposer,
          $$StoredAccountsTableAnnotationComposer,
          $$StoredAccountsTableCreateCompanionBuilder,
          $$StoredAccountsTableUpdateCompanionBuilder,
          (StoredAccount, $$StoredAccountsTableReferences),
          StoredAccount,
          PrefetchHooks Function({
            bool storedBoardsRefs,
            bool storedStacksRefs,
            bool storedCardsRefs,
            bool syncCheckpointsRefs,
            bool pendingWritesRefs,
            bool syncLeasesRefs,
            bool editorDraftsRefs,
            bool storedCommentsRefs,
            bool storedAttachmentsRefs,
          })
        > {
  $$StoredAccountsTableTableManager(
    _$DeckDatabase db,
    $StoredAccountsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StoredAccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StoredAccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StoredAccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> server = const Value.absent(),
                Value<String> loginName = const Value.absent(),
                Value<String?> userId = const Value.absent(),
                Value<String?> certificateFingerprint = const Value.absent(),
                Value<DateTime?> syncNotBefore = const Value.absent(),
                Value<String> credentialRef = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<int> generation = const Value.absent(),
                Value<String?> capabilities = const Value.absent(),
                Value<int> contentEpoch = const Value.absent(),
                Value<bool> selected = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StoredAccountsCompanion(
                id: id,
                server: server,
                loginName: loginName,
                userId: userId,
                certificateFingerprint: certificateFingerprint,
                syncNotBefore: syncNotBefore,
                credentialRef: credentialRef,
                state: state,
                generation: generation,
                capabilities: capabilities,
                contentEpoch: contentEpoch,
                selected: selected,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String server,
                required String loginName,
                Value<String?> userId = const Value.absent(),
                Value<String?> certificateFingerprint = const Value.absent(),
                Value<DateTime?> syncNotBefore = const Value.absent(),
                required String credentialRef,
                Value<String> state = const Value.absent(),
                Value<int> generation = const Value.absent(),
                Value<String?> capabilities = const Value.absent(),
                Value<int> contentEpoch = const Value.absent(),
                Value<bool> selected = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StoredAccountsCompanion.insert(
                id: id,
                server: server,
                loginName: loginName,
                userId: userId,
                certificateFingerprint: certificateFingerprint,
                syncNotBefore: syncNotBefore,
                credentialRef: credentialRef,
                state: state,
                generation: generation,
                capabilities: capabilities,
                contentEpoch: contentEpoch,
                selected: selected,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$StoredAccountsTable, StoredAccount>(table),
                  $$StoredAccountsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                storedBoardsRefs = false,
                storedStacksRefs = false,
                storedCardsRefs = false,
                syncCheckpointsRefs = false,
                pendingWritesRefs = false,
                syncLeasesRefs = false,
                editorDraftsRefs = false,
                storedCommentsRefs = false,
                storedAttachmentsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (storedBoardsRefs) db.storedBoards,
                    if (storedStacksRefs) db.storedStacks,
                    if (storedCardsRefs) db.storedCards,
                    if (syncCheckpointsRefs) db.syncCheckpoints,
                    if (pendingWritesRefs) db.pendingWrites,
                    if (syncLeasesRefs) db.syncLeases,
                    if (editorDraftsRefs) db.editorDrafts,
                    if (storedCommentsRefs) db.storedComments,
                    if (storedAttachmentsRefs) db.storedAttachments,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (storedBoardsRefs)
                        await $_getPrefetchedDataByColumns<
                          StoredAccount,
                          $StoredAccountsTable,
                          StoredBoard,
                          $StoredBoardsTable
                        >(
                          currentTable: table,
                          referencedTable: $$StoredAccountsTableReferences
                              ._storedBoardsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$StoredAccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).storedBoardsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'account_id',
                          typedResults: items,
                        ),
                      if (storedStacksRefs)
                        await $_getPrefetchedDataByColumns<
                          StoredAccount,
                          $StoredAccountsTable,
                          StoredStack,
                          $StoredStacksTable
                        >(
                          currentTable: table,
                          referencedTable: $$StoredAccountsTableReferences
                              ._storedStacksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$StoredAccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).storedStacksRefs,
                          currentColumn: 'id',
                          referencedColumn: 'account_id',
                          typedResults: items,
                        ),
                      if (storedCardsRefs)
                        await $_getPrefetchedDataByColumns<
                          StoredAccount,
                          $StoredAccountsTable,
                          StoredCard,
                          $StoredCardsTable
                        >(
                          currentTable: table,
                          referencedTable: $$StoredAccountsTableReferences
                              ._storedCardsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$StoredAccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).storedCardsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'account_id',
                          typedResults: items,
                        ),
                      if (syncCheckpointsRefs)
                        await $_getPrefetchedDataByColumns<
                          StoredAccount,
                          $StoredAccountsTable,
                          SyncCheckpoint,
                          $SyncCheckpointsTable
                        >(
                          currentTable: table,
                          referencedTable: $$StoredAccountsTableReferences
                              ._syncCheckpointsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$StoredAccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).syncCheckpointsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'account_id',
                          typedResults: items,
                        ),
                      if (pendingWritesRefs)
                        await $_getPrefetchedDataByColumns<
                          StoredAccount,
                          $StoredAccountsTable,
                          PendingWrite,
                          $PendingWritesTable
                        >(
                          currentTable: table,
                          referencedTable: $$StoredAccountsTableReferences
                              ._pendingWritesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$StoredAccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).pendingWritesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'account_id',
                          typedResults: items,
                        ),
                      if (syncLeasesRefs)
                        await $_getPrefetchedDataByColumns<
                          StoredAccount,
                          $StoredAccountsTable,
                          SyncLease,
                          $SyncLeasesTable
                        >(
                          currentTable: table,
                          referencedTable: $$StoredAccountsTableReferences
                              ._syncLeasesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$StoredAccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).syncLeasesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'account_id',
                          typedResults: items,
                        ),
                      if (editorDraftsRefs)
                        await $_getPrefetchedDataByColumns<
                          StoredAccount,
                          $StoredAccountsTable,
                          EditorDraft,
                          $EditorDraftsTable
                        >(
                          currentTable: table,
                          referencedTable: $$StoredAccountsTableReferences
                              ._editorDraftsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$StoredAccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).editorDraftsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'account_id',
                          typedResults: items,
                        ),
                      if (storedCommentsRefs)
                        await $_getPrefetchedDataByColumns<
                          StoredAccount,
                          $StoredAccountsTable,
                          StoredComment,
                          $StoredCommentsTable
                        >(
                          currentTable: table,
                          referencedTable: $$StoredAccountsTableReferences
                              ._storedCommentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$StoredAccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).storedCommentsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'account_id',
                          typedResults: items,
                        ),
                      if (storedAttachmentsRefs)
                        await $_getPrefetchedDataByColumns<
                          StoredAccount,
                          $StoredAccountsTable,
                          StoredAttachment,
                          $StoredAttachmentsTable
                        >(
                          currentTable: table,
                          referencedTable: $$StoredAccountsTableReferences
                              ._storedAttachmentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$StoredAccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).storedAttachmentsRefs,
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

typedef $$StoredAccountsTableProcessedTableManager =
    ProcessedTableManager<
      _$DeckDatabase,
      $StoredAccountsTable,
      StoredAccount,
      $$StoredAccountsTableFilterComposer,
      $$StoredAccountsTableOrderingComposer,
      $$StoredAccountsTableAnnotationComposer,
      $$StoredAccountsTableCreateCompanionBuilder,
      $$StoredAccountsTableUpdateCompanionBuilder,
      (StoredAccount, $$StoredAccountsTableReferences),
      StoredAccount,
      PrefetchHooks Function({
        bool storedBoardsRefs,
        bool storedStacksRefs,
        bool storedCardsRefs,
        bool syncCheckpointsRefs,
        bool pendingWritesRefs,
        bool syncLeasesRefs,
        bool editorDraftsRefs,
        bool storedCommentsRefs,
        bool storedAttachmentsRefs,
      })
    >;
typedef $$StoredBoardsTableCreateCompanionBuilder =
    StoredBoardsCompanion Function({
      required String accountId,
      required int remoteId,
      required String payload,
      Value<int> rowid,
    });
typedef $$StoredBoardsTableUpdateCompanionBuilder =
    StoredBoardsCompanion Function({
      Value<String> accountId,
      Value<int> remoteId,
      Value<String> payload,
      Value<int> rowid,
    });

final class $$StoredBoardsTableReferences
    extends BaseReferences<_$DeckDatabase, $StoredBoardsTable, StoredBoard> {
  $$StoredBoardsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $StoredAccountsTable _accountIdTable(_$DeckDatabase db) => db
      .storedAccounts
      .createAlias('stored_boards__account_id__stored_accounts__id');

  $$StoredAccountsTableProcessedTableManager get accountId {
    final $_column = $_itemColumn<String>('account_id')!;

    final manager = $$StoredAccountsTableTableManager(
      $_db,
      $_db.storedAccounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$StoredBoardsTableFilterComposer
    extends Composer<_$DeckDatabase, $StoredBoardsTable> {
  $$StoredBoardsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  $$StoredAccountsTableFilterComposer get accountId {
    final $$StoredAccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.storedAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoredAccountsTableFilterComposer(
            $db: $db,
            $table: $db.storedAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StoredBoardsTableOrderingComposer
    extends Composer<_$DeckDatabase, $StoredBoardsTable> {
  $$StoredBoardsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  $$StoredAccountsTableOrderingComposer get accountId {
    final $$StoredAccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.storedAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoredAccountsTableOrderingComposer(
            $db: $db,
            $table: $db.storedAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StoredBoardsTableAnnotationComposer
    extends Composer<_$DeckDatabase, $StoredBoardsTable> {
  $$StoredBoardsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  $$StoredAccountsTableAnnotationComposer get accountId {
    final $$StoredAccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.storedAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoredAccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.storedAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StoredBoardsTableTableManager
    extends
        RootTableManager<
          _$DeckDatabase,
          $StoredBoardsTable,
          StoredBoard,
          $$StoredBoardsTableFilterComposer,
          $$StoredBoardsTableOrderingComposer,
          $$StoredBoardsTableAnnotationComposer,
          $$StoredBoardsTableCreateCompanionBuilder,
          $$StoredBoardsTableUpdateCompanionBuilder,
          (StoredBoard, $$StoredBoardsTableReferences),
          StoredBoard,
          PrefetchHooks Function({bool accountId})
        > {
  $$StoredBoardsTableTableManager(_$DeckDatabase db, $StoredBoardsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StoredBoardsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StoredBoardsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StoredBoardsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> accountId = const Value.absent(),
                Value<int> remoteId = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StoredBoardsCompanion(
                accountId: accountId,
                remoteId: remoteId,
                payload: payload,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String accountId,
                required int remoteId,
                required String payload,
                Value<int> rowid = const Value.absent(),
              }) => StoredBoardsCompanion.insert(
                accountId: accountId,
                remoteId: remoteId,
                payload: payload,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$StoredBoardsTable, StoredBoard>(table),
                  $$StoredBoardsTableReferences(db, table, e),
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
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.accountId,
                                referencedTable: $$StoredBoardsTableReferences
                                    ._accountIdTable(db),
                                referencedColumn: $$StoredBoardsTableReferences
                                    ._accountIdTable(db)
                                    .id,
                              )
                              as T;
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

typedef $$StoredBoardsTableProcessedTableManager =
    ProcessedTableManager<
      _$DeckDatabase,
      $StoredBoardsTable,
      StoredBoard,
      $$StoredBoardsTableFilterComposer,
      $$StoredBoardsTableOrderingComposer,
      $$StoredBoardsTableAnnotationComposer,
      $$StoredBoardsTableCreateCompanionBuilder,
      $$StoredBoardsTableUpdateCompanionBuilder,
      (StoredBoard, $$StoredBoardsTableReferences),
      StoredBoard,
      PrefetchHooks Function({bool accountId})
    >;
typedef $$StoredStacksTableCreateCompanionBuilder =
    StoredStacksCompanion Function({
      required String accountId,
      required int remoteId,
      required int boardId,
      required int position,
      required String payload,
      Value<int> rowid,
    });
typedef $$StoredStacksTableUpdateCompanionBuilder =
    StoredStacksCompanion Function({
      Value<String> accountId,
      Value<int> remoteId,
      Value<int> boardId,
      Value<int> position,
      Value<String> payload,
      Value<int> rowid,
    });

final class $$StoredStacksTableReferences
    extends BaseReferences<_$DeckDatabase, $StoredStacksTable, StoredStack> {
  $$StoredStacksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $StoredAccountsTable _accountIdTable(_$DeckDatabase db) => db
      .storedAccounts
      .createAlias('stored_stacks__account_id__stored_accounts__id');

  $$StoredAccountsTableProcessedTableManager get accountId {
    final $_column = $_itemColumn<String>('account_id')!;

    final manager = $$StoredAccountsTableTableManager(
      $_db,
      $_db.storedAccounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$StoredStacksTableFilterComposer
    extends Composer<_$DeckDatabase, $StoredStacksTable> {
  $$StoredStacksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get boardId => $composableBuilder(
    column: $table.boardId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  $$StoredAccountsTableFilterComposer get accountId {
    final $$StoredAccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.storedAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoredAccountsTableFilterComposer(
            $db: $db,
            $table: $db.storedAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StoredStacksTableOrderingComposer
    extends Composer<_$DeckDatabase, $StoredStacksTable> {
  $$StoredStacksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get boardId => $composableBuilder(
    column: $table.boardId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  $$StoredAccountsTableOrderingComposer get accountId {
    final $$StoredAccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.storedAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoredAccountsTableOrderingComposer(
            $db: $db,
            $table: $db.storedAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StoredStacksTableAnnotationComposer
    extends Composer<_$DeckDatabase, $StoredStacksTable> {
  $$StoredStacksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<int> get boardId =>
      $composableBuilder(column: $table.boardId, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  $$StoredAccountsTableAnnotationComposer get accountId {
    final $$StoredAccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.storedAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoredAccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.storedAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StoredStacksTableTableManager
    extends
        RootTableManager<
          _$DeckDatabase,
          $StoredStacksTable,
          StoredStack,
          $$StoredStacksTableFilterComposer,
          $$StoredStacksTableOrderingComposer,
          $$StoredStacksTableAnnotationComposer,
          $$StoredStacksTableCreateCompanionBuilder,
          $$StoredStacksTableUpdateCompanionBuilder,
          (StoredStack, $$StoredStacksTableReferences),
          StoredStack,
          PrefetchHooks Function({bool accountId})
        > {
  $$StoredStacksTableTableManager(_$DeckDatabase db, $StoredStacksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StoredStacksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StoredStacksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StoredStacksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> accountId = const Value.absent(),
                Value<int> remoteId = const Value.absent(),
                Value<int> boardId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StoredStacksCompanion(
                accountId: accountId,
                remoteId: remoteId,
                boardId: boardId,
                position: position,
                payload: payload,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String accountId,
                required int remoteId,
                required int boardId,
                required int position,
                required String payload,
                Value<int> rowid = const Value.absent(),
              }) => StoredStacksCompanion.insert(
                accountId: accountId,
                remoteId: remoteId,
                boardId: boardId,
                position: position,
                payload: payload,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$StoredStacksTable, StoredStack>(table),
                  $$StoredStacksTableReferences(db, table, e),
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
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.accountId,
                                referencedTable: $$StoredStacksTableReferences
                                    ._accountIdTable(db),
                                referencedColumn: $$StoredStacksTableReferences
                                    ._accountIdTable(db)
                                    .id,
                              )
                              as T;
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

typedef $$StoredStacksTableProcessedTableManager =
    ProcessedTableManager<
      _$DeckDatabase,
      $StoredStacksTable,
      StoredStack,
      $$StoredStacksTableFilterComposer,
      $$StoredStacksTableOrderingComposer,
      $$StoredStacksTableAnnotationComposer,
      $$StoredStacksTableCreateCompanionBuilder,
      $$StoredStacksTableUpdateCompanionBuilder,
      (StoredStack, $$StoredStacksTableReferences),
      StoredStack,
      PrefetchHooks Function({bool accountId})
    >;
typedef $$StoredCardsTableCreateCompanionBuilder =
    StoredCardsCompanion Function({
      required String accountId,
      required int remoteId,
      required int boardId,
      required int stackId,
      required int position,
      required String payload,
      Value<int> rowid,
    });
typedef $$StoredCardsTableUpdateCompanionBuilder =
    StoredCardsCompanion Function({
      Value<String> accountId,
      Value<int> remoteId,
      Value<int> boardId,
      Value<int> stackId,
      Value<int> position,
      Value<String> payload,
      Value<int> rowid,
    });

final class $$StoredCardsTableReferences
    extends BaseReferences<_$DeckDatabase, $StoredCardsTable, StoredCard> {
  $$StoredCardsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $StoredAccountsTable _accountIdTable(_$DeckDatabase db) => db
      .storedAccounts
      .createAlias('stored_cards__account_id__stored_accounts__id');

  $$StoredAccountsTableProcessedTableManager get accountId {
    final $_column = $_itemColumn<String>('account_id')!;

    final manager = $$StoredAccountsTableTableManager(
      $_db,
      $_db.storedAccounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$StoredCardsTableFilterComposer
    extends Composer<_$DeckDatabase, $StoredCardsTable> {
  $$StoredCardsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get boardId => $composableBuilder(
    column: $table.boardId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stackId => $composableBuilder(
    column: $table.stackId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  $$StoredAccountsTableFilterComposer get accountId {
    final $$StoredAccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.storedAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoredAccountsTableFilterComposer(
            $db: $db,
            $table: $db.storedAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StoredCardsTableOrderingComposer
    extends Composer<_$DeckDatabase, $StoredCardsTable> {
  $$StoredCardsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get boardId => $composableBuilder(
    column: $table.boardId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stackId => $composableBuilder(
    column: $table.stackId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  $$StoredAccountsTableOrderingComposer get accountId {
    final $$StoredAccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.storedAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoredAccountsTableOrderingComposer(
            $db: $db,
            $table: $db.storedAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StoredCardsTableAnnotationComposer
    extends Composer<_$DeckDatabase, $StoredCardsTable> {
  $$StoredCardsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<int> get boardId =>
      $composableBuilder(column: $table.boardId, builder: (column) => column);

  GeneratedColumn<int> get stackId =>
      $composableBuilder(column: $table.stackId, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  $$StoredAccountsTableAnnotationComposer get accountId {
    final $$StoredAccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.storedAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoredAccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.storedAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StoredCardsTableTableManager
    extends
        RootTableManager<
          _$DeckDatabase,
          $StoredCardsTable,
          StoredCard,
          $$StoredCardsTableFilterComposer,
          $$StoredCardsTableOrderingComposer,
          $$StoredCardsTableAnnotationComposer,
          $$StoredCardsTableCreateCompanionBuilder,
          $$StoredCardsTableUpdateCompanionBuilder,
          (StoredCard, $$StoredCardsTableReferences),
          StoredCard,
          PrefetchHooks Function({bool accountId})
        > {
  $$StoredCardsTableTableManager(_$DeckDatabase db, $StoredCardsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StoredCardsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StoredCardsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StoredCardsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> accountId = const Value.absent(),
                Value<int> remoteId = const Value.absent(),
                Value<int> boardId = const Value.absent(),
                Value<int> stackId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StoredCardsCompanion(
                accountId: accountId,
                remoteId: remoteId,
                boardId: boardId,
                stackId: stackId,
                position: position,
                payload: payload,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String accountId,
                required int remoteId,
                required int boardId,
                required int stackId,
                required int position,
                required String payload,
                Value<int> rowid = const Value.absent(),
              }) => StoredCardsCompanion.insert(
                accountId: accountId,
                remoteId: remoteId,
                boardId: boardId,
                stackId: stackId,
                position: position,
                payload: payload,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$StoredCardsTable, StoredCard>(table),
                  $$StoredCardsTableReferences(db, table, e),
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
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.accountId,
                                referencedTable: $$StoredCardsTableReferences
                                    ._accountIdTable(db),
                                referencedColumn: $$StoredCardsTableReferences
                                    ._accountIdTable(db)
                                    .id,
                              )
                              as T;
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

typedef $$StoredCardsTableProcessedTableManager =
    ProcessedTableManager<
      _$DeckDatabase,
      $StoredCardsTable,
      StoredCard,
      $$StoredCardsTableFilterComposer,
      $$StoredCardsTableOrderingComposer,
      $$StoredCardsTableAnnotationComposer,
      $$StoredCardsTableCreateCompanionBuilder,
      $$StoredCardsTableUpdateCompanionBuilder,
      (StoredCard, $$StoredCardsTableReferences),
      StoredCard,
      PrefetchHooks Function({bool accountId})
    >;
typedef $$SyncCheckpointsTableCreateCompanionBuilder =
    SyncCheckpointsCompanion Function({
      required String accountId,
      required String scope,
      Value<String?> etag,
      required DateTime fetchedAt,
      Value<int> rowid,
    });
typedef $$SyncCheckpointsTableUpdateCompanionBuilder =
    SyncCheckpointsCompanion Function({
      Value<String> accountId,
      Value<String> scope,
      Value<String?> etag,
      Value<DateTime> fetchedAt,
      Value<int> rowid,
    });

final class $$SyncCheckpointsTableReferences
    extends
        BaseReferences<_$DeckDatabase, $SyncCheckpointsTable, SyncCheckpoint> {
  $$SyncCheckpointsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $StoredAccountsTable _accountIdTable(_$DeckDatabase db) => db
      .storedAccounts
      .createAlias('sync_checkpoints__account_id__stored_accounts__id');

  $$StoredAccountsTableProcessedTableManager get accountId {
    final $_column = $_itemColumn<String>('account_id')!;

    final manager = $$StoredAccountsTableTableManager(
      $_db,
      $_db.storedAccounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SyncCheckpointsTableFilterComposer
    extends Composer<_$DeckDatabase, $SyncCheckpointsTable> {
  $$SyncCheckpointsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get scope => $composableBuilder(
    column: $table.scope,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get etag => $composableBuilder(
    column: $table.etag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$StoredAccountsTableFilterComposer get accountId {
    final $$StoredAccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.storedAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoredAccountsTableFilterComposer(
            $db: $db,
            $table: $db.storedAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SyncCheckpointsTableOrderingComposer
    extends Composer<_$DeckDatabase, $SyncCheckpointsTable> {
  $$SyncCheckpointsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get scope => $composableBuilder(
    column: $table.scope,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get etag => $composableBuilder(
    column: $table.etag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$StoredAccountsTableOrderingComposer get accountId {
    final $$StoredAccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.storedAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoredAccountsTableOrderingComposer(
            $db: $db,
            $table: $db.storedAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SyncCheckpointsTableAnnotationComposer
    extends Composer<_$DeckDatabase, $SyncCheckpointsTable> {
  $$SyncCheckpointsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get scope =>
      $composableBuilder(column: $table.scope, builder: (column) => column);

  GeneratedColumn<String> get etag =>
      $composableBuilder(column: $table.etag, builder: (column) => column);

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);

  $$StoredAccountsTableAnnotationComposer get accountId {
    final $$StoredAccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.storedAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoredAccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.storedAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SyncCheckpointsTableTableManager
    extends
        RootTableManager<
          _$DeckDatabase,
          $SyncCheckpointsTable,
          SyncCheckpoint,
          $$SyncCheckpointsTableFilterComposer,
          $$SyncCheckpointsTableOrderingComposer,
          $$SyncCheckpointsTableAnnotationComposer,
          $$SyncCheckpointsTableCreateCompanionBuilder,
          $$SyncCheckpointsTableUpdateCompanionBuilder,
          (SyncCheckpoint, $$SyncCheckpointsTableReferences),
          SyncCheckpoint,
          PrefetchHooks Function({bool accountId})
        > {
  $$SyncCheckpointsTableTableManager(
    _$DeckDatabase db,
    $SyncCheckpointsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncCheckpointsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncCheckpointsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncCheckpointsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> accountId = const Value.absent(),
                Value<String> scope = const Value.absent(),
                Value<String?> etag = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncCheckpointsCompanion(
                accountId: accountId,
                scope: scope,
                etag: etag,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String accountId,
                required String scope,
                Value<String?> etag = const Value.absent(),
                required DateTime fetchedAt,
                Value<int> rowid = const Value.absent(),
              }) => SyncCheckpointsCompanion.insert(
                accountId: accountId,
                scope: scope,
                etag: etag,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncCheckpointsTable, SyncCheckpoint>(table),
                  $$SyncCheckpointsTableReferences(db, table, e),
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
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.accountId,
                                referencedTable:
                                    $$SyncCheckpointsTableReferences
                                        ._accountIdTable(db),
                                referencedColumn:
                                    $$SyncCheckpointsTableReferences
                                        ._accountIdTable(db)
                                        .id,
                              )
                              as T;
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

typedef $$SyncCheckpointsTableProcessedTableManager =
    ProcessedTableManager<
      _$DeckDatabase,
      $SyncCheckpointsTable,
      SyncCheckpoint,
      $$SyncCheckpointsTableFilterComposer,
      $$SyncCheckpointsTableOrderingComposer,
      $$SyncCheckpointsTableAnnotationComposer,
      $$SyncCheckpointsTableCreateCompanionBuilder,
      $$SyncCheckpointsTableUpdateCompanionBuilder,
      (SyncCheckpoint, $$SyncCheckpointsTableReferences),
      SyncCheckpoint,
      PrefetchHooks Function({bool accountId})
    >;
typedef $$PendingWritesTableCreateCompanionBuilder =
    PendingWritesCompanion Function({
      Value<int> sequence,
      required String id,
      required String accountId,
      required String kind,
      required int boardId,
      required int stackId,
      Value<int?> cardId,
      required String proposal,
      Value<String?> base,
      Value<String?> remote,
      Value<String> state,
      Value<String?> error,
    });
typedef $$PendingWritesTableUpdateCompanionBuilder =
    PendingWritesCompanion Function({
      Value<int> sequence,
      Value<String> id,
      Value<String> accountId,
      Value<String> kind,
      Value<int> boardId,
      Value<int> stackId,
      Value<int?> cardId,
      Value<String> proposal,
      Value<String?> base,
      Value<String?> remote,
      Value<String> state,
      Value<String?> error,
    });

final class $$PendingWritesTableReferences
    extends BaseReferences<_$DeckDatabase, $PendingWritesTable, PendingWrite> {
  $$PendingWritesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $StoredAccountsTable _accountIdTable(_$DeckDatabase db) => db
      .storedAccounts
      .createAlias('pending_writes__account_id__stored_accounts__id');

  $$StoredAccountsTableProcessedTableManager get accountId {
    final $_column = $_itemColumn<String>('account_id')!;

    final manager = $$StoredAccountsTableTableManager(
      $_db,
      $_db.storedAccounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PendingWritesTableFilterComposer
    extends Composer<_$DeckDatabase, $PendingWritesTable> {
  $$PendingWritesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get sequence => $composableBuilder(
    column: $table.sequence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get boardId => $composableBuilder(
    column: $table.boardId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stackId => $composableBuilder(
    column: $table.stackId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cardId => $composableBuilder(
    column: $table.cardId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get proposal => $composableBuilder(
    column: $table.proposal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get base => $composableBuilder(
    column: $table.base,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remote => $composableBuilder(
    column: $table.remote,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get error => $composableBuilder(
    column: $table.error,
    builder: (column) => ColumnFilters(column),
  );

  $$StoredAccountsTableFilterComposer get accountId {
    final $$StoredAccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.storedAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoredAccountsTableFilterComposer(
            $db: $db,
            $table: $db.storedAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PendingWritesTableOrderingComposer
    extends Composer<_$DeckDatabase, $PendingWritesTable> {
  $$PendingWritesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get sequence => $composableBuilder(
    column: $table.sequence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get boardId => $composableBuilder(
    column: $table.boardId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stackId => $composableBuilder(
    column: $table.stackId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cardId => $composableBuilder(
    column: $table.cardId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get proposal => $composableBuilder(
    column: $table.proposal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get base => $composableBuilder(
    column: $table.base,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remote => $composableBuilder(
    column: $table.remote,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get error => $composableBuilder(
    column: $table.error,
    builder: (column) => ColumnOrderings(column),
  );

  $$StoredAccountsTableOrderingComposer get accountId {
    final $$StoredAccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.storedAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoredAccountsTableOrderingComposer(
            $db: $db,
            $table: $db.storedAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PendingWritesTableAnnotationComposer
    extends Composer<_$DeckDatabase, $PendingWritesTable> {
  $$PendingWritesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get sequence =>
      $composableBuilder(column: $table.sequence, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get boardId =>
      $composableBuilder(column: $table.boardId, builder: (column) => column);

  GeneratedColumn<int> get stackId =>
      $composableBuilder(column: $table.stackId, builder: (column) => column);

  GeneratedColumn<int> get cardId =>
      $composableBuilder(column: $table.cardId, builder: (column) => column);

  GeneratedColumn<String> get proposal =>
      $composableBuilder(column: $table.proposal, builder: (column) => column);

  GeneratedColumn<String> get base =>
      $composableBuilder(column: $table.base, builder: (column) => column);

  GeneratedColumn<String> get remote =>
      $composableBuilder(column: $table.remote, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<String> get error =>
      $composableBuilder(column: $table.error, builder: (column) => column);

  $$StoredAccountsTableAnnotationComposer get accountId {
    final $$StoredAccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.storedAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoredAccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.storedAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PendingWritesTableTableManager
    extends
        RootTableManager<
          _$DeckDatabase,
          $PendingWritesTable,
          PendingWrite,
          $$PendingWritesTableFilterComposer,
          $$PendingWritesTableOrderingComposer,
          $$PendingWritesTableAnnotationComposer,
          $$PendingWritesTableCreateCompanionBuilder,
          $$PendingWritesTableUpdateCompanionBuilder,
          (PendingWrite, $$PendingWritesTableReferences),
          PendingWrite,
          PrefetchHooks Function({bool accountId})
        > {
  $$PendingWritesTableTableManager(_$DeckDatabase db, $PendingWritesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingWritesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingWritesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingWritesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> sequence = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<int> boardId = const Value.absent(),
                Value<int> stackId = const Value.absent(),
                Value<int?> cardId = const Value.absent(),
                Value<String> proposal = const Value.absent(),
                Value<String?> base = const Value.absent(),
                Value<String?> remote = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<String?> error = const Value.absent(),
              }) => PendingWritesCompanion(
                sequence: sequence,
                id: id,
                accountId: accountId,
                kind: kind,
                boardId: boardId,
                stackId: stackId,
                cardId: cardId,
                proposal: proposal,
                base: base,
                remote: remote,
                state: state,
                error: error,
              ),
          createCompanionCallback:
              ({
                Value<int> sequence = const Value.absent(),
                required String id,
                required String accountId,
                required String kind,
                required int boardId,
                required int stackId,
                Value<int?> cardId = const Value.absent(),
                required String proposal,
                Value<String?> base = const Value.absent(),
                Value<String?> remote = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<String?> error = const Value.absent(),
              }) => PendingWritesCompanion.insert(
                sequence: sequence,
                id: id,
                accountId: accountId,
                kind: kind,
                boardId: boardId,
                stackId: stackId,
                cardId: cardId,
                proposal: proposal,
                base: base,
                remote: remote,
                state: state,
                error: error,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PendingWritesTable, PendingWrite>(table),
                  $$PendingWritesTableReferences(db, table, e),
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
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.accountId,
                                referencedTable: $$PendingWritesTableReferences
                                    ._accountIdTable(db),
                                referencedColumn: $$PendingWritesTableReferences
                                    ._accountIdTable(db)
                                    .id,
                              )
                              as T;
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

typedef $$PendingWritesTableProcessedTableManager =
    ProcessedTableManager<
      _$DeckDatabase,
      $PendingWritesTable,
      PendingWrite,
      $$PendingWritesTableFilterComposer,
      $$PendingWritesTableOrderingComposer,
      $$PendingWritesTableAnnotationComposer,
      $$PendingWritesTableCreateCompanionBuilder,
      $$PendingWritesTableUpdateCompanionBuilder,
      (PendingWrite, $$PendingWritesTableReferences),
      PendingWrite,
      PrefetchHooks Function({bool accountId})
    >;
typedef $$SyncLeasesTableCreateCompanionBuilder =
    SyncLeasesCompanion Function({
      required String accountId,
      required String owner,
      required DateTime expires,
      Value<int> rowid,
    });
typedef $$SyncLeasesTableUpdateCompanionBuilder =
    SyncLeasesCompanion Function({
      Value<String> accountId,
      Value<String> owner,
      Value<DateTime> expires,
      Value<int> rowid,
    });

final class $$SyncLeasesTableReferences
    extends BaseReferences<_$DeckDatabase, $SyncLeasesTable, SyncLease> {
  $$SyncLeasesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $StoredAccountsTable _accountIdTable(_$DeckDatabase db) => db
      .storedAccounts
      .createAlias('sync_leases__account_id__stored_accounts__id');

  $$StoredAccountsTableProcessedTableManager get accountId {
    final $_column = $_itemColumn<String>('account_id')!;

    final manager = $$StoredAccountsTableTableManager(
      $_db,
      $_db.storedAccounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SyncLeasesTableFilterComposer
    extends Composer<_$DeckDatabase, $SyncLeasesTable> {
  $$SyncLeasesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get owner => $composableBuilder(
    column: $table.owner,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expires => $composableBuilder(
    column: $table.expires,
    builder: (column) => ColumnFilters(column),
  );

  $$StoredAccountsTableFilterComposer get accountId {
    final $$StoredAccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.storedAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoredAccountsTableFilterComposer(
            $db: $db,
            $table: $db.storedAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SyncLeasesTableOrderingComposer
    extends Composer<_$DeckDatabase, $SyncLeasesTable> {
  $$SyncLeasesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get owner => $composableBuilder(
    column: $table.owner,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expires => $composableBuilder(
    column: $table.expires,
    builder: (column) => ColumnOrderings(column),
  );

  $$StoredAccountsTableOrderingComposer get accountId {
    final $$StoredAccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.storedAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoredAccountsTableOrderingComposer(
            $db: $db,
            $table: $db.storedAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SyncLeasesTableAnnotationComposer
    extends Composer<_$DeckDatabase, $SyncLeasesTable> {
  $$SyncLeasesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get owner =>
      $composableBuilder(column: $table.owner, builder: (column) => column);

  GeneratedColumn<DateTime> get expires =>
      $composableBuilder(column: $table.expires, builder: (column) => column);

  $$StoredAccountsTableAnnotationComposer get accountId {
    final $$StoredAccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.storedAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoredAccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.storedAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SyncLeasesTableTableManager
    extends
        RootTableManager<
          _$DeckDatabase,
          $SyncLeasesTable,
          SyncLease,
          $$SyncLeasesTableFilterComposer,
          $$SyncLeasesTableOrderingComposer,
          $$SyncLeasesTableAnnotationComposer,
          $$SyncLeasesTableCreateCompanionBuilder,
          $$SyncLeasesTableUpdateCompanionBuilder,
          (SyncLease, $$SyncLeasesTableReferences),
          SyncLease,
          PrefetchHooks Function({bool accountId})
        > {
  $$SyncLeasesTableTableManager(_$DeckDatabase db, $SyncLeasesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncLeasesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncLeasesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncLeasesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> accountId = const Value.absent(),
                Value<String> owner = const Value.absent(),
                Value<DateTime> expires = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncLeasesCompanion(
                accountId: accountId,
                owner: owner,
                expires: expires,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String accountId,
                required String owner,
                required DateTime expires,
                Value<int> rowid = const Value.absent(),
              }) => SyncLeasesCompanion.insert(
                accountId: accountId,
                owner: owner,
                expires: expires,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncLeasesTable, SyncLease>(table),
                  $$SyncLeasesTableReferences(db, table, e),
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
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.accountId,
                                referencedTable: $$SyncLeasesTableReferences
                                    ._accountIdTable(db),
                                referencedColumn: $$SyncLeasesTableReferences
                                    ._accountIdTable(db)
                                    .id,
                              )
                              as T;
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

typedef $$SyncLeasesTableProcessedTableManager =
    ProcessedTableManager<
      _$DeckDatabase,
      $SyncLeasesTable,
      SyncLease,
      $$SyncLeasesTableFilterComposer,
      $$SyncLeasesTableOrderingComposer,
      $$SyncLeasesTableAnnotationComposer,
      $$SyncLeasesTableCreateCompanionBuilder,
      $$SyncLeasesTableUpdateCompanionBuilder,
      (SyncLease, $$SyncLeasesTableReferences),
      SyncLease,
      PrefetchHooks Function({bool accountId})
    >;
typedef $$EditorDraftsTableCreateCompanionBuilder =
    EditorDraftsCompanion Function({
      Value<String> kind,
      required String accountId,
      required String draftKey,
      required int boardId,
      required int stackId,
      Value<int?> cardId,
      required String payload,
      Value<String?> base,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$EditorDraftsTableUpdateCompanionBuilder =
    EditorDraftsCompanion Function({
      Value<String> kind,
      Value<String> accountId,
      Value<String> draftKey,
      Value<int> boardId,
      Value<int> stackId,
      Value<int?> cardId,
      Value<String> payload,
      Value<String?> base,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$EditorDraftsTableReferences
    extends BaseReferences<_$DeckDatabase, $EditorDraftsTable, EditorDraft> {
  $$EditorDraftsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $StoredAccountsTable _accountIdTable(_$DeckDatabase db) => db
      .storedAccounts
      .createAlias('editor_drafts__account_id__stored_accounts__id');

  $$StoredAccountsTableProcessedTableManager get accountId {
    final $_column = $_itemColumn<String>('account_id')!;

    final manager = $$StoredAccountsTableTableManager(
      $_db,
      $_db.storedAccounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$EditorDraftsTableFilterComposer
    extends Composer<_$DeckDatabase, $EditorDraftsTable> {
  $$EditorDraftsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get draftKey => $composableBuilder(
    column: $table.draftKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get boardId => $composableBuilder(
    column: $table.boardId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stackId => $composableBuilder(
    column: $table.stackId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cardId => $composableBuilder(
    column: $table.cardId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get base => $composableBuilder(
    column: $table.base,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$StoredAccountsTableFilterComposer get accountId {
    final $$StoredAccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.storedAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoredAccountsTableFilterComposer(
            $db: $db,
            $table: $db.storedAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EditorDraftsTableOrderingComposer
    extends Composer<_$DeckDatabase, $EditorDraftsTable> {
  $$EditorDraftsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get draftKey => $composableBuilder(
    column: $table.draftKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get boardId => $composableBuilder(
    column: $table.boardId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stackId => $composableBuilder(
    column: $table.stackId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cardId => $composableBuilder(
    column: $table.cardId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get base => $composableBuilder(
    column: $table.base,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$StoredAccountsTableOrderingComposer get accountId {
    final $$StoredAccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.storedAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoredAccountsTableOrderingComposer(
            $db: $db,
            $table: $db.storedAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EditorDraftsTableAnnotationComposer
    extends Composer<_$DeckDatabase, $EditorDraftsTable> {
  $$EditorDraftsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get draftKey =>
      $composableBuilder(column: $table.draftKey, builder: (column) => column);

  GeneratedColumn<int> get boardId =>
      $composableBuilder(column: $table.boardId, builder: (column) => column);

  GeneratedColumn<int> get stackId =>
      $composableBuilder(column: $table.stackId, builder: (column) => column);

  GeneratedColumn<int> get cardId =>
      $composableBuilder(column: $table.cardId, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get base =>
      $composableBuilder(column: $table.base, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$StoredAccountsTableAnnotationComposer get accountId {
    final $$StoredAccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.storedAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoredAccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.storedAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EditorDraftsTableTableManager
    extends
        RootTableManager<
          _$DeckDatabase,
          $EditorDraftsTable,
          EditorDraft,
          $$EditorDraftsTableFilterComposer,
          $$EditorDraftsTableOrderingComposer,
          $$EditorDraftsTableAnnotationComposer,
          $$EditorDraftsTableCreateCompanionBuilder,
          $$EditorDraftsTableUpdateCompanionBuilder,
          (EditorDraft, $$EditorDraftsTableReferences),
          EditorDraft,
          PrefetchHooks Function({bool accountId})
        > {
  $$EditorDraftsTableTableManager(_$DeckDatabase db, $EditorDraftsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EditorDraftsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EditorDraftsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EditorDraftsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> kind = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<String> draftKey = const Value.absent(),
                Value<int> boardId = const Value.absent(),
                Value<int> stackId = const Value.absent(),
                Value<int?> cardId = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<String?> base = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EditorDraftsCompanion(
                kind: kind,
                accountId: accountId,
                draftKey: draftKey,
                boardId: boardId,
                stackId: stackId,
                cardId: cardId,
                payload: payload,
                base: base,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> kind = const Value.absent(),
                required String accountId,
                required String draftKey,
                required int boardId,
                required int stackId,
                Value<int?> cardId = const Value.absent(),
                required String payload,
                Value<String?> base = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => EditorDraftsCompanion.insert(
                kind: kind,
                accountId: accountId,
                draftKey: draftKey,
                boardId: boardId,
                stackId: stackId,
                cardId: cardId,
                payload: payload,
                base: base,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EditorDraftsTable, EditorDraft>(table),
                  $$EditorDraftsTableReferences(db, table, e),
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
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.accountId,
                                referencedTable: $$EditorDraftsTableReferences
                                    ._accountIdTable(db),
                                referencedColumn: $$EditorDraftsTableReferences
                                    ._accountIdTable(db)
                                    .id,
                              )
                              as T;
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

typedef $$EditorDraftsTableProcessedTableManager =
    ProcessedTableManager<
      _$DeckDatabase,
      $EditorDraftsTable,
      EditorDraft,
      $$EditorDraftsTableFilterComposer,
      $$EditorDraftsTableOrderingComposer,
      $$EditorDraftsTableAnnotationComposer,
      $$EditorDraftsTableCreateCompanionBuilder,
      $$EditorDraftsTableUpdateCompanionBuilder,
      (EditorDraft, $$EditorDraftsTableReferences),
      EditorDraft,
      PrefetchHooks Function({bool accountId})
    >;
typedef $$StoredCommentsTableCreateCompanionBuilder =
    StoredCommentsCompanion Function({
      required String accountId,
      required int cardId,
      required int remoteId,
      required String payload,
      Value<int> rowid,
    });
typedef $$StoredCommentsTableUpdateCompanionBuilder =
    StoredCommentsCompanion Function({
      Value<String> accountId,
      Value<int> cardId,
      Value<int> remoteId,
      Value<String> payload,
      Value<int> rowid,
    });

final class $$StoredCommentsTableReferences
    extends
        BaseReferences<_$DeckDatabase, $StoredCommentsTable, StoredComment> {
  $$StoredCommentsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $StoredAccountsTable _accountIdTable(_$DeckDatabase db) => db
      .storedAccounts
      .createAlias('stored_comments__account_id__stored_accounts__id');

  $$StoredAccountsTableProcessedTableManager get accountId {
    final $_column = $_itemColumn<String>('account_id')!;

    final manager = $$StoredAccountsTableTableManager(
      $_db,
      $_db.storedAccounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$StoredCommentsTableFilterComposer
    extends Composer<_$DeckDatabase, $StoredCommentsTable> {
  $$StoredCommentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get cardId => $composableBuilder(
    column: $table.cardId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  $$StoredAccountsTableFilterComposer get accountId {
    final $$StoredAccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.storedAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoredAccountsTableFilterComposer(
            $db: $db,
            $table: $db.storedAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StoredCommentsTableOrderingComposer
    extends Composer<_$DeckDatabase, $StoredCommentsTable> {
  $$StoredCommentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get cardId => $composableBuilder(
    column: $table.cardId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  $$StoredAccountsTableOrderingComposer get accountId {
    final $$StoredAccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.storedAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoredAccountsTableOrderingComposer(
            $db: $db,
            $table: $db.storedAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StoredCommentsTableAnnotationComposer
    extends Composer<_$DeckDatabase, $StoredCommentsTable> {
  $$StoredCommentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get cardId =>
      $composableBuilder(column: $table.cardId, builder: (column) => column);

  GeneratedColumn<int> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  $$StoredAccountsTableAnnotationComposer get accountId {
    final $$StoredAccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.storedAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoredAccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.storedAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StoredCommentsTableTableManager
    extends
        RootTableManager<
          _$DeckDatabase,
          $StoredCommentsTable,
          StoredComment,
          $$StoredCommentsTableFilterComposer,
          $$StoredCommentsTableOrderingComposer,
          $$StoredCommentsTableAnnotationComposer,
          $$StoredCommentsTableCreateCompanionBuilder,
          $$StoredCommentsTableUpdateCompanionBuilder,
          (StoredComment, $$StoredCommentsTableReferences),
          StoredComment,
          PrefetchHooks Function({bool accountId})
        > {
  $$StoredCommentsTableTableManager(
    _$DeckDatabase db,
    $StoredCommentsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StoredCommentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StoredCommentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StoredCommentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> accountId = const Value.absent(),
                Value<int> cardId = const Value.absent(),
                Value<int> remoteId = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StoredCommentsCompanion(
                accountId: accountId,
                cardId: cardId,
                remoteId: remoteId,
                payload: payload,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String accountId,
                required int cardId,
                required int remoteId,
                required String payload,
                Value<int> rowid = const Value.absent(),
              }) => StoredCommentsCompanion.insert(
                accountId: accountId,
                cardId: cardId,
                remoteId: remoteId,
                payload: payload,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$StoredCommentsTable, StoredComment>(table),
                  $$StoredCommentsTableReferences(db, table, e),
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
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.accountId,
                                referencedTable: $$StoredCommentsTableReferences
                                    ._accountIdTable(db),
                                referencedColumn:
                                    $$StoredCommentsTableReferences
                                        ._accountIdTable(db)
                                        .id,
                              )
                              as T;
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

typedef $$StoredCommentsTableProcessedTableManager =
    ProcessedTableManager<
      _$DeckDatabase,
      $StoredCommentsTable,
      StoredComment,
      $$StoredCommentsTableFilterComposer,
      $$StoredCommentsTableOrderingComposer,
      $$StoredCommentsTableAnnotationComposer,
      $$StoredCommentsTableCreateCompanionBuilder,
      $$StoredCommentsTableUpdateCompanionBuilder,
      (StoredComment, $$StoredCommentsTableReferences),
      StoredComment,
      PrefetchHooks Function({bool accountId})
    >;
typedef $$StoredAttachmentsTableCreateCompanionBuilder =
    StoredAttachmentsCompanion Function({
      required String accountId,
      required int boardId,
      required int cardId,
      required String type,
      required int remoteId,
      required String payload,
      Value<int> rowid,
    });
typedef $$StoredAttachmentsTableUpdateCompanionBuilder =
    StoredAttachmentsCompanion Function({
      Value<String> accountId,
      Value<int> boardId,
      Value<int> cardId,
      Value<String> type,
      Value<int> remoteId,
      Value<String> payload,
      Value<int> rowid,
    });

final class $$StoredAttachmentsTableReferences
    extends
        BaseReferences<
          _$DeckDatabase,
          $StoredAttachmentsTable,
          StoredAttachment
        > {
  $$StoredAttachmentsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $StoredAccountsTable _accountIdTable(_$DeckDatabase db) => db
      .storedAccounts
      .createAlias('stored_attachments__account_id__stored_accounts__id');

  $$StoredAccountsTableProcessedTableManager get accountId {
    final $_column = $_itemColumn<String>('account_id')!;

    final manager = $$StoredAccountsTableTableManager(
      $_db,
      $_db.storedAccounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$StoredAttachmentsTableFilterComposer
    extends Composer<_$DeckDatabase, $StoredAttachmentsTable> {
  $$StoredAttachmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get boardId => $composableBuilder(
    column: $table.boardId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cardId => $composableBuilder(
    column: $table.cardId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  $$StoredAccountsTableFilterComposer get accountId {
    final $$StoredAccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.storedAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoredAccountsTableFilterComposer(
            $db: $db,
            $table: $db.storedAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StoredAttachmentsTableOrderingComposer
    extends Composer<_$DeckDatabase, $StoredAttachmentsTable> {
  $$StoredAttachmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get boardId => $composableBuilder(
    column: $table.boardId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cardId => $composableBuilder(
    column: $table.cardId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  $$StoredAccountsTableOrderingComposer get accountId {
    final $$StoredAccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.storedAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoredAccountsTableOrderingComposer(
            $db: $db,
            $table: $db.storedAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StoredAttachmentsTableAnnotationComposer
    extends Composer<_$DeckDatabase, $StoredAttachmentsTable> {
  $$StoredAttachmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get boardId =>
      $composableBuilder(column: $table.boardId, builder: (column) => column);

  GeneratedColumn<int> get cardId =>
      $composableBuilder(column: $table.cardId, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  $$StoredAccountsTableAnnotationComposer get accountId {
    final $$StoredAccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.storedAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoredAccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.storedAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StoredAttachmentsTableTableManager
    extends
        RootTableManager<
          _$DeckDatabase,
          $StoredAttachmentsTable,
          StoredAttachment,
          $$StoredAttachmentsTableFilterComposer,
          $$StoredAttachmentsTableOrderingComposer,
          $$StoredAttachmentsTableAnnotationComposer,
          $$StoredAttachmentsTableCreateCompanionBuilder,
          $$StoredAttachmentsTableUpdateCompanionBuilder,
          (StoredAttachment, $$StoredAttachmentsTableReferences),
          StoredAttachment,
          PrefetchHooks Function({bool accountId})
        > {
  $$StoredAttachmentsTableTableManager(
    _$DeckDatabase db,
    $StoredAttachmentsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StoredAttachmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StoredAttachmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StoredAttachmentsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> accountId = const Value.absent(),
                Value<int> boardId = const Value.absent(),
                Value<int> cardId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<int> remoteId = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StoredAttachmentsCompanion(
                accountId: accountId,
                boardId: boardId,
                cardId: cardId,
                type: type,
                remoteId: remoteId,
                payload: payload,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String accountId,
                required int boardId,
                required int cardId,
                required String type,
                required int remoteId,
                required String payload,
                Value<int> rowid = const Value.absent(),
              }) => StoredAttachmentsCompanion.insert(
                accountId: accountId,
                boardId: boardId,
                cardId: cardId,
                type: type,
                remoteId: remoteId,
                payload: payload,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$StoredAttachmentsTable, StoredAttachment>(table),
                  $$StoredAttachmentsTableReferences(db, table, e),
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
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.accountId,
                                referencedTable:
                                    $$StoredAttachmentsTableReferences
                                        ._accountIdTable(db),
                                referencedColumn:
                                    $$StoredAttachmentsTableReferences
                                        ._accountIdTable(db)
                                        .id,
                              )
                              as T;
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

typedef $$StoredAttachmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$DeckDatabase,
      $StoredAttachmentsTable,
      StoredAttachment,
      $$StoredAttachmentsTableFilterComposer,
      $$StoredAttachmentsTableOrderingComposer,
      $$StoredAttachmentsTableAnnotationComposer,
      $$StoredAttachmentsTableCreateCompanionBuilder,
      $$StoredAttachmentsTableUpdateCompanionBuilder,
      (StoredAttachment, $$StoredAttachmentsTableReferences),
      StoredAttachment,
      PrefetchHooks Function({bool accountId})
    >;

class $DeckDatabaseManager {
  final _$DeckDatabase _db;
  $DeckDatabaseManager(this._db);
  $$StoredAccountsTableTableManager get storedAccounts =>
      $$StoredAccountsTableTableManager(_db, _db.storedAccounts);
  $$StoredBoardsTableTableManager get storedBoards =>
      $$StoredBoardsTableTableManager(_db, _db.storedBoards);
  $$StoredStacksTableTableManager get storedStacks =>
      $$StoredStacksTableTableManager(_db, _db.storedStacks);
  $$StoredCardsTableTableManager get storedCards =>
      $$StoredCardsTableTableManager(_db, _db.storedCards);
  $$SyncCheckpointsTableTableManager get syncCheckpoints =>
      $$SyncCheckpointsTableTableManager(_db, _db.syncCheckpoints);
  $$PendingWritesTableTableManager get pendingWrites =>
      $$PendingWritesTableTableManager(_db, _db.pendingWrites);
  $$SyncLeasesTableTableManager get syncLeases =>
      $$SyncLeasesTableTableManager(_db, _db.syncLeases);
  $$EditorDraftsTableTableManager get editorDrafts =>
      $$EditorDraftsTableTableManager(_db, _db.editorDrafts);
  $$StoredCommentsTableTableManager get storedComments =>
      $$StoredCommentsTableTableManager(_db, _db.storedComments);
  $$StoredAttachmentsTableTableManager get storedAttachments =>
      $$StoredAttachmentsTableTableManager(_db, _db.storedAttachments);
}
