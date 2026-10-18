//
//  ContentView.swift
//  KrDict
//

import SwiftUI

struct ContentView: View {
    let searchModel: SearchModel

    var body: some View {
        TabView {
            Tab("Home", systemImage: "house") {
                HomeView(model: searchModel)
            }

            // Placeholder until the home bar sections are defined.
            Tab("More", systemImage: "square.grid.2x2") {
                PlaceholderView(title: "More")
            }
        }
    }
}

#Preview {
    ContentView(searchModel: SearchModel(dictionary: InMemoryDictionary.preview))
}
