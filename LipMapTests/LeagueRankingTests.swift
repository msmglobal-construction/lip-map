import XCTest
@testable import LipMap

final class LeagueRankingTests: XCTestCase {
    func testRanksByUniquePlacesNotVolume() {
        let ranked = LeagueRanking.rank(
            myCode: "111111",
            myName: "Me",
            myWeeklyPlaceKeys: ["a", "b"],
            friends: [
                (code: "222222", name: "Busy", placeKeys: ["x"]),
                (code: "333333", name: "Explorer", placeKeys: ["p", "q", "r"])
            ]
        )
        XCTAssertEqual(ranked.map(\.code), ["333333", "111111", "222222"])
        XCTAssertEqual(ranked.first?.uniquePlaces, 3)
    }

    func testPlaceKeysDedupRoundedCoords() {
        let week = LeagueRanking.weekInterval()
        let a = TuckPin(latitude: 40.71280, longitude: -74.00600, timestamp: week.start.addingTimeInterval(3600))
        let b = TuckPin(latitude: 40.71281, longitude: -74.00601, timestamp: week.start.addingTimeInterval(7200))
        let keys = LeagueRanking.placeKeys(from: [a, b], in: week)
        XCTAssertEqual(keys.count, 1)
    }
}
