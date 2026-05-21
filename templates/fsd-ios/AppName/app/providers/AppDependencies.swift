import Foundation

struct AppDependencies {
    let initialSampleItems: [SampleItem]

    static func bootstrap() -> AppDependencies {
        AppDependencies(
            initialSampleItems: [
                SampleItem(title: "Map first page boundary", subtitle: "Keep route-owned state in pages"),
                SampleItem(title: "Extract one real feature", subtitle: "Move reusable user action to features"),
            ]
        )
    }
}
