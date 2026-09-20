#!/usr/bin/env lua
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/awesome-neovim.git
-- ::: :/spec/picker_spec.lua
--
--

local picker = require("awesome_neovim_annotate.picker")

---@param haystack string
---@param needle   string
---@return boolean
local function contains(haystack, needle)
    return haystack:find(needle, 1, true) ~= nil
end

describe("awesome_neovim_annotate.picker", function()
    describe("_entry_maker", function()
        it("includes the note in display and ordinal when present", function()
            local result = picker._entry_maker({
                url = "https://x/1",
                section = "AI",
                subsection = nil,
                name = "x/1",
                description = "does things",
                note = "tried it",
            })

            assert.equal("https://x/1", result.value.url)
            assert.is_true(contains(result.display, "AI"))
            assert.is_true(contains(result.display, "x/1"))
            assert.is_true(contains(result.display, "tried it"))
            assert.is_true(contains(result.ordinal, "tried it"))
        end)

        it("omits the note separator when there is no note", function()
            local result = picker._entry_maker({
                url = "https://x/2",
                section = "AI",
                subsection = nil,
                name = "x/2",
                description = nil,
                note = nil,
            })

            assert.is_false(contains(result.display, "|"))
        end)
    end)

    describe("_notify", function()
        it("prefixes the message and defaults to ERROR level", function()
            local captured
            stub(vim, "notify", function(msg, level)
                captured = { msg = msg, level = level }
            end)

            picker._notify("something broke")
            vim.wait(200, function() return captured ~= nil end)

            assert.equal(
                "awesome_neovim_annotate: something broke",
                captured.msg
            )
            assert.equal(vim.log.levels.ERROR, captured.level)

            vim.notify:revert()
        end)
    end)

    describe("_run_python", function()
        it("builds the expected python3 -m annotate command", function()
            local seen
            stub(vim, "system", function(cmd, opts, on_exit)
                seen = { cmd = cmd, opts = opts }
                on_exit({ code = 0 })
                return { wait = function() end }
            end)

            local done = false
            picker._run_python(
                { "note-set", "https://x/1", "hi" },
                function() done = true end
            )
            vim.wait(200, function() return done end)

            assert.same({
                "python3",
                "-m",
                "annotate",
                "note-set",
                "https://x/1",
                "hi",
            }, seen.cmd)
            assert.is_true(done)

            vim.system:revert()
        end)

        it("notifies, skips on_done, when the command fails", function()
            stub(vim, "system", function(_, _, on_exit)
                on_exit({ code = 1, stderr = "boom" })
                return { wait = function() end }
            end)
            local captured
            stub(vim, "notify", function(msg) captured = msg end)

            local done = false
            picker._run_python({ "sync" }, function() done = true end)
            vim.wait(200, function() return captured ~= nil end)

            assert.is_false(done)
            assert.is_true(contains(captured, "boom"))

            vim.system:revert()
            vim.notify:revert()
        end)
    end)

    describe("open", function()
        it("notifies when telescope.nvim is not on the runtimepath", function()
            local captured
            stub(vim, "notify", function(msg) captured = msg end)

            picker.open()
            vim.wait(200, function() return captured ~= nil end)

            assert.is_true(contains(captured, "telescope.nvim not found"))

            vim.notify:revert()
        end)
    end)
end)
