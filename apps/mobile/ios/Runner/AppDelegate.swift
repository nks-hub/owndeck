import Flutter
import UIKit

final class CardLinkDelivery {
  private var pending: String?
  private var ready = false
  var emit: ((String) -> Void)?

  func receive(_ url: URL) -> Bool {
    guard url.scheme == "ncdeck", url.absoluteString.utf8.count <= 4096 else { return false }
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

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  let cardLinks = CardLinkDelivery()

  override func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
    cardLinks.receive(url) || super.application(application, open: url, options: options)
  }

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
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
