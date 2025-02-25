//
//  debotApp.swift
//  debot
//
//  Created by Deter Brown on 2/24/25.
//

import SwiftUI

@main
struct debotApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView()
                    .navigationBarTitleDisplayMode(.large)
            }
            .preferredColorScheme(.light) // You can change this to .dark or remove it for system default
            .accentColor(.blue) // You can customize your app's accent color here
        }
    }
}
