import Foundation

struct USState: Identifiable, Hashable, Sendable {
    var id: String { code }
    let code: String
    let name: String

    static let all: [USState] = [
        .init(code: "AL", name: "Alabama"),
        .init(code: "AK", name: "Alaska"),
        .init(code: "AZ", name: "Arizona"),
        .init(code: "AR", name: "Arkansas"),
        .init(code: "CA", name: "California"),
        .init(code: "CO", name: "Colorado"),
        .init(code: "CT", name: "Connecticut"),
        .init(code: "DE", name: "Delaware"),
        .init(code: "DC", name: "District of Columbia"),
        .init(code: "FL", name: "Florida"),
        .init(code: "GA", name: "Georgia"),
        .init(code: "HI", name: "Hawaii"),
        .init(code: "ID", name: "Idaho"),
        .init(code: "IL", name: "Illinois"),
        .init(code: "IN", name: "Indiana"),
        .init(code: "IA", name: "Iowa"),
        .init(code: "KS", name: "Kansas"),
        .init(code: "KY", name: "Kentucky"),
        .init(code: "LA", name: "Louisiana"),
        .init(code: "ME", name: "Maine"),
        .init(code: "MD", name: "Maryland"),
        .init(code: "MA", name: "Massachusetts"),
        .init(code: "MI", name: "Michigan"),
        .init(code: "MN", name: "Minnesota"),
        .init(code: "MS", name: "Mississippi"),
        .init(code: "MO", name: "Missouri"),
        .init(code: "MT", name: "Montana"),
        .init(code: "NE", name: "Nebraska"),
        .init(code: "NV", name: "Nevada"),
        .init(code: "NH", name: "New Hampshire"),
        .init(code: "NJ", name: "New Jersey"),
        .init(code: "NM", name: "New Mexico"),
        .init(code: "NY", name: "New York"),
        .init(code: "NC", name: "North Carolina"),
        .init(code: "ND", name: "North Dakota"),
        .init(code: "OH", name: "Ohio"),
        .init(code: "OK", name: "Oklahoma"),
        .init(code: "OR", name: "Oregon"),
        .init(code: "PA", name: "Pennsylvania"),
        .init(code: "RI", name: "Rhode Island"),
        .init(code: "SC", name: "South Carolina"),
        .init(code: "SD", name: "South Dakota"),
        .init(code: "TN", name: "Tennessee"),
        .init(code: "TX", name: "Texas"),
        .init(code: "UT", name: "Utah"),
        .init(code: "VT", name: "Vermont"),
        .init(code: "VA", name: "Virginia"),
        .init(code: "WA", name: "Washington"),
        .init(code: "WV", name: "West Virginia"),
        .init(code: "WI", name: "Wisconsin"),
        .init(code: "WY", name: "Wyoming"),
    ]

    private static let byName: [String: USState] = {
        Dictionary(uniqueKeysWithValues: all.map { ($0.name.lowercased(), $0) })
    }()

    private static let byCode: [String: USState] = {
        Dictionary(uniqueKeysWithValues: all.map { ($0.code.uppercased(), $0) })
    }()

    static func resolve(code: String?, name: String?) -> USState? {
        if let code, let match = byCode[code.uppercased()] { return match }
        if let name, let match = byName[name.lowercased()] { return match }
        return nil
    }
}

enum StateAtlas {
    /// Distinct US states / DC visited from pins that have region data.
    static func visited(from pins: [TuckPin]) -> [USState] {
        var codes = Set<String>()
        var ordered: [USState] = []
        for pin in pins.sorted(by: { $0.timestamp < $1.timestamp }) {
            guard let state = USState.resolve(code: pin.regionCode, name: pin.regionName) else { continue }
            if codes.insert(state.code).inserted {
                ordered.append(state)
            }
        }
        return ordered
    }

    static func visitedCodes(from pins: [TuckPin]) -> Set<String> {
        Set(visited(from: pins).map(\.code))
    }
}
