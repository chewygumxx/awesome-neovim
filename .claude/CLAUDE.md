# CLAUDE.md

This file gives Claude Code context for working in this repository.

## Purpose

This repository is `chewygumxx`'s fork of [rockerBOO/awesome-neovim], tracked on
the `annotation` branch. Per the README, it exists purely for personal
annotation and tracking, not for accepting community contributions or
maintaining a curated public list.

[rockerBOO/awesome-neovim]: https://github.com/rockerBOO/awesome-neovim

The underlying goal is to attach personal notes to individual entries in the
awesome-list while still being able to merge in upstream changes without
conflict. Editing `README.md` in place to add notes works against that goal,
since any note added on a line upstream also touches will collide on the next
sync.

Other candidate approaches were considered (sidecar notes file with a generator
script, `merge=union` on `README.md`, third-party page annotation) but the
chosen approach, now implemented, is structured extraction into a local
database, kept separate from `README.md` entirely:

- `annotate/` is a Python package. `parser.py` parses `README.md` into entries;
  `db.py` is the primary runtime store, `annotations.db` (SQLite, gitignored,
  regenerable); `yaml_store.py` mirrors every entry and note to `notes.yaml`
  (git-tracked, the durable redundant backup); `render.py` writes `annotated.md`
  (also git-tracked, regenerable, and linked from the top of `README.md` so
  notes are readable on GitHub without cloning) for reading as a buffer or a web
  page. Run `python3 -m annotate sync` after merging `upstream/main` to reparse
  `README.md` and refresh both stores.
  `python3 -m annotate note-set <url> <text>` writes a note; it always
  re-exports the YAML backup and re-renders `annotated.md` in the same step, so
  the three stores never drift apart. `annotated.md` only reaches GitHub once it
  is committed and pushed like any other tracked file. `git_commit.py` runs
  after every `note-set`: it stages only `notes.yaml` and `annotated.md` (never
  `annotations.db`) and makes one local, single-line commit per annotation,
  scoped with `git commit -- <paths>` so it never sweeps up unrelated staged
  changes; it is a no-op if the note text did not actually change. Set
  `AWESOME_NEOVIM_ANNOTATE_NO_COMMIT=1` to disable this, for example while
  testing `note-set` by hand. It never pushes.
- `lua/awesome_neovim_annotate/` is a small Neovim plugin. Reads go through the
  `sqlite3 -json` CLI directly against `annotations.db` for speed; writes always
  shell out to `python3 -m annotate note-set` rather than writing SQLite from
  Lua, so the YAML/render refresh above is never skipped. `:AnnotateFind` opens
  a Telescope picker over entries (`<C-e>` edits the note under the cursor);
  `:AnnotateSections` opens a picker of section names first, then scopes
  `:AnnotateFind` to just that section. Telescope's live fuzzy re-sort rules out
  real collapsible folds over the flat entry list, so this two-stage picker is
  the closest equivalent; `:AnnotateFind` itself still searches everything at
  once. `:AnnotateOpen` opens `annotated.md`.
- `.lazy.lua` at the repo root is a lazy.nvim plugin spec for the above. It is
  not picked up automatically, since this repo is not itself a Neovim config;
  point a real config's lazy spec at this repo's path (see the comment in
  `.lazy.lua`).
- `spec/` holds busted tests for `lua/awesome_neovim_annotate/`. `.busted` runs
  them under `nlua` (`nvim -l`), so `vim.*` is the real Neovim API, not a mock.
  `query_spec.lua` exercises `M.entries()` against a real temporary SQLite
  database; `picker_spec.lua` and `init_spec.lua` test private helpers exposed
  as `M._name` fields (not part of the public API) since the code that needs
  `telescope.nvim` on the runtimepath cannot run in this isolated environment.
  Run `busted` for tests, `luacheck lua/ spec/` to lint,
  `busted --run=coverage && luacov` for a coverage report (`luacov.report.out`,
  gitignored, regenerable). `busted --coverage` alone does not work here: it
  assumes an interpreter that accepts `-l luacov`, and `nlua` explicitly rejects
  `-l`; `spec/coverage_helper.lua` loads luacov directly instead, wired in via
  the `coverage` profile in `.busted`.
- `spec/ui/` is a second, mini.test-based layer for what the busted suite
  structurally cannot cover: real Telescope integration. Each test boots a
  genuine child Neovim (`MiniTest.new_child_neovim()`) with mini.nvim,
  telescope.nvim, and plenary.nvim actually on the runtimepath, located at
  lazy.nvim's default install path (`spec/minimal_init.lua`, shared by the
  harness process and every child it spawns). `test_picker.lua` drives
  `:AnnotateFind` against a real temporary SQLite database and asserts on the
  real `TelescopePrompt` buffer and the real `<C-e>` mapping, both unreachable
  from `picker_spec.lua`. Requires mini.nvim, telescope.nvim, and plenary.nvim
  already installed via lazy.nvim. Run with:
  `nvim --headless --noplugin -u spec/minimal_init.lua -c "lua require('mini.test').setup({collect = {find_files = function() return vim.fn.globpath('spec/ui', '**/test_*.lua', true, true) end}}); MiniTest.run()"`.

If a different or additional approach is proposed later, treat it as a revision
to this design, not as filling in a still-open decision.

## Inherited files

`CONTRIBUTING.md`, `MAINTAINERS.md`, and `scripts/` come from upstream
rockerBOO/awesome-neovim. They describe a multi-maintainer PR review workflow
(compliance checks, acceptance criteria, colorscheme tagging, and so on) that
does not apply to this fork's actual use. Treat them as reference material
carried over from upstream, not as active process for this repository.

## Style

- Do not use em dashes anywhere in this repository. Use a comma, a colon, a
  semicolon, or split into two sentences instead.
- Wrap conversational response text to a line width of 80 characters. This
  applies to chat responses, not to file content.
