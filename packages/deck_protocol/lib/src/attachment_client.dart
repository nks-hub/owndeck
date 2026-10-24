part of 'client.dart';

const attachmentMaxBytes = 64 * 1024 * 1024;

List<String> _attachmentPath(
  int boardId,
  int stackId,
  int cardId, [
  DeckAttachment? attachment,
]) {
  if ([boardId, stackId, cardId].any((id) => id <= 0)) {
    throw ArgumentError('invalid_attachment_parent');
  }
  if (attachment != null &&
      (!attachment.supported ||
          attachment.id <= 0 ||
          attachment.cardId != cardId)) {
    throw ArgumentError('invalid_attachment_identity');
  }
  return [
    'boards',
    '$boardId',
    'stacks',
    '$stackId',
    'cards',
    '$cardId',
    'attachments',
    if (attachment != null) ...[attachment.type, '${attachment.id}'],
  ];
}

extension DeckAttachmentClient on DeckClient {
  Future<List<DeckAttachment>> attachments(
    int boardId,
    int stackId,
    int cardId,
  ) async {
    final response = await _request(
      'GET',
      base.deck('1.1', _attachmentPath(boardId, stackId, cardId)),
      null,
      null,
      false,
    );
    try {
      final result = objects(
        response.data,
      ).map(DeckAttachment.fromJson).toList();
      final keys = <(String, int)>{};
      if (result.any(
        (item) =>
            item.cardId != cardId ||
            item.id <= 0 ||
            !keys.add((item.type, item.id)),
      )) {
        throw const FormatException('invalid_attachment_list');
      }
      return result;
    } on FormatException {
      throw const DeckException('invalid_response');
    }
  }

  Future<DeckAttachment> uploadAttachment(
    int boardId,
    int stackId,
    int cardId, {
    required String filename,
    required String mime,
    required int length,
    required Stream<List<int>> bytes,
    String type = 'file',
    Future<void>? cancelled,
  }) async {
    if (!{'file', 'deck_file'}.contains(type) ||
        length < 0 ||
        length > attachmentMaxBytes ||
        !_safeFileSegment(filename)) {
      throw ArgumentError('invalid_attachment_upload');
    }
    final contentType = MediaType.parse(mime);
    final uri = base.deck('1.1', _attachmentPath(boardId, stackId, cardId));
    final response = await _send(
      (abort) =>
          http.AbortableMultipartRequest('POST', uri, abortTrigger: abort)
            ..headers['Accept'] = 'application/json'
            ..fields['type'] = type
            ..files.add(
              http.MultipartFile(
                'file',
                bytes,
                length,
                filename: filename,
                contentType: contentType,
              ),
            ),
      mutation: true,
      cancelled: cancelled,
      requestTimeout: const Duration(minutes: 2),
    );
    try {
      final item = DeckAttachment.fromJson(
        object(_json(response, mutation: true)),
      );
      if (item.id <= 0 || item.cardId != cardId || item.type != type) {
        throw const FormatException('invalid_attachment_identity');
      }
      return item;
    } on FormatException {
      throw const DeckException('invalid_response', uncertain: true);
    }
  }

  Future<Uint8List> downloadAttachment(
    int boardId,
    int stackId,
    DeckAttachment attachment, {
    Future<void>? cancelled,
  }) async {
    final uri = base.deck(
      '1.1',
      _attachmentPath(boardId, stackId, attachment.cardId, attachment),
    );
    final response = await _send(
      (abort) => http.AbortableRequest('GET', uri, abortTrigger: abort),
      maxBytes: attachmentMaxBytes,
      cancelled: cancelled,
      requestTimeout: const Duration(minutes: 2),
    );
    return response.bodyBytes;
  }

  Future<void> removeAttachment(
    int boardId,
    int stackId,
    DeckAttachment attachment,
  ) async {
    await _request(
      'DELETE',
      base.deck(
        '1.1',
        _attachmentPath(boardId, stackId, attachment.cardId, attachment),
      ),
      null,
      null,
      false,
    );
  }

  Future<void> restoreAttachment(
    int boardId,
    int stackId,
    DeckAttachment attachment,
  ) async {
    if (!attachment.canRestore) {
      throw ArgumentError('attachment_not_restorable');
    }
    await _request(
      'PUT',
      base.deck('1.1', [
        ..._attachmentPath(boardId, stackId, attachment.cardId, attachment),
        'restore',
      ]),
      null,
      null,
      false,
    );
  }

  Future<int> attachCloudFile(int cardId, List<String> segments) async {
    if (cardId <= 0 || segments.isEmpty || !segments.every(_safeFileSegment)) {
      throw ArgumentError('invalid_cloud_file');
    }
    final response = await ocs(
      'POST',
      ['apps', 'files_sharing', 'api', 'v1', 'shares'],
      body: {
        'path': '/${segments.join('/')}',
        'shareType': 12,
        'shareWith': '$cardId',
      },
    );
    try {
      final id = object(response.data)['id'];
      final parsed = id is int
          ? id
          : id is String
          ? int.tryParse(id)
          : null;
      if (parsed == null || parsed <= 0) {
        throw const FormatException('invalid_share_id');
      }
      return parsed;
    } on FormatException {
      throw const DeckException('invalid_response', uncertain: true);
    }
  }
}

bool _safeFileSegment(String value) =>
    value.isNotEmpty &&
    value != '.' &&
    value != '..' &&
    !value.contains('/') &&
    !value.contains('\\') &&
    !value.runes.any((c) => c < 32 || c == 127);
