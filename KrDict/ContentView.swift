//
//  ContentView.swift
//  KrDict
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Home", systemImage: "house") {
                HomeView()
            }

            // Placeholder until the home bar sections are defined.
            Tab("More", systemImage: "square.grid.2x2") {
                PlaceholderView(title: "More")
            }
        }
    }
}

#Preview {
    ContentView()
}
