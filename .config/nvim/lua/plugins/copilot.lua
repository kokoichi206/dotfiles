return {
    "zbirenbaum/copilot.lua",
    event = "InsertEnter",
    config = function()
        require("copilot").setup({
            suggestion = {
                enabled = false, -- disable inline suggestions for blink.cmp integration
            },
            panel = { enabled = false },
            filetypes = {
                markdown = true,
                help = true,
            },
        })
    end,
}
