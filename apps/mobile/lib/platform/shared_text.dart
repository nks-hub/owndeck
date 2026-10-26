import 'package:flutter/services.dart';

import '../data/shared_text_inbox.dart';

/// Receives text shared from other apps through the native `share` channel.
final class NativeSharedText {
  NativeSharedText(this.inbox, {MethodChannel? channel})
    : channel =
          channel ?? const MethodChannel('com.nkshub.nextclouddeck/share');
  final SharedTextInbox inbox;
  final MethodChannel channel;
  bool _closed = false;

  void _offer(Object? value) {
    if (_closed || value is! Map) return;
    final text = value['text'];
    final subject = value['subject'];
    inbox.offer(
      text is String ? text : null,
      subject: subject is String ? subject : null,
    );
  }

  Future<void> start() async {
    channel.setMethodCallHandler((call) async {
      if (call.method == 'share') _offer(call.arguments);
    });
    try {
      _offer(await channel.invokeMethod<Object>('getLaunchShare'));
    } on MissingPluginException {
      // Desktop development has no mobile share channel.
    } on PlatformException {
      // A failed launch-share read must not block account loading.
    }
  }

  void close() {
    _closed = true;
    channel.setMethodCallHandler(null);
  }
}
