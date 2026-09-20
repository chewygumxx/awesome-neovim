#!/usr/bin/env lua
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/awesome-neovim.git
-- ::: :/lua/awesome_neovim_annotate/picker.lua
--
--

-- Telescope picker over annotated awesome-neovim entries.
local query = require("awesome_neovim_annotate.query")

---One entry as wrapped for a Telescope finder.
---@class AwesomeNeovimAnnotate.FinderEntry
---@field value AwesomeNeovimAnnotate.Entry
---@field display string
---@field ordinal string

---@class AwesomeNeovimAnnotate.Picker
---@field open fun()
local M = {}

---@param msg string
---@param level? integer defaults to `vim.log.levels.ERROR`.
local function notify(msg, level)
    vim.schedule(function()
        vim.notify(
            "awesome_neovim_annotate: " .. msg, level or vim.log.levels.ERROR
        )
    end)
end

---Run `python3 -m annotate <args>` from the repo root.
---@param args string[]
---@param on_done? fun() called on the main loop after a successful run.
local function run_python(args, on_done)
    local cmd  = { "python3", "-m", "annotate", unpack(args) }
    local opts = { cwd = query.python_module_dir, text = true }
    vim.system(cmd, opts, function(out)
        if out.code ~= 0 then
            notify(out.stderr or "command failed")
            return
        end
        if on_done then
            vim.schedule(on_done)
        end
    end)
end

---Prompt for a note and write it via `python3 -m annotate note-set`.
---@param entry AwesomeNeovimAnnotate.Entry
---@param on_saved? fun() called after the note has been written.
local function edit_note(entry, on_saved)
    local opts = {
        prompt = entry.name .. " note: ",
        default = entry.note or "",
    }
    vim.ui.input(opts, function(text)
        if text == nil then
            return
        end
        run_python({ "note-set", entry.url, text }, on_saved)
    end)
end

---@param entry AwesomeNeovimAnnotate.Entry
---@return AwesomeNeovimAnnotate.FinderEntry
local function entry_maker(entry)
    local note_preview = entry.note and (" | " .. entry.note) or ""
    return {
        value = entry,
        display = string.format(
            "%-24s %s%s",
            entry.section,
            entry.name,
            note_preview
        ),
        ordinal = table.concat({
            entry.section,
            entry.subsection or "",
            entry.name,
            entry.description or "",
            entry.note or "",
        }, " "),
    }
end

---Build a fresh Telescope finder over the current entries.
---@return table finder a `telescope.finders` table finder.
local function make_finder()
    local finders = require("telescope.finders")
    return finders.new_table({
        results = query.entries(),
        entry_maker = entry_maker,
    })
end

---Close the picker and open the selected entry's URL.
---@param bufnr integer
local function select_entry(bufnr)
    local actions      = require("telescope.actions")
    local action_state = require("telescope.actions.state")
    local selection    = action_state.get_selected_entry()
    actions.close(bufnr)
    if selection then
        vim.ui.open(selection.value.url)
    end
end

---Edit the note on the entry under the cursor, then refresh the picker.
---@param bufnr integer
local function edit_selected_note(bufnr)
    local action_state = require("telescope.actions.state")
    local selection    = action_state.get_selected_entry()
    if not selection then
        return
    end
    local picker = action_state.get_current_picker(bufnr)
    edit_note(selection.value, function()
        picker:refresh(make_finder(), { reset_prompt = false })
    end)
end

---Telescope `attach_mappings` callback: default select, `<C-e>` to edit.
---@param bufnr integer
---@param map fun(modes: string|string[], lhs: string, rhs: function)
---@return boolean
local function attach_mappings(bufnr, map)
    local actions = require("telescope.actions")
    actions.select_default:replace(function()
        select_entry(bufnr)
    end)
    map({ "i", "n" }, "<C-e>", function()
        edit_selected_note(bufnr)
    end)
    return true
end

---Open the Telescope picker over annotated awesome-neovim entries.
function M.open()
    local ok, pickers = pcall(require, "telescope.pickers")
    if not ok then
        notify(
            "telescope.nvim not found. Ensure nvim-telescope/telescope.nvim "
                .. "is installed, then run :Lazy sync."
        )
        return
    end
    local conf = require("telescope.config").values
    pickers.new({}, {
        prompt_title = "Awesome Neovim (annotated)",
        finder = make_finder(),
        sorter = conf.generic_sorter({}),
        attach_mappings = attach_mappings,
    }):find()
end

-- Exposed for spec/picker_spec.lua only; not part of the public API.
M._notify = notify
M._run_python = run_python
M._entry_maker = entry_maker

return M
