import SwiftUI
import SwiftData
import MapKit

struct PinsMapView: View {
    @Environment(AppModel.self) private var appModel
    @Query(sort: \TuckPin.timestamp, order: .reverse) private var pins: [TuckPin]
    @State private var selectedID: UUID?
    @State private var position: MapCameraPosition = .automatic

    var body: some View {
        let visible = appModel.visiblePins(pins)
        let selected = visible.first { $0.id == selectedID }
        NavigationStack {
            ZStack {
                Map(position: $position, selection: $selectedID) {
                    ForEach(visible, id: \.id) { pin in
                        Annotation(
                            pin.timestamp.formatted(date: .omitted, time: .shortened),
                            coordinate: pin.coordinate,
                            anchor: .bottom
                        ) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.title)
                                .foregroundStyle(LipMapTheme.pin)
                                .shadow(radius: 2, y: 1)
                        }
                        .tag(pin.id)
                    }
                }
                .mapStyle(.standard(elevation: .realistic))
                .mapControls {
                    MapCompass()
                    MapUserLocationButton()
                }

                if visible.isEmpty {
                    ContentUnavailableView(
                        "No pins yet",
                        systemImage: "mappin.slash",
                        description: Text("Tap Tucked on Home to drop one.")
                    )
                    .background(.ultraThinMaterial)
                }
            }
            .navigationTitle("Map")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                if let selected {
                    PinCallout(pin: selected)
                        .padding()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                } else if !appModel.entitlements.isSubscribed && pins.count > visible.count {
                    Text("Free map shows the last 7 days. Full Map unlocks all-time pins.")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding(12)
                        .frame(maxWidth: .infinity)
                        .background(.ultraThinMaterial)
                }
            }
            .onAppear {
                if let first = visible.first {
                    position = .region(
                        MKCoordinateRegion(
                            center: first.coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
                        )
                    )
                }
            }
        }
    }
}

private struct PinCallout: View {
    let pin: TuckPin

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(pin.timestamp.formatted(date: .abbreviated, time: .shortened))
                .font(.headline)
            if let flavor = pin.flavor {
                Text(flavor.rawValue)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text("No flavor noted")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
