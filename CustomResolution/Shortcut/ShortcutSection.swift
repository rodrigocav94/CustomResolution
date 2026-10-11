import SwiftUI

/// Installs the one-click Switch Resolution app.
struct ShortcutSection: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        Section {
            LabeledContent {
                Button(model.isShortcutInstalled ? "Reinstall" : "Install", action: model.installShortcut)
            } label: {
                Text("Switch Resolution")
                Text(model.isShortcutInstalled
                     ? "Installed in your Applications folder."
                     : "One click switches between the custom and previous resolution.")
            }
        } header: {
            Text("Shortcut")
        } footer: {
            Text("Installs to the Applications folder in your home folder. Drag it to the Dock for quick access.")
        }
    }
}
