import SwiftUI

/// Shows which display is being changed and its current resolution.
struct DisplaySection: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model

        Section("Display") {
            if model.displays.count > 1 {
                Picker("Display", selection: $model.selectedDisplayID) {
                    ForEach(model.displays) { display in
                        Text(display.name).tag(Optional(display.id))
                    }
                }
            } else {
                LabeledContent("Display", value: model.selectedDisplay?.name ?? "")
            }

            if let mode = model.currentMode {
                LabeledContent("Currently looks like", value: mode.sizeDescription)
                LabeledContent("Drawn at", value: "\(mode.pixelSizeDescription), \(Int(mode.refreshRate.rounded())) Hz")
            }
        }
        .onChange(of: model.selectedDisplayID) {
            model.loadSelectedProfile()
        }
    }
}
