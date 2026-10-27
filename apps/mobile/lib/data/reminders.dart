import 'dart:async';
import 'dart:convert';
import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../core/app_preferences.dart';
import '../l10n/app_localizations.dart';
import 'accounts.dart';
import 'card_link_inbox.dart';

bool get hasLocalReminders =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

/// iOS keeps at most 64 pending local notifications, so only the nearest
/// ones are scheduled; the rest follow when the app or a background run
/// reconciles again.
const reminderLimit = 60;

/// Whether reminders are on and how long before the due time they fire.
final class ReminderPreferences {
  const ReminderPreferences({this.enabled = false, this.leadMinutes = 60});

  /// Minutes before the due time; 0 fires at the due time.
  static const leads = [0, 15, 60, 1440];
  static const _key = 'dueReminders';
  final bool enabled;
  final int leadMinutes;

  static Future<ReminderPreferences> load() async {
    try {
      final stored = await SharedPreferencesAsync().getString(_key);
      if (stored == null) return const ReminderPreferences();
      final values = jsonDecode(stored);
      if (values is Map &&
          values['enabled'] is bool &&
          leads.contains(values['leadMinutes'])) {
        return ReminderPreferences(
          enabled: values['enabled'] as bool,
          leadMinutes: values['leadMinutes'] as int,
        );
      }
    } on Object {
      // Unreadable storage keeps reminders off rather than guessing.
    }
    return const ReminderPreferences();
  }

  Future<void> save() => SharedPreferencesAsync().setString(
    _key,
    jsonEncode({'enabled': enabled, 'leadMinutes': leadMinutes}),
  );
}

/// A notification the operating system holds for us.
final class ScheduledReminder {
  const ScheduledReminder(this.id, this.payload);
  final int id;
  final String? payload;
}

/// The part of the notification plugin the app needs, so scheduling can be
/// tested without a device.
abstract interface class ReminderPlatform {
  /// Asks for the notification permission; false if the user refused.
  Future<bool> requestPermission();
  Future<List<ScheduledReminder>> scheduled();
  Future<void> schedule({
    required int id,
    required DateTime at,
    required String title,
    required String body,
    required String payload,
    required String channelName,
  });
  Future<void> cancel(int id);

  /// Payloads of notifications the user tapped while the app was running.
  Stream<String> get taps;

  /// Payload of the notification that started the app, if any.
  Future<String?> launchPayload();
}

/// `flutter_local_notifications` on Android and iOS.
///
/// Android uses inexact alarms that may run in Doze, so no exact-alarm
/// permission is needed; a reminder can arrive a few minutes late.
final class LocalNotificationsPlatform implements ReminderPlatform {
  LocalNotificationsPlatform();
  final _plugin = FlutterLocalNotificationsPlugin();
  final _taps = StreamController<String>.broadcast();
  Future<void>? _ready;

  Future<void> _initialize() => _ready ??= () async {
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null) _taps.add(payload);
      },
    );
  }();

  @override
  Stream<String> get taps {
    unawaited(_initialize());
    return _taps.stream;
  }

  @override
  Future<bool> requestPermission() async {
    await _initialize();
    return switch (defaultTargetPlatform) {
      TargetPlatform.android =>
        await _plugin
                .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin
                >()
                ?.requestNotificationsPermission() ??
            false,
      TargetPlatform.iOS =>
        await _plugin
                .resolvePlatformSpecificImplementation<
                  IOSFlutterLocalNotificationsPlugin
                >()
                ?.requestPermissions(alert: true, sound: true) ??
            false,
      _ => false,
    };
  }

  @override
  Future<List<ScheduledReminder>> scheduled() async {
    await _initialize();
    return [
      for (final item in await _plugin.pendingNotificationRequests())
        ScheduledReminder(item.id, item.payload),
    ];
  }

  @override
  Future<void> schedule({
    required int id,
    required DateTime at,
    required String title,
    required String body,
    required String payload,
    required String channelName,
  }) async {
    await _initialize();
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      payload: payload,
      scheduledDate: tz.TZDateTime.from(at.toUtc(), tz.UTC),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'card-due',
          channelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  @override
  Future<void> cancel(int id) async {
    await _initialize();
    await _plugin.cancel(id: id);
  }

  @override
  Future<String?> launchPayload() async {
    await _initialize();
    final details = await _plugin.getNotificationAppLaunchDetails();
    return details?.didNotificationLaunchApp == true
        ? details?.notificationResponse?.payload
        : null;
  }
}

/// Texts of one reminder, in the language chosen in the app.
typedef ReminderTexts = ({
  String languageTag,
  String channelName,
  String Function(DueReminder) body,
});

/// Brings the operating system's scheduled notifications in line with the
/// reminders the cache calls for: schedules missing ones, replaces changed
/// ones and cancels the rest (card done, due date moved, card or account gone).
final class ReminderService {
  ReminderService(this.platform, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;
  final ReminderPlatform platform;
  final DateTime Function() _clock;
  Future<void> _tail = Future.value();

  /// Runs one reconcile after any earlier one has finished.
  Future<void> reconcile(
    List<DueReminder> cards,
    ReminderPreferences preferences,
    ReminderTexts texts,
  ) {
    final run = _tail.then(
      (_) => _reconcile(cards, preferences, texts),
      onError: (Object _) => _reconcile(cards, preferences, texts),
    );
    _tail = run.then((_) {}, onError: (Object _) {});
    return run;
  }

  static String keyOf(String accountId, int cardId) => '$accountId|$cardId';

  Future<void> _reconcile(
    List<DueReminder> cards,
    ReminderPreferences preferences,
    ReminderTexts texts,
  ) async {
    final now = _clock().toUtc();
    final lead = Duration(minutes: preferences.leadMinutes);
    final wanted =
        <String, ({DueReminder card, DateTime at, String payload})>{};
    if (preferences.enabled) {
      final upcoming = [
        for (final card in cards)
          if (card.due.subtract(lead).isAfter(now))
            (card: card, at: card.due.subtract(lead)),
      ]..sort((a, b) => a.at.compareTo(b.at));
      for (final item in upcoming.take(reminderLimit)) {
        final card = item.card;
        wanted[keyOf(card.accountId, card.cardId)] = (
          card: card,
          at: item.at,
          payload: jsonEncode({
            'a': card.accountId,
            'b': card.boardId,
            'c': card.cardId,
            'at': item.at.millisecondsSinceEpoch,
            't': card.title,
            'o': card.boardTitle,
            'l': texts.languageTag,
          }),
        );
      }
    }
    // Inexact alarms may fire minutes late; a reminder whose time has passed
    // but which the OS has not delivered yet stays while its card is unchanged.
    final due = <String, int>{
      if (preferences.enabled)
        for (final card in cards)
          keyOf(card.accountId, card.cardId): card.due
              .subtract(lead)
              .millisecondsSinceEpoch,
    };
    final taken = <int>{};
    final kept = <String>{};
    for (final pending in await platform.scheduled()) {
      final key = _keyOfPayload(pending.payload);
      final current = key == null ? null : wanted[key];
      final at = _atOfPayload(pending.payload);
      final overdue =
          key != null &&
          at != null &&
          at <= now.millisecondsSinceEpoch &&
          due[key] == at;
      if ((current != null && current.payload == pending.payload || overdue) &&
          kept.add(key!)) {
        taken.add(pending.id);
      } else {
        await platform.cancel(pending.id);
      }
    }
    for (final entry in wanted.entries) {
      if (kept.contains(entry.key)) continue;
      var id = _stableId(entry.key);
      while (!taken.add(id)) {
        id = (id + 1) & 0x7fffffff;
      }
      final card = entry.value.card;
      await platform.schedule(
        id: id,
        at: entry.value.at,
        title: card.title,
        body: texts.body(card),
        payload: entry.value.payload,
        channelName: texts.channelName,
      );
    }
  }

  static String? _keyOfPayload(String? payload) {
    if (payload == null) return null;
    try {
      final values = jsonDecode(payload);
      if (values is Map && values['a'] is String && values['c'] is int) {
        return keyOf(values['a'] as String, values['c'] as int);
      }
    } on FormatException {
      // A payload we did not write is cancelled by the caller.
    }
    return null;
  }

  static int? _atOfPayload(String? payload) {
    if (payload == null) return null;
    try {
      final values = jsonDecode(payload);
      if (values is Map && values['at'] is int) return values['at'] as int;
    } on FormatException {
      // Unknown payloads never count as overdue.
    }
    return null;
  }

  /// FNV-1a over the key, cut to the positive 32-bit range notifications use.
  static int _stableId(String key) {
    var hash = 0x811c9dc5;
    for (final unit in key.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0xffffffff;
    }
    return hash & 0x7fffffff;
  }
}

/// Opens the card of a tapped reminder in the account that owns it.
///
/// Selecting the account first makes the existing card link flow pick it, even
/// when another account is signed in to the same server.
Future<bool> openReminder(
  String payload,
  Accounts accounts,
  CardLinkInbox inbox,
) async {
  try {
    final values = jsonDecode(payload);
    if (values is! Map ||
        values['a'] is! String ||
        values['b'] is! int ||
        values['c'] is! int) {
      return false;
    }
    await accounts.ready;
    final account = accounts.items
        .where((item) => item.id == values['a'])
        .firstOrNull;
    if (account == null) return false;
    if (accounts.selected?.id != account.id) await accounts.select(account.id);
    inbox.offer(
      DeckCardLink(
        server: ServerBase.parse(account.server),
        boardId: values['b'] as int,
        cardId: values['c'] as int,
      ).appUri.toString(),
    );
    return true;
  } on FormatException {
    return false;
  }
}

/// Texts in the language the user chose; the system language when unset.
ReminderTexts reminderTexts(AppLanguage language) {
  final wanted = switch (language) {
    AppLanguage.system => PlatformDispatcher.instance.locale,
    AppLanguage.cs => const Locale('cs'),
    AppLanguage.en => const Locale('en'),
  };
  final locale = AppLocalizations.supportedLocales.firstWhere(
    (supported) => supported.languageCode == wanted.languageCode,
    orElse: () => const Locale('en'),
  );
  final text = lookupAppLocalizations(locale);
  String two(int value) => value.toString().padLeft(2, '0');
  return (
    languageTag: locale.languageCode,
    channelName: text.reminderChannel,
    body: (card) {
      final due = card.due.toLocal();
      final when =
          '${due.year}-${two(due.month)}-${two(due.day)} ${two(due.hour)}:${two(due.minute)}';
      return text.reminderBody(when, card.boardTitle);
    },
  );
}

/// Keeps scheduled reminders equal to the cache. It watches the local copy,
/// so a card finished, moved in time, deleted or its account removed cancels
/// its notification, also while the change still waits in the outbox.
final class ReminderCoordinator {
  ReminderCoordinator({
    required this.database,
    required this.service,
    required this.language,
    required this.onOpen,
    this.debounce = const Duration(seconds: 1),
    Future<ReminderPreferences> Function()? loadPreferences,
  }) : _load = loadPreferences ?? ReminderPreferences.load;
  final DeckDatabase database;
  final ReminderService service;
  final AppLanguage Function() language;
  final Future<void> Function(String payload) onOpen;
  final Duration debounce;
  final Future<ReminderPreferences> Function() _load;
  StreamSubscription<List<DueReminder>>? _cards;
  StreamSubscription<String>? _taps;
  Timer? _timer;
  List<DueReminder> _latest = const [];
  bool _disposed = false;

  /// Opens the card of the notification that started the app, listens for
  /// taps and brings the schedule up to date.
  Future<void> start() async {
    try {
      _taps ??= service.platform.taps.listen((payload) {
        unawaited(onOpen(payload));
      }, onError: (Object _) {});
      final launch = await service.platform.launchPayload();
      if (launch != null) unawaited(onOpen(launch));
    } on Object {
      // Without a notification plugin there is nothing to open.
    }
    await refresh();
  }

  /// Re-reads the settings and language and reconciles once.
  Future<void> refresh() async {
    final preferences = await _load();
    if (_disposed) return;
    if (!preferences.enabled) {
      await _cards?.cancel();
      _cards = null;
      _latest = const [];
    } else {
      _cards ??= database.watchDueReminders().listen((cards) {
        _latest = cards;
        _timer?.cancel();
        _timer = Timer(debounce, () => unawaited(_apply()));
      }, onError: (Object _) {});
    }
    await _apply(preferences);
  }

  Future<void> _apply([ReminderPreferences? known]) async {
    if (_disposed) return;
    try {
      await service.reconcile(
        _latest,
        known ?? await _load(),
        reminderTexts(language()),
      );
    } on Object {
      // A refused schedule is retried on the next change or app start.
    }
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    unawaited(_cards?.cancel());
    unawaited(_taps?.cancel());
  }
}

/// Reconciles from the stored settings, for a run without the app open.
Future<void> reconcileStoredReminders(
  DeckDatabase database, {
  ReminderPlatform? platform,
  DateTime Function()? clock,
}) async {
  final preferences = await ReminderPreferences.load();
  if (!preferences.enabled) return;
  final stored = await SharedPreferencesAsync().getString(
    AppPreferences.languageKey,
  );
  final language = AppLanguage.values.firstWhere(
    (value) => value.name == stored,
    orElse: () => AppLanguage.system,
  );
  await ReminderService(
    platform ?? LocalNotificationsPlatform(),
    clock: clock,
  ).reconcile(
    await database.dueReminders(now: clock?.call()),
    preferences,
    reminderTexts(language),
  );
}

/// Reminder settings; turning them on asks for the notification permission.
final class ReminderSettings extends ChangeNotifier {
  ReminderSettings(this._platform, this._changed) {
    unawaited(_loadStored());
  }
  final ReminderPlatform _platform;
  final Future<void> Function() _changed;
  ReminderPreferences preferences = const ReminderPreferences();
  bool loaded = false;

  /// The permission request was refused; the switch stays off.
  bool denied = false;
  bool _disposed = false;

  Future<void> _loadStored() async {
    preferences = await ReminderPreferences.load();
    loaded = true;
    if (!_disposed) notifyListeners();
  }

  Future<void> update({bool? enabled, int? leadMinutes}) async {
    final next = ReminderPreferences(
      enabled: enabled ?? preferences.enabled,
      leadMinutes: leadMinutes ?? preferences.leadMinutes,
    );
    denied = false;
    if (enabled == true) {
      var granted = false;
      try {
        granted = await _platform.requestPermission();
      } on Object {
        // No plugin or a platform error counts as not granted.
      }
      if (!granted) {
        denied = true;
        notifyListeners();
        return;
      }
    }
    preferences = next;
    notifyListeners();
    try {
      await next.save();
    } on Object {
      // The choice still applies until restart if storage refuses the write.
    }
    await _changed();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

final reminderPlatformProvider = Provider<ReminderPlatform>(
  (ref) => LocalNotificationsPlatform(),
);

final reminderCoordinatorProvider = Provider<ReminderCoordinator>((ref) {
  final accounts = ref.read(accountsProvider);
  final preferences = ref.read(appPreferencesProvider);
  final coordinator = ReminderCoordinator(
    database: accounts.database,
    service: ReminderService(ref.read(reminderPlatformProvider)),
    language: () => preferences.language,
    onOpen: (payload) async {
      await openReminder(payload, accounts, incomingCardLinks);
    },
  );
  var shown = preferences.language;
  void languageChanged() {
    if (preferences.language == shown) return;
    shown = preferences.language;
    unawaited(coordinator.refresh());
  }

  preferences.addListener(languageChanged);
  ref.onDispose(() {
    preferences.removeListener(languageChanged);
    coordinator.dispose();
  });
  return coordinator;
});

final reminderSettingsProvider =
    ChangeNotifierProvider.autoDispose<ReminderSettings>(
      (ref) => ReminderSettings(
        ref.read(reminderPlatformProvider),
        () => ref.read(reminderCoordinatorProvider).refresh(),
      ),
    );
