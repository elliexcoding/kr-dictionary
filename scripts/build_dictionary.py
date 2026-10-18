#!/usr/bin/env python3
"""Convert the NIKL Korean Learners' Dictionary (한국어기초사전) JSON export
into the SQLite database bundled with the app.

Download the export from https://krdict.korean.go.kr/download/downloadPopup
("Json 전체 내려받기"), unzip it anywhere under data/raw/, then run:

    python3 scripts/build_dictionary.py

The source data is licensed CC BY-SA 2.0 KR by the National Institute of
Korean Language; the generated database inherits that license.
"""

import argparse
import json
import sqlite3
import sys
import unicodedata
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_INPUT = REPO_ROOT / "data" / "raw"
DEFAULT_OUTPUT = REPO_ROOT / "KrDict" / "Resources" / "Dictionary.sqlite"

# Bump when the schema changes; the app checks it on open.
SCHEMA_VERSION = 1

SCHEMA = """
CREATE TABLE metadata (
    key   TEXT PRIMARY KEY,
    value TEXT NOT NULL
) WITHOUT ROWID;

CREATE TABLE entries (
    id               INTEGER PRIMARY KEY,
    source_id        INTEGER NOT NULL,     -- NIKL entry id; idioms share their head word's
    word             TEXT NOT NULL,        -- headword as written, e.g. "가-"
    search_key       TEXT NOT NULL,        -- word without spaces/hyphens
    homonym_number   INTEGER NOT NULL,     -- 0 when the word has no homonyms
    lexical_unit     TEXT,                 -- 단어, 구, 관용구, 속담, 문법‧표현
    part_of_speech   TEXT,                 -- 명사, 동사, ...; NULL if none
    origin           TEXT,                 -- 원어, e.g. Hanja "單語"
    pronunciation    TEXT,                 -- "가ː", alternatives joined by " / "
    vocabulary_level TEXT                  -- 초급, 중급, 고급; NULL if unrated
);

CREATE INDEX entries_search_key ON entries (search_key);

CREATE TABLE senses (
    entry_id           INTEGER NOT NULL REFERENCES entries (id),
    sense_order        INTEGER NOT NULL,   -- 1-based
    definition         TEXT NOT NULL,      -- Korean definition
    english_lemma      TEXT,               -- English equivalent(s)
    english_definition TEXT,
    PRIMARY KEY (entry_id, sense_order)
) WITHOUT ROWID;
"""

NO_PART_OF_SPEECH = "품사 없음"
ENGLISH = "영어"


def as_list(value):
    if value is None:
        return []
    return value if isinstance(value, list) else [value]


def feats(node):
    """Flatten the `feat` attributes of a node or list of nodes into pairs.

    The export is LMF XML converted to JSON, so a single child becomes an
    object and repeated children become a list; this hides the difference.
    """
    return [
        (feat["att"], feat["val"])
        for item in as_list(node)
        for feat in as_list(item.get("feat"))
        if "val" in feat
    ]


def first(pairs, attribute):
    return next((value for att, value in pairs if att == attribute), None)


def nfc(text):
    if text is None:
        return None
    text = unicodedata.normalize("NFC", text).strip()
    return text or None


def search_key(word):
    """Must match `DictionarySearchQuery.normalize` in the app."""
    return "".join(ch for ch in word if not ch.isspace() and ch != "-")


def parse_entry(entry):
    entry_feats = feats(entry)
    word = nfc(first(feats(entry["Lemma"]), "writtenForm"))
    if not word:
        return None

    part_of_speech = nfc(first(entry_feats, "partOfSpeech"))
    if part_of_speech == NO_PART_OF_SPEECH:
        part_of_speech = None

    pronunciations = []
    for form in as_list(entry.get("WordForm")):
        form_feats = feats(form)
        if first(form_feats, "type") != "발음":
            continue
        for att, value in form_feats:
            value = nfc(value)
            if att == "pronunciation" and value and value not in pronunciations:
                pronunciations.append(value)

    senses = []
    for order, sense in enumerate(as_list(entry.get("Sense")), start=1):
        definition = nfc(first(feats(sense), "definition"))
        if not definition:
            continue
        english_lemma = english_definition = None
        for equivalent in as_list(sense.get("Equivalent")):
            equivalent_feats = feats(equivalent)
            if first(equivalent_feats, "language") == ENGLISH:
                english_lemma = nfc(first(equivalent_feats, "lemma"))
                english_definition = nfc(first(equivalent_feats, "definition"))
                break
        senses.append((order, definition, english_lemma, english_definition))

    return {
        "source_id": int(entry["val"]),
        "word": word,
        "search_key": search_key(word),
        "homonym_number": int(first(entry_feats, "homonym_number") or 0),
        "lexical_unit": nfc(first(entry_feats, "lexicalUnit")),
        "part_of_speech": part_of_speech,
        "origin": nfc(first(entry_feats, "origin")),
        "pronunciation": " / ".join(pronunciations) or None,
        "vocabulary_level": nfc(first(entry_feats, "vocabularyLevel")),
        "senses": senses,
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--input", type=Path, default=DEFAULT_INPUT,
                        help="directory searched recursively for *.json export files")
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    args = parser.parse_args()

    # Export files are named "<part>_<count>_<date>.json"; read them in part
    # order so ids stay stable between runs.
    sources = sorted(args.input.rglob("*.json"),
                     key=lambda path: (int(path.name.split("_")[0]) if path.name[0].isdigit() else 0, path.name))
    if not sources:
        sys.exit(f"No .json files found under {args.input}")

    args.output.parent.mkdir(parents=True, exist_ok=True)
    temporary = args.output.with_suffix(".tmp")
    temporary.unlink(missing_ok=True)

    db = sqlite3.connect(temporary)
    db.executescript(SCHEMA)
    db.execute("PRAGMA journal_mode = OFF")

    creation_date = None
    entry_count = sense_count = 0
    for source in sources:
        print(f"Reading {source.name}…", file=sys.stderr)
        with source.open(encoding="utf-8") as file:
            resource = json.load(file)["LexicalResource"]
        creation_date = creation_date or first(feats(resource.get("GlobalInformation")), "creationDate")

        rows = []
        sense_rows = []
        for raw in as_list(resource["Lexicon"]["LexicalEntry"]):
            entry = parse_entry(raw)
            if entry is None:
                continue
            entry_count += 1
            rows.append((entry_count, entry["source_id"], entry["word"], entry["search_key"],
                         entry["homonym_number"], entry["lexical_unit"],
                         entry["part_of_speech"], entry["origin"],
                         entry["pronunciation"], entry["vocabulary_level"]))
            sense_rows.extend((entry_count, *sense) for sense in entry["senses"])

        db.executemany("INSERT INTO entries VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", rows)
        db.executemany("INSERT INTO senses VALUES (?, ?, ?, ?, ?)", sense_rows)
        sense_count += len(sense_rows)

    db.executemany("INSERT INTO metadata VALUES (?, ?)", [
        ("source", "한국어기초사전 (Korean Learners' Dictionary), National Institute of Korean Language"),
        ("source_url", "https://krdict.korean.go.kr"),
        ("source_created", creation_date or ""),
        ("license", "CC BY-SA 2.0 KR"),
        ("license_url", "https://creativecommons.org/licenses/by-sa/2.0/kr/"),
    ])
    db.execute(f"PRAGMA user_version = {SCHEMA_VERSION}")
    db.commit()
    db.execute("VACUUM")
    db.close()
    temporary.replace(args.output)

    size_mb = args.output.stat().st_size / 1_000_000
    print(f"Wrote {entry_count} entries, {sense_count} senses "
          f"({size_mb:.1f} MB) to {args.output.relative_to(REPO_ROOT)}", file=sys.stderr)


if __name__ == "__main__":
    main()
