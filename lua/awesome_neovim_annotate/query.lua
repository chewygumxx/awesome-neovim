#!/usr/bin/env lua
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/awesome-neovim.git
-- ::: :/lua/awesome_neovim_annotate/query.lua
--
--

-- Read access to the annotation store, via the sqlite3 CLI.
--
-- Reads bypass Python entirely for speed (Telescope calls this on every
-- keystroke), and go straight at annotations.db with `sqlite3 -json`.
-- Writes are never done here; see picker.lua, which shells out to
-- `python3 -m annotate note-set` so every write also refreshes the YAML
-- backup and the rendered static page in one place.

---One row of the `entries`/`notes` join: an awesome-neovim entry plus its
---optional personal note.
---@class AwesomeNeovimAnnotate.Entry
---@field url string
---@field section string
---@field subsection string?
---@field name string
---@field description string?
---@field note string?

---@class AwesomeNeovimAnnotate.Query
---@field db_path string
---@field python_module_dir string
---@field entries fun(): AwesomeNeovimAnnotate.Entry[]
local M = {}

local root = vim.fn.fnamemodify(
    debug.getinfo(1, "S").source:sub(2),
    ":p:h:h:h"
)

---@type string absolute path to the SQLite database.
M.db_path = root .. "/annotate/annotations.db"
---@type string absolute path to the repo root, the `annotate` package's parent.
M.python_module_dir = root

local SELECT = [[
SELECT e.url AS url, e.section AS section, e.subsection AS subsection,
       e.name AS name, e.description AS description, n.note AS note
FROM entries e
LEFT JOIN notes n ON n.url = e.url
WHERE e.present = 1
ORDER BY e.section, e.subsection, e.name;
]]

---List every present entry, with its note if one exists. Returns an empty
---list if the database has not been synced yet, or the query fails.
---@return AwesomeNeovimAnnotate.Entry[]
function M.entries()
    if vim.fn.filereadable(M.db_path) == 0 then
        return {}
    end
    local out = vim.system(
        { "sqlite3", "-json", M.db_path, SELECT },
        { text = true }
    ):wait()
    if out.code ~= 0 or out.stdout == "" then
        return {}
    end
    local decode_opts = { luanil = { object = true, array = true } }
    local ok, rows = pcall(vim.json.decode, out.stdout, decode_opts)
    if not ok then
        return {}
    end
    return rows
end

return M
