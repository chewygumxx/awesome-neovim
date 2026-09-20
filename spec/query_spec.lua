#!/usr/bin/env lua
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/awesome-neovim.git
-- ::: :/spec/query_spec.lua
--
--

local query = require("awesome_neovim_annotate.query")

local ENTRIES_TABLE = [[
CREATE TABLE entries (
    url TEXT PRIMARY KEY, section TEXT, subsection TEXT,
    name TEXT, description TEXT, present INTEGER
);
CREATE TABLE notes (url TEXT PRIMARY KEY, note TEXT);
]]

local function run_sqlite(db_path, sql)
    vim.system({ "sqlite3", db_path, sql }, { text = true }):wait()
end

describe("awesome_neovim_annotate.query", function()
    local real_db_path
    local tmp_db

    before_each(function()
        real_db_path = query.db_path
        tmp_db       = os.tmpname()
        os.remove(tmp_db)
        query.db_path = tmp_db
    end)

    after_each(function()
        os.remove(tmp_db)
        query.db_path = real_db_path
    end)

    it(
        "returns an empty list when the database file does not exist",
        function()
            assert.same({}, query.entries())
        end
    )

    it("decodes a present entry with no note as a real nil", function()
        run_sqlite(
            tmp_db,
            ENTRIES_TABLE
                .. [[
            INSERT INTO entries VALUES
                ('https://x/1', 'Section', NULL, 'x/1', 'desc', 1);
        ]]
        )

        local entries = query.entries()

        assert.equal(1, #entries)
        assert.equal("https://x/1", entries[1].url)
        assert.is_nil(entries[1].note)
        assert.is_nil(entries[1].subsection)
    end)

    it("decodes an entry with a note as a plain string", function()
        run_sqlite(
            tmp_db,
            ENTRIES_TABLE
                .. [[
            INSERT INTO entries VALUES
                ('https://x/2', 'Section', NULL, 'x/2', 'desc', 1);
            INSERT INTO notes VALUES ('https://x/2', 'tried it, solid');
        ]]
        )

        local entries = query.entries()

        assert.equal("tried it, solid", entries[1].note)
    end)

    it("excludes entries marked not present", function()
        run_sqlite(
            tmp_db,
            ENTRIES_TABLE
                .. [[
            INSERT INTO entries VALUES
                ('https://x/3', 'Section', NULL, 'x/3', 'desc', 0);
        ]]
        )

        assert.same({}, query.entries())
    end)

    it("orders results by section, subsection, name", function()
        run_sqlite(
            tmp_db,
            ENTRIES_TABLE
                .. [[
            INSERT INTO entries VALUES
                ('https://x/b', 'B', NULL, 'b', 'desc', 1),
                ('https://x/a', 'A', NULL, 'a', 'desc', 1);
        ]]
        )

        local entries = query.entries()

        assert.equal("A", entries[1].section)
        assert.equal("B", entries[2].section)
    end)
end)
