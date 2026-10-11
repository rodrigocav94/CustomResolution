import SwiftUI

struct ContentView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model

        Group {
            if model.displays.isEmpty {
                ContentUnavailableView(
                    "No Display Found",
                    systemImage: "display.trianglebadge.exclamationmark",
                    description: Text("Connect a display to add a custom resolution.")
                )
            } else {
                Form {
                    DisplaySection()
                    CustomResolutionSection()
                    SwitchSection()
                    ShortcutSection()
                }
                .formStyle(.grouped)
            }
        }
        .frame(minWidth: Design.windowMinWidth, minHeight: Design.windowMinHeight)
        .alert(model.presentedAlert?.title ?? "", isPresented: $model.isAlertPresented, presenting: model.presentedAlert) { alert in
            if alert.offersRestart {
                Button("Restart Now", action: model.restart)
                Button("Later", role: .cancel) { }
            }
        } message: { alert in
            Text(alert.message)
        }
        .task {
            await model.observeSystemChanges()
        }
    }
}

#Preview {
    ContentView()
        .environment(AppModel())
}
