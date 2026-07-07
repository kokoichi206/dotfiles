-- nvim-treesitter main は組み込みの incremental_selection を持たないため、
-- Neovim コアの treesitter API だけで同等機能を提供する。
-- レンジ変換は end-exclusive な TSNode 範囲を Vim の 1-based inclusive へ直し、
-- ecol==0（ノード末尾が行頭に接する）ときは前行末へ寄せる必要がある。

local M = {}

---@type table<integer, TSNode[]>
local selections = {}

---0-based end-exclusive な TSNode 範囲を 1-based inclusive な Vim 範囲へ変換する。
local function to_vim_range(srow, scol, erow, ecol, buf)
	srow = srow + 1
	scol = scol + 1
	erow = erow + 1
	if ecol == 0 then
		erow = erow - 1
		ecol = #vim.api.nvim_buf_get_lines(buf, erow - 1, erow, false)[1]
		ecol = math.max(ecol, 1)
	end
	return srow, scol, erow, ecol
end

local function node_range(node, buf)
	local nsrow, nscol, nerow, necol = node:range()
	return to_vim_range(nsrow, nscol, nerow, necol, buf)
end

---現在の charwise ビジュアル選択を 1-based inclusive（start<=end）で返す。
local function visual_range()
	local _, csrow, cscol = unpack(vim.fn.getpos("v"))
	local _, cerow, cecol = unpack(vim.fn.getpos("."))
	if csrow < cerow or (csrow == cerow and cscol <= cecol) then
		return csrow, cscol, cerow, cecol
	end
	return cerow, cecol, csrow, cscol
end

local function matches(node, buf, csrow, cscol, cerow, cecol)
	local srow, scol, erow, ecol = node_range(node, buf)
	return srow == csrow and scol == cscol and erow == cerow and ecol == cecol
end

---ノードの範囲を charwise ビジュアルで選択し直す。
local function select_node(buf, node)
	local srow, scol, erow, ecol = node_range(node, buf)
	if vim.api.nvim_get_mode().mode ~= "v" then
		vim.cmd("normal! v")
	end
	vim.api.nvim_win_set_cursor(0, { srow, scol - 1 })
	vim.cmd("normal! o")
	vim.api.nvim_win_set_cursor(0, { erow, ecol - 1 })
end

local function get_parser(buf)
	local ok, parser = pcall(vim.treesitter.get_parser, buf)
	if not ok then
		return nil
	end
	return parser
end

function M.init_selection()
	local buf = vim.api.nvim_get_current_buf()
	local node = vim.treesitter.get_node()
	if not node then
		return
	end
	selections[buf] = { node }
	select_node(buf, node)
end

function M.node_incremental()
	local buf = vim.api.nvim_get_current_buf()
	local nodes = selections[buf]
	local csrow, cscol, cerow, cecol = visual_range()

	-- スタックが空、または現在の選択がスタック先頭と一致しない（手動で選択を変えた）場合は
	-- 現在の選択範囲を覆う named node から選択をやり直す。
	if not nodes or #nodes == 0 or not matches(nodes[#nodes], buf, csrow, cscol, cerow, cecol) then
		local parser = get_parser(buf)
		if not parser then
			return
		end
		parser:parse({ vim.fn.line("w0") - 1, vim.fn.line("w$") })
		local node = parser:named_node_for_range(
			{ csrow - 1, cscol - 1, cerow - 1, cecol },
			{ ignore_injections = false }
		)
		if not node then
			return
		end
		selections[buf] = { node }
		select_node(buf, node)
		return
	end

	-- 現在の選択より大きい範囲を持つ最も近い祖先へ拡張する。
	local node = nodes[#nodes]
	while true do
		local parent = node:parent()
		if not parent or parent == node then
			return
		end
		node = parent
		if not matches(node, buf, csrow, cscol, cerow, cecol) then
			table.insert(nodes, node)
			select_node(buf, node)
			return
		end
	end
end

function M.node_decremental()
	local buf = vim.api.nvim_get_current_buf()
	local nodes = selections[buf]
	if not nodes or #nodes < 2 then
		return
	end
	table.remove(nodes)
	select_node(buf, nodes[#nodes])
end

return M
