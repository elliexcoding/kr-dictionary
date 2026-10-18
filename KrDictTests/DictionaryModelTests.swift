//
//  DictionaryModelTests.swift
//  KrDictTests
//

import Testing
@testable import KrDict

struct DictionarySearchQueryTests {
    @Test(arguments: [
        ("사랑", "사랑"),
        ("  사랑 \n", "사랑"),
        ("가격 인상", "가격인상"),
        ("-가", "가"),
        ("가-", "가"),
        ("", ""),
        ("   ", ""),
    ])
    func normalizeStripsSpacesAndHyphens(input: String, expected: String) {
        #expect(DictionarySearchQuery.normalize(input) == expected)
    }

    @Test func normalizeComposesDecomposedHangul() {
        // 사랑 typed as individual jamo (NFD), as some pasted text arrives.
        let decomposed = "\u{1109}\u{1161}\u{1105}\u{1161}\u{11BC}"
        #expect(DictionarySearchQuery.normalize(decomposed) == "사랑")
    }
}

struct DictionaryEntryTests {
    @Test(arguments: [
        ("명사", "Noun"),
        ("동사", "Verb"),
        ("의존 명사", "Bound noun"),
        ("새품사", "새품사"),  // unknown labels fall back to the Korean
    ])
    func partOfSpeechInEnglish(korean: String, english: String) {
        #expect(entry(partOfSpeech: korean).partOfSpeechInEnglish == english)
    }

    @Test func partOfSpeechInEnglishIsNilWithoutPartOfSpeech() {
        #expect(entry(partOfSpeech: nil).partOfSpeechInEnglish == nil)
    }

    @Test func summaryUsesFirstSenseWithAnEnglishLemma() {
        let entry = entry(senses: [
            .init(order: 1, definition: "뜻", englishLemma: nil, englishDefinition: nil),
            .init(order: 2, definition: "뜻", englishLemma: "second", englishDefinition: nil),
        ])
        #expect(entry.summary == "second")
    }

    private func entry(partOfSpeech: String? = "명사", senses: [DictionaryEntry.Sense] = []) -> DictionaryEntry {
        DictionaryEntry(
            id: 1, word: "단어", homonymNumber: 0, lexicalUnit: "단어", partOfSpeech: partOfSpeech,
            origin: nil, pronunciation: nil, vocabularyLevel: nil, senses: senses
        )
    }
}
