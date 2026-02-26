return {
	"gaoDean/autolist.nvim",
	ft = { "markdown", "text" },
	opts = {},
	keys = {
		{ "<CR>", "<CR><cmd>AutolistNewBullet<CR>", mode = "i", ft = { "markdown", "text" } },
		{ "<CR>", "<cmd>AutolistToggleCheckbox<CR>", mode = "n", ft = { "markdown", "text" } },
		{ "<Tab>", "<cmd>AutolistTab<CR>", mode = "i", ft = { "markdown", "text" } },
		{ "<S-Tab>", "<cmd>AutolistShiftTab<CR>", mode = "i", ft = { "markdown", "text" } },
		{ "o", "o<cmd>AutolistNewBullet<CR>", mode = "n", ft = { "markdown", "text" } },
		{ "O", "O<cmd>AutolistNewBulletBefore<CR>", mode = "n", ft = { "markdown", "text" } },
	},
}
