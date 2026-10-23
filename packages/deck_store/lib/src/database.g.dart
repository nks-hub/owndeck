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
    credentialRef,
    state,
    generation,
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
  final String credentialRef;
  final String state;
  final int generation;
  final bool selected;
  const StoredAccount({
    required this.id,
    required this.server,
    required this.loginName,
    required this.credentialRef,
    required this.state,
    required this.generation,
    required this.selected,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['server'] = Variable<String>(server);
    map['login_name'] = Variable<String>(loginName);
    map['credential_ref'] = Variable<String>(credentialRef);
    map['state'] = Variable<String>(state);
    map['generation'] = Variable<int>(generation);
    map['selected'] = Variable<bool>(selected);
    return map;
  }

  StoredAccountsCompanion toCompanion(bool nullToAbsent) {
    return StoredAccountsCompanion(
      id: Value(id),
      server: Value(server),
      loginName: Value(loginName),
      credentialRef: Value(credentialRef),
      state: Value(state),
      generation: Value(generation),
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
      credentialRef: serializer.fromJson<String>(json['credentialRef']),
      state: serializer.fromJson<String>(json['state']),
      generation: serializer.fromJson<int>(json['generation']),
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
      'credentialRef': serializer.toJson<String>(credentialRef),
      'state': serializer.toJson<String>(state),
      'generation': serializer.toJson<int>(generation),
      'selected': serializer.toJson<bool>(selected),
    };
  }

  StoredAccount copyWith({
    String? id,
    String? server,
    String? loginName,
    String? credentialRef,
    String? state,
    int? generation,
    bool? selected,
  }) => StoredAccount(
    id: id ?? this.id,
    server: server ?? this.server,
    loginName: loginName ?? this.loginName,
    credentialRef: credentialRef ?? this.credentialRef,
    state: state ?? this.state,
    generation: generation ?? this.generation,
    selected: selected ?? this.selected,
  );
  StoredAccount copyWithCompanion(StoredAccountsCompanion data) {
    return StoredAccount(
      id: data.id.present ? data.id.value : this.id,
      server: data.server.present ? data.server.value : this.server,
      loginName: data.loginName.present ? data.loginName.value : this.loginName,
      credentialRef: data.credentialRef.present
          ? data.credentialRef.value
          : this.credentialRef,
      state: data.state.present ? data.state.value : this.state,
      generation: data.generation.present
          ? data.generation.value
          : this.generation,
      selected: data.selected.present ? data.selected.value : this.selected,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoredAccount(')
          ..write('id: $id, ')
          ..write('server: $server, ')
          ..write('loginName: $loginName, ')
          ..write('credentialRef: $credentialRef, ')
          ..write('state: $state, ')
          ..write('generation: $generation, ')
          ..write('selected: $selected')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    server,
    loginName,
    credentialRef,
    state,
    generation,
    selected,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoredAccount &&
          other.id == this.id &&
          other.server == this.server &&
          other.loginName == this.loginName &&
          other.credentialRef == this.credentialRef &&
          other.state == this.state &&
          other.generation == this.generation &&
          other.selected == this.selected);
}

class StoredAccountsCompanion extends UpdateCompanion<StoredAccount> {
  final Value<String> id;
  final Value<String> server;
  final Value<String> loginName;
  final Value<String> credentialRef;
  final Value<String> state;
  final Value<int> generation;
  final Value<bool> selected;
  final Value<int> rowid;
  const StoredAccountsCompanion({
    this.id = const Value.absent(),
    this.server = const Value.absent(),
    this.loginName = const Value.absent(),
    this.credentialRef = const Value.absent(),
    this.state = const Value.absent(),
    this.generation = const Value.absent(),
    this.selected = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StoredAccountsCompanion.insert({
    required String id,
    required String server,
    required String loginName,
    required String credentialRef,
    this.state = const Value.absent(),
    this.generation = const Value.absent(),
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
    Expression<String>? credentialRef,
    Expression<String>? state,
    Expression<int>? generation,
    Expression<bool>? selected,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (server != null) 'server': server,
      if (loginName != null) 'login_name': loginName,
      if (credentialRef != null) 'credential_ref': credentialRef,
      if (state != null) 'state': state,
      if (generation != null) 'generation': generation,
      if (selected != null) 'selected': selected,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StoredAccountsCompanion copyWith({
    Value<String>? id,
    Value<String>? server,
    Value<String>? loginName,
    Value<String>? credentialRef,
    Value<String>? state,
    Value<int>? generation,
    Value<bool>? selected,
    Value<int>? rowid,
  }) {
    return StoredAccountsCompanion(
      id: id ?? this.id,
      server: server ?? this.server,
      loginName: loginName ?? this.loginName,
      credentialRef: credentialRef ?? this.credentialRef,
      state: state ?? this.state,
      generation: generation ?? this.generation,
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
    if (credentialRef.present) {
      map['credential_ref'] = Variable<String>(credentialRef.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (generation.present) {
      map['generation'] = Variable<int>(generation.value);
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
          ..write('credentialRef: $credentialRef, ')
          ..write('state: $state, ')
          ..write('generation: $generation, ')
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
  ]);
}

typedef $$StoredAccountsTableCreateCompanionBuilder =
    StoredAccountsCompanion Function({
      required String id,
      required String server,
      required String loginName,
      required String credentialRef,
      Value<String> state,
      Value<int> generation,
      Value<bool> selected,
      Value<int> rowid,
    });
typedef $$StoredAccountsTableUpdateCompanionBuilder =
    StoredAccountsCompanion Function({
      Value<String> id,
      Value<String> server,
      Value<String> loginName,
      Value<String> credentialRef,
      Value<String> state,
      Value<int> generation,
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
                Value<String> credentialRef = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<int> generation = const Value.absent(),
                Value<bool> selected = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StoredAccountsCompanion(
                id: id,
                server: server,
                loginName: loginName,
                credentialRef: credentialRef,
                state: state,
                generation: generation,
                selected: selected,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String server,
                required String loginName,
                required String credentialRef,
                Value<String> state = const Value.absent(),
                Value<int> generation = const Value.absent(),
                Value<bool> selected = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StoredAccountsCompanion.insert(
                id: id,
                server: server,
                loginName: loginName,
                credentialRef: credentialRef,
                state: state,
                generation: generation,
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
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (storedBoardsRefs) db.storedBoards,
                    if (storedStacksRefs) db.storedStacks,
                    if (storedCardsRefs) db.storedCards,
                    if (syncCheckpointsRefs) db.syncCheckpoints,
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
}
