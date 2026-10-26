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

/// Holds the newest shared text. With a [store] the pending text also survives an app restart,
/// so a share received before sign-in is offered again after the next start.
final class SharedTextInbox extends ChangeNotifier {
  SharedTextInbox({this.store});

  static const storeKey = 'share.pending';
  final AppPreferenceStore? store;
  SharedTextRequest? pending;
  int _sequence = 0;
  Future<void> _writes = Future.value();

  void offer(String? text, {String? subject}) {
    pending = SharedTextRequest(
      ++_sequence,
      SharedText.parse(text, subject: subject),
    );
    _persist(pending!.content);
    notifyListeners();
  }

  /// Loads a text saved by an earlier run unless something newer already arrived.
  Future<void> restore() async {
    final store = this.store;
    if (store == null) return;
    try {
      final raw = await store.read(storeKey);
      if (raw == null || raw.isEmpty || pending != null) return;
      final value = jsonDecode(raw);
      if (value is! Map) return;
      final title = value['title'];
      final description = value['description'];
      if (title is! String || title.isEmpty || description is! String) return;
      pending = SharedTextRequest(
        ++_sequence,
        SharedText(title: title, description: description),
      );
      notifyListeners();
    } on Object {
      // A damaged or unreadable saved share must not block startup.
    }
  }

  bool contains(SharedTextRequest request) => identical(pending, request);

  void complete(SharedTextRequest request) {
    if (!contains(request)) return;
    pending = null;
    _persist(null);
    notifyListeners();
  }

  void _persist(SharedText? content) {
    final store = this.store;
    if (store == null) return;
    final value = content == null
        ? ''
        : jsonEncode({
            'title': content.title,
            'description': content.description,
          });
    _writes = _writes
        .then((_) => store.write(storeKey, value))
        .catchError((Object _) {});
  }
}

final incomingSharedText = SharedTextInbox(store: SharedAppPreferenceStore());
