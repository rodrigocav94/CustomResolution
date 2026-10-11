import SwiftUI

/// One line describing where the custom resolution stands.
struct StatusRow: View {
    let status: ProfileStatus
    let sizeDescription: String

    var body: some View {
        Label {
            Text(message)
        } icon: {
            Image(systemName: symbolName)
                .foregroundStyle(tint)
        }
    }

    private var message: String {
        switch status {
        case .notSetUp: "No custom resolution added yet."
        case .needsRestart: "\(sizeDescription) was added. Restart your Mac to use it."
        case .available: "\(sizeDescription) is ready to use."
        case .removalPending: "Original settings restored. Restart your Mac to finish."
        }
    }

    private var symbolName: String {
        switch status {
        case .notSetUp: "circle.dashed"
        case .needsRestart, .removalPending: "arrow.clockwise.circle.fill"
        case .available: "checkmark.circle.fill"
        }
    }

    private var tint: Color {
        switch status {
        case .notSetUp: .secondary
        case .needsRestart, .removalPending: .orange
        case .available: .green
        }
    }
}
