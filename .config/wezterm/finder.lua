-- 統合ファインダー: 開いている全 pane（cwd + 動作プロセス）と zoxide の dir を
-- 横断 fuzzy 検索し、既存ならジャンプ・無ければ workspace を作成する。
-- `cd dot` の frecency ジャンプ体験を、ターミナル全体（workspace/tab/pane）へ拡張する。
local wezterm = require("wezterm")
local act = wezterm.action
local mux = wezterm.mux

local M = {}

-- zoxide の絶対パス（wezterm の spawn 環境に PATH 依存しないため固定）
local ZOXIDE = "/opt/homebrew/bin/zoxide"

local function home_tilde(p)
	local home = wezterm.home_dir
	if p and p:sub(1, #home) == home then
		return "~" .. p:sub(#home + 1)
	end
	return p
end

-- get_current_working_dir() は Url オブジェクト（新しめ）か file:// 文字列（古い）を返す。
local function url_to_path(url)
	if not url then
		return nil
	end
	if type(url) == "userdata" and url.file_path then
		return url.file_path
	end
	local s = tostring(url)
	s = s:gsub("^file://[^/]*", "")
	return s
end

-- ghq レイアウトの path を owner/repo:worktree 形式の workspace 名に正準化。
-- worktree（repo 名と末尾が異なる dir）は repo:base で判別できるようにする。
local function workspace_name(path)
	local _, repo = path:match("/ghq/github%.com/([^/]+)/([^/]+)")
	if repo then
		local base = path:gsub("/+$", ""):gsub("(.*/)", "")
		if base ~= repo then
			return repo .. ":" .. base
		end
		return repo
	end
	return home_tilde(path)
end

-- 開いている全 pane と zoxide dir を統合した選択肢を構築。
local function build_choices()
	local choices = {}
	local open_dirs = {}

	for _, win in ipairs(mux.all_windows()) do
		local ws = win:get_workspace()
		for _, tab in ipairs(win:tabs()) do
			for _, pane in ipairs(tab:panes()) do
				local cwd = url_to_path(pane:get_current_working_dir())
				if cwd then
					open_dirs[cwd] = true
				end
				local proc = pane:get_foreground_process_name()
				proc = proc and proc:gsub("(.*[/\\])", "") or "?"
				local label = string.format("● [%s] %s — %s", ws, home_tilde(cwd) or "?", proc)
				table.insert(choices, { id = "pane:" .. tostring(pane:pane_id()), label = label })
			end
		end
	end

	local ok, stdout = wezterm.run_child_process({ ZOXIDE, "query", "-l" })
	if ok and stdout then
		for line in stdout:gmatch("[^\r\n]+") do
			if not open_dirs[line] then
				table.insert(choices, { id = "dir:" .. line, label = "○ " .. home_tilde(line) })
			end
		end
	end

	return choices
end

function M.jump_action()
	return wezterm.action_callback(function(window, pane)
		window:perform_action(
			act.InputSelector({
				title = "Jump (open pane / zoxide dir)",
				fuzzy = true,
				choices = build_choices(),
				action = wezterm.action_callback(function(win, p, id, _label)
					if not id then
						return
					end
					local kind, rest = id:match("^(%a+):(.*)$")
					if kind == "pane" then
						local target = mux.get_pane(tonumber(rest))
						if not target then
							return
						end
						local tw = target:window()
						win:perform_action(act.SwitchToWorkspace({ name = tw:get_workspace() }), p)
						local gw = tw:gui_window()
						if gw then
							gw:focus()
						end
						target:activate()
					elseif kind == "dir" then
						-- 同名 workspace があれば切替、無ければ rest を cwd に作成。
						win:perform_action(
							act.SwitchToWorkspace({ name = workspace_name(rest), spawn = { cwd = rest } }),
							p
						)
					end
				end),
			}),
			pane
		)
	end)
end

return M
