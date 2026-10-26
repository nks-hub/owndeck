import 'package:flutter/foundation.dart';

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

final class SharedTextInbox extends ChangeNotifier {
  SharedTextRequest? pending;
  int _sequence = 0;

  void offer(String? text, {String? subject}) {
    pending = SharedTextRequest(
      ++_sequence,
      SharedText.parse(text, subject: subject),
    );
    notifyListeners();
  }

  bool contains(SharedTextRequest request) => identical(pending, request);

  void complete(SharedTextRequest request) {
    if (!contains(request)) return;
    pending = null;
    notifyListeners();
  }
}

final incomingSharedText = SharedTextInbox();
