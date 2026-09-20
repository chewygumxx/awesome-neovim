#!/usr/bin/env lua
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/awesome-neovim.git
-- ::: :/spec/ui/test_picker.lua
--
--

-- Integration-layer tests for the real Telescope picker, run inside a
-- genuine child Neovim process with mini.nvim, telescope.nvim, and
-- plenary.nvim actually on the runtimepath. spec/picker_spec.lua (busted,
-- under nlua) cannot exercise this: nlua's runtimepath has no telescope
-- on it, so that suite only ever reaches the "telescope.nvim not found"
-- guard in picker.lua. This layer verifies what happens past that guard.

local new_set = MiniTest.new_set
local eq      = MiniTest.expect.equality
local child   = MiniTest.new_child_neovim()

local ENTRIES_TABLE = [[
CREATE TABLE entries (
    url TEXT PRIMARY KEY, section TEXT, subsection TEXT,
    name TEXT, description TEXT, present INTEGER
);
CREATE TABLE notes (url TEXT PRIMARY KEY, note TEXT);
]]

---@param db_path string
---@param note    string?
local function seed_db(db_path, note)
    local sql = {
        ENTRIES_TABLE,
        [[INSERT INTO entries VALUES
            ('https://x/1', 'AI', NULL, 'x/1', 'does things', 1);]],
    }
    if note then
        sql[#sql + 1] = string.format(
            "INSERT INTO notes VALUES ('https://x/1', '%s');",
            note
        )
    end
    vim.system(
        { "sqlite3", db_path, table.concat(sql, "\n") },
        { text = true }
    ):wait()
end

--- Block the harness briefly, then let the child process pending events.
---@param ms integer
local function sleep(ms)
    vim.loop.sleep(ms)
    child.lua_get("0")
end

local tmp_db

local T = new_set({
    hooks = {
        pre_case = function()
            tmp_db = os.tmpname()
            os.remove(tmp_db)
            child.restart({ "-u", "spec/minimal_init.lua" })
            child.lua(
                [[
                require("awesome_neovim_annotate.query").db_path = ...
                require("awesome_neovim_annotate").setup()
            ]],
                { tmp_db }
            )
        end,
        post_case = function()
            os.remove(tmp_db)
        end,
        post_once = child.stop,
    },
})

T["AnnotateFind opens a real Telescope prompt"] = function()
    seed_db(tmp_db, nil)

    child.cmd("AnnotateFind")
    sleep(150)

    eq(child.lua_get("vim.bo.filetype"), "TelescopePrompt")
    local screen = tostring(child.get_screenshot())
    eq(screen:find("x/1", 1, true) ~= nil, true)
end

T["<C-e> opens vim.ui.input pre-filled with the existing note"] = function()
    seed_db(tmp_db, "tried it, solid")

    child.lua(
        [[
        _G.captured_input = nil
        vim.ui.input = function(opts) _G.captured_input = opts end
    ]]
    )
    child.cmd("AnnotateFind")
    sleep(150)
    child.type_keys("<C-e>")
    sleep(50)

    local captured = child.lua_get("_G.captured_input")
    eq(captured.default, "tried it, solid")
    eq(captured.prompt:find("x/1", 1, true) ~= nil, true)
end

return T
