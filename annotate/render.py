#!/usr/bin/env python3
# vim:set expandtab shiftwidth=4 filetype=python:
# SPDX-License-Identifier: GPL-3.0-only

#
#
# ~chewygumxx/awesome-neovim.git
# ::: :/annotate/render.py
#
#

"""Render a static annotated page from the SQLite store.

The output is meant to be opened directly as a Neovim buffer, and is
regenerated after every sync or note edit.
"""
from pathlib import Path

from . import db as db_mod

OUT_PATH = Path(__file__).parent / "annotated.md"


def render_markdown(conn):
    lines = ["# Annotated awesome-neovim", ""]
    current_section = None
    current_subsection = None
    for row in db_mod.all_entries(conn, present_only=True):
        if row["section"] != current_section:
            current_section = row["section"]
            current_subsection = None
            lines.append(f"## {current_section}")
            lines.append("")
        if row["subsection"] != current_subsection:
            current_subsection = row["subsection"]
            if current_subsection:
                lines.append(f"### {current_subsection}")
                lines.append("")
        desc = f" - {row['description']}" if row["description"] else ""
        lines.append(f"- [{row['name']}]({row['url']}){desc}")
        note = db_mod.get_note(conn, row["url"])
        if note:
            for note_line in note.splitlines():
                lines.append(f"    - Note: {note_line}")
    return "\n".join(lines) + "\n"


def write(conn, path=OUT_PATH):
    path.write_text(render_markdown(conn), encoding="utf-8")
    return path
