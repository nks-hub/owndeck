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

  func testNewerShareReplacesOlderOne() throws {
    let inbox = try IncomingShareInbox(directory: root)
    try inbox.store(text: "one", subject: nil)
    try inbox.store(text: "two", subject: nil)
    XCTAssertEqual(inbox.take()?.text, "two")
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
    XCTAssertEqual(delivery.take(), ["text": "cold"])
    try inbox.store(text: "warm", subject: nil)
    delivery.drain()
    XCTAssertEqual(emitted, [["text": "warm"]])
    delivery.drain()
    XCTAssertEqual(emitted.count, 1)
  }
}
