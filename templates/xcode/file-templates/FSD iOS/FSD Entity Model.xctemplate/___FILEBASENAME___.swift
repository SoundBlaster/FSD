//___FILEHEADER___

import Foundation

struct ___FILEBASENAMEASIDENTIFIER___: Identifiable, Equatable {
    let id: UUID
    <#let attribute: AttributeType#>

    init(id: UUID = UUID(), <#attribute: AttributeType#>) {
        self.id = id
        self.<#attribute#> = <#attribute#>
    }
}
