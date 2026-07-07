return {
	"nvim-treesitter/nvim-treesitter-textobjects",
	branch = "main",
	dependencies = {
		"nvim-treesitter/nvim-treesitter",
	},
	config = function()
		require("nvim-treesitter-textobjects").setup({
			select = {
				lookahead = true,
				selection_modes = {
					["@parameter.outer"] = "v",
					["@function.outer"] = "V",
					["@class.outer"] = "<c-v>",
				},
				include_surrounding_whitespace = true,
			},
		})

		local select = require("nvim-treesitter-textobjects.select").select_textobject
		local map = function(key, query, group)
			vim.keymap.set({ "x", "o" }, key, function()
				select(query, group)
			end, { desc = "Select " .. query })
		end

		map("af", "@function.outer", "textobjects")
		map("if", "@function.inner", "textobjects")
		map("ac", "@class.outer", "textobjects")
		map("ic", "@class.inner", "textobjects")
		map("ao", "@comment.outer", "textobjects")
		map("as", "@local.scope", "locals")
	end,
}
