import Foundation

enum LipBadge: String, CaseIterable, Identifiable, Codable {
    case zynachino
    case churchParkingLot
    case gateB12
    case herParentsHouse
    case twoOhSevenAM
    case twoInOneRedLight
    case workBathroom
    case boat
    case deerStand
    case upperDeck
    case interstate
    case firstOne

    var id: String { rawValue }

    var title: String {
        switch self {
        case .zynachino: return "ZYNachino"
        case .churchParkingLot: return "Church Parking Lot"
        case .gateB12: return "Gate B12"
        case .herParentsHouse: return "Her Parents’ House"
        case .twoOhSevenAM: return "2:07 AM"
        case .twoInOneRedLight: return "Two In One Red Light"
        case .workBathroom: return "Work Bathroom"
        case .boat: return "Boat"
        case .deerStand: return "Deer Stand"
        case .upperDeck: return "Upper Deck"
        case .interstate: return "Interstate"
        case .firstOne: return "First One"
        }
    }

    var blurb: String {
        switch self {
        case .zynachino: return "Coffee or cafe tuck"
        case .churchParkingLot: return "Near a church parking lot"
        case .gateB12: return "Airport energy"
        case .herParentsHouse: return "Manual — you know where"
        case .twoOhSevenAM: return "Tucked between 2:00–2:59 AM"
        case .twoInOneRedLight: return "Two pins within 3 minutes"
        case .workBathroom: return "Manual — the stall classic"
        case .boat: return "On the water"
        case .deerStand: return "Manual — woods hour"
        case .upperDeck: return "Upper level / stadium"
        case .interstate: return "Highway tuck"
        case .firstOne: return "Your first pin"
        }
    }

    var systemImage: String {
        switch self {
        case .zynachino: return "cup.and.saucer.fill"
        case .churchParkingLot: return "building.columns.fill"
        case .gateB12: return "airplane.departure"
        case .herParentsHouse: return "house.fill"
        case .twoOhSevenAM: return "moon.stars.fill"
        case .twoInOneRedLight: return "car.fill"
        case .workBathroom: return "toilet.fill"
        case .boat: return "sailboat.fill"
        case .deerStand: return "tree.fill"
        case .upperDeck: return "stairs"
        case .interstate: return "road.lanes"
        case .firstOne: return "mappin.circle.fill"
        }
    }

    /// Badges that unlock only when the user marks a pin manually.
    var isManual: Bool {
        switch self {
        case .herParentsHouse, .workBathroom, .deerStand:
            return true
        default:
            return false
        }
    }
}
