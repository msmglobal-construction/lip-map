import XCTest
@testable import LipMap

final class BadgeEvaluatorTests: XCTestCase {
    func testFirstOne() {
        let pin = TuckPin(latitude: 1, longitude: 2, timestamp: .now)
        let unlocked = BadgeEvaluator.unlocked(pins: [pin])
        XCTAssertTrue(unlocked.contains(.firstOne))
    }

    func testTwoOhSevenAM() {
        var comps = DateComponents()
        comps.year = 2026
        comps.month = 3
        comps.day = 1
        comps.hour = 2
        comps.minute = 7
        let date = Calendar.current.date(from: comps)!
        let pin = TuckPin(latitude: 1, longitude: 2, timestamp: date)
        XCTAssertTrue(BadgeEvaluator.unlocked(pins: [pin]).contains(.twoOhSevenAM))
    }

    func testTwoInOneRedLight() {
        let a = TuckPin(latitude: 1, longitude: 2, timestamp: .now)
        let b = TuckPin(latitude: 1.001, longitude: 2.001, timestamp: Date().addingTimeInterval(90))
        XCTAssertTrue(BadgeEvaluator.unlocked(pins: [a, b]).contains(.twoInOneRedLight))
    }

    func testCoffeeTagUnlocksZynachino() {
        let pin = TuckPin(latitude: 1, longitude: 2, tags: ["coffee"])
        XCTAssertTrue(BadgeEvaluator.unlocked(pins: [pin]).contains(.zynachino))
    }

    func testManualBadge() {
        let pin = TuckPin(
            latitude: 1,
            longitude: 2,
            manualBadgeIDs: [LipBadge.herParentsHouse.rawValue]
        )
        XCTAssertTrue(BadgeEvaluator.unlocked(pins: [pin]).contains(.herParentsHouse))
    }
}
