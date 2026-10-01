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

    func testLifetimeMilestonesByCountOnly() {
        let pins = (0..<10).map { i in
            TuckPin(latitude: 0, longitude: 0, timestamp: Date().addingTimeInterval(Double(i)))
        }
        let unlocked = BadgeEvaluator.unlocked(pins: pins)
        XCTAssertEqual(BadgeEvaluator.lifetimeTuckCount(pins: pins), 10)
        XCTAssertTrue(unlocked.contains(.firstOne))
        XCTAssertTrue(unlocked.contains(.tenDeep))
        XCTAssertFalse(unlocked.contains(.fiftyDeep))
        XCTAssertFalse(unlocked.contains(.hundredClub))
    }

    func testHundredClubAt100() {
        let pins = (0..<100).map { i in
            TuckPin(latitude: 0, longitude: 0, timestamp: Date().addingTimeInterval(Double(i)))
        }
        let unlocked = BadgeEvaluator.unlocked(pins: pins)
        XCTAssertTrue(unlocked.contains(.fiftyDeep))
        XCTAssertTrue(unlocked.contains(.hundredClub))
    }

    func testFirstCoolMintFlavorBadge() {
        let pin = TuckPin(latitude: 1, longitude: 2, flavor: .coolMint)
        XCTAssertTrue(BadgeEvaluator.unlocked(pins: [pin]).contains(.firstCoolMint))
    }

    func testFlavorTouristAtFiveDistinct() {
        let flavors: [TuckFlavor] = [.coolMint, .wintergreen, .citrus, .coffee, .vanilla]
        let pins = flavors.enumerated().map { i, flavor in
            TuckPin(latitude: 0, longitude: 0, timestamp: Date().addingTimeInterval(Double(i)), flavor: flavor)
        }
        let unlocked = BadgeEvaluator.unlocked(pins: pins)
        XCTAssertTrue(unlocked.contains(.flavorTourist))
        XCTAssertFalse(unlocked.contains(.fullFlight))
    }

    func testZynbabweAtFiveStates() {
        let codes = ["TX", "CA", "NY", "FL", "WA"]
        let pins = codes.enumerated().map { i, code in
            TuckPin(
                latitude: Double(i),
                longitude: Double(i),
                timestamp: Date().addingTimeInterval(Double(i)),
                regionCode: code,
                regionName: USState.resolve(code: code, name: nil)?.name
            )
        }
        XCTAssertTrue(BadgeEvaluator.unlocked(pins: pins).contains(.zynbabwe))
    }
}
