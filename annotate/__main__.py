#!/usr/bin/env python3
# vim:set expandtab shiftwidth=4 filetype=python:
# SPDX-License-Identifier: GPL-3.0-only

#
#
# ~chewygumxx/awesome-neovim.git
# ::: :/annotate/__main__.py
#
#

"""Command-line entry point for the annotation store.

    python3 -m annotate sync            # parse README.md, refresh db + yaml
    python3 -m annotate render          # regenerate annotated.md
    python3 -m annotate note-get URL
    python3 -m annotate note-set URL TEXT...

Reads used by the Neovim picker go straight through the `sqlite3` CLI
against `annotations.db`; this module is only needed for writes and for the
parse/render steps, so the Lua side never has to embed this parsing logic.
"""
import argparse
import sys
from pathlib import Path

from . import db as db_mod
from . import parser as parser_mod
from . import render as render_mod
from . import yaml_store

README_PATH = Path(__file__).parent.parent / "README.md"


def cmd_sync(_args):
    conn = db_mod.connect()
    if db_mod.is_empty(conn):
        yaml_store.import_yaml(conn)
    entries = parser_mod.parse_readme(README_PATH)
    db_mod.upsert_entries(conn, entries)
    yaml_store.export_yaml(conn)
    render_mod.write(conn)
    print(f"Synced {len(entries)} entries from {README_PATH.name}.")


def cmd_render(_args):
    conn = db_mod.connect()
    path = render_mod.write(conn)
    print(f"Rendered {path}.")


def cmd_note_get(args):
    conn = db_mod.connect()
    note = db_mod.get_note(conn, args.url)
    if note:
        print(note)


def cmd_note_set(args):
    text = " ".join(args.text) if args.text else sys.stdin.read().rstrip("\n")
    conn = db_mod.connect()
    db_mod.set_note(conn, args.url, text)
    yaml_store.export_yaml(conn)
    render_mod.write(conn)


def main():
    parser = argparse.ArgumentParser(prog="python3 -m annotate")
    sub = parser.add_subparsers(dest="command", required=True)

    sub.add_parser("sync").set_defaults(func=cmd_sync)
    sub.add_parser("render").set_defaults(func=cmd_render)

    get_p = sub.add_parser("note-get")
    get_p.add_argument("url")
    get_p.set_defaults(func=cmd_note_get)

    set_p = sub.add_parser("note-set")
    set_p.add_argument("url")
    set_p.add_argument("text", nargs="*")
    set_p.set_defaults(func=cmd_note_set)

    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
