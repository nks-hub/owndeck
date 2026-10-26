import XCTest

@testable import Runner

final class IncomingShareInboxTests: XCTestCase {
  private var root: URL!

  override func setUpWithError() throws {
    root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
  }

  override func tearDownWithError() throws {
    try? FileManager.default.removeItem(at: root)
  }

  func testStoredShareIsTrimmedSurvivesANewInstanceAndIsTakenOnce() throws {
    try IncomingShareInbox(directory: root).store(text: "  https://example.com/a \n", subject: " Article ")
    let reopened = try IncomingShareInbox(directory: root)
    let share = try XCTUnwrap(reopened.take())
    XCTAssertEqual(share.text, "https://example.com/a")
    XCTAssertEqual(share.subject, "Article")
    XCTAssertEqual(share.channelValue, ["text": "https://example.com/a", "subject": "Article"])
    XCTAssertNil(reopened.take())
  }

  func testSharesAreTakenOldestFirstAndNoneIsLost() throws {
    let inbox = try IncomingShareInbox(directory: root)
    try inbox.store(text: "one", subject: nil)
    try inbox.store(text: "two", subject: nil)
    try inbox.store(text: "three", subject: nil)
    XCTAssertEqual(inbox.take()?.text, "one")
    XCTAssertEqual(inbox.takeAll().map(\.text), ["two", "three"])
    XCTAssertNil(inbox.take())
  }

  func testBlankShareIsRejectedAndLeavesNothing() throws {
    let inbox = try IncomingShareInbox(directory: root)
    XCTAssertThrowsError(try inbox.store(text: " \n", subject: nil)) {
      XCTAssertEqual($0 as? IncomingShareError, .empty)
    }
    XCTAssertNil(inbox.take())
  }

  func testTextIsCutToTheDartLimitByUnicodeScalars() throws {
    let inbox = try IncomingShareInbox(directory: root)
    try inbox.store(text: String(repeating: "😀", count: IncomingShareInbox.maximumLength + 5), subject: nil)
    XCTAssertEqual(inbox.take()?.text?.unicodeScalars.count, IncomingShareInbox.maximumLength)
  }

  func testDeliveryHoldsTheShareUntilDartIsReady() throws {
    let inbox = try IncomingShareInbox(directory: root)
    let delivery = ShareDelivery(inbox: inbox)
    var emitted: [[String: String]] = []
    delivery.emit = { emitted.append($0) }
    try inbox.store(text: "cold", subject: nil)
    try inbox.store(text: "cold two", subject: nil)
    XCTAssertEqual(delivery.take(), [["text": "cold"], ["text": "cold two"]])
    XCTAssertTrue(delivery.take().isEmpty)
    try inbox.store(text: "warm", subject: nil)
    try inbox.store(text: "warm two", subject: nil)
    delivery.drain()
    XCTAssertEqual(emitted, [["text": "warm"], ["text": "warm two"]])
    delivery.drain()
    XCTAssertEqual(emitted.count, 2)
  }

  func testShareUrlsReachSharingAndAreNotCardLinks() throws {
    let delivery = ShareDelivery(inbox: try IncomingShareInbox(directory: root))
    let links = CardLinkDelivery()
    let share = try XCTUnwrap(URL(string: "ncdeck://share?text=Ahoj&subject=Tema"))
    XCTAssertFalse(links.receive(share))
    XCTAssertTrue(delivery.receive(share))
    XCTAssertEqual(delivery.take(), [["text": "Ahoj", "subject": "Tema"]])
    let card = try XCTUnwrap(URL(string: "ncdeck://open?uri=https%3A%2F%2Fcloud.example.com"))
    XCTAssertTrue(links.receive(card))
    XCTAssertFalse(delivery.receive(card))
    XCTAssertEqual(links.take(), card.absoluteString)
  }
}
