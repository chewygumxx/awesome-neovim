#!/usr/bin/env python3
# vim:set expandtab shiftwidth=4 filetype=python:
# SPDX-License-Identifier: GPL-3.0-only

#
#
# ~chewygumxx/awesome-neovim.git
# ::: :/annotate/parser.py
#
#

"""Parse the awesome-neovim README.md into a flat list of entries."""
import re
from pathlib import Path

SECTION_RE = re.compile(r"^(#{2,3})\s+(.+?)\s*$")
ENTRY_RE = re.compile(r"^\s*-\s*\[([^\]]+)\]\((https?://[^)\s]+)\)\s*-?\s*(.*)$")


def parse_readme(path):
    section = None
    subsection = None
    entries = []
    for line in Path(path).read_text(encoding="utf-8").splitlines():
        heading = SECTION_RE.match(line)
        if heading:
            level, title = heading.groups()
            if level == "##":
                section = title
                subsection = None
            else:
                subsection = title
            continue
        if section is None:
            continue
        entry = ENTRY_RE.match(line)
        if not entry:
            continue
        name, url, description = entry.groups()
        entries.append(
            {
                "url": url,
                "section": section,
                "subsection": subsection,
                "name": name.strip("`"),
                "description": description.strip(),
            }
        )
    return entries
