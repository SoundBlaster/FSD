import AppNameCoreUI
import AppNameCreateSampleFeature
import AppNameProductDomain
import SwiftUI

public struct ProductListScreen: View {
    @State private var products: [Product]

    public init(products: [Product] = []) {
        _products = State(initialValue: products)
    }

    public var body: some View {
        NavigationStack {
            List(products) { product in
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.title)
                        .font(.headline)

                    if let subtitle = product.subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
            .overlay {
                if products.isEmpty {
                    EmptyStateView(title: "No products", systemImage: "shippingbox")
                }
            }
            .navigationTitle("Products")
            .toolbar {
                CreateSampleProductButton(existingCount: products.count) { product in
                    products.append(product)
                }
            }
        }
    }
}
