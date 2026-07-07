-- main ブランチは auto_install を持たないため parser を明示 install する。
-- markdown_inline は render-markdown の injection 解析に必須。
local ensure_installed = {
	"bash",
	"erlang",
	"git_rebase",
	"go",
	"ini",
	"json",
	"lua",
	"markdown",
	"markdown_inline",
	"nix",
	"pem",
	"python",
	"rust",
	"ssh_config",
	"toml",
	"typescript",
	"vim",
	"vimdoc",
	"yaml",
}

return {
	"nvim-treesitter/nvim-treesitter",
	branch = "main",
	build = ":TSUpdate",
	config = function()
		require("nvim-treesitter").install(ensure_installed)

		local inc = require("util.ts_incremental_selection")

		vim.api.nvim_create_autocmd("FileType", {
			callback = function(args)
				local buf = args.buf
				local lang = vim.treesitter.language.get_lang(vim.bo[buf].filetype)
				if not lang then
					return
				end
				-- parser 未導入の間は start が失敗するので、成功時のみ機能を有効化する。
				if not pcall(vim.treesitter.start, buf, lang) then
					return
				end

				vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"

				vim.keymap.set("n", "<Enter>", inc.init_selection, { buffer = buf, desc = "Init incremental selection" })
				vim.keymap.set("x", "<Enter>", inc.node_incremental, { buffer = buf, desc = "Increment node selection" })
				vim.keymap.set("x", "<Backspace>", inc.node_decremental, { buffer = buf, desc = "Decrement node selection" })
			end,
		})
	end,
}
