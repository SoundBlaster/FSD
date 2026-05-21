import AppNameProductDomain
import Foundation

public struct CreateSampleProductAction: Sendable {
    public init() {}

    public func callAsFunction(existingCount: Int) -> Product {
        Product(
            title: "Product \(existingCount + 1)",
            subtitle: "Created inside an FSD SwiftPM feature"
        )
    }
}
