//
//  KrDictApp.swift
//  KrDict
//

import SwiftUI

@main
struct KrDictApp: App {
    @State private var searchModel = SearchModel(dictionary: Self.makeDictionary())

    var body: some Scene {
        WindowGroup {
            ContentView(searchModel: searchModel)
        }
    }

    private static func makeDictionary() -> any DictionarySearching {
        do {
            return try SQLiteDictionary.bundled()
        } catch {
            return UnavailableDictionary(error: error)
        }
    }
}
