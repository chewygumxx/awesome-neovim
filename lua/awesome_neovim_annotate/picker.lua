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
---@field display fun(): string, table[]?
---@field ordinal string

---@class AwesomeNeovimAnnotate.Picker
---@field open fun()
local M = {}

-- Highlight group for the "has a note" marker and the note text in the
-- previewer, so a note reads as set apart from the awesome-neovim entry
-- it is attached to.
local NOTE_HL = "AwesomeNeovimAnnotateNote"
local NOTE_MARKER = "^"

-- Telescope draws its prompt, results, and preview windows with `winhl`
-- remapping `Normal`/`FloatBorder` to its own Telescope*Normal/Border
-- groups, often a visually distinct float color. Remapping back to plain
-- `Normal` makes this picker match the regular editor background instead.
local WINHL = "Normal:Normal,FloatBorder:Normal"

local function link_note_hl()
    vim.api.nvim_set_hl(0, NOTE_HL, { link = "Comment", default = true })
end

link_note_hl()
vim.api.nvim_create_autocmd("ColorScheme", { callback = link_note_hl })

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
    local marker = entry.note and NOTE_MARKER or " "
    local suffix = entry.description and (" - " .. entry.description) or ""
    local line = string.format(
        "%s %-16s %s%s",
        marker,
        entry.section,
        entry.name,
        suffix
    )

    local highlights = entry.note and { { { 0, #marker }, NOTE_HL } }

    return {
        value = entry,
        display = function()
            return line, highlights
        end,
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

---Render the currently highlighted entry, with its note, if any, on an
---indented line of its own.
---@return table previewer a `telescope.previewers` buffer previewer.
local function make_previewer()
    local previewers = require("telescope.previewers")
    return previewers.new_buffer_previewer({
        title = "Annotation",
        define_preview = function(self, telescope_entry)
            local entry = telescope_entry.value
            local lines = {
                entry.name,
                entry.url,
                "",
                entry.description or "",
            }
            local note_row
            if entry.note then
                lines[#lines + 1] = ""
                note_row = #lines
                lines[#lines + 1] = "    " .. entry.note
            end

            vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
            if note_row then
                vim.api.nvim_buf_add_highlight(
                    self.state.bufnr, -1, NOTE_HL, note_row, 0, -1
                )
            end

            -- Telescope's own preview setup turns wrap off, and points the
            -- background at TelescopePreviewNormal, unconditionally, and
            -- recreates the window on every entry change, so both have to
            -- be redone here, every time. breakindent keeps a wrapped
            -- note's continuation lines aligned under its own indent.
            local winid = self.state.winid
            vim.wo[winid].wrap = true
            vim.wo[winid].linebreak = true
            vim.wo[winid].breakindent = true
            vim.wo[winid].winhl = WINHL
        end,
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

-- The preview content window's own background is handled inside
-- define_preview above instead, since Telescope recreates that one
-- window on every entry change and would otherwise clobber this.
---@param picker table
local function match_editor_background(picker)
    vim.wo[picker.layout.prompt.winid].winhl = WINHL
    vim.wo[picker.layout.prompt.border.winid].winhl = WINHL
    vim.wo[picker.layout.results.winid].winhl = WINHL
    vim.wo[picker.layout.results.border.winid].winhl = WINHL
    if picker.layout.preview then
        vim.wo[picker.layout.preview.border.winid].winhl = WINHL
    end
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
    local picker = pickers.new({}, {
        prompt_title = "Awesome Neovim (annotated)",
        finder = make_finder(),
        sorter = conf.generic_sorter({}),
        previewer = make_previewer(),
        attach_mappings = attach_mappings,
        sorting_strategy = "ascending",
        layout_config = { prompt_position = "top" },
    })
    picker:find()
    match_editor_background(picker)
end

-- Exposed for spec/picker_spec.lua only; not part of the public API.
M._notify = notify
M._run_python = run_python
M._entry_maker = entry_maker

return M
