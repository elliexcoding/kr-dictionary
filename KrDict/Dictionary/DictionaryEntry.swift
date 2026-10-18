//
//  DictionaryEntry.swift
//  KrDict
//

import Foundation

/// One headword from the Korean Learners' Dictionary, with all its senses.
nonisolated struct DictionaryEntry: Identifiable, Hashable, Sendable {
    let id: Int64
    /// Headword as written in the source, e.g. "가다" or "-가".
    let word: String
    /// Distinguishes homonyms (가다¹, 가다²); 0 when the word has none.
    let homonymNumber: Int
    /// 단어, 구, 관용구, 속담, or 문법‧표현.
    let lexicalUnit: String?
    /// Korean part-of-speech label as stored in the source, e.g. "명사".
    let partOfSpeech: String?
    /// Word origin, usually Hanja (e.g. "單語").
    let origin: String?
    let pronunciation: String?
    /// 초급, 중급, or 고급.
    let vocabularyLevel: String?
    let senses: [Sense]

    nonisolated struct Sense: Hashable, Sendable {
        let order: Int
        /// Korean definition.
        let definition: String
        let englishLemma: String?
        let englishDefinition: String?
    }

    /// English name for `partOfSpeech`, falling back to the Korean label.
    var partOfSpeechInEnglish: String? {
        partOfSpeech.map { Self.englishPartOfSpeech[$0] ?? $0 }
    }

    /// First English equivalent, for one-line summaries in result lists.
    var summary: String? {
        senses.lazy.compactMap(\.englishLemma).first
    }

    static let englishPartOfSpeech: [String: String] = [
        "명사": "Noun",
        "의존 명사": "Bound noun",
        "대명사": "Pronoun",
        "수사": "Numeral",
        "동사": "Verb",
        "보조 동사": "Auxiliary verb",
        "형용사": "Adjective",
        "보조 형용사": "Auxiliary adjective",
        "관형사": "Determiner",
        "부사": "Adverb",
        "감탄사": "Interjection",
        "조사": "Particle",
        "어미": "Ending",
        "접사": "Affix",
    ]
}
