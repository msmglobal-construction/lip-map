import XCTest
@testable import LipMap

final class DashboardInsightsTests: XCTestCase {
    func testBuildsFlavorAndStateBreakdown() {
        let pins = [
            TuckPin(
                latitude: 30, longitude: -97,
                timestamp: .now,
                flavor: .coolMint,
                regionCode: "TX",
                regionName: "Texas",
                locality: "Austin"
            ),
            TuckPin(
                latitude: 30.01, longitude: -97.01,
                timestamp: Date().addingTimeInterval(-60),
                flavor: .wintergreen,
                regionCode: "TX",
                regionName: "Texas",
                locality: "Austin"
            ),
            TuckPin(
                latitude: 34, longitude: -118,
                timestamp: Date().addingTimeInterval(-120),
                flavor: .coolMint,
                regionCode: "CA",
                regionName: "California",
                locality: "LA"
            ),
        ]
        let insights = DashboardInsights.build(pins: pins)
        XCTAssertEqual(insights.lifetimeTucks, 3)
        XCTAssertEqual(insights.statesVisited, 2)
        XCTAssertEqual(insights.flavorsTried, 2)
        XCTAssertFalse(insights.flavorBreakdown.isEmpty)
        XCTAssertEqual(insights.topStates.first?.name, "Texas")
        XCTAssertEqual(StateAtlas.visited(from: pins).map(\.code).sorted(), ["CA", "TX"])
    }

    func testEmptyPins() {
        let insights = DashboardInsights.build(pins: [])
        XCTAssertEqual(insights.lifetimeTucks, 0)
        XCTAssertNil(insights.peakTimeLabel)
    }
}
