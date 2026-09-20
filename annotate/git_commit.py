#!/usr/bin/env python3
# vim:set expandtab shiftwidth=4 filetype=python:
# SPDX-License-Identifier: GPL-3.0-only

#
#
# ~chewygumxx/awesome-neovim.git
# ::: :/annotate/git_commit.py
#
#

"""Commit each annotation write as its own local, single-line commit.

Runs after every successful `note-set`, staging only notes.yaml and
annotated.md (never annotations.db, which is gitignored). Set
AWESOME_NEOVIM_ANNOTATE_NO_COMMIT to any non-empty value to skip this, for
example while scripting or testing note-set by hand. Never pushes; that
stays a separate, deliberate step outside this tool's scope.
"""
import os
import subprocess
import sys

TRACKED_PATHS = ["annotate/notes.yaml", "annotate/annotated.md"]

MESSAGE_LIMIT = 72


def _message(name, note):
    if not note:
        return f"Clear note on {name}"[:MESSAGE_LIMIT]
    prefix = f"Annotate {name}: "
    budget = MESSAGE_LIMIT - len(prefix)
    if budget <= 0:
        return prefix[:MESSAGE_LIMIT]
    if len(note) > budget:
        note = note[: budget - 3].rstrip() + "..."
    return prefix + note


def commit_note(repo_root, name, note):
    if os.environ.get("AWESOME_NEOVIM_ANNOTATE_NO_COMMIT"):
        return

    subprocess.run(["git", "add", *TRACKED_PATHS], cwd=repo_root, check=True)

    staged = subprocess.run(
        ["git", "diff", "--cached", "--quiet", "--", *TRACKED_PATHS],
        cwd=repo_root,
    )
    if staged.returncode == 0:
        return

    result = subprocess.run(
        ["git", "commit", "-m", _message(name, note), "--", *TRACKED_PATHS],
        cwd=repo_root,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        print(
            f"annotate: git commit failed: {result.stderr.strip()}",
            file=sys.stderr,
        )
