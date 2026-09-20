#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/awesome-neovim.git
-- ::: :/.lazy.lua
--
--

--
-- lazy.nvim plugin spec for the local annotation picker in this repo.
--
-- This repo is not itself a Neovim config, so this file is not picked up
-- automatically. Point your own lazy.nvim spec at this repo's local path,
-- for example in your config's plugins/ directory:
--
--   { dir = "~/dev/awesome-neovim", import = ".lazy" }
--
-- or copy the spec below into your own config, adjusting `dir`.
--

local M = {
    {
        dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h"),
        name = "awesome-neovim-annotate",
        dependencies = {
            "nvim-telescope/telescope.nvim",
            "nvim-lua/plenary.nvim"
        },
        cmd = { "AnnotateFind", "AnnotateOpen" },
        opts = {}
    }
}

return M
