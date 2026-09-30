import XCTest
@testable import LipMap

final class PaywallGateTests: XCTestCase {
    func testFreeUnderLimits() {
        let gate = PaywallGate(
            tuckCount: 19,
            firstTuckDate: Calendar.current.date(byAdding: .day, value: -6, to: .now),
            isSubscribed: false,
            now: .now
        )
        XCTAssertFalse(gate.isHardPaywallRequired)
    }

    func testHardPaywallAtTwentyTucks() {
        let gate = PaywallGate(
            tuckCount: 20,
            firstTuckDate: .now,
            isSubscribed: false,
            now: .now
        )
        XCTAssertTrue(gate.isHardPaywallRequired)
    }

    func testHardPaywallAtSevenDays() {
        let first = Calendar.current.date(byAdding: .day, value: -7, to: .now)!
        let gate = PaywallGate(
            tuckCount: 3,
            firstTuckDate: first,
            isSubscribed: false,
            now: .now
        )
        XCTAssertTrue(gate.isHardPaywallRequired)
    }

    func testSubscribedBypassesGate() {
        let gate = PaywallGate(
            tuckCount: 100,
            firstTuckDate: Calendar.current.date(byAdding: .day, value: -30, to: .now),
            isSubscribed: true,
            now: .now
        )
        XCTAssertFalse(gate.isHardPaywallRequired)
        XCTAssertTrue(gate.canUseFriendsLeague)
    }

    func testFreeSeesOnlyLastSevenDaysPins() {
        let now = Date()
        let gate = PaywallGate(tuckCount: 1, firstTuckDate: now, isSubscribed: false, now: now)
        let recent = Calendar.current.date(byAdding: .day, value: -3, to: now)!
        let old = Calendar.current.date(byAdding: .day, value: -8, to: now)!
        XCTAssertTrue(gate.isPinVisible(recent))
        XCTAssertFalse(gate.isPinVisible(old))
    }
}
