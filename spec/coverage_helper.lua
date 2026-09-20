#!/usr/bin/env lua
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/awesome-neovim.git
-- ::: :/spec/coverage_helper.lua
--
--

-- Loaded before the spec files via `.busted`'s `helper` option.
--
-- `busted --coverage` assumes it can re-invoke the interpreter with a
-- `-l luacov` flag, the way `lua5.1 -lluacov` works. `nlua` (this repo's
-- `lua = "nlua"` in `.busted`) is really `nvim -l`, which explicitly
-- rejects `-l`, so that mechanism silently produces no stats file.
-- Requiring luacov directly here, and flushing it when the suite ends,
-- works with any interpreter busted is configured to use.
require("luacov")

local busted = require("busted")
busted.subscribe({ "suite", "end" }, function()
    require("luacov.runner").shutdown()
end)
