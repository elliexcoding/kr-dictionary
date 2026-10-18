//
//  DictionarySearching.swift
//  KrDict
//

import Foundation

/// Looks up dictionary entries. The app uses `SQLiteDictionary`; tests and
/// previews substitute in-memory implementations.
nonisolated protocol DictionarySearching: Sendable {
    /// Returns entries whose headword contains `query`, best matches first.
    func search(_ query: String, limit: Int) async throws -> [DictionaryEntry]
}

nonisolated enum DictionarySearchQuery {
    /// Normalizes user input to the form stored in `entries.search_key`:
    /// NFC-composed, with whitespace and hyphens removed, so "가격 인상"
    /// matches "가격인상" and "가" matches the affix "가-".
    ///
    /// Must match `search_key()` in scripts/build_dictionary.py.
    static func normalize(_ query: String) -> String {
        String(
            query.precomposedStringWithCanonicalMapping.unicodeScalars
                .filter { !CharacterSet.whitespacesAndNewlines.contains($0) && $0 != "-" }
        )
    }
}

/// Stands in when the bundled database can't be opened, so the failure shows
/// up as a search error instead of a crash.
nonisolated struct UnavailableDictionary: DictionarySearching {
    let error: any Error

    func search(_ query: String, limit: Int) async throws -> [DictionaryEntry] {
        throw error
    }
}

#if DEBUG
/// Fixed list of entries for SwiftUI previews and tests.
nonisolated struct InMemoryDictionary: DictionarySearching {
    var entries: [DictionaryEntry]

    func search(_ query: String, limit: Int) async throws -> [DictionaryEntry] {
        let key = DictionarySearchQuery.normalize(query)
        guard !key.isEmpty else { return [] }
        return Array(
            entries
                .filter { DictionarySearchQuery.normalize($0.word).contains(key) }
                .prefix(limit)
        )
    }

    static let preview = InMemoryDictionary(entries: [
        DictionaryEntry(
            id: 1, word: "사랑", homonymNumber: 1, lexicalUnit: "단어",
            partOfSpeech: "명사", origin: nil, pronunciation: "사랑", vocabularyLevel: "초급",
            senses: [
                .init(order: 1, definition: "어떤 사람이나 존재를 몹시 아끼고 귀중히 여기는 마음.",
                      englishLemma: "love", englishDefinition: "The feeling of caring for and treasuring someone or something."),
            ]
        ),
        DictionaryEntry(
            id: 2, word: "사랑하다", homonymNumber: 0, lexicalUnit: "단어",
            partOfSpeech: "동사", origin: nil, pronunciation: "사랑하다", vocabularyLevel: "초급",
            senses: [
                .init(order: 1, definition: "어떤 사람이나 존재를 몹시 아끼고 귀중히 여기다.",
                      englishLemma: "love", englishDefinition: "To care for and treasure someone or something."),
            ]
        ),
        DictionaryEntry(
            id: 3, word: "단어", homonymNumber: 0, lexicalUnit: "단어",
            partOfSpeech: "명사", origin: "單語", pronunciation: "다너", vocabularyLevel: "초급",
            senses: [
                .init(order: 1, definition: "일정한 뜻과 기능을 가지며 홀로 쓰일 수 있는 가장 작은 말의 단위.",
                      englishLemma: "word", englishDefinition: "The smallest independent unit of language, which has a certain meaning or function."),
            ]
        ),
    ])
}
#endif
