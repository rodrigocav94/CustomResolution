import SwiftUI

/// Where the user enters an aspect ratio and height, then adds the resolution.
struct CustomResolutionSection: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model

        Section {
            LabeledContent("Aspect ratio") {
                HStack {
                    TextField("Ratio width", value: $model.spec.ratioWidth, format: .number.grouping(.never))
                        .frame(maxWidth: Design.numberFieldWidth)
                    Text(":")
                        .accessibilityHidden(true)
                    TextField("Ratio height", value: $model.spec.ratioHeight, format: .number.grouping(.never))
                        .frame(maxWidth: Design.numberFieldWidth)
                    Menu("Presets") {
                        ForEach(AspectRatioPreset.all) { preset in
                            Button(preset.name) { model.apply(preset) }
                        }
                    }
                    .fixedSize()
                }
                .labelsHidden()
                .textFieldStyle(.roundedBorder)
            }

            LabeledContent("Looks like height") {
                TextField("Looks like height", value: $model.spec.height, format: .number.grouping(.never))
                    .labelsHidden()
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: Design.numberFieldWidth)
            }

            LabeledContent("New resolution") {
                if model.spec.isValid {
                    VStack(alignment: .trailing) {
                        Text("Looks like \(model.spec.sizeDescription)")
                        Text("Drawn at \(model.spec.retinaSizeDescription)")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("Enter a ratio and a height between \(CustomResolutionSpec.heightRange.lowerBound) and \(CustomResolutionSpec.heightRange.upperBound).")
                        .foregroundStyle(.secondary)
                }
            }

            if let warning = model.specWarning {
                Label(warning, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
            }

            Button("Add Resolution…", action: model.addResolution)
                .buttonStyle(.borderedProminent)
                .disabled(!model.canAddResolution)
        } header: {
            Text("Custom Resolution")
        } footer: {
            Text("macOS asks for your administrator password, then you restart. The display's original settings file is backed up first.")
        }
    }
}
