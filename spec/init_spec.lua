#!/usr/bin/env lua
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/awesome-neovim.git
-- ::: :/spec/init_spec.lua
--
--

local mod   = require("awesome_neovim_annotate")
local query = require("awesome_neovim_annotate.query")

describe("awesome_neovim_annotate", function()
    describe("_open_annotated_buffer", function()
        local real_dir

        before_each(function()
            real_dir = query.python_module_dir
        end)

        after_each(function()
            query.python_module_dir = real_dir
        end)

        it("warns when annotated.md is missing", function()
            query.python_module_dir = os.tmpname()
            vim.cmd("enew")
            local before_name = vim.fn.expand("%:t")
            local warned
            stub(vim, "notify", function(msg, level)
                warned = { msg = msg, level = level }
            end)

            mod._open_annotated_buffer()

            assert.is_not_nil(warned)
            assert.equal(vim.log.levels.WARN, warned.level)
            assert.equal(before_name, vim.fn.expand("%:t"))

            vim.notify:revert()
        end)

        it("opens annotated.md when it exists", function()
            vim.cmd("enew")

            mod._open_annotated_buffer()

            assert.equal("annotated.md", vim.fn.expand("%:t"))
        end)
    end)

    describe("setup", function()
        it("registers :AnnotateFind and :AnnotateOpen", function()
            mod.setup()

            assert.is_true(vim.fn.exists(":AnnotateFind") ~= 0)
            assert.is_true(vim.fn.exists(":AnnotateOpen") ~= 0)
        end)
    end)
end)
