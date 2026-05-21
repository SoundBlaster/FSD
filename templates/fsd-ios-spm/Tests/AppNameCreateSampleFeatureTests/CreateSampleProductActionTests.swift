import AppNameCreateSampleFeature
import Testing

struct CreateSampleProductActionTests {
    @Test func createSampleProductUsesNextIndex() {
        let product = CreateSampleProductAction()(existingCount: 2)

        #expect(product.title == "Product 3")
        #expect(product.subtitle == "Created inside an FSD SwiftPM feature")
    }
}
