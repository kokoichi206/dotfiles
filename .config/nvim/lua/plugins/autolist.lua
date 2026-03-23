return {
	"gaoDean/autolist.nvim",
	ft = { "markdown", "text" },
	opts = {},
	config = function(_, opts)
		require("autolist").setup(opts)

		local autolist_utils = require("autolist.utils")
		local autolist_config = require("autolist.config")

		-- autolist.nvim の set_line_marker は marker を再計算するたびに
		-- 行末の空白を削り、さらにカーソルを行末へ寄せてしまう。
		-- Markdown では trailing space に意味があり、今回ほしい Tab / Shift-Tab
		-- の体験でもカーソル位置は維持したいので、ここだけ差し替えている。
		autolist_utils.set_line_marker = function(linenum, marker, list_types)
			local win = vim.api.nvim_get_current_win()
			local cursor = vim.api.nvim_win_get_cursor(win)
			local line = vim.fn.getline(linenum)
			line = line:gsub(
				"^(%s*)" .. autolist_utils.get_marker_pat(line, list_types) .. "(%s*)",
				"%1" .. (marker or "") .. "%2",
				1
			)
			vim.fn.setline(linenum, line)

			local current_line = vim.api.nvim_buf_get_lines(0, cursor[1] - 1, cursor[1], false)[1]
			local max_col = #current_line
			vim.api.nvim_win_set_cursor(win, { cursor[1], math.min(cursor[2], max_col) })
		end

		local group = vim.api.nvim_create_augroup("kokoichi-autolist-indent", { clear = true })

		local function apply_markdown_indent(bufnr)
			vim.bo[bufnr].expandtab = true
			vim.bo[bufnr].shiftwidth = 2
			vim.bo[bufnr].tabstop = 2
			vim.bo[bufnr].softtabstop = 2
		end

		local function sync_autolist_indent(bufnr)
			local tabstop = vim.bo[bufnr].tabstop

			autolist_config.tabstop = vim.bo[bufnr].expandtab and tabstop or 1
			autolist_config.tab = vim.bo[bufnr].expandtab and string.rep(" ", tabstop) or "\t"
		end

		local function current_markdown_list_types()
			return autolist_config.lists[vim.bo.filetype]
		end

		local function line_is_markdown_list(bufnr)
			local list_types = current_markdown_list_types()
			if not list_types then
				return false
			end

			return autolist_utils.is_list(
				vim.api.nvim_buf_get_lines(bufnr, vim.fn.line(".") - 1, vim.fn.line("."), false)[1],
				list_types
			)
		end

		local function insert_text_at_cursor(text)
			local bufnr = vim.api.nvim_get_current_buf()
			local win = vim.api.nvim_get_current_win()
			local cursor = vim.api.nvim_win_get_cursor(win)
			local line = vim.api.nvim_get_current_line()
			local col = cursor[2]
			local new_line = line:sub(1, col) .. text .. line:sub(col + 1)

			vim.api.nvim_buf_set_lines(bufnr, cursor[1] - 1, cursor[1], false, { new_line })
			vim.api.nvim_win_set_cursor(win, { cursor[1], col + #text })
		end

		local function current_indent_text(bufnr)
			if vim.bo[bufnr].expandtab then
				return string.rep(" ", vim.bo[bufnr].shiftwidth)
			end

			return "\t"
		end

		local function recalculate_current_list()
			if vim.bo.filetype == "markdown" or vim.bo.filetype == "text" then
				require("autolist").recalculate()
			end
		end

		-- 行中で Tab を押したときも、文字の途中に空白を差し込むのではなく
		-- 「その list item 自体を一段深くする」挙動に寄せたい。
		-- VSCode 系の Markdown 拡張でもこの期待値が一般的なので、
		-- list 行では行頭インデントを直接増やしてから番号だけ再計算する。
		-- 非 list 行だけ通常の Tab 入力へフォールバックする。
		local function indent_current_list_item_or_insert_tab()
			local bufnr = vim.api.nvim_get_current_buf()
			if not line_is_markdown_list(bufnr) then
				insert_text_at_cursor(current_indent_text(bufnr))
				return
			end

			local win = vim.api.nvim_get_current_win()
			local cursor = vim.api.nvim_win_get_cursor(win)
			local col = cursor[2]
			local indent = current_indent_text(bufnr)
			local line = vim.api.nvim_get_current_line()

			vim.api.nvim_buf_set_lines(bufnr, cursor[1] - 1, cursor[1], false, { indent .. line })
			vim.api.nvim_win_set_cursor(win, { cursor[1], col + #indent })

			recalculate_current_list()
		end

		-- Shift-Tab も同じ考え方で、行中のカーソル位置に依存せず
		-- 現在の list item の階層を一段浅くする。
		-- ここでも marker の整合性だけ autolist.nvim に任せ、
		-- 本文やカーソル位置は極力そのまま保つ。
		local function dedent_current_list_item_or_shift_tab()
			local bufnr = vim.api.nvim_get_current_buf()
			if not line_is_markdown_list(bufnr) then
				return
			end

			local win = vim.api.nvim_get_current_win()
			local cursor = vim.api.nvim_win_get_cursor(win)
			local col = cursor[2]
			local width = vim.bo[bufnr].shiftwidth
			local line = vim.api.nvim_get_current_line()
			local leading_spaces = #(line:match("^ *"))
			local remove_width = math.min(width, leading_spaces)

			if remove_width == 0 then
				return
			end

			vim.api.nvim_buf_set_lines(bufnr, cursor[1] - 1, cursor[1], false, { line:sub(remove_width + 1) })
			vim.api.nvim_win_set_cursor(win, { cursor[1], math.max(0, col - remove_width) })

			recalculate_current_list()
		end

		vim.api.nvim_create_autocmd({ "FileType", "BufEnter" }, {
			group = group,
			pattern = "*",
			callback = function(args)
				if vim.bo[args.buf].filetype == "markdown" then
					apply_markdown_indent(args.buf)
				end

				if vim.bo[args.buf].filetype == "markdown" or vim.bo[args.buf].filetype == "text" then
					sync_autolist_indent(args.buf)
				end
			end,
		})

		vim.api.nvim_create_autocmd("FileType", {
			group = group,
			pattern = { "markdown", "text" },
			callback = function(args)
				local opts = { buffer = args.buf }
				vim.keymap.set("i", "<CR>", "<CR><cmd>AutolistNewBullet<CR>", opts)
				vim.keymap.set("n", "<CR>", "<cmd>AutolistToggleCheckbox<CR>", opts)
				vim.keymap.set("i", "<Tab>", indent_current_list_item_or_insert_tab, opts)
				vim.keymap.set("i", "<S-Tab>", dedent_current_list_item_or_shift_tab, opts)
				vim.keymap.set("n", "o", "o<cmd>AutolistNewBullet<CR>", opts)
				vim.keymap.set("n", "O", "O<cmd>AutolistNewBulletBefore<CR>", opts)
			end,
		})

		if vim.bo.filetype == "markdown" then
			apply_markdown_indent(0)
		end

		if vim.bo.filetype == "markdown" or vim.bo.filetype == "text" then
			sync_autolist_indent(0)
		end
	end,
}
