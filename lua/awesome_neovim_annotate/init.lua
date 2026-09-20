#!/usr/bin/env lua
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/awesome-neovim.git
-- ::: :/lua/awesome_neovim_annotate/init.lua
--
--

---@class AwesomeNeovimAnnotate
---@field setup fun(opts?: table)
local M = {}

---Open the Telescope picker over annotated entries.
local function open_annotate_find()
    require("awesome_neovim_annotate.picker").open()
end

---Open the generated `annotated.md` buffer, if it has been rendered.
local function open_annotated_buffer()
    local query = require("awesome_neovim_annotate.query")
    local path = query.python_module_dir .. "/annotate/annotated.md"
    if vim.fn.filereadable(path) == 0 then
        vim.notify(
            "awesome_neovim_annotate: run `python3 -m annotate sync` first",
            vim.log.levels.WARN
        )
        return
    end
    vim.cmd.edit(path)
end

---Register the `:AnnotateFind` and `:AnnotateOpen` user commands.
function M.setup()
    vim.api.nvim_create_user_command(
        "AnnotateFind",
        open_annotate_find,
        { desc = "Search annotated awesome-neovim entries" }
    )
    vim.api.nvim_create_user_command(
        "AnnotateOpen",
        open_annotated_buffer,
        { desc = "Open the generated annotated.md buffer" }
    )
end

-- Exposed for spec/init_spec.lua only; not part of the public API.
M._open_annotate_find = open_annotate_find
M._open_annotated_buffer = open_annotated_buffer

return M
