part of 'client.dart';

extension DeckFilesClient on DeckClient {
  Future<List<CloudFile>> files(
    String userId,
    List<String> directory, {
    Future<void>? cancelled,
  }) async {
    if (!_safeFileSegment(userId) || !directory.every(_safeFileSegment)) {
      throw ArgumentError('invalid_files_path');
    }
    final prefix = [
      ...base.uri.pathSegments.where((part) => part.isNotEmpty),
      'remote.php',
      'dav',
      'files',
      userId,
    ];
    final parent = [...prefix, ...directory];
    final uri = base.uri.replace(pathSegments: [...parent, '']);
    final response = await _send(
      (abort) => http.AbortableRequest('PROPFIND', uri, abortTrigger: abort)
        ..headers.addAll({
          'Depth': '1',
          'Content-Type': 'application/xml',
          'Accept': 'application/xml',
        })
        ..body =
            '<?xml version="1.0"?><d:propfind xmlns:d="DAV:" xmlns:oc="http://owncloud.org/ns">'
            '<d:prop><d:resourcetype/><d:getcontentlength/><d:getcontenttype/><oc:fileid/><oc:permissions/></d:prop></d:propfind>',
      cancelled: cancelled,
    );
    if (response.statusCode != 207) {
      throw const DeckException('invalid_dav_listing');
    }
    try {
      final text = utf8.decode(response.bodyBytes);
      if (RegExp(
        r'<!DOCTYPE\b|<!ENTITY\b',
        caseSensitive: false,
      ).hasMatch(text)) {
        throw const FormatException('invalid_xml');
      }
      final root = XmlDocument.parse(text).rootElement;
      if (root.localName != 'multistatus' || root.namespaceUri != 'DAV:') {
        throw const FormatException('invalid_multistatus');
      }
      final result = <CloudFile>[];
      final seen = <String>{};
      for (final node in root.childElements) {
        if (node.localName == 'responsedescription' &&
            node.namespaceUri == 'DAV:') {
          continue;
        }
        if (node.localName != 'response' || node.namespaceUri != 'DAV:') {
          throw const FormatException('invalid_dav_response');
        }
        final hrefs = node.findElements('href', namespaceUri: 'DAV:').toList();
        if (hrefs.length != 1) throw const FormatException('invalid_dav_href');
        final segments = _davSegments(
          hrefs.single.innerText.trim(),
          uri,
          parent,
        );
        if (!seen.add(segments.join('/'))) {
          throw const FormatException('duplicate_dav_path');
        }
        final status = node.getElement('status', namespaceUri: 'DAV:');
        if (status != null && !_davSuccess(status.innerText)) {
          throw const FormatException('incomplete_dav_listing');
        }
        final props = <(String?, String), XmlElement>{};
        for (final stat in node.findElements(
          'propstat',
          namespaceUri: 'DAV:',
        )) {
          final status = stat.getElement('status', namespaceUri: 'DAV:');
          if (status == null) throw const FormatException('missing_dav_status');
          if (!_davSuccess(status.innerText)) continue;
          final prop = stat.getElement('prop', namespaceUri: 'DAV:');
          if (prop == null) {
            throw const FormatException('missing_dav_properties');
          }
          for (final value in prop.childElements) {
            final key = (value.namespaceUri, value.localName);
            if (props.containsKey(key)) {
              throw const FormatException('duplicate_dav_property');
            }
            props[key] = value;
          }
        }
        final type = props[('DAV:', 'resourcetype')];
        if (type == null) throw const FormatException('missing_dav_type');
        if (type.childElements.any(
          (e) => e.localName != 'collection' || e.namespaceUri != 'DAV:',
        )) {
          throw const FormatException('unsupported_dav_type');
        }
        if (segments.length == parent.length) continue;
        final permissions =
            props[('http://owncloud.org/ns', 'permissions')]?.innerText ?? '';
        final length = int.tryParse(
          props[('DAV:', 'getcontentlength')]?.innerText.trim() ?? '',
        );
        result.add(
          CloudFile(
            segments: List.unmodifiable(segments.skip(prefix.length)),
            directory: type.childElements.isNotEmpty,
            readable: permissions.contains('G'),
            shareable: permissions.contains('S'),
            size: length != null && length >= 0 ? length : null,
            mime: props[('DAV:', 'getcontenttype')]?.innerText.trim(),
            id: int.tryParse(
              props[('http://owncloud.org/ns', 'fileid')]?.innerText.trim() ??
                  '',
            ),
          ),
        );
      }
      result.sort(
        (a, b) => a.directory == b.directory
            ? a.name.toLowerCase().compareTo(b.name.toLowerCase())
            : a.directory
            ? -1
            : 1,
      );
      return result;
    } on FormatException {
      throw const DeckException('invalid_dav_listing');
    } on XmlException {
      throw const DeckException('invalid_dav_listing');
    }
  }
}

List<String> _davSegments(String href, Uri request, List<String> parent) {
  if (RegExp(r'%(?![0-9a-fA-F]{2})').hasMatch(href)) {
    throw const FormatException('invalid_dav_href');
  }
  final uri = Uri.parse(href);
  if (uri.userInfo.isNotEmpty ||
      uri.hasQuery ||
      uri.hasFragment ||
      (uri.hasAuthority && (uri.origin != request.origin)) ||
      (!uri.hasAuthority && (uri.hasScheme || !uri.path.startsWith('/')))) {
    throw const FormatException('invalid_dav_href');
  }
  final segments = uri.pathSegments.toList();
  if (segments.isNotEmpty && segments.last.isEmpty) segments.removeLast();
  if (!segments.every(_safeFileSegment) ||
      segments.length < parent.length ||
      segments.length > parent.length + 1 ||
      !Iterable<int>.generate(
        parent.length,
      ).every((index) => segments[index] == parent[index])) {
    throw const FormatException('invalid_dav_href');
  }
  return segments;
}

bool _davSuccess(String status) =>
    RegExp(r'^HTTP/\d+(?:\.\d+)? 2\d\d(?: |$)').hasMatch(status.trim());
