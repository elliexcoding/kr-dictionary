//
//  ContentView.swift
//  KrDict
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Image(systemName: "character.book.closed")
                    .font(.system(size: 48))
                    .foregroundStyle(.tint)
                Text("한영사전")
                    .font(.title)
                Text("Korean–English Dictionary")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .navigationTitle("KrDict")
        }
    }
}

#Preview {
    ContentView()
}
