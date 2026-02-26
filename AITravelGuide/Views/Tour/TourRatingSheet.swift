import SwiftUI

struct TourRatingSheet: View {
    let tour: Tour
    let tourViewModel: TourViewModel
    let storageService: TourStorageService

    @Environment(\.dismiss) private var dismiss
    @State private var rating: Int = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "star.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.orange)

                Text("How was your tour?")
                    .font(.title2.bold())

                Text(tour.name)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                // Star rating
                HStack(spacing: 12) {
                    ForEach(1...5, id: \.self) { star in
                        Button {
                            withAnimation(.spring(duration: 0.2)) {
                                rating = star
                            }
                        } label: {
                            Image(systemName: star <= rating ? "star.fill" : "star")
                                .font(.system(size: 36))
                                .foregroundStyle(star <= rating ? .orange : .secondary)
                        }
                    }
                }
                .padding(.vertical)

                if rating > 0 {
                    Text(ratingLabel)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    if rating > 0 {
                        var ratedTour = tour
                        ratedTour.rating = rating
                        storageService.saveTour(ratedTour)
                    }
                    dismiss()
                } label: {
                    Text(rating > 0 ? "Submit Rating" : "Skip")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(rating > 0 ? .orange : .secondary)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("Rate Tour")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var ratingLabel: String {
        switch rating {
        case 1: return "Not great"
        case 2: return "Could be better"
        case 3: return "It was okay"
        case 4: return "Really enjoyed it!"
        case 5: return "Amazing tour!"
        default: return ""
        }
    }
}
