return {
	"ahmedkhalf/project.nvim",
	init = function()
		require("project_nvim").setup({
			-- manual_mode = true にすると、バッファを開いた時に自動で cwd を
			-- git root に変更しなくなる。
			-- デフォルト(false)では project.nvim が git root を検出して cwd を
			-- 自動変更するため、fzf-lua の <leader>ff 等が nvim を起動した
			-- ディレクトリではなくリポジトリルートを起点に検索してしまう。
			-- 元の挙動に戻したい場合は manual_mode を false にするか、この行を削除する。
			manual_mode = true,
		})
	end,
}
