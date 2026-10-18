//
//  SearchModelTests.swift
//  KrDictTests
//

import Testing
@testable import KrDict

@MainActor
struct SearchModelTests {
    @Test func startsIdle() {
        let model = SearchModel(dictionary: RecordingDictionary(), debounce: .zero)
        #expect(model.phase == .idle)
    }

    @Test func showsResultsForQuery() async {
        let dictionary = RecordingDictionary(results: [Self.sarang])
        let model = SearchModel(dictionary: dictionary, debounce: .zero, limit: 7)

        model.query = "사랑"
        await model.search()

        #expect(model.phase == .results([Self.sarang]))
        #expect(await dictionary.calls.map(\.query) == ["사랑"])
        #expect(await dictionary.calls.map(\.limit) == [7])
    }

    @Test func showsEmptyResultsWhenNothingMatches() async {
        let model = SearchModel(dictionary: RecordingDictionary(results: []), debounce: .zero)

        model.query = "없는말"
        await model.search()

        #expect(model.phase == .results([]))
    }

    @Test(arguments: ["", "   ", "-"])
    func blankQueryGoesIdleWithoutSearching(query: String) async {
        let dictionary = RecordingDictionary(results: [Self.sarang])
        let model = SearchModel(dictionary: dictionary, debounce: .zero)

        model.query = "사랑"
        await model.search()
        model.query = query
        await model.search()

        #expect(model.phase == .idle)
        #expect(await dictionary.calls.count == 1)
    }

    @Test func showsFailure() async {
        let model = SearchModel(dictionary: UnavailableDictionary(error: DictionaryError.databaseNotFound), debounce: .zero)

        model.query = "사랑"
        await model.search()

        guard case .failed = model.phase else {
            Issue.record("Expected failure, got \(model.phase)")
            return
        }
    }

    @Test func cancelledSearchLeavesPhaseUnchanged() async {
        let model = SearchModel(dictionary: RecordingDictionary(results: [Self.sarang]), debounce: .seconds(60))

        model.query = "사랑"
        let task = Task { await model.search() }
        task.cancel()
        await task.value

        #expect(model.phase == .idle)
    }

    static let sarang = DictionaryEntry(
        id: 1, word: "사랑", homonymNumber: 1, lexicalUnit: "단어", partOfSpeech: "명사",
        origin: nil, pronunciation: "사랑", vocabularyLevel: "초급",
        senses: [.init(order: 1, definition: "아끼는 마음.", englishLemma: "love", englishDefinition: nil)]
    )
}

/// Returns canned results and records every call.
private actor RecordingDictionary: DictionarySearching {
    private let results: [DictionaryEntry]
    private(set) var calls: [(query: String, limit: Int)] = []

    init(results: [DictionaryEntry] = []) {
        self.results = results
    }

    func search(_ query: String, limit: Int) async throws -> [DictionaryEntry] {
        calls.append((query, limit))
        return results
    }
}
