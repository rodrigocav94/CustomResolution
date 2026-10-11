import SwiftUI

/// Switches between the custom and previous resolution, and restores the original settings file.
struct SwitchSection: View {
    @Environment(AppModel.self) private var model
    @State private var isConfirmingRestore = false

    var body: some View {
        Section {
            StatusRow(status: model.status, sizeDescription: model.profile?.sizeDescription ?? "")

            HStack {
                switch model.status {
                case .available:
                    Button(model.toggleTitle, action: model.toggleResolution)
                        .buttonStyle(.borderedProminent)
                case .needsRestart, .removalPending:
                    Button("Restart Now…", action: model.restart)
                case .notSetUp:
                    EmptyView()
                }

                Spacer()

                Button("Restore Original…", role: .destructive, action: confirmRestore)
                    .disabled(!model.hasBackup)
                    .confirmationDialog("Restore the original display settings?", isPresented: $isConfirmingRestore) {
                        Button("Restore", role: .destructive, action: model.restoreBackup)
                    } message: {
                        Text("This puts back the settings file your display had before. The custom resolution disappears after you restart.")
                    }
            }
        } header: {
            Text("Switch")
        } footer: {
            Text("Display Settings only lists sizes with your display's own shape, so switch here or with the Switch Resolution shortcut.")
        }
    }

    private func confirmRestore() {
        isConfirmingRestore = true
    }
}
