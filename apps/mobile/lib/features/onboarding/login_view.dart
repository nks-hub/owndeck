import 'package:flutter/material.dart';
import '../../core/brand_mark.dart';
import '../../l10n/app_localizations.dart';

enum LoginPhase { entry, checking, openingLogin, waitingForLogin }

final class LoginEntry extends StatelessWidget {
  const LoginEntry({
    super.key,
    required this.serverController,
    required this.serverFocus,
    required this.busy,
    required this.phase,
    required this.reauthentication,
    required this.errorMessage,
    required this.onConnect,
    required this.onScan,
  });

  final TextEditingController serverController;
  final FocusNode serverFocus;
  final bool busy;
  final LoginPhase phase;
  final bool reauthentication;
  final String? errorMessage;
  final VoidCallback onConnect;
  final VoidCallback? onScan;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 900;
        final content = desktop
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: _Introduction(
                      key: const Key('onboarding-introduction'),
                      strings: strings,
                    ),
                  ),
                  const SizedBox(width: 48),
                  SizedBox(
                    width: 420,
                    child: _ServerCard(
                      key: const Key('onboarding-server-card'),
                      controller: serverController,
                      focusNode: serverFocus,
                      busy: busy,
                      phase: phase,
                      reauthentication: reauthentication,
                      errorMessage: errorMessage,
                      onConnect: onConnect,
                      onScan: onScan,
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Introduction(
                    key: const Key('onboarding-introduction'),
                    strings: strings,
                  ),
                  const SizedBox(height: 24),
                  _ServerCard(
                    key: const Key('onboarding-server-card'),
                    controller: serverController,
                    focusNode: serverFocus,
                    busy: busy,
                    phase: phase,
                    reauthentication: reauthentication,
                    errorMessage: errorMessage,
                    onConnect: onConnect,
                    onScan: onScan,
                  ),
                ],
              );
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: desktop ? 48 : 20,
            vertical: desktop ? 40 : 24,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: content,
            ),
          ),
        );
      },
    );
  }
}

final class _Introduction extends StatelessWidget {
  const _Introduction({super.key, required this.strings});

  final AppLocalizations strings;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BrandMark(),
        const SizedBox(height: 24),
        Text(strings.onboardingTitle, style: textTheme.headlineLarge),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Text(
            strings.onboardingBody,
            style: textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 28),
        _FeatureLine(
          icon: Icons.hub_outlined,
          title: strings.multiServerTitle,
          body: strings.multiServerBody,
        ),
        const SizedBox(height: 18),
        _FeatureLine(
          icon: Icons.shield_outlined,
          title: strings.secureTitle,
          body: strings.secureBody,
        ),
      ],
    );
  }
}

final class _FeatureLine extends StatelessWidget {
  const _FeatureLine({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, color: scheme.onPrimaryContainer),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 3),
              Text(
                body,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

final class _ServerCard extends StatelessWidget {
  const _ServerCard({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.busy,
    required this.phase,
    required this.reauthentication,
    required this.errorMessage,
    required this.onConnect,
    required this.onScan,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool busy;
  final LoginPhase phase;
  final bool reauthentication;
  final String? errorMessage;
  final VoidCallback onConnect;
  final VoidCallback? onScan;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              reauthentication
                  ? strings.reauthenticateAccountTitle
                  : strings.addServerTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              focusNode: focusNode,
              enabled: !busy && !reauthentication,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.url],
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                labelText: strings.serverAddressLabel,
                hintText: strings.serverAddressHint,
                prefixIcon: const Icon(Icons.language_rounded),
              ),
              onSubmitted: (_) => onConnect(),
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 14),
              Semantics(
                liveRegion: true,
                child: _InlineError(message: errorMessage!),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: busy ? null : onConnect,
              icon: busy
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    )
                  : const Icon(Icons.arrow_forward_rounded),
              label: Text(_buttonLabel(strings)),
            ),
            if (onScan != null) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                key: const Key('onboarding-scan-login-code'),
                onPressed: busy ? null : onScan,
                icon: const Icon(Icons.qr_code_scanner_rounded),
                label: Text(strings.scanLoginCode),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _buttonLabel(AppLocalizations strings) => switch (phase) {
    LoginPhase.entry =>
      reauthentication ? strings.reauthenticateAccountAction : strings.connect,
    LoginPhase.checking => strings.checkingServer,
    LoginPhase.openingLogin => strings.openingLogin,
    LoginPhase.waitingForLogin => strings.waitingForLogin,
  };
}

final class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, color: scheme.onErrorContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: scheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}

final class LoginWaiting extends StatelessWidget {
  const LoginWaiting({super.key, required this.host, required this.onCancel});

  final String host;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  const BrandMark(size: 64),
                  const SizedBox(height: 28),
                  const CircularProgressIndicator(),
                  const SizedBox(height: 24),
                  Text(
                    strings.waitingForLogin,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    strings.waitingForLoginBody,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    host,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: onCancel,
                    icon: const Icon(Icons.close_rounded),
                    label: Text(strings.cancel),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
