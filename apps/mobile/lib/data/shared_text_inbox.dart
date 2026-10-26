import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../core/app_preferences.dart';

const sharedTitleLimit = 255;
const sharedTextLimit = 65536;
const sharedDraftPrefix = 'share:';

/// Text received from the system share sheet, split into a card title and description.
final class SharedText {
  const SharedText({required this.title, required this.description});
  final String title;
  final String description;

  /// Builds a card draft from shared [text] and an optional [subject], or null when both are blank.
  static SharedText? parse(String? text, {String? subject}) {
    var body = (text ?? '').trim();
    if (body.runes.length > sharedTextLimit) {
      body = String.fromCharCodes(body.runes.take(sharedTextLimit));
    }
    final heading = (subject ?? '').trim();
    final firstLine = body
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .firstWhere((line) => line.isNotEmpty, orElse: () => '');
    final source = heading.isNotEmpty ? heading : firstLine;
    if (source.isEmpty) return null;
    final title = String.fromCharCodes(source.runes.take(sharedTitleLimit));
    return SharedText(title: title, description: body == title ? '' : body);
  }
}

final class SharedTextRequest {
  const SharedTextRequest(this.sequence, this.content);
  final int sequence;
  final SharedText? content;
}

/// Holds shared texts in arrival order; [pending] is the oldest one still to be offered.
/// With a [store] the queue also survives an app restart, so shares received before
/// sign-in are offered again after the next start.
final class SharedTextInbox extends ChangeNotifier {
  SharedTextInbox({this.store});

  static const storeKey = 'share.pending';
  final AppPreferenceStore? store;
  final List<SharedTextRequest> _queue = [];
  int _sequence = 0;
  bool _restored = false;
  Future<void> _writes = Future.value();

  SharedTextRequest? get pending => _queue.firstOrNull;

  void offer(String? text, {String? subject}) {
    _queue.add(
      SharedTextRequest(++_sequence, SharedText.parse(text, subject: subject)),
    );
    _persist();
    notifyListeners();
  }

  /// Loads shares saved by an earlier run in front of any that arrived meanwhile.
  /// Accepts the former single-share value as well as the current list.
  Future<void> restore() async {
    final store = this.store;
    if (store == null || _restored) return;
    _restored = true;
    final gate = Completer<void>();
    _writes = _writes.then((_) => gate.future);
    try {
      final raw = await store.read(storeKey);
      if (raw == null || raw.isEmpty) return;
      final value = jsonDecode(raw);
      final restored = <SharedTextRequest>[];
      for (final item in value is List ? value : [value]) {
        if (item is! Map) continue;
        final title = item['title'];
        final description = item['description'];
        if (title is! String || title.isEmpty || description is! String) {
          continue;
        }
        restored.add(
          SharedTextRequest(
            ++_sequence,
            SharedText(title: title, description: description),
          ),
        );
      }
      if (restored.isEmpty) return;
      _queue.insertAll(0, restored);
      notifyListeners();
    } on Object {
      // A damaged or unreadable saved share must not block startup.
    } finally {
      gate.complete();
    }
  }

  bool contains(SharedTextRequest request) => identical(pending, request);

  void complete(SharedTextRequest request) {
    if (!contains(request)) return;
    _queue.removeAt(0);
    _persist();
    notifyListeners();
  }

  void _persist() {
    final store = this.store;
    if (store == null) return;
    _writes = _writes
        .then((_) {
          final items = [
            for (final request in _queue)
              if (request.content case final content?)
                {'title': content.title, 'description': content.description},
          ];
          return store.write(storeKey, items.isEmpty ? '' : jsonEncode(items));
        })
        .catchError((Object _) {});
  }
}

final incomingSharedText = SharedTextInbox(store: SharedAppPreferenceStore());
