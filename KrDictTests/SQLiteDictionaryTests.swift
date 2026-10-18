//
//  SQLiteDictionaryTests.swift
//  KrDictTests
//

import Foundation
import Testing
@testable import KrDict

struct SQLiteDictionaryTests {
    @Test func ranksExactThenPrefixThenContains() async throws {
        let dictionary = try makeDictionary([
            .init(word: "첫사랑"),
            .init(word: "사랑하다"),
            .init(word: "사랑"),
        ])
        let words = try await dictionary.search("사랑", limit: 10).map(\.word)
        #expect(words == ["사랑", "사랑하다", "첫사랑"])
    }

    @Test func ranksSingleWordsBeforeIdioms() async throws {
        let dictionary = try makeDictionary([
            .init(word: "눈 감다", lexicalUnit: "관용구", partOfSpeech: nil),
            .init(word: "눈썹달"),
        ])
        let words = try await dictionary.search("눈", limit: 10).map(\.word)
        #expect(words == ["눈썹달", "눈 감다"])
    }

    @Test func ranksEasierVocabularyFirst() async throws {
        let dictionary = try makeDictionary([
            .init(word: "나무꾼", vocabularyLevel: "고급"),
            .init(word: "나무라다", vocabularyLevel: "중급"),
            .init(word: "나무늘보"),
        ])
        let words = try await dictionary.search("나무", limit: 10).map(\.word)
        #expect(words == ["나무라다", "나무꾼", "나무늘보"])
    }

    @Test func ignoresSpacesAndHyphens() async throws {
        let dictionary = try makeDictionary([
            .init(word: "가격 인상"),
            .init(word: "-가", partOfSpeech: "접사"),
        ])
        #expect(try await dictionary.search("가격인상", limit: 10).map(\.word) == ["가격 인상"])
        #expect(try await dictionary.search("가", limit: 10).map(\.word).contains("-가"))
    }

    @Test func attachesSensesInOrder() async throws {
        let dictionary = try makeDictionary([
            .init(word: "가다", homonymNumber: 1, partOfSpeech: "동사", senses: [("뜻 하나", "go"), ("뜻 둘", nil)]),
            .init(word: "가다랑어", senses: [("물고기", "skipjack tuna")]),
        ])
        let results = try await dictionary.search("가다", limit: 10)

        let gada = try #require(results.first)
        #expect(gada.word == "가다")
        #expect(gada.homonymNumber == 1)
        #expect(gada.partOfSpeech == "동사")
        #expect(gada.senses.map(\.order) == [1, 2])
        #expect(gada.senses.map(\.definition) == ["뜻 하나", "뜻 둘"])
        #expect(gada.senses.map(\.englishLemma) == ["go", nil])
        #expect(results.last?.senses.map(\.englishLemma) == ["skipjack tuna"])
    }

    @Test func respectsLimit() async throws {
        let dictionary = try makeDictionary((1...5).map { .init(word: "사과\($0)") })
        #expect(try await dictionary.search("사과", limit: 3).count == 3)
    }

    @Test(arguments: ["", "   ", "-"])
    func blankQueryReturnsNothing(query: String) async throws {
        let dictionary = try makeDictionary([.init(word: "사랑")])
        #expect(try await dictionary.search(query, limit: 10).isEmpty)
    }

    @Test func noMatchReturnsNothing() async throws {
        let dictionary = try makeDictionary([.init(word: "사랑")])
        #expect(try await dictionary.search("바다", limit: 10).isEmpty)
    }

    @Test func rejectsMissingFile() {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("missing-\(UUID()).sqlite")
        #expect(throws: DictionaryError.databaseNotFound) {
            try SQLiteDictionary(url: url)
        }
    }

    @Test func rejectsUnknownSchemaVersion() throws {
        let url = try FixtureDatabase.make([], userVersion: 99)
        defer { try? FileManager.default.removeItem(at: url) }
        #expect(throws: DictionaryError.unsupportedSchemaVersion(99)) {
            try SQLiteDictionary(url: url)
        }
    }

    private func makeDictionary(_ entries: [FixtureDatabase.Entry]) throws -> SQLiteDictionary {
        try SQLiteDictionary(url: FixtureDatabase.make(entries))
    }
}

/// Runs against the real Dictionary.sqlite in the app bundle, to catch the
/// generated database and the Swift queries drifting apart.
struct BundledDictionaryTests {
    @Test func findsCommonWordWithPartOfSpeechAndEnglish() async throws {
        let dictionary = try SQLiteDictionary.bundled()
        let first = try #require(try await dictionary.search("사랑", limit: 20).first)

        #expect(first.word == "사랑")
        #expect(first.partOfSpeech == "명사")
        #expect(first.vocabularyLevel == "초급")
        #expect(first.senses.contains { $0.englishLemma?.contains("love") == true })
    }

    @Test func findsPhrasesWithoutTypingSpaces() async throws {
        let dictionary = try SQLiteDictionary.bundled()
        let words = try await dictionary.search("가격인상", limit: 20).map(\.word)
        #expect(words.contains("가격 인상"))
    }
}
