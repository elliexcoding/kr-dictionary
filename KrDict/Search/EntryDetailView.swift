//
//  EntryDetailView.swift
//  KrDict
//

import SwiftUI

struct EntryDetailView: View {
    let entry: DictionaryEntry

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    HeadwordText(entry: entry)
                        .font(.largeTitle.bold())
                    if let pronunciation = entry.pronunciation {
                        Text("[\(pronunciation)]")
                            .foregroundStyle(.secondary)
                    }
                }
                if let partOfSpeech = entry.partOfSpeech {
                    LabeledContent("Part of speech") {
                        Text("\(entry.partOfSpeechInEnglish ?? partOfSpeech) · \(partOfSpeech)")
                    }
                }
                if let origin = entry.origin {
                    LabeledContent("Origin", value: origin)
                }
                if let level = entry.vocabularyLevel {
                    LabeledContent("Level", value: level)
                }
            }

            Section("Meanings") {
                ForEach(entry.senses, id: \.order) { sense in
                    SenseRow(sense: sense)
                }
            }

            Section {
            } footer: {
                Text("Source: 국립국어원 한국어기초사전 (CC BY-SA 2.0 KR)")
            }
        }
        .navigationTitle(entry.word)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct SenseRow: View {
    let sense: DictionaryEntry.Sense

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text("\(sense.order).")
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 4) {
                if let lemma = sense.englishLemma {
                    Text(lemma)
                        .font(.headline)
                }
                if let definition = sense.englishDefinition {
                    Text(definition)
                }
                Text(sense.definition)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

/// Headword with its homonym number as a superscript, e.g. 가다¹.
struct HeadwordText: View {
    let entry: DictionaryEntry

    var body: some View {
        if entry.homonymNumber > 0 {
            Text("\(entry.word)\(Text("\(entry.homonymNumber)").font(.caption).baselineOffset(8))")
        } else {
            Text(entry.word)
        }
    }
}

#Preview {
    NavigationStack {
        EntryDetailView(entry: InMemoryDictionary.preview.entries[0])
    }
}
