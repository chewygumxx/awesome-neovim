#!/usr/bin/env python3
# vim:set expandtab shiftwidth=4 filetype=python:
# SPDX-License-Identifier: GPL-3.0-only

#
#
# ~chewygumxx/awesome-neovim.git
# ::: :/annotate/db.py
#
#

"""SQLite schema and access helpers for the annotation store.

This is the primary, runtime store: the Telescope picker reads from it and
all note edits write to it. `yaml_store.py` keeps a redundant, git-tracked
mirror of everything in here for recovery if this file is lost or corrupted.
"""
import sqlite3
from datetime import datetime, timezone
from pathlib import Path

DB_PATH = Path(__file__).parent / "annotations.db"

SCHEMA = """
CREATE TABLE IF NOT EXISTS entries (
    url TEXT PRIMARY KEY,
    section TEXT NOT NULL,
    subsection TEXT,
    name TEXT NOT NULL,
    description TEXT,
    present INTEGER NOT NULL DEFAULT 1,
    first_seen TEXT NOT NULL,
    last_seen TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS notes (
    url TEXT PRIMARY KEY REFERENCES entries(url) ON DELETE CASCADE,
    note TEXT NOT NULL,
    updated_at TEXT NOT NULL
);
"""


def connect(path=DB_PATH):
    conn = sqlite3.connect(path)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON")
    conn.executescript(SCHEMA)
    return conn


def _now():
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def is_empty(conn):
    row = conn.execute("SELECT COUNT(*) AS n FROM entries").fetchone()
    return row["n"] == 0


def upsert_entries(conn, entries):
    now = _now()
    seen_urls = set()
    for e in entries:
        seen_urls.add(e["url"])
        conn.execute(
            """
            INSERT INTO entries
                (url, section, subsection, name, description,
                 present, first_seen, last_seen)
            VALUES
                (:url, :section, :subsection, :name, :description,
                 1, :now, :now)
            ON CONFLICT(url) DO UPDATE SET
                section = excluded.section,
                subsection = excluded.subsection,
                name = excluded.name,
                description = excluded.description,
                present = 1,
                last_seen = excluded.last_seen
            """,
            {**e, "now": now},
        )
    if seen_urls:
        placeholders = ",".join("?" * len(seen_urls))
        conn.execute(
            f"UPDATE entries SET present = 0 WHERE url NOT IN ({placeholders})",
            list(seen_urls),
        )
    else:
        conn.execute("UPDATE entries SET present = 0")
    conn.commit()


def all_entries(conn, present_only=False):
    query = "SELECT * FROM entries"
    if present_only:
        query += " WHERE present = 1"
    query += " ORDER BY section, subsection, name"
    return conn.execute(query).fetchall()


def all_notes(conn):
    return conn.execute("SELECT * FROM notes").fetchall()


def get_entry(conn, url):
    return conn.execute("SELECT * FROM entries WHERE url = ?", (url,)).fetchone()


def get_note(conn, url):
    row = conn.execute("SELECT note FROM notes WHERE url = ?", (url,)).fetchone()
    return row["note"] if row else None


def set_note(conn, url, note, updated_at=None):
    conn.execute(
        """
        INSERT INTO notes (url, note, updated_at) VALUES (?, ?, ?)
        ON CONFLICT(url) DO UPDATE SET
            note = excluded.note,
            updated_at = excluded.updated_at
        """,
        (url, note, updated_at or _now()),
    )
    conn.commit()
