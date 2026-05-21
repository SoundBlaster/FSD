import Testing
@testable import AppName

struct AppNameTests {
    @Test func createSampleItemUsesNextIndex() {
        let item = CreateSampleItemAction()(existingCount: 2)

        #expect(item.title == "Sample item 3")
        #expect(item.subtitle == "Created by a feature action")
    }
}
