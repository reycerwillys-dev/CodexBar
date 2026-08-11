import SwiftUI

/// The native labeled-content row was added in macOS 13. This keeps the same
/// two-column shape on Monterey without depending on that API.
struct CodexBarLabeledContent<LabelContent: View, Content: View>: View {
    private let label: LabelContent
    private let content: Content

    init(
        @ViewBuilder content: () -> Content,
        @ViewBuilder label: () -> LabelContent)
    {
        self.label = label()
        self.content = content()
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            self.label
                .frame(maxWidth: .infinity, alignment: .leading)
            self.content
                .multilineTextAlignment(.trailing)
        }
    }
}

extension CodexBarLabeledContent where LabelContent == Text {
    init<S>(_ title: S, @ViewBuilder content: () -> Content) where S: StringProtocol {
        self.init(content: content) {
            Text(title)
        }
    }
}

extension CodexBarLabeledContent where LabelContent == Text, Content == Text {
    init<S1, S2>(_ title: S1, value: S2)
        where S1: StringProtocol, S2: StringProtocol
    {
        self.init(content: { Text(value) }) {
            Text(title)
        }
    }
}

extension View {
    /// `scrollContentBackground` was added after Monterey. Keep the visual
    /// treatment on newer systems and make it a no-op on macOS 12.
    @ViewBuilder
    func codexbarScrollContentBackgroundHidden() -> some View {
        if #available(macOS 13, *) {
            self.scrollContentBackground(.hidden)
        } else {
            self
        }
    }

    /// `scrollIndicators` was added in macOS 13.
    @ViewBuilder
    func codexbarScrollIndicators(shows: Bool) -> some View {
        if #available(macOS 13, *) {
            self.scrollIndicators(shows ? .visible : .hidden)
        } else {
            self
        }
    }

    /// `formStyle` was added in macOS 13.
    @ViewBuilder
    func codexbarGroupedFormStyle() -> some View {
        if #available(macOS 13, *) {
            self.formStyle(.grouped)
        } else {
            self
        }
    }
}
