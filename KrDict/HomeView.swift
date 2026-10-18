//
//  HomeView.swift
//  KrDict
//

import SwiftUI

struct HomeView: View {
    @Bindable var model: SearchModel
    @State private var isShowingSettings = false

    var body: some View {
        NavigationStack {
            Group {
                switch model.phase {
                case .idle:
                    ContentUnavailableView {
                        Label("한영사전", systemImage: "character.book.closed")
                    } description: {
                        Text("Search for a Korean word.")
                    }
                case .results(let entries) where entries.isEmpty:
                    ContentUnavailableView.search(text: model.query)
                case .results(let entries):
                    List(entries) { entry in
                        NavigationLink(value: entry) {
                            EntryRow(entry: entry)
                        }
                    }
                    .listStyle(.plain)
                case .failed(let message):
                    ContentUnavailableView(
                        "Search Unavailable",
                        systemImage: "exclamationmark.triangle",
                        description: Text(message)
                    )
                }
            }
            .navigationTitle("KrDict")
            .navigationDestination(for: DictionaryEntry.self) { entry in
                EntryDetailView(entry: entry)
            }
            .searchable(
                text: $model.query,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search words"
            )
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .task(id: model.query) {
                await model.search()
            }
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

private struct EntryRow: View {
    let entry: DictionaryEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                HeadwordText(entry: entry)
                    .font(.headline)
                if let partOfSpeech = entry.partOfSpeechInEnglish {
                    Text(partOfSpeech)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            if let summary = entry.summary {
                Text(summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }
}

#Preview {
    HomeView(model: SearchModel(dictionary: InMemoryDictionary.preview))
}
