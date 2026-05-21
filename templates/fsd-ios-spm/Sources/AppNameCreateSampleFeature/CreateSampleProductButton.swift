import AppNameProductDomain
import SwiftUI

public struct CreateSampleProductButton: View {
    private let existingCount: Int
    private let onCreate: (Product) -> Void
    private let action = CreateSampleProductAction()

    public init(
        existingCount: Int,
        onCreate: @escaping (Product) -> Void
    ) {
        self.existingCount = existingCount
        self.onCreate = onCreate
    }

    public var body: some View {
        Button {
            onCreate(action(existingCount: existingCount))
        } label: {
            Label("Add", systemImage: "plus")
        }
    }
}
