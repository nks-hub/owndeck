import 'package:flutter/services.dart';

import '../data/card_link_inbox.dart';

final class NativeCardLinks {
  NativeCardLinks(this.inbox, {MethodChannel? channel})
    : channel =
          channel ?? const MethodChannel('com.nkshub.nextclouddeck/links');
  final CardLinkInbox inbox;
  final MethodChannel channel;
  bool _closed = false;

  Future<void> start() async {
    channel.setMethodCallHandler((call) async {
      if (!_closed && call.method == 'link' && call.arguments is String) {
        inbox.offer(call.arguments as String);
      }
    });
    try {
      final initial = await channel.invokeMethod<String>('getLaunchLink');
      if (!_closed && initial != null) inbox.offer(initial);
    } on MissingPluginException {
      // Desktop development has no mobile intent channel.
    } on PlatformException {
      // A failed launch-link read must not block account loading.
    }
  }

  void close() {
    _closed = true;
    channel.setMethodCallHandler(null);
  }
}
