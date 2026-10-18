//
//  SearchModel.swift
//  KrDict
//

import Foundation
import Observation

/// Drives the search screen: holds the query and turns it into results.
@Observable
final class SearchModel {
    enum Phase: Equatable {
        /// Nothing typed yet.
        case idle
        case results([DictionaryEntry])
        case failed(String)
    }

    var query = ""
    private(set) var phase: Phase = .idle

    private let dictionary: any DictionarySearching
    private let debounce: Duration
    private let limit: Int

    /// - Parameters:
    ///   - debounce: How long to wait after the last keystroke before
    ///     searching. Tests pass `.zero`.
    ///   - limit: Maximum number of results to show.
    init(dictionary: any DictionarySearching, debounce: Duration = .milliseconds(150), limit: Int = 50) {
        self.dictionary = dictionary
        self.debounce = debounce
        self.limit = limit
    }

    /// Searches for the current query. Call from `.task(id: query)` so a new
    /// keystroke cancels the previous search.
    func search() async {
        let query = query
        guard !DictionarySearchQuery.normalize(query).isEmpty else {
            phase = .idle
            return
        }
        do {
            try await Task.sleep(for: debounce)
            let entries = try await dictionary.search(query, limit: limit)
            try Task.checkCancellation()
            phase = .results(entries)
        } catch is CancellationError {
            // Superseded by a newer query; leave the current results alone.
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }
}
