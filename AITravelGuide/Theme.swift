import SwiftUI

// MARK: - Semantic Colors

enum AppColors {
    static let discoveryIcon: Color = .accentColor
    static let discoveryBackground = Color.accentColor.opacity(0.12)

    static let progressIcon: Color = .mint
    static let progressBackground = Color.mint.opacity(0.12)

    static let historicalBackground = Color.brown.opacity(0.12)
    static let historicalAccent: Color = .brown

    static let tipBackground = Color.mint.opacity(0.12)
    static let tipAccent: Color = .mint

    static let cardBackground = Color(.secondarySystemBackground)
}

// MARK: - Animations

enum AppAnimation {
    static let bannerIn: Animation = .spring(response: 0.4, dampingFraction: 0.8)
    static let bannerOut: Animation = .easeOut(duration: 0.3)
    static let press: Animation = .easeInOut(duration: 0.15)
}

// MARK: - QuickQuestionsBar

struct QuickQuestionsBar: View {
    let questions: [String]
    let onSelect: (String) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(questions, id: \.self) { question in
                    Button {
                        onSelect(question)
                    } label: {
                        Text(question)
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(.secondarySystemBackground), in: Capsule())
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
}

// MARK: - PressableButtonStyle

struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(AppAnimation.press, value: configuration.isPressed)
    }
}

extension View {
    func pressable() -> some View {
        buttonStyle(PressableButtonStyle())
    }
}
