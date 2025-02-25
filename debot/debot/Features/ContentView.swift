//
//  ContentView.swift
//  debot
//
//  Created by Deter Brown on 2/24/25.
//

import SwiftUI

struct ContentView: View {
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: Theme.Layout.paddingLarge) {
            Image(systemName: "globe")
                .imageScale(.large)
                .font(Theme.Typography.titleLarge)
                .foregroundStyle(.tint)
            
            Text("Welcome to Debot!")
                .font(Theme.Typography.titleMedium)
            
            Text("Your new iOS app")
                .font(Theme.Typography.bodyLarge)
                .foregroundStyle(.secondary)
            
            Spacer()
                .frame(height: Theme.Layout.paddingLarge)
            
            NavigationLink(destination: ComponentShowcase()) {
                HStack {
                    Text("View Component Showcase")
                    Image(systemName: "arrow.right")
                }
                .font(Theme.Typography.bodyLarge)
            }
            
            PrimaryButton(
                title: "Get Started",
                action: {
                    isLoading = true
                    // Add your action here
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        isLoading = false
                    }
                },
                isLoading: isLoading
            )
        }
        .padding(Theme.Layout.paddingLarge)
        .navigationTitle("Debot")
    }
}

#Preview {
    NavigationView {
        ContentView()
    }
}
