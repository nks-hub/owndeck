import Flutter
import UIKit
import workmanager_apple

final class CardLinkDelivery {
  private var pending: String?
  private var ready = false
  var emit: ((String) -> Void)?

  func receive(_ url: URL) -> Bool {
    guard url.scheme == "ncdeck", url.host == "open", url.absoluteString.utf8.count <= 4096 else { return false }
    if ready, let emit { emit(url.absoluteString) } else { pending = url.absoluteString }
    return true
  }

  func take() -> String? {
    ready = true
    let value = pending
    pending = nil
    return value
  }
}

/// Receives text from `ncdeck://share?text=...&subject=...` URLs, for example from Shortcuts.
final class ShareDelivery {
  private var pending: [[String: String]] = []
  private var ready = false
  private let inbox: IncomingShareInbox?
  var emit: (([String: String]) -> Void)?

  init(inbox: IncomingShareInbox? = try? IncomingShareInbox()) {
    self.inbox = inbox
  }

  /// Moves the shares left by the share extension to Flutter in arrival order, or holds them until Flutter asks.
  func drain() {
    deliver((inbox?.takeAll() ?? []).map(\.channelValue).filter { !$0.isEmpty })
  }

  private func deliver(_ values: [[String: String]]) {
    if ready, let emit { values.forEach(emit) } else { pending.append(contentsOf: values) }
  }

  func receive(_ url: URL) -> Bool {
    guard url.scheme == "ncdeck", url.host == "share",
      let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems
    else { return false }
    var value: [String: String] = [:]
    for name in ["text", "subject"] {
      if let item = items.first(where: { $0.name == name })?.value, !item.isEmpty {
        value[name] = String(item.prefix(65536))
      }
    }
    guard !value.isEmpty else { return false }
    deliver([value])
    return true
  }

  func take() -> [[String: String]] {
    if !ready { drain() }
    ready = true
    let values = pending
    pending = []
    return values
  }
}

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  let cardLinks = CardLinkDelivery()
  let shares = ShareDelivery()

  override func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
    shares.receive(url) || cardLinks.receive(url) || super.application(application, open: url, options: options)
  }

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Background refresh starts a headless engine that needs the plugins registered.
    WorkmanagerPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }
    // With UIScene the plugin registers late, so BGTaskScheduler handlers are restored here.
    WorkmanagerPlugin.registerLaunchHandlers()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let links = FlutterMethodChannel(name: "com.nkshub.nextclouddeck/links", binaryMessenger: engineBridge.applicationRegistrar.messenger())
    links.setMethodCallHandler { [weak self] call, result in
      if call.method == "getLaunchLink" { result(self?.cardLinks.take()) }
      else { result(FlutterMethodNotImplemented) }
    }
    cardLinks.emit = { value in links.invokeMethod("link", arguments: value) }
    let share = FlutterMethodChannel(name: "com.nkshub.nextclouddeck/share", binaryMessenger: engineBridge.applicationRegistrar.messenger())
    share.setMethodCallHandler { [weak self] call, result in
      if call.method == "getLaunchShare" { result(self?.shares.take()) }
      else { result(FlutterMethodNotImplemented) }
    }
    shares.emit = { value in share.invokeMethod("share", arguments: value) }
    let channel = FlutterMethodChannel(name: "com.nkshub.nextclouddeck/files", binaryMessenger: engineBridge.applicationRegistrar.messenger())
    channel.setMethodCallHandler { call, result in
      guard call.method == "prepareAttachments" else {
        result(FlutterMethodNotImplemented)
        return
      }
      do {
        let base = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        var folder = base.appendingPathComponent("owndeck-attachments", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try folder.setResourceValues(values)
        result(folder.path)
      } catch {
        result(FlutterError(code: "attachment_storage_unavailable", message: nil, details: nil))
      }
    }
  }
}
