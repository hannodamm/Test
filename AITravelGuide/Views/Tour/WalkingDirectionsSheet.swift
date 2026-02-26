import SwiftUI
import MapKit

struct WalkingDirectionsSheet: View {
    let fromStop: TourStop
    let toStop: TourStop
    let steps: [WalkingDirectionStep]
    let routeCoordinates: [CLLocationCoordinate2D]
    let eta: String?
    let distance: CLLocationDistance?

    @EnvironmentObject var speechService: SpeechService
    @Environment(\.dismiss) private var dismiss

    private var isLastStop: Bool { fromStop.id == toStop.id }

    private var formattedDistance: String? {
        guard let d = distance, d > 0 else { return nil }
        if d < 1000 { return String(format: "%.0f m", d) }
        return String(format: "%.1f km", d / 1000)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Route header
                    routeHeader

                    // Route map
                    if !routeCoordinates.isEmpty {
                        routeMap
                    }

                    // Turn-by-turn steps
                    if !steps.isEmpty {
                        stepsList
                    } else if isLastStop {
                        lastStopMessage
                    } else {
                        noDirectionsMessage
                    }
                }
                .padding()
            }
            .navigationTitle("Walking Directions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
                if !steps.isEmpty {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            let stepTexts = steps.map { $0.instructions }
                            speechService.speakDirectionSummary(
                                to: toStop,
                                steps: stepTexts,
                                distance: formattedDistance
                            )
                        } label: {
                            Image(systemName: speechService.isSpeaking ? "stop.circle.fill" : "speaker.wave.2")
                                .foregroundStyle(speechService.isSpeaking ? .red : .accent)
                        }
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Route Header

    private var routeHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            if isLastStop {
                Text("You're at the last stop")
                    .font(.headline)
            } else {
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("From")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(fromStop.name)
                            .font(.subheadline.bold())
                    }
                    Image(systemName: "arrow.right")
                        .foregroundStyle(.blue)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("To")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(toStop.name)
                            .font(.subheadline.bold())
                    }
                }
            }

            if !isLastStop {
                HStack(spacing: 16) {
                    if let eta {
                        Label(eta, systemImage: "clock")
                    }
                    if let formattedDistance {
                        Label(formattedDistance, systemImage: "figure.walk")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Route Map

    private var routeMap: some View {
        Map(initialPosition: .region(routeRegion)) {
            Annotation(fromStop.name, coordinate: fromStop.coordinate) {
                ZStack {
                    Circle().fill(.blue).frame(width: 28, height: 28)
                    Text("\(fromStop.orderIndex + 1)")
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                }
            }
            if !isLastStop {
                Annotation(toStop.name, coordinate: toStop.coordinate) {
                    ZStack {
                        Circle().fill(.green).frame(width: 28, height: 28)
                        Text("\(toStop.orderIndex + 1)")
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                    }
                }
            }
            MapPolyline(coordinates: routeCoordinates)
                .stroke(.blue, lineWidth: 4)
        }
        .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .excludingAll))
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var routeRegion: MKCoordinateRegion {
        guard !routeCoordinates.isEmpty else {
            return MKCoordinateRegion(
                center: fromStop.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
            )
        }
        var minLat = routeCoordinates[0].latitude
        var maxLat = routeCoordinates[0].latitude
        var minLon = routeCoordinates[0].longitude
        var maxLon = routeCoordinates[0].longitude

        for c in routeCoordinates {
            minLat = min(minLat, c.latitude)
            maxLat = max(maxLat, c.latitude)
            minLon = min(minLon, c.longitude)
            maxLon = max(maxLon, c.longitude)
        }
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: (minLat + maxLat) / 2,
                longitude: (minLon + maxLon) / 2
            ),
            span: MKCoordinateSpan(
                latitudeDelta: max((maxLat - minLat) * 1.6, 0.004),
                longitudeDelta: max((maxLon - minLon) * 1.6, 0.004)
            )
        )
    }

    // MARK: - Steps List

    private var stepsList: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Turn-by-turn")
                .font(.headline)
                .padding(.bottom, 8)

            ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                HStack(alignment: .top, spacing: 12) {
                    // Step number with line
                    VStack(spacing: 0) {
                        ZStack {
                            Circle()
                                .fill(index == 0 ? Color.blue : Color(.systemGray4))
                                .frame(width: 28, height: 28)
                            Text("\(index + 1)")
                                .font(.caption2.bold())
                                .foregroundStyle(index == 0 ? .white : .primary)
                        }
                        if index < steps.count - 1 {
                            Rectangle()
                                .fill(Color(.systemGray4))
                                .frame(width: 2)
                                .frame(maxHeight: .infinity)
                        }
                    }
                    .frame(width: 28)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(step.instructions)
                            .font(.subheadline)
                        if step.distance > 0 {
                            Text(step.formattedDistance)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)

                    Spacer()
                }
            }

            // Arrival indicator
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(.green)
                        .frame(width: 28, height: 28)
                    Image(systemName: "flag.fill")
                        .font(.caption2)
                        .foregroundStyle(.white)
                }
                .frame(width: 28)

                Text("Arrive at \(toStop.name)")
                    .font(.subheadline.bold())
                    .foregroundStyle(.green)
                    .padding(.vertical, 8)
            }
        }
    }

    private var lastStopMessage: some View {
        VStack(spacing: 12) {
            Image(systemName: "flag.checkered")
                .font(.title)
                .foregroundStyle(.green)
            Text("This is the final stop on your tour!")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    private var noDirectionsMessage: some View {
        VStack(spacing: 12) {
            Image(systemName: "map.fill")
                .font(.title)
                .foregroundStyle(.secondary)
            Text("Detailed directions aren't available for this segment. Head toward \(toStop.name) using the map above.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}
