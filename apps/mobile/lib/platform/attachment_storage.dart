import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../data/attachment_files.dart';

/// Opens the attachment folder. A [background] engine has no app channels, so
/// on iOS it uses the same folder the native side prepared at launch.
Future<AttachmentFiles> openAttachmentFiles({bool background = false}) async {
  final String path;
  if (Platform.isIOS && !background) {
    path = (await const MethodChannel(
      'com.nkshub.nextclouddeck/files',
    ).invokeMethod<String>('prepareAttachments'))!;
  } else {
    path =
        '${(await getApplicationSupportDirectory()).path}/owndeck-attachments';
  }
  final root = Directory(path);
  await root.create(recursive: true);
  return AttachmentFiles(root);
}
