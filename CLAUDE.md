# KrDict — Korean–English dictionary (iOS)

SwiftUI app, iOS 18+, Swift 6 with main-actor default isolation. No third-party
dependencies. Data comes from NIKL's Korean Learners' Dictionary (한국어기초사전).
This file is a map; the code is the reference.

## Commands

Xcode may not be the active developer dir on this Mac, so prefix `xcodebuild`
with `DEVELOPER_DIR` (harmless if it already is).

```sh
# Build + run all unit tests (required before committing Swift changes)
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test \
  -project KrDict.xcodeproj -scheme KrDict \
  -destination 'platform=iOS Simulator,name=iPhone 17'

# Regenerate the bundled database after a new NIKL export or a script change
python3 -I scripts/build_dictionary.py
```

## Architecture

```
data/raw/**/*.json ──build_dictionary.py──► KrDict/Resources/Dictionary.sqlite
   (NIKL export, gitignored)                   (generated, committed)

HomeView ─► SearchModel ─► any DictionarySearching ─► SQLiteDictionary (actor)
 (view)     (@Observable)   (protocol)                 reads Dictionary.sqlite
```

- `KrDict/Dictionary/`: data layer. `DictionarySearching` is the seam;
  `SQLiteDictionary` is the real implementation; `InMemoryDictionary` (DEBUG
  only) is for previews and tests; `UnavailableDictionary` reports a failed open.
- `KrDict/Search/`: `SearchModel` (debounced query → `Phase`) and the detail screen.
- `KrDictApp` creates the dictionary and injects it. Views never touch SQLite.
- Folders are Xcode synced groups: new files under `KrDict/` or `KrDictTests/`
  join their target automatically; don't hand-edit the pbxproj to add files.

## Invariants (and what breaks)

- **Search normalization must match.** `search_key()` in
  `scripts/build_dictionary.py` and `DictionarySearchQuery.normalize` in Swift
  (NFC, strip whitespace and `-`). If they differ, queries silently miss entries.
- **Schema changes go everywhere at once.** Bump `SCHEMA_VERSION` (script) and
  `SQLiteDictionary.schemaVersion`, update `KrDictTests/Support/FixtureDatabase.swift`,
  and regenerate the DB. A mismatch makes the app show "Search Unavailable".
- **Never hand-edit `Dictionary.sqlite`.** Change the script and regenerate.
- **Never commit `data/raw/`.** It's about 1 GB, and GitHub rejects files over 100 MB.
- **NIKL `source_id` is not unique.** Idioms/proverbs reuse their head word's id;
  use `entries.id`.
- **Raw export quirk:** a `feat` may be an object or a list; always go through
  `as_list()` / `feats()` in the script.
- **Concurrency:** everything defaults to `@MainActor`. Types that cross actors
  (models, the protocol) are `nonisolated`; database work stays in the actor.

## Data and license

- Source: https://krdict.korean.go.kr/download/downloadPopup → "Json 전체 내려받기".
  Unzip under `data/raw/`, run the script, run tests, commit the new DB on its own.
- Text is **CC BY-SA 2.0 KR**. Keep the attribution in `SettingsView` and the
  detail-screen footer. The generated DB stays under CC BY-SA.
- **Do not ship** NIKL audio, images, or video (not redistributable). Example
  sentences quoted from publications are fair-use only; check before adding.

## Conventions

- Tests use Swift Testing (`@Test`, `#expect`), not XCTest. Put new logic behind a
  protocol or in pure functions so it can be tested without the UI or the real DB.
  `BundledDictionaryTests` checks the real DB against the Swift queries.
- Atomic commits: one logical change each, and every commit builds. Keep
  generated data (`Dictionary.sqlite`) in its own commit.
- Commits written by Claude end with a `Co-Authored-By: Claude …` trailer.
- Search is Korean-only so far; English search and example sentences are not
  built yet.
