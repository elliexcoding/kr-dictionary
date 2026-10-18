//
//  PlaceholderView.swift
//  KrDict
//

import SwiftUI

/// Stand-in screen for tabs that haven't been built yet.
struct PlaceholderView: View {
    let title: String

    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Coming Soon",
                systemImage: "hammer",
                description: Text("This section isn't built yet.")
            )
            .navigationTitle(title)
        }
    }
}

#Preview {
    PlaceholderView(title: "More")
}
