import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            content
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        NavigationLink {
                            SettingsView()
                        } label: {
                            Image(systemName: "gearshape")
                        }
                    }
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch appState.route {
        case .onboarding:
            OnboardingView()
        case .scan:
            ScanFlowView(classifier: appState.classifier)
        case .pickMethod(let cube):
            SolveMethodPicker { method in
                appState.didPickMethod(method, cube: cube)
            }
        case .guide(let cube, let method):
            GuideView(cube: cube, method: method, guide: appState.prescriptiveGuide)
        }
    }
}
