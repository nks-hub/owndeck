import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../platform/attachment_storage.dart';
import 'accounts.dart';
import 'attachment_files.dart';
import 'keychain_migration.dart';
import 'session.dart';

/// Android WorkManager unique name and iOS BGTaskScheduler identifier. The iOS
/// value must be listed in `BGTaskSchedulerPermittedIdentifiers` in Info.plist.
const backgroundSyncTask = 'com.nkshub.nextclouddeck.sync';

bool get hasBackgroundSync =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

/// How often the OS may run the outbox and cache refresh while the app is closed.
final class BackgroundSyncPreferences {
  const BackgroundSyncPreferences({this.minutes = 15, this.wifiOnly = false});

  /// Minutes between runs; 0 turns the background run off.
  static const intervals = [0, 15, 60, 360];
  static const _key = 'backgroundSync';
  final int minutes;
  final bool wifiOnly;
  bool get enabled => minutes != 0;

  /// Reads the stored choice; a missing or damaged value yields the defaults.
  static Future<BackgroundSyncPreferences> load() async {
    try {
      final stored = await SharedPreferencesAsync().getString(_key);
      if (stored == null) return const BackgroundSyncPreferences();
      final values = jsonDecode(stored);
      if (values is Map &&
          intervals.contains(values['minutes']) &&
          values['wifiOnly'] is bool) {
        return BackgroundSyncPreferences(
          minutes: values['minutes'] as int,
          wifiOnly: values['wifiOnly'] as bool,
        );
      }
    } on Object {
      // Unreadable storage keeps the safe defaults instead of stopping the app.
    }
    return const BackgroundSyncPreferences();
  }

  Future<void> save() {
    if (!intervals.contains(minutes)) throw ArgumentError.value(minutes);
    return SharedPreferencesAsync().setString(
      _key,
      jsonEncode({'minutes': minutes, 'wifiOnly': wifiOnly}),
    );
  }
}

/// Whether a background run may touch the network right now. Read in every
/// isolate and again before each request, because settings or the network can
/// change while a worker is running.
Future<bool> backgroundSyncAllowed() async {
  final preferences = await BackgroundSyncPreferences.load();
  if (!preferences.enabled) return false;
  if (!preferences.wifiOnly) return true;
  final networks = await Connectivity().checkConnectivity();
  return networks.contains(ConnectivityResult.wifi) ||
      networks.contains(ConnectivityResult.ethernet);
}

/// Gates every request of a background run, not just its start.
final class BackgroundSyncClient extends http.BaseClient {
  BackgroundSyncClient(this._inner, this._allowed);
  final http.Client _inner;
  final Future<bool> Function() _allowed;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (!await _allowed()) throw http.ClientException('background_sync_paused');
    return _inner.send(request);
  }

  @override
  void close() => _inner.close();
}

/// Entry point of the OS-started isolate. It opens its own database
/// connection; the per-account lease keeps it from sending at the same time
/// as the app.
@pragma('vm:entry-point')
void backgroundDispatcher() {
  Workmanager().executeTask((task, input) => runBackgroundSync());
}

/// Sends queued changes and refreshes the cache of every active account.
///
/// Only `queued` changes are sent; an `uncertain` one waits for the user's
/// decision, exactly as in the app. Nothing here touches telemetry, so the
/// opt-out needs no check. Returns true when the run finished or was skipped.
Future<bool> runBackgroundSync({
  DeckDatabase? database,
  CredentialVault? vault,
  http.Client Function(StoredAccount account)? transport,
  Future<AttachmentFiles> Function()? files,
  Future<bool> Function()? allowed,
  Duration? budget,
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  final isAllowed = allowed ?? backgroundSyncAllowed;
  if (!await isAllowed()) return true;
  final db =
      database ??
      DeckDatabase(driftDatabase(name: 'owndeck'), background: true);
  final secrets =
      vault ??
      SecureVault(const FlutterSecureStorage(iOptions: deviceOnlyKeychain));
  final repository = AccountRepository(db, secrets);
  // iOS gives a background refresh about 30 seconds.
  final limit =
      budget ??
      (defaultTargetPlatform == TargetPlatform.iOS
          ? const Duration(seconds: 20)
          : const Duration(minutes: 5));
  final started = Stopwatch()..start();
  try {
    for (final account in await db.accounts()) {
      if (account.state != 'active') continue;
      if (started.elapsed >= limit || !await isAllowed()) break;
      final password = await secrets.read(account.credentialRef);
      if (password == null) continue;
      final inner =
          transport?.call(account) ??
          CertificateHttpClient(
            server: ServerBase.parse(account.server).uri,
            fingerprint: account.certificateFingerprint,
          );
      final session = DeckSession(
        db,
        account,
        DeckClient(
          base: ServerBase.parse(account.server),
          loginName: account.loginName,
          appPassword: password,
          transport: BackgroundSyncClient(inner, isAllowed),
          retryUntil: account.syncNotBefore,
        ),
        files: files ?? () => openAttachmentFiles(background: true),
        onAuthenticationRequired: () async {
          await repository.requireAuthentication(account);
        },
        pollInterval: const Duration(days: 1),
        background: true,
      );
      try {
        await session.syncNow(budget: limit - started.elapsed);
      } finally {
        session.dispose();
        inner.close();
      }
    }
    return true;
  } finally {
    if (database == null) await db.close();
  }
}

/// Registers or cancels the OS job that runs [runBackgroundSync].
abstract interface class BackgroundScheduler {
  /// Applies the stored [BackgroundSyncPreferences]; with no account there is
  /// nothing to send, so the job is cancelled.
  Future<void> apply({required bool hasAccounts});
}

final class WorkmanagerScheduler implements BackgroundScheduler {
  const WorkmanagerScheduler();

  @override
  Future<void> apply({required bool hasAccounts}) async {
    if (!hasBackgroundSync) return;
    try {
      final preferences = await BackgroundSyncPreferences.load();
      final work = Workmanager();
      if (!preferences.enabled || !hasAccounts) {
        await work.cancelByUniqueName(backgroundSyncTask);
        return;
      }
      await work.initialize(backgroundDispatcher);
      final ios = defaultTargetPlatform == TargetPlatform.iOS;
      final interval = Duration(minutes: preferences.minutes);
      await work.registerPeriodicTask(
        backgroundSyncTask,
        backgroundSyncTask,
        // iOS ignores the frequency and treats the delay as the earliest start.
        frequency: ios ? null : interval,
        initialDelay: ios ? interval : null,
        // iOS cannot require an unmetered network; the run checks Wi-Fi itself.
        constraints: Constraints(
          networkType: preferences.wifiOnly && !ios
              ? NetworkType.unmetered
              : NetworkType.connected,
        ),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
      );
    } on Object {
      // A missing platform plugin or scheduler refusal must not stop the app.
    }
  }
}

final backgroundSchedulerProvider = Provider<BackgroundScheduler>(
  (ref) => const WorkmanagerScheduler(),
);

/// Settings state for the background run; every change re-applies the schedule.
final class BackgroundSyncSettings extends ChangeNotifier {
  BackgroundSyncSettings(this._scheduler, this._hasAccounts) {
    unawaited(_load());
  }
  final BackgroundScheduler _scheduler;
  final bool Function() _hasAccounts;
  BackgroundSyncPreferences preferences = const BackgroundSyncPreferences();
  bool loaded = false;
  bool _disposed = false;

  Future<void> _load() async {
    preferences = await BackgroundSyncPreferences.load();
    loaded = true;
    if (!_disposed) notifyListeners();
  }

  Future<void> update({int? minutes, bool? wifiOnly}) async {
    preferences = BackgroundSyncPreferences(
      minutes: minutes ?? preferences.minutes,
      wifiOnly: wifiOnly ?? preferences.wifiOnly,
    );
    notifyListeners();
    try {
      await preferences.save();
    } on Object {
      // The choice still applies until restart if storage refuses the write.
    }
    await _scheduler.apply(hasAccounts: _hasAccounts());
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

final backgroundSyncSettingsProvider =
    ChangeNotifierProvider.autoDispose<BackgroundSyncSettings>(
      (ref) => BackgroundSyncSettings(
        ref.read(backgroundSchedulerProvider),
        () => ref.read(accountsProvider).items.isNotEmpty,
      ),
    );
