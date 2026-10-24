import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../data/attachment_files.dart';

Future<AttachmentFiles> openAttachmentFiles() async {
  final String path;
  if (Platform.isIOS) {
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
