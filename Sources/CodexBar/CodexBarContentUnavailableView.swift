import SwiftUI

/// Monterey does not provide SwiftUI's `ContentUnavailableView`.
struct CodexBarContentUnavailableView<LabelContent: View, DescriptionContent: View>: View {
    private let label: LabelContent
    private let description: DescriptionContent

    init(
        @ViewBuilder label: () -> LabelContent,
        @ViewBuilder description: () -> DescriptionContent)
    {
        self.label = label()
        self.description = description()
    }

    var body: some View {
        VStack(spacing: 8) {
            self.label
            self.description
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

struct CodexBarContentUnavailableTitleView: View {
    let title: String
    let systemImage: String

    var body: some View {
        Label(self.title, systemImage: self.systemImage)
            .font(.headline)
    }
}
