return {
    "tpope/vim-sleuth",
    init = function()
        -- Lua は 4 スペースでそろえたいので、自動検出を止めておく。
        vim.g.sleuth_lua_heuristics = 0
    end,
}
