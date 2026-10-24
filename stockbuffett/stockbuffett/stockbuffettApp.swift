//
//  stockbuffettApp.swift
//  stockbuffett
//
//  Created by 龚敬博 on 17/10/26.
//

import SwiftUI

@main
struct stockbuffettApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(ThemeManager.shared)
        }
    }
}
