import SwiftUI

@main
struct RubiksCubeSolverApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .preferredColorScheme(.dark)  // camera feed dominates; dark chrome reads better
        }
    }
}
