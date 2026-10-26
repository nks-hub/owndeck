import 'dart:async';

import 'package:deck_store/deck_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/accounts.dart';
import '../l10n/app_localizations.dart';
import 'login.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  Future<void> _remove(
    BuildContext context,
    WidgetRef ref,
    StoredAccount account,
  ) async {
    final text = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: Text(text.removeAccount),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text.removeAccountQuestion),
            const SizedBox(height: 16),
            Text(text.removeAccountAccessWarning),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(text.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(text.remove),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final revoked = await ref.read(accountsProvider).remove(account.id);
      if (!revoked && messenger.mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(text.revocationFailed),
            duration: const Duration(seconds: 10),
          ),
        );
      }
    } catch (_) {
      if (messenger.mounted) {
        messenger.showSnackBar(SnackBar(content: Text(text.storageError)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = AppLocalizations.of(context)!;
    final accounts = ref.watch(accountsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(text.accounts)),
      body: Column(
        children: [
          if (accounts.busy) const LinearProgressIndicator(),
          Expanded(
            child: ListView(
              children: [
                for (final account in accounts.items)
                  ListTile(
                    selected: account.id == accounts.selected?.id,
                    leading: const Icon(Icons.account_circle_outlined),
                    title: Text(account.loginName),
                    subtitle: Text(account.server),
                    trailing: IconButton(
                      tooltip: text.removeAccount,
                      onPressed: accounts.busy
                          ? null
                          : () => _remove(context, ref, account),
                      icon: const Icon(Icons.delete_outline),
                    ),
                    onTap: accounts.busy
                        ? null
                        : () async {
                            try {
                              await accounts.select(account.id);
                            } catch (_) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(text.storageError)),
                                );
                              }
                            }
                          },
                  ),
                ListTile(
                  leading: const Icon(Icons.add),
                  title: Text(text.addAccount),
                  onTap: accounts.busy
                      ? null
                      : () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            settings: const RouteSettings(name: '/login'),
                            builder: (_) =>
                                AccountLoginScreen(accounts: accounts),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AccountLoginScreen extends StatefulWidget {
  const AccountLoginScreen({super.key, required this.accounts});
  final Accounts accounts;
  @override
  State<AccountLoginScreen> createState() => _AccountLoginScreenState();
}

class _AccountLoginScreenState extends State<AccountLoginScreen> {
  @override
  void initState() {
    super.initState();
    widget.accounts.beginOnboarding();
  }

  @override
  void dispose() {
    unawaited(widget.accounts.endOnboarding());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const LoginScreen(closeOnSuccess: true);
}
