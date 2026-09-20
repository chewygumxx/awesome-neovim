#!/usr/bin/env python3
# vim:set expandtab shiftwidth=4 filetype=python:
# SPDX-License-Identifier: GPL-3.0-only

#
#
# ~chewygumxx/awesome-neovim.git
# ::: :/annotate/yaml_store.py
#
#

"""Redundant YAML backup for the SQLite annotation store.

`annotations.db` is primary and gitignored, since it is a regenerable local
cache. `notes.yaml` is git-tracked: it is the durable, human-readable copy
that a fresh clone (or a corrupted `.db` file) can be rebuilt from.
"""
from pathlib import Path

import yaml

from . import db as db_mod

YAML_PATH = Path(__file__).parent / "notes.yaml"


def export_yaml(conn, path=YAML_PATH):
    notes_by_url = {row["url"]: row for row in db_mod.all_notes(conn)}
    records = []
    for entry in db_mod.all_entries(conn):
        record = dict(entry)
        note = notes_by_url.get(entry["url"])
        record["note"] = note["note"] if note else None
        record["note_updated_at"] = note["updated_at"] if note else None
        records.append(record)
    path.write_text(
        yaml.safe_dump(records, sort_keys=False, allow_unicode=True),
        encoding="utf-8",
    )


def import_yaml(conn, path=YAML_PATH):
    if not path.exists():
        return
    records = yaml.safe_load(path.read_text(encoding="utf-8")) or []
    entries = [
        {
            "url": r["url"],
            "section": r["section"],
            "subsection": r.get("subsection"),
            "name": r["name"],
            "description": r.get("description"),
        }
        for r in records
    ]
    db_mod.upsert_entries(conn, entries)
    for r in records:
        if r.get("note"):
            db_mod.set_note(conn, r["url"], r["note"], r.get("note_updated_at"))
