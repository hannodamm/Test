import Foundation

@MainActor
final class TourStorageService: ObservableObject {
    @Published var savedTours: [Tour] = []
    @Published var favoritePOIIds: Set<String> = []

    private let fileManager = FileManager.default
    private let favoritesKey = "favoritePOIIds"

    private var toursDirectory: URL {
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("SavedTours", isDirectory: true)
        try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    init() {
        loadTours()
        loadFavorites()
    }

    // MARK: - Tour Persistence

    func saveTour(_ tour: Tour) {
        let url = toursDirectory.appendingPathComponent("\(tour.id.uuidString).json")
        do {
            let data = try JSONEncoder().encode(tour)
            try data.write(to: url)
            if let index = savedTours.firstIndex(where: { $0.id == tour.id }) {
                savedTours[index] = tour
            } else {
                savedTours.insert(tour, at: 0)
            }
        } catch {
            // Silent failure — tour just won't persist
        }
    }

    func deleteTour(_ tour: Tour) {
        let url = toursDirectory.appendingPathComponent("\(tour.id.uuidString).json")
        try? fileManager.removeItem(at: url)
        savedTours.removeAll { $0.id == tour.id }
    }

    func loadTours() {
        guard let files = try? fileManager.contentsOfDirectory(
            at: toursDirectory,
            includingPropertiesForKeys: nil
        ) else { return }

        savedTours = files
            .filter { $0.pathExtension == "json" }
            .compactMap { url -> Tour? in
                guard let data = try? Data(contentsOf: url) else { return nil }
                return try? JSONDecoder().decode(Tour.self, from: data)
            }
            .sorted { $0.createdAt > $1.createdAt }
    }

    // MARK: - Favorite POIs

    func toggleFavorite(_ poiId: String) {
        if favoritePOIIds.contains(poiId) {
            favoritePOIIds.remove(poiId)
        } else {
            favoritePOIIds.insert(poiId)
        }
        saveFavorites()
    }

    func isFavorite(_ poiId: String) -> Bool {
        favoritePOIIds.contains(poiId)
    }

    private func saveFavorites() {
        UserDefaults.standard.set(Array(favoritePOIIds), forKey: favoritesKey)
    }

    private func loadFavorites() {
        let ids = UserDefaults.standard.stringArray(forKey: favoritesKey) ?? []
        favoritePOIIds = Set(ids)
    }
}
