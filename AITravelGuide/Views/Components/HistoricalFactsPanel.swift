import SwiftUI

/// Expandable historical fact cards with category-filter pills. When a stop
/// carries only one fact (typical for legacy `historicalNote` or curated
/// templates), the filter row hides itself and the single card opens expanded
/// by default.
struct HistoricalFactsPanel: View {
    let facts: [HistoricalFact]
    @State private var selectedCategory: FactCategory?
    @State private var expandedFactIds: Set<UUID> = []

    private var availableCategories: [FactCategory] {
        let seen = Set(facts.map(\.category))
        return FactCategory.allCases.filter { seen.contains($0) }
    }

    private var filteredFacts: [HistoricalFact] {
        guard let selected = selectedCategory else { return facts }
        return facts.filter { $0.category == selected }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Historical Facts", systemImage: "book.fill")
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            if availableCategories.count > 1 {
                filterPills
            }

            VStack(spacing: 8) {
                ForEach(filteredFacts) { fact in
                    FactCard(
                        fact: fact,
                        isExpanded: facts.count == 1 || expandedFactIds.contains(fact.id),
                        onToggle: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                if expandedFactIds.contains(fact.id) {
                                    expandedFactIds.remove(fact.id)
                                } else {
                                    expandedFactIds.insert(fact.id)
                                }
                            }
                        }
                    )
                }
            }
        }
        .padding()
        .background(AppColors.historicalBackground, in: RoundedRectangle(cornerRadius: 12))
    }

    private var filterPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                CategoryFilterPill(label: "All", isSelected: selectedCategory == nil) {
                    selectedCategory = nil
                }
                ForEach(availableCategories, id: \.self) { category in
                    CategoryFilterPill(
                        label: category.displayName,
                        iconSystemName: category.iconSystemName,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = (selectedCategory == category) ? nil : category
                    }
                }
            }
        }
    }
}

private struct FactCard: View {
    let fact: HistoricalFact
    let isExpanded: Bool
    let onToggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button(action: onToggle) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Image(systemName: fact.category.iconSystemName)
                        .font(.caption)
                        .foregroundStyle(AppColors.historicalAccent)
                        .frame(width: 16)
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            if let year = fact.year, !year.isEmpty {
                                Text(year)
                                    .font(.caption2.monospacedDigit())
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(AppColors.historicalAccent.opacity(0.15), in: Capsule())
                            }
                            Text(fact.title)
                                .font(.subheadline.bold())
                                .foregroundStyle(.primary)
                        }
                    }
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                Text(fact.content)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 24)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(10)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct CategoryFilterPill: View {
    let label: String
    var iconSystemName: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let iconSystemName {
                    Image(systemName: iconSystemName)
                        .font(.caption2)
                }
                Text(label)
                    .font(.caption.bold())
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                isSelected ? AppColors.historicalAccent : Color(.tertiarySystemBackground),
                in: Capsule()
            )
            .foregroundStyle(isSelected ? Color.white : .primary)
        }
        .buttonStyle(.plain)
    }
}
