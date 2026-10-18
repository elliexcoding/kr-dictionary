//
//  HomeView.swift
//  KrDict
//

import SwiftUI

struct HomeView: View {
    @State private var query = ""
    @State private var isShowingSettings = false

    var body: some View {
        NavigationStack {
            Group {
                if query.isEmpty {
                    ContentUnavailableView {
                        Label("한영사전", systemImage: "character.book.closed")
                    } description: {
                        Text("Search for a Korean or English word.")
                    }
                } else {
                    // No word corpus yet, so every search comes back empty.
                    ContentUnavailableView.search(text: query)
                }
            }
            .navigationTitle("KrDict")
            .searchable(
                text: $query,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search words"
            )
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Settings", systemImage: "gearshape") {
                        isShowingSettings = true
                    }
                }
            }
            .sheet(isPresented: $isShowingSettings) {
                SettingsView()
            }
        }
    }
}

#Preview {
    HomeView()
}
