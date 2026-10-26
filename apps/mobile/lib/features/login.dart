import 'dart:async';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../core/onboarding_theme.dart';
import '../data/accounts.dart';
import '../l10n/app_localizations.dart';
import '../platform/camera_permission.dart';
import 'onboarding/certificate_dialog.dart';
import 'onboarding/login_view.dart';
import 'onboarding/qr_login_scanner_screen.dart';
import 'onboarding/server_address_input.dart';
import 'accounts.dart';

typedef LoginTransportFactory =
    http.Client Function(ServerBase server, String? fingerprint);

class LoginScreen extends StatelessWidget {
  const LoginScreen({
    super.key,
    this.closeOnSuccess = false,
    this.initialServer,
    this.reauthenticateAccount,
    this.transportFactory,
    this.openBrowser,
    this.scan,
  });
  final bool closeOnSuccess;
  final String? initialServer;
  final StoredAccount? reauthenticateAccount;
  final LoginTransportFactory? transportFactory;
  final Future<bool> Function(Uri)? openBrowser;
  final Future<QrLoginPayload?> Function(BuildContext)? scan;

  @override
  Widget build(BuildContext context) => Theme(
    data: Theme.of(context).brightness == Brightness.dark
        ? OnboardingTheme.dark()
        : OnboardingTheme.light(),
    child: _LoginContent(
      key: ValueKey((
        reauthenticateAccount?.id,
        reauthenticateAccount?.generation,
        initialServer,
      )),
      closeOnSuccess: closeOnSuccess,
      initialServer: initialServer,
      reauthenticateAccount: reauthenticateAccount,
      transportFactory: transportFactory,
      openBrowser: openBrowser,
      scan: scan,
    ),
  );
}

class _LoginContent extends ConsumerStatefulWidget {
  const _LoginContent({
    super.key,
    required this.closeOnSuccess,
    this.initialServer,
    this.reauthenticateAccount,
    this.transportFactory,
    this.openBrowser,
    this.scan,
  });
  final bool closeOnSuccess;
  final String? initialServer;
  final StoredAccount? reauthenticateAccount;
  final LoginTransportFactory? transportFactory;
  final Future<bool> Function(Uri)? openBrowser;
  final Future<QrLoginPayload?> Function(BuildContext)? scan;
  @override
  ConsumerState<_LoginContent> createState() => _LoginContentState();
}

class _LoginContentState extends ConsumerState<_LoginContent> {
  late final TextEditingController _server;
  final _focus = FocusNode();
  LoginPhase _phase = LoginPhase.entry;
  Object? _error;
  http.Client? _transport;
  LoginSession? _session;
  ServerBase? _base;
  Completer<void>? _cancelled;
  String? _trustedOrigin;
  String? _temporaryPin;
  String? _activePin;
  bool _scannerOpen = false;
  int _generation = 0;
  bool get _busy => _phase != LoginPhase.entry;
  bool get _desktop => const {
    TargetPlatform.windows,
    TargetPlatform.macOS,
    TargetPlatform.linux,
  }.contains(defaultTargetPlatform);
  bool _valid(int generation) => mounted && generation == _generation;

  @override
  void initState() {
    super.initState();
    final initial =
        widget.reauthenticateAccount?.server ??
        widget.initialServer ??
        'https://';
    _server = TextEditingController(text: initial)
      ..selection = TextSelection.collapsed(offset: initial.length);
  }

  http.Client _clientFor(ServerBase base, int generation, {String? loginName}) {
    if (!_valid(generation)) throw const LoginException('cancelled');
    final expected = widget.reauthenticateAccount;
    if (expected != null &&
        (ServerBase.parse(expected.server).uri != base.uri ||
            loginName != null && expected.loginName != loginName)) {
      throw const LoginException('identity_mismatch');
    }
    final known = loginName == null
        ? expected
        : ref
              .read(accountsProvider)
              .items
              .where(
                (account) =>
                    account.loginName == loginName &&
                    ServerBase.parse(account.server).uri == base.uri,
              )
              .firstOrNull;
    _activePin =
        known?.certificateFingerprint ??
        (_trustedOrigin == base.uri.origin ? _temporaryPin : null);
    _transport?.close();
    return _transport =
        widget.transportFactory?.call(base, _activePin) ??
        CertificateHttpClient(server: base.uri, fingerprint: _activePin);
  }

  Future<void> _run(Future<void> Function(int generation) operation) async {
    if (_busy) return;
    final generation = ++_generation;
    _cancelled = Completer<void>();
    _focus.unfocus();
    setState(() {
      _error = null;
      _phase = LoginPhase.checking;
    });
    var retry = false;
    try {
      await operation(generation);
    } catch (error) {
      if (!_valid(generation)) return;
      final transport = _transport;
      final encounter = transport is CertificateHttpClient
          ? transport.lastEncounter
          : null;
      setState(() {
        _phase = LoginPhase.entry;
        _error = null;
      });
      if (encounter != null) {
        if (!mounted) return;
        final trusted = await confirmLoginCertificate(context, encounter);
        if (trusted && _valid(generation)) {
          _trustedOrigin = _base!.uri.origin;
          _temporaryPin = encounter.fingerprint;
          retry = true;
        }
      } else if (!(error is LoginException && error.code == 'cancelled')) {
        setState(() => _error = error);
      }
    } finally {
      if (generation == _generation) {
        _session?.cancel();
        _session = null;
        _transport?.close();
        _transport = null;
        if (mounted) setState(() => _phase = LoginPhase.entry);
      }
    }
    if (retry && _valid(generation)) await _run(operation);
  }

  Future<void> _connect() => _run((generation) async {
    final value = normalizeServerAddressInput(_server.text);
    final base = ServerBase.parse(
      value.contains('://') ? value : 'https://$value',
    );
    _base = base;
    final login = LoginClient(
      base: base,
      transport: _clientFor(base, generation),
    );
    await login.checkServer();
    if (!_valid(generation)) return;
    final session = await login.start();
    if (!_valid(generation)) {
      session.cancel();
      return;
    }
    _session = session;
    setState(() => _phase = LoginPhase.openingLogin);
    final opened = await _openPage(session.loginUri, _cancelled!.future);
    if (!_valid(generation)) return;
    if (!opened) throw const LoginException('browser_unavailable');
    setState(() => _phase = LoginPhase.waitingForLogin);
    final deadline = DateTime.now().toUtc().add(const Duration(minutes: 15));
    var lostPolls = 0;
    while (_valid(generation) && DateTime.now().toUtc().isBefore(deadline)) {
      LoginCredentials? credentials;
      try {
        credentials = await session.poll();
        lostPolls = 0;
      } on LoginException catch (error) {
        // A connection reused after the app was suspended behind the browser
        // fails once; the session stays open, so poll again on a fresh one.
        final lost =
            error.code == 'transport_failed' || error.code == 'timeout';
        if (!lost || ++lostPolls > 5) rethrow;
      }
      if (!_valid(generation)) return;
      if (credentials != null) {
        await _complete(credentials, generation);
        return;
      }
      await Future.any([
        Future<void>.delayed(const Duration(seconds: 2)),
        _cancelled!.future,
      ]);
    }
    if (_valid(generation)) throw const LoginException('login_timed_out');
  });

  Future<bool> _openPage(Uri uri, Future<void> cancelled) async {
    if (widget.openBrowser != null) return widget.openBrowser!(uri);
    final returned = Completer<void>();
    var hidden = false;
    final listener = AppLifecycleListener(
      onHide: () => hidden = true,
      onResume: () {
        if (hidden && !returned.isCompleted) returned.complete();
      },
    );
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        return false;
      }
      // A desktop window stays visible behind the browser, so there is no
      // hide and resume to wait for; polling starts right away.
      if (_desktop) return true;
      await Future.any([
        returned.future,
        cancelled,
        Future<void>.delayed(const Duration(minutes: 5)),
      ]);
      return true;
    } finally {
      listener.dispose();
    }
  }

  Future<void> _scan() async {
    if (_busy || _scannerOpen) return;
    _focus.unfocus();
    _scannerOpen = true;
    QrLoginPayload? payload;
    try {
      payload =
          await (widget.scan?.call(context) ??
              QrLoginScannerScreen.push(
                context,
                onOpenSettings: openCameraSettings,
              ));
    } finally {
      _scannerOpen = false;
    }
    if (!mounted || payload == null) return;
    if (payload is QrLoginServerOnly) {
      final expected = widget.reauthenticateAccount;
      if (expected != null &&
          ServerBase.parse(expected.server).uri != payload.server.uri) {
        setState(() => _error = const LoginException('identity_mismatch'));
        return;
      }
      _server.text = payload.server.uri.toString();
      await _connect();
    } else if (payload is QrLoginCredentials) {
      final scanned = payload;
      LoginCredentials? issued;
      await _run(
        (generation) => _scanned(
          scanned,
          generation,
          issued: issued,
          onIssued: (value) => issued = value,
        ),
      );
    }
  }

  Future<void> _scanned(
    QrLoginCredentials payload,
    int generation, {
    LoginCredentials? issued,
    required ValueChanged<LoginCredentials> onIssued,
  }) async {
    _base = payload.server;
    final transport = _clientFor(
      payload.server,
      generation,
      loginName: payload.loginName,
    );
    await LoginClient(base: payload.server, transport: transport).checkServer();
    if (!_valid(generation)) return;
    var credentials = issued ?? payload.toLoginCredentials();
    if (payload.isOneTime && issued == null) {
      try {
        final data = object(
          (await DeckClient(
            base: payload.server,
            loginName: payload.loginName,
            appPassword: payload.secret,
            transport: transport,
          ).ocs('GET', ['core', 'getapppassword-onetime'])).data,
        );
        credentials = LoginCredentials(
          server: payload.server,
          loginName: payload.loginName,
          appPassword: stringField(data, 'apppassword'),
        );
        onIssued(credentials);
      } on DeckException catch (error) {
        if (error.status == 401 || error.status == 403) {
          throw const LoginException('scanned_login_rejected');
        }
        rethrow;
      }
    }
    if (_valid(generation)) {
      await _complete(credentials, generation, scanned: true);
    }
  }

  Future<void> _complete(
    LoginCredentials credentials,
    int generation, {
    bool scanned = false,
  }) async {
    if (!_valid(generation)) return;
    final transport = _clientFor(
      credentials.server,
      generation,
      loginName: credentials.loginName,
    );
    final api = DeckClient(
      base: credentials.server,
      loginName: credentials.loginName,
      appPassword: credentials.appPassword,
      transport: transport,
    );
    String userId;
    try {
      await api.capabilities();
      userId = await api.currentUserId();
    } on DeckException catch (error) {
      if (scanned && (error.status == 401 || error.status == 403)) {
        throw const LoginException('scanned_login_rejected');
      }
      rethrow;
    }
    if (!_valid(generation)) return;
    try {
      await ref
          .read(accountsProvider)
          .add(
            credentials,
            userId: userId,
            certificateFingerprint: _activePin,
            canCommit: () => _valid(generation),
          );
    } on StateError catch (error) {
      if (error.message == 'identity_mismatch' ||
          error.message == 'certificate_changed' ||
          error.message == 'onboarding_cancelled') {
        rethrow;
      }
      throw const LoginException('local_persistence');
    } catch (_) {
      throw const LoginException('local_persistence');
    }
    if (mounted && generation == _generation && widget.closeOnSuccess) {
      Navigator.of(context).pop();
    }
  }

  void _cancel() {
    ++_generation;
    _session?.cancel();
    _transport?.close();
    _session = null;
    _transport = null;
    if (_cancelled?.isCompleted == false) _cancelled!.complete();
    setState(() => _phase = LoginPhase.entry);
  }

  @override
  void dispose() {
    ++_generation;
    _session?.cancel();
    _transport?.close();
    if (_cancelled?.isCompleted == false) _cancelled!.complete();
    _focus.dispose();
    _server.dispose();
    super.dispose();
  }

  String? _message(AppLocalizations text) {
    final error = _error;
    if (error == null) return null;
    if (error is FormatException) return text.invalidServer;
    final code = switch (error) {
      LoginException() => error.code,
      DeckException() => error.code,
      StateError() => error.message,
      _ => '',
    };
    return switch (code) {
      'server_maintenance' => text.serverMaintenance,
      'server_upgrade' => text.serverUpgrade,
      'server_not_installed' => text.serverNotInstalled,
      'browser_unavailable' => text.browserUnavailable,
      'login_timed_out' || 'flow_closed' => text.loginTimedOut,
      'identity_mismatch' => text.reauthenticateAccountMismatch,
      'certificate_changed' => text.certificateChangedTitle,
      'scanned_login_rejected' => text.scannedLoginRejected,
      'local_persistence' => text.localPersistenceFailed,
      'deck_unavailable' => text.deckError,
      'tls_failed' => text.certificateUnverifiedTitle,
      'timeout' || 'transport_failed' => text.serverUnavailable,
      'invalid_response' ||
      'invalid_content_type' ||
      'untrusted_endpoint' ||
      'start_rejected' ||
      'poll_rejected' => text.invalidResponse,
      'onboarding_cancelled' => null,
      _ => text.unexpectedError,
    };
  }

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context)!;
    final canScan =
        widget.scan != null ||
        !kIsWeb &&
            {
              TargetPlatform.android,
              TargetPlatform.iOS,
            }.contains(defaultTargetPlatform);
    return PopScope(
      canPop: !_busy,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _cancel();
      },
      child: Scaffold(
        bottomNavigationBar: widget.reauthenticateAccount == null
            ? null
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: TextButton.icon(
                    onPressed: _busy
                        ? null
                        : () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              settings: const RouteSettings(name: '/accounts'),
                              builder: (_) => const AccountsScreen(),
                            ),
                          ),
                    icon: const Icon(Icons.account_circle_outlined),
                    label: Text(text.accounts),
                  ),
                ),
              ),
        body: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: _phase == LoginPhase.waitingForLogin
                ? LoginWaiting(
                    key: const ValueKey('waiting'),
                    host: _base!.uri.host,
                    onCancel: _cancel,
                  )
                : LoginEntry(
                    key: const ValueKey('entry'),
                    serverController: _server,
                    serverFocus: _focus,
                    busy: _busy,
                    phase: _phase,
                    reauthentication: widget.reauthenticateAccount != null,
                    errorMessage: _message(text),
                    onConnect: _connect,
                    onScan: canScan ? _scan : null,
                  ),
          ),
        ),
      ),
    );
  }
}
