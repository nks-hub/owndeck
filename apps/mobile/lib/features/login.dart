import 'dart:async';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../core/errors.dart';
import '../data/accounts.dart';
import '../l10n/app_localizations.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({
    super.key,
    this.closeOnSuccess = false,
    this.initialServer,
  });
  final bool closeOnSuccess;
  final String? initialServer;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _server = TextEditingController();
  http.Client? _transport;
  LoginSession? _session;
  bool _waiting = false;
  Object? _error;
  bool _browserFailed = false;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _server.text = widget.initialServer ?? '';
  }

  Future<void> _connect() async {
    if (_waiting) return;
    final generation = ++_generation;
    setState(() {
      _waiting = true;
      _error = null;
      _browserFailed = false;
    });
    final transport = http.Client();
    _transport = transport;
    try {
      final base = ServerBase.parse(_server.text);
      final session = await LoginClient(
        base: base,
        transport: transport,
      ).start();
      if (!mounted || generation != _generation) {
        session.cancel();
        return;
      }
      _session = session;
      final opened = await launchUrl(
        session.loginUri,
        mode: LaunchMode.externalApplication,
      );
      if (!mounted || generation != _generation) return;
      if (!opened) {
        setState(() => _browserFailed = true);
        return;
      }
      while (!session.isClosed && mounted && generation == _generation) {
        final credentials = await session.poll();
        if (!mounted || generation != _generation) return;
        if (credentials != null) {
          await DeckClient(
            base: credentials.server,
            loginName: credentials.loginName,
            appPassword: credentials.appPassword,
            transport: transport,
          ).capabilities();
          if (!mounted || generation != _generation) return;
          await ref.read(accountsProvider).add(credentials);
          if (mounted && widget.closeOnSuccess && generation == _generation) {
            Navigator.of(context).pop();
          }
          return;
        }
        await Future<void>.delayed(const Duration(seconds: 2));
      }
    } catch (error) {
      if (mounted && generation == _generation) setState(() => _error = error);
    } finally {
      transport.close();
      if (generation == _generation) {
        _session?.cancel();
        _session = null;
        _transport = null;
        if (mounted) setState(() => _waiting = false);
      }
    }
  }

  void _cancel() {
    ++_generation;
    _session?.cancel();
    _transport?.close();
    _session = null;
    _transport = null;
    setState(() => _waiting = false);
  }

  @override
  void dispose() {
    ++_generation;
    _session?.cancel();
    _transport?.close();
    _server.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(text.appTitle)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.all(24),
              shrinkWrap: true,
              children: [
                Icon(
                  Icons.view_kanban_outlined,
                  size: 56,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  text.connectTitle,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Text(text.connectDescription),
                const SizedBox(height: 24),
                TextField(
                  controller: _server,
                  enabled: !_waiting,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  textInputAction: TextInputAction.go,
                  decoration: InputDecoration(
                    labelText: text.serverLabel,
                    hintText: 'https://cloud.example.com',
                  ),
                  onSubmitted: (_) => _connect(),
                ),
                const SizedBox(height: 16),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Semantics(
                      liveRegion: true,
                      child: Text(errorMessage(_error!, text)),
                    ),
                  ),
                if (_browserFailed) Text(text.browserError),
                if (_waiting) ...[
                  const LinearProgressIndicator(),
                  const SizedBox(height: 16),
                  Semantics(liveRegion: true, child: Text(text.waiting)),
                  const SizedBox(height: 16),
                  OutlinedButton(onPressed: _cancel, child: Text(text.cancel)),
                ] else
                  FilledButton.icon(
                    onPressed: _connect,
                    icon: const Icon(Icons.login),
                    label: Text(text.connect),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
