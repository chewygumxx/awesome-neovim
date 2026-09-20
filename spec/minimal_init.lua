#!/usr/bin/env lua
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/awesome-neovim.git
-- ::: :/spec/minimal_init.lua
--
--

-- rtp setup shared by the mini.test harness process and every child
-- Neovim it spawns for spec/ui/*. Locates mini.nvim, telescope.nvim, and
-- plenary.nvim (telescope's own dependency) at lazy.nvim's default
-- install path, since this repo's own `.lazy.lua` already assumes
-- lazy.nvim as the plugin manager for local dev use.

local lazy_root = vim.fn.stdpath("data") .. "/lazy"

---@param name string
local function add_dep(name)
    local path = lazy_root .. "/" .. name
    if vim.fn.isdirectory(path) == 0 then
        error(
            name .. " not found at " .. path .. ". Install it via "
                .. "lazy.nvim before running the mini.test suite."
        )
    end
    vim.opt.rtp:prepend(path)
end

add_dep("mini.nvim")
add_dep("plenary.nvim")
add_dep("telescope.nvim")
vim.opt.rtp:prepend(vim.fn.getcwd())
