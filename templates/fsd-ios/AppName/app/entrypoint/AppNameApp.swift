import SwiftUI

@main
struct AppNameApp: App {
    private let dependencies = AppDependencies.bootstrap()

    var body: some Scene {
        WindowGroup {
            HomePage(initialSampleItems: dependencies.initialSampleItems)
        }
    }
}
