import UIKit
import UniformTypeIdentifiers

/// Share sheet entry for text and web links. The content is parked in the App Group inbox; the app reads it when opened.
final class ShareViewController: UIViewController {
  private let statusLabel = UILabel()
  private let actionButton = UIButton(type: .system)

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground
    statusLabel.font = .preferredFont(forTextStyle: .body)
    statusLabel.adjustsFontForContentSizeCategory = true
    statusLabel.numberOfLines = 0
    statusLabel.textAlignment = .center
    statusLabel.text = NSLocalizedString("Preparing shared item…", comment: "Share extension status")
    actionButton.setTitle(NSLocalizedString("Cancel", comment: "Share extension action"), for: .normal)
    actionButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
    actionButton.addTarget(self, action: #selector(finish), for: .touchUpInside)
    actionButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
    let stack = UIStackView(arrangedSubviews: [statusLabel, actionButton])
    stack.axis = .vertical
    stack.spacing = 20
    stack.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(stack)
    NSLayoutConstraint.activate([
      stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
      stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
      stack.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
    ])
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    Task { await capture() }
  }

  @objc private func finish() {
    extensionContext?.completeRequest(returningItems: nil)
  }

  @MainActor
  private func capture() async {
    let items = (extensionContext?.inputItems as? [NSExtensionItem]) ?? []
    do {
      let body = await text(from: items)
      let subject = items.compactMap { $0.attributedTitle?.string }.first
      try IncomingShareInbox().store(text: body, subject: subject)
      statusLabel.text = NSLocalizedString("Ready. Open OwnDeck to create a card.", comment: "Share extension completion")
      actionButton.setTitle(NSLocalizedString("Done", comment: "Share extension action"), for: .normal)
    } catch {
      statusLabel.text = NSLocalizedString("This item could not be shared.", comment: "Share extension failure")
      actionButton.setTitle(NSLocalizedString("Close", comment: "Share extension action"), for: .normal)
    }
  }

  private func text(from items: [NSExtensionItem]) async -> String? {
    for provider in items.flatMap({ $0.attachments ?? [] }) {
      for type in [UTType.url, UTType.plainText] where provider.hasItemConformingToTypeIdentifier(type.identifier) {
        if let value = try? await provider.loadItem(forTypeIdentifier: type.identifier),
          let text = Self.string(from: value)
        { return text }
      }
    }
    return items.compactMap { $0.attributedContentText?.string }.first
  }

  static func string(from item: NSSecureCoding) -> String? {
    switch item {
    case let value as String: return value
    case let value as URL: return value.absoluteString
    case let value as NSAttributedString: return value.string
    case let value as Data: return String(data: value, encoding: .utf8)
    default: return nil
    }
  }
}
