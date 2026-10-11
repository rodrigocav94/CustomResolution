import SwiftUI

@main
struct CustomResolutionApp: App {
    @State private var model = AppModel()

    var body: some Scene {
        Window("Custom Resolution", id: "main") {
            ContentView()
                .environment(model)
        }
        .defaultSize(width: 560, height: 860)
    }
}
