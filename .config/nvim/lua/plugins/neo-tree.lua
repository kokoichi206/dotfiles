return {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-tree/nvim-web-devicons",
        "MunifTanjim/nui.nvim",
        "s1n7ax/nvim-window-picker",
    },
    event = "VimEnter",
    keys = {
        {
            "<leader>e",
            function()
                require("neo-tree.command").execute({
                    toggle = true,
                    dir = vim.loop.cwd(),
                    position = "left",
                    source = "filesystem",
                    reveal = true,
                })
            end,
            desc = "Toggle Neo-tree",
        },
        {
            "<leader>E",
            function()
                require("neo-tree.command").execute({
                    action = "focus",
                    dir = vim.loop.cwd(),
                    position = "left",
                    source = "filesystem",
                    reveal = true,
                })
            end,
            desc = "Focus Neo-tree",
        },
    },
    init = function()
        vim.g.neo_tree_remove_legacy_commands = 1

        -- 起動時に常に Neo-tree を開く
        vim.api.nvim_create_autocmd("VimEnter", {
            callback = function()
                require("neo-tree.command").execute({
                    dir = vim.loop.cwd(),
                    position = "left",
                    source = "filesystem",
                    reveal = true,
                })
            end,
        })
    end,
    opts = {
        close_if_last_window = true,
        enable_git_status = true,
        enable_diagnostics = true,
        sources = { "filesystem" },
        filesystem = {
            bind_to_cwd = false,
            follow_current_file = {
                enabled = true,
                leave_dirs_open = true,
            },
            use_libuv_file_watcher = true,
            hijack_netrw_behavior = "open_current",
            filtered_items = {
                visible = false,
                hide_dotfiles = false,
                hide_gitignored = false,
                hide_by_name = { "node_modules" },
                never_show = { ".git", ".DS_Store" },
            },
        },
        window = {
            position = "left",
            width = math.max(20, math.floor(vim.o.columns * 0.2)),
            mappings = {
                ["<space>"] = "toggle_node",
                ["<cr>"] = "open",
                ["h"] = "close_node",
                ["l"] = "open",
                ["s"] = "open_split",
                ["v"] = "open_vsplit",
                ["Y"] = function(state)
                    local node = state.tree:get_node()
                    local filepath = node:get_id()
                    local git_root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
                    if git_root and git_root ~= "" then
                        local relative = filepath:sub(#git_root + 2)
                        vim.fn.setreg("+", relative)
                        vim.notify("Copied: " .. relative)
                    else
                        vim.fn.setreg("+", filepath)
                        vim.notify("Copied: " .. filepath)
                    end
                end,
            },
        },
    },
}
