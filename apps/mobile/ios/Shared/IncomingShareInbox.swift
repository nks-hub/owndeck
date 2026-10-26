import Foundation

/// Text handed from the share extension to the app through the App Group container.
struct IncomingShare: Codable, Equatable {
  let text: String?
  let subject: String?

  var channelValue: [String: String] {
    var value: [String: String] = [:]
    if let text { value["text"] = text }
    if let subject { value["subject"] = subject }
    return value
  }
}

enum IncomingShareError: Error, Equatable {
  case appGroupUnavailable
  case empty
}

/// Holds unread shares, one file each, and hands them out oldest first.
final class IncomingShareInbox {
  static let applicationGroup = "group.com.nkshub.nextclouddeck"
  static let maximumLength = 65_536

  private let directory: URL
  private let fileManager: FileManager

  convenience init() throws {
    guard let container = FileManager.default.containerURL(
      forSecurityApplicationGroupIdentifier: Self.applicationGroup
    ) else { throw IncomingShareError.appGroupUnavailable }
    try self.init(directory: container.appendingPathComponent("share-inbox-v1", isDirectory: true))
  }

  init(directory: URL, fileManager: FileManager = .default) throws {
    self.directory = directory
    self.fileManager = fileManager
    try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
  }

  /// Stores the share and returns it, or throws `empty` when both parts are blank.
  @discardableResult
  func store(text: String?, subject: String?) throws -> IncomingShare {
    let share = IncomingShare(text: normalized(text), subject: normalized(subject))
    if share.text == nil && share.subject == nil { throw IncomingShareError.empty }
    let stamp = String(format: "%020llu", UInt64(Date().timeIntervalSince1970 * 1_000_000))
    let file = directory.appendingPathComponent("share-\(stamp)-\(UUID().uuidString).json")
    try JSONEncoder().encode(share).write(to: file, options: [.atomic])
    return share
  }

  /// Removes and returns the oldest stored share.
  func take() -> IncomingShare? {
    for file in pendingFiles() {
      if let share = claim(file) { return share }
    }
    return nil
  }

  /// Removes and returns every stored share, oldest first.
  func takeAll() -> [IncomingShare] {
    pendingFiles().compactMap(claim)
  }

  private func pendingFiles() -> [URL] {
    let files = (try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
    return files
      .filter { $0.lastPathComponent.hasPrefix("share-") && $0.pathExtension == "json" }
      .sorted { $0.lastPathComponent < $1.lastPathComponent }
  }

  /// The file is renamed first so two readers never return the same share and a concurrent `store` is never deleted.
  private func claim(_ file: URL) -> IncomingShare? {
    let claimed = directory.appendingPathComponent("claimed-\(UUID().uuidString).json")
    do { try fileManager.moveItem(at: file, to: claimed) } catch { return nil }
    defer { try? fileManager.removeItem(at: claimed) }
    return (try? Data(contentsOf: claimed)).flatMap { try? JSONDecoder().decode(IncomingShare.self, from: $0) }
  }

  private func normalized(_ value: String?) -> String? {
    guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else { return nil }
    return String(String.UnicodeScalarView(trimmed.unicodeScalars.prefix(Self.maximumLength)))
  }
}
