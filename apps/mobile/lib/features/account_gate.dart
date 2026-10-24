import 'dart:async';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors.dart';
import '../core/telemetry_bootstrap.dart';
import '../data/accounts.dart';
import '../data/card_link_inbox.dart';
import '../data/card_reads.dart';
import '../data/session.dart';
import '../l10n/app_localizations.dart';
import '../platform/card_links.dart';
import 'boards.dart';
import 'card_detail.dart';
import 'login.dart';

class DeckAccountGate extends ConsumerStatefulWidget {
  const DeckAccountGate({super.key, this.links});
  final CardLinkInbox? links;
  @override
  ConsumerState<DeckAccountGate> createState() => _DeckAccountGateState();
}

class _DeckAccountGateState extends ConsumerState<DeckAccountGate> {
  late final _links = widget.links ?? incomingCardLinks;
  NativeCardLinks? _native;
  DeckSession? _shown;
  GlobalKey<NavigatorState>? _navigation;
  bool _routing = false;
  int? _authenticationRetry;

  @override
  void initState() {
    super.initState();
    _links.addListener(_inboxChanged);
    if (widget.links == null) {
      _native = NativeCardLinks(_links);
      unawaited(_native!.start());
    }
    _schedule();
  }

  @override
  void dispose() {
    _links.removeListener(_inboxChanged);
    _native?.close();
    super.dispose();
  }

  void _schedule() {
    if (!mounted || _routing || _links.pending == null) return;
    _routing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (ModalRoute.of(context)?.isCurrent == false) {
        setState(() => _routing = false);
        return;
      }
      setState(() {});
      await WidgetsBinding.instance.endOfFrame;
      await _route();
    });
  }

  void _inboxChanged() {
    if (!mounted) return;
    setState(() {});
    _schedule();
  }

  Future<StoredAccount?> _choose(
    Accounts accounts,
    DeckCardLink link,
    CardLinkRequest request,
  ) async {
    final matching = accountsForCardLink(accounts.items, link);
    final selected = matching
        .where((account) => account.id == accounts.selected?.id)
        .firstOrNull;
    if (selected != null) return selected;
    if (matching.length == 1) return matching.single;
    final text = AppLocalizations.of(context)!;
    if (matching.isEmpty) {
      final add = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(text.cardLinkAccountRequired),
          content: Text(link.server.uri.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(text.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(text.addAccount),
            ),
          ],
        ),
      );
      if (add != true || !mounted || !_links.contains(request)) return null;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          settings: const RouteSettings(name: '/login'),
          builder: (_) => LoginScreen(
            initialServer: link.server.uri.toString(),
            closeOnSuccess: true,
          ),
        ),
      );
      if (!mounted || !_links.contains(request)) return null;
      final updated = accountsForCardLink(accounts.items, link);
      return updated
          .where((account) => account.id == accounts.selected?.id)
          .firstOrNull;
    }
    return showDialog<StoredAccount>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(text.chooseCardLinkAccount),
        children: [
          for (final account in matching)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, account),
              child: Text(account.loginName),
            ),
        ],
      ),
    );
  }

  Future<void> _route() async {
    final request = _links.pending;
    if (!mounted || request == null) {
      _routing = false;
      return;
    }
    var retryAuthentication = false;
    var deferred = false;
    try {
      final link = request.link;
      if (link == null) throw const FormatException('invalid_card_link');
      final accounts = ref.read(accountsProvider);
      await accounts.ready;
      if ((!mounted || !_links.contains(request))) return;
      if (ModalRoute.of(context)?.isCurrent == false) {
        deferred = true;
        return;
      }
      if (accounts.loadError != null) throw StateError('account_unavailable');
      final selected = await _choose(accounts, link, request);
      if ((!mounted || !_links.contains(request)) || selected == null) return;
      if (ModalRoute.of(context)?.isCurrent == false) {
        deferred = true;
        return;
      }
      if (accounts.selected?.id != selected.id) {
        await accounts.select(selected.id);
      }
      if ((!mounted || !_links.contains(request))) return;
      if (accounts.session == null) {
        if (!mounted) return;
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            settings: const RouteSettings(name: '/login'),
            builder: (_) => LoginScreen(
              reauthenticateAccount: accounts.selected,
              closeOnSuccess: true,
            ),
          ),
        );
      }
      if ((!mounted || !_links.contains(request))) return;
      final session = accounts.session;
      if (session == null ||
          session.account.id != selected.id ||
          ServerBase.parse(session.account.server).uri != link.server.uri) {
        return;
      }
      await WidgetsBinding.instance.endOfFrame;
      if ((!mounted || !_links.contains(request)) ||
          !identical(accounts.session, session)) {
        return;
      }
      if (ModalRoute.of(context)?.isCurrent == false) {
        deferred = true;
        return;
      }
      final card = await session.openRemoteCard(link.boardId, link.cardId);
      if ((!mounted || !_links.contains(request)) ||
          !identical(accounts.session, session) ||
          !identical(_shown, session)) {
        return;
      }
      if (ModalRoute.of(context)?.isCurrent == false) {
        deferred = true;
        return;
      }
      _navigation?.currentState?.push(
        MaterialPageRoute<void>(
          settings: const RouteSettings(name: '/card'),
          builder: (_) =>
              CardScreen(session: session, board: card.board, card: card.card),
        ),
      );
    } catch (error) {
      if (mounted && _links.contains(request)) {
        if (error is DeckException &&
            error.status == 401 &&
            _authenticationRetry != request.sequence) {
          _authenticationRetry = request.sequence;
          retryAuthentication = true;
        } else {
          final text = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                error is FormatException
                    ? text.invalidCardLink
                    : errorMessage(error, text),
              ),
            ),
          );
        }
      }
    } finally {
      if (mounted && !retryAuthentication && !deferred) {
        _links.complete(request);
      }
      _routing = false;
      if (mounted) setState(() {});
      if (!deferred) _schedule();
    }
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsProvider);
    final text = AppLocalizations.of(context)!;
    final current = ModalRoute.of(context)?.isCurrent != false;
    if (current) _schedule();
    final busy = _routing && _links.pending != null && current;
    return Stack(
      fit: StackFit.expand,
      children: [
        AbsorbPointer(
          absorbing: busy,
          child: FutureBuilder<void>(
            future: accounts.ready,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              final text = AppLocalizations.of(context)!;
              if (accounts.loadError != null) {
                return Scaffold(
                  body: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(text.storageError),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: accounts.retryLoad,
                            child: Text(text.retry),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              final session = accounts.session;
              if (!identical(_shown, session)) {
                _shown = session;
                _navigation = session == null
                    ? null
                    : GlobalKey<NavigatorState>();
              }
              if (session == null) {
                return LoginScreen(reauthenticateAccount: accounts.selected);
              }
              return Navigator(
                key: _navigation,
                observers: [telemetry.navigatorObserver()],
                onGenerateRoute: (_) => MaterialPageRoute<void>(
                  settings: const RouteSettings(name: '/boards'),
                  builder: (_) => BoardsScreen(session: session),
                ),
              );
            },
          ),
        ),
        if (busy)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Material(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(text.openingCardLink)),
                      TextButton(
                        onPressed: () {
                          final request = _links.pending;
                          if (request != null) _links.complete(request);
                        },
                        child: Text(text.cancel),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
