//
//  FSDDemoAppApp.swift
//  FSDDemoApp
//
//  Created by Egor Merkushev on 5/9/26.
//

import SwiftData
import SwiftUI

@main
struct FSDDemoAppApp: App {
    private let sharedModelContainer = AppModelContainerFactory.makePersistentContainer()

    var body: some Scene {
        WindowGroup {
            ItemsPage()
        }
        .modelContainer(sharedModelContainer)
    }
}
