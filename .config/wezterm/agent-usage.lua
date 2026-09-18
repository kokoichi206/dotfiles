-- Claude Code と Codex の利用枠をタブバーの右側に出す。
--
-- 右側は 1 か所しか持てず、最後に set_right_status を呼んだ側が全体を置き換える。
-- そのため keybinds.lua のキーテーブル / pane 表示もここで合成する。
--
-- update-status は毎秒発火するため、ここでは HTTP を叩かず、
-- agent-usage.py が書いたキャッシュを読むだけにする。

local wezterm = require("wezterm")

local M = {}

local CACHE_PATH = wezterm.home_dir .. "/.cache/wezterm/agent-usage.json"
local FETCHER = wezterm.config_dir .. "/agent-usage.py"

-- mise の shim は wezterm の起動環境から解決できないため、OS 同梱の実体パスを使う。
local PYTHON = "/usr/bin/python3"

-- percent は整数で、5 時間枠なら 1% がおよそ 3 分ぶん。短い間隔で取り直しても同じ値が返る。
-- 秒単位で動くのは残り時間の表示だが、そちらは resets_at からローカルに計算できる。
local FETCH_INTERVAL_SECONDS = 120

-- 未フォーカスでもウィンドウは見えているので取得は止めない。頻度だけ落とす。
local FETCH_INTERVAL_UNFOCUSED_SECONDS = 600

local CACHE_REREAD_SECONDS = 5

-- 取得が失敗し続けている間に毎秒起動しないための下限。
local SPAWN_RETRY_SECONDS = 20

local WARN_PERCENT = 60
local CRITICAL_PERCENT = 85

local GAUGE_CELLS = 5

-- ▬ は縦中央に太く出る。線が細く見えるなら ━、もっと太くするなら █ に替える。
local GAUGE_GLYPH = "▬"

local COLOR_OK = "#7fd1a8"
local COLOR_WARN = "#e8c06a"
local COLOR_CRITICAL = "#f08a7a"
local COLOR_MUTED = "#70828b"
local COLOR_WINDOW = "#8fa3ad"
local COLOR_RULE = "#3a444b"
local COLOR_TRACK = "#333c43"
local COLOR_CLAUDE = "#d98b5a"
local COLOR_CODEX = "#79b0d8"
local COLOR_GROK = "#b49ad6"

local read_state = { data = nil, read_at = 0 }

local function severity_color(percent)
	if percent >= CRITICAL_PERCENT then
		return COLOR_CRITICAL
	elseif percent >= WARN_PERCENT then
		return COLOR_WARN
	end
	return COLOR_OK
end

local function window_label(minutes)
	if type(minutes) ~= "number" then
		return nil
	end
	if minutes == 300 then
		return "5h"
	elseif minutes == 10080 then
		return "7d"
	elseif minutes % 1440 == 0 then
		return string.format("%dd", minutes / 1440)
	elseif minutes % 60 == 0 then
		return string.format("%dh", minutes / 60)
	end
	return string.format("%dm", minutes)
end

local function remaining(resets_at)
	if type(resets_at) ~= "number" then
		return nil
	end
	local secs = math.floor(resets_at - os.time())
	if secs <= 0 then
		return "now"
	end
	local days = math.floor(secs / 86400)
	local hours = math.floor((secs % 86400) / 3600)
	local minutes = math.floor((secs % 3600) / 60)
	if days > 0 then
		return string.format("%dd%dh", days, hours)
	elseif hours > 0 then
		return string.format("%dh%dm", hours, minutes)
	end
	return string.format("%dm", minutes)
end

local function read_cache()
	local file = io.open(CACHE_PATH, "r")
	if not file then
		return nil
	end
	local body = file:read("*a")
	file:close()
	local ok, parsed = pcall(wezterm.json_parse, body)
	if not ok then
		return nil
	end
	return parsed
end

local function cached()
	local now = os.time()
	if now - read_state.read_at >= CACHE_REREAD_SECONDS then
		read_state = { data = read_cache(), read_at = now }
	end
	return read_state.data
end

-- 起動済みの時刻は GLOBAL に置く。設定 reload でモジュールが読み直されても、
-- 同じプロセスで多重起動しないようにするため。
local function maybe_fetch(window, data)
	local now = os.time()
	if now - (wezterm.GLOBAL.agent_usage_spawned_at or 0) < SPAWN_RETRY_SECONDS then
		return
	end
	local interval = window:is_focused() and FETCH_INTERVAL_SECONDS or FETCH_INTERVAL_UNFOCUSED_SECONDS
	if data then
		if type(data.retry_until) == "number" and now < data.retry_until then
			return
		end
		if type(data.fetched_at) == "number" and now - data.fetched_at < interval then
			return
		end
	end
	wezterm.GLOBAL.agent_usage_spawned_at = now
	wezterm.background_child_process({ PYTHON, FETCHER })
end

local function push(out, text, color, intensity)
	table.insert(out, { Foreground = { Color = color } })
	table.insert(out, { Attribute = { Intensity = intensity or "Normal" } })
	table.insert(out, { Text = text })
end

local function push_gauge(out, percent)
	local filled = math.floor(percent / 100 * GAUGE_CELLS + 0.5)
	if filled > GAUGE_CELLS then
		filled = GAUGE_CELLS
	end
	if filled > 0 then
		push(out, string.rep(GAUGE_GLYPH, filled), severity_color(percent))
	end
	if filled < GAUGE_CELLS then
		push(out, string.rep(GAUGE_GLYPH, GAUGE_CELLS - filled), COLOR_TRACK)
	end
end

local function present(provider, keys)
	local entries = {}
	for _, key in ipairs(keys) do
		local entry = provider[key]
		if type(entry) == "table" and type(entry.percent) == "number" then
			table.insert(entries, entry)
		end
	end
	return entries
end

-- ゲージは窓が最も短い枠に付ける。Claude なら 5h、Codex なら唯一の 7d 枠。
local function shortest(entries)
	local best = nil
	for _, entry in ipairs(entries) do
		if type(entry.window_minutes) == "number" then
			if best == nil or entry.window_minutes < best.window_minutes then
				best = entry
			end
		end
	end
	return best
end

local function push_provider(out, icon, icon_color, provider, keys)
	if type(provider) ~= "table" then
		return
	end
	push(out, icon .. " ", icon_color, "Bold")
	if not provider.ok then
		push(out, provider.error or "error", COLOR_CRITICAL)
		return
	end

	local entries = present(provider, keys)
	if #entries == 0 then
		push(out, "-", COLOR_MUTED)
		return
	end

	local gauged = shortest(entries)
	for index, entry in ipairs(entries) do
		if index > 1 then
			push(out, "   ", COLOR_MUTED)
		end
		push(out, (entry.label or window_label(entry.window_minutes) or "?") .. " ", COLOR_WINDOW)
		if entry == gauged then
			push_gauge(out, entry.percent)
			push(out, " ", COLOR_MUTED)
		end
		push(out, string.format("%d%%", entry.percent), severity_color(entry.percent), "Bold")
		-- scoped 枠は reset 時刻が weekly と同じなので、モデル名だけにして時刻は省く。
		if not entry.label then
			local left = remaining(entry.resets_at)
			if left then
				push(out, " " .. left, COLOR_MUTED)
			end
		end
	end
end

function M.render(data, prefix)
	local out = {}
	if prefix and prefix ~= "" then
		push(out, prefix .. "   ", COLOR_MUTED)
	end
	if not data then
		push(out, "usage …  ", COLOR_MUTED)
		return out
	end
	-- ⌀ は grok のロゴ（円を斜線が貫く形）に近い。空集合の ∅ は「データ無し」と読めるので使わない。
	local providers = {
		{ "✳", COLOR_CLAUDE, data.claude, { "session", "weekly", "scoped" } },
		{ "⬢", COLOR_CODEX, data.codex, { "session", "weekly" } },
		{ "⌀", COLOR_GROK, data.grok, { "period" } },
	}
	local written = false
	for _, provider in ipairs(providers) do
		if type(provider[3]) == "table" then
			if written then
				push(out, "   ┃   ", COLOR_RULE)
			end
			written = true
			push_provider(out, provider[1], provider[2], provider[3], provider[4])
		end
	end
	push(out, "  ", COLOR_MUTED)
	return out
end

function M.update(window, prefix)
	local data = cached()
	maybe_fetch(window, data)
	-- 左スロットは使わない。set_left_status は設定し直すまで内容が残るため、明示的に空にする。
	window:set_left_status("")
	window:set_right_status(wezterm.format(M.render(data, prefix)))
end

return M
