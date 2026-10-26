import Cocoa
import FlutterMacOS

/// Smallest window the adaptive layout is designed for, in points.
/// Keep in sync with the Windows and Linux runners.
private let minimumWindowWidth: CGFloat = 600
private let minimumWindowHeight: CGFloat = 400

/// Key AppKit stores the window frame under between launches.
private let windowFrameAutosaveName = "OwnDeckMainWindow"

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
    self.minSize = NSSize(width: minimumWindowWidth, height: minimumWindowHeight)
    self.title = "OwnDeck"
    // Window state restoration keeps its own copy of the frame and ignores
    // `minSize`, so it is off and the saved frame is restored by hand, clamped
    // to the minimum (`setFrameUsingName` does not clamp).
    self.isRestorable = false
    self.setFrameAutosaveName(windowFrameAutosaveName)
    if self.setFrameUsingName(windowFrameAutosaveName) {
      var restored = self.frame
      restored.size.width = max(restored.width, minimumWindowWidth)
      restored.size.height = max(restored.height, minimumWindowHeight)
      self.setFrame(restored, display: true)
    }

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
