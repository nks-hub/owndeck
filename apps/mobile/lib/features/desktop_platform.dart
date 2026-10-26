import 'package:flutter/foundation.dart';

/// Whether the app runs on a desktop operating system (honours test overrides).
bool get isDesktopPlatform => const {
  TargetPlatform.windows,
  TargetPlatform.macOS,
  TargetPlatform.linux,
}.contains(defaultTargetPlatform);
