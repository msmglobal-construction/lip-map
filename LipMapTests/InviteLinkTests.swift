import XCTest
@testable import LipMap

final class InviteLinkTests: XCTestCase {
    func testMakeAndParseInviteURL() {
        let url = InviteLink.makeURL(code: "123456")
        XCTAssertEqual(url.scheme, "lipmap")
        XCTAssertEqual(InviteLink.parseCode(from: url), "123456")
    }

    func testParseJoinPath() {
        let url = URL(string: "lipmap://join/654321")!
        XCTAssertEqual(InviteLink.parseCode(from: url), "654321")
    }

    func testRejectsNonLipMapScheme() {
        let url = URL(string: "https://example.com/invite?code=123456")!
        XCTAssertNil(InviteLink.parseCode(from: url))
    }

    func testShareMessageContainsLinkAndCode() {
        let message = InviteLink.shareMessage(myCode: "424242")
        XCTAssertTrue(message.contains("lipmap://"))
        XCTAssertTrue(message.contains("424242"))
        XCTAssertTrue(message.contains("Lip Map"))
    }
}
