//
//  FixtureDatabase.swift
//  KrDictTests
//

import Foundation
import SQLite3
@testable import KrDict

/// Builds small throwaway databases with the same schema as
/// scripts/build_dictionary.py, so `SQLiteDictionary` can be tested against
/// known data. `BundledDictionaryTests` guards against the two drifting apart.
struct FixtureDatabase {
    struct Entry {
        var word: String
        var homonymNumber = 0
        var lexicalUnit: String? = "단어"
        var partOfSpeech: String? = "명사"
        var origin: String?
        var pronunciation: String?
        var vocabularyLevel: String?
        /// (Korean definition, English lemma)
        var senses: [(String, String?)] = [("정의", "definition")]
    }

    static func make(_ entries: [Entry], userVersion: Int = SQLiteDictionary.schemaVersion) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("fixture-\(UUID().uuidString).sqlite")
        var db: OpaquePointer?
        guard sqlite3_open(url.path, &db) == SQLITE_OK, let db else {
            throw FixtureError("could not create \(url.path)")
        }
        defer { sqlite3_close(db) }

        try exec(db, """
            CREATE TABLE entries (
                id INTEGER PRIMARY KEY, source_id INTEGER NOT NULL, word TEXT NOT NULL,
                search_key TEXT NOT NULL, homonym_number INTEGER NOT NULL, lexical_unit TEXT,
                part_of_speech TEXT, origin TEXT, pronunciation TEXT, vocabulary_level TEXT
            );
            CREATE TABLE senses (
                entry_id INTEGER NOT NULL, sense_order INTEGER NOT NULL, definition TEXT NOT NULL,
                english_lemma TEXT, english_definition TEXT, PRIMARY KEY (entry_id, sense_order)
            ) WITHOUT ROWID;
            PRAGMA user_version = \(userVersion);
            """)

        for (index, entry) in entries.enumerated() {
            let id = index + 1
            try exec(db, """
                INSERT INTO entries VALUES (\(id), \(id), \(quote(entry.word)),
                    \(quote(DictionarySearchQuery.normalize(entry.word))), \(entry.homonymNumber),
                    \(quote(entry.lexicalUnit)), \(quote(entry.partOfSpeech)), \(quote(entry.origin)),
                    \(quote(entry.pronunciation)), \(quote(entry.vocabularyLevel)))
                """)
            for (order, sense) in entry.senses.enumerated() {
                try exec(db, """
                    INSERT INTO senses VALUES (\(id), \(order + 1), \(quote(sense.0)), \(quote(sense.1)), NULL)
                    """)
            }
        }
        return url
    }

    private static func exec(_ db: OpaquePointer, _ sql: String) throws {
        guard sqlite3_exec(db, sql, nil, nil, nil) == SQLITE_OK else {
            throw FixtureError(String(cString: sqlite3_errmsg(db)))
        }
    }

    private static func quote(_ value: String?) -> String {
        guard let value else { return "NULL" }
        return "'" + value.replacingOccurrences(of: "'", with: "''") + "'"
    }
}

struct FixtureError: Error, CustomStringConvertible {
    let description: String
    init(_ description: String) { self.description = description }
}
