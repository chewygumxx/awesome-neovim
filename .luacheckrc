-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/awesome-neovim.git
-- ::: :/.luacheckrc
--
--

std     = "luajit"
globals = { "vim" }

files["spec/"] = {
    std = "luajit+busted",
}

files["spec/ui/"] = {
    std = "luajit",
    globals = { "vim", "MiniTest" },
}
