import 'package:deck_protocol/deck_protocol.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

Future<bool> confirmLoginCertificate(
  BuildContext context,
  CertificateEncounter encounter,
) async {
  final text = AppLocalizations.of(context)!;
  final changed =
      encounter.outcome.refusal == CertificateRefusal.pinnedFingerprintMismatch;
  final fingerprint = [
    for (var i = 0; i < encounter.fingerprint.length; i += 2)
      encounter.fingerprint.substring(
        i,
        (i + 2).clamp(0, encounter.fingerprint.length),
      ),
  ].join(':').toUpperCase();
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          key: const Key('certificate-trust-dialog'),
          title: Text(
            changed
                ? text.certificateChangedTitle
                : text.certificateUnverifiedTitle,
          ),
          scrollable: true,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                changed
                    ? text.certificateChangedBody(encounter.host)
                    : text.certificateUnverifiedBody(encounter.host),
              ),
              const SizedBox(height: 16),
              Text(
                text.certificateFingerprintLabel,
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 4),
              SelectableText(
                fingerprint,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(changed ? text.close : text.cancel),
            ),
            if (encounter.outcome.decision == CertificateTrustDecision.ask)
              FilledButton(
                key: const Key('certificate-trust-confirm'),
                onPressed: () => Navigator.pop(context, true),
                child: Text(text.certificateTrustAction),
              ),
          ],
        ),
      ) ==
      true;
}
