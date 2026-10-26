import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'desktop_platform.dart';

/// Keyboard shortcuts of the desktop builds: Ctrl (Cmd on macOS) + N and F,
/// and Escape. On mobile it only returns [child].
class DesktopShortcuts extends StatelessWidget {
  const DesktopShortcuts({
    super.key,
    required this.child,
    this.onNew,
    this.onSearch,
    this.onEscape,
  });
  final Widget child;
  final VoidCallback? onNew;
  final VoidCallback? onSearch;
  final VoidCallback? onEscape;

  @override
  Widget build(BuildContext context) {
    if (!isDesktopPlatform) return child;
    final mac = defaultTargetPlatform == TargetPlatform.macOS;
    SingleActivator command(LogicalKeyboardKey key) =>
        SingleActivator(key, control: !mac, meta: mac);
    return CallbackShortcuts(
      bindings: {
        command(LogicalKeyboardKey.keyN): ?onNew,
        command(LogicalKeyboardKey.keyF): ?onSearch,
        const SingleActivator(LogicalKeyboardKey.escape): ?onEscape,
      },
      child: Focus(autofocus: true, skipTraversal: true, child: child),
    );
  }
}
