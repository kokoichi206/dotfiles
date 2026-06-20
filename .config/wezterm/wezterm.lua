local wezterm = require("wezterm")
local config = wezterm.config_builder()

config.audible_bell = "SystemBeep"

config.automatically_reload_config = true
config.font_size = 18.0
config.font = wezterm.font_with_fallback({
	{ family = "Cica" },
	{ family = "Cica", assume_emoji_presentation = true },
})
config.use_ime = true
config.window_background_opacity = 0.75
config.macos_window_background_blur = 20

-- 背景画像の設定
config.window_background_image = wezterm.config_dir .. "/background.png"
config.window_background_image_hsb = {
	brightness = 0.05, -- テキストの可読性を保つために暗めに設定（0.0-1.0、低いほど暗い）
	hue = 1.0,
	saturation = 1.0,
}

-- ウィンドウサイズの設定（起動時のサイズを記憶）
config.initial_cols = 210
config.initial_rows = 54

-- ハイパーリンク設定（URLやファイルパスをクリック可能に）
-- default_hyperlink_rules() から mailto ルールを除外（@入りテキストでメーラーが開くのを防ぐ）
config.hyperlink_rules = {}
for _, rule in ipairs(wezterm.default_hyperlink_rules()) do
	if not rule.format:find("mailto:") then
		table.insert(config.hyperlink_rules, rule)
	end
end
-- ファイルパス:行番号 の形式を検出（例: src/main.rs:123）
table.insert(config.hyperlink_rules, {
	regex = [[["]?([\w\d]{1}[\w\d\.\-\_/]+):(\d+):?(\d+)?["]?]],
	format = "$1:$2:$3",
})
-- 絶対パスを検出
table.insert(config.hyperlink_rules, {
	regex = [[/[\w\d\.\-\_/]+]],
	format = "$0",
})

-- 非アクティブペインを暗くして区別しやすくする
config.inactive_pane_hsb = {
	saturation = 0.3,
	brightness = 0.2,
}

-- ペイン選択時の表示設定
config.pane_select_font_size = 24
config.pane_select_bg_color = "#F19DB5"
config.pane_select_fg_color = "#FFFFFF"

----------------------------------------------------
-- Tab
----------------------------------------------------
-- タイトルバーを非表示
config.window_decorations = "RESIZE"
-- タブバーの表示
config.show_tabs_in_tab_bar = true
-- タブが一つの時は非表示
config.hide_tab_bar_if_only_one_tab = true
-- falseにするとタブバーの透過が効かなくなる
-- config.use_fancy_tab_bar = false

-- タブバーの透過
config.window_frame = {
	inactive_titlebar_bg = "rgba(13, 13, 13, 0.75)",
	active_titlebar_bg = "rgba(13, 13, 13, 0.75)",
}

-- タブバーを背景色に合わせる
-- 背景画像を使用する場合はコメントアウト
-- config.window_background_gradient = {
--     colors = { "#000000" },
-- }

-- タブの追加ボタンを非表示
config.show_new_tab_button_in_tab_bar = false
-- nightlyのみ使用可能
-- タブの閉じるボタンを非表示
config.show_close_tab_button_in_tabs = false

-- タブ同士の境界線を非表示
config.colors = {
	tab_bar = {
		background = "#5c6d74",
		inactive_tab_edge = "none",
	},
	-- ペイン間の区切り線の色を変更。
	split = "#F19DB5",
}

-- タブの形をカスタマイズ
-- タブの左側の装飾
local SOLID_LEFT_ARROW = wezterm.nerdfonts.ple_lower_right_triangle
-- タブの右側の装飾
local SOLID_RIGHT_ARROW = wezterm.nerdfonts.ple_upper_left_triangle

wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
	local background = "#5c6d74"
	local foreground = "#FFFFFF"
	local edge_background = "none"
	if tab.is_active then
		background = "#ae8b2d"
		foreground = "#FFFFFF"
	end
	local edge_foreground = background
	local title = "   " .. wezterm.truncate_right(tab.active_pane.title, max_width - 1) .. "   "
	return {
		{ Background = { Color = edge_background } },
		{ Foreground = { Color = edge_foreground } },
		{ Text = SOLID_LEFT_ARROW },
		{ Background = { Color = background } },
		{ Foreground = { Color = foreground } },
		{ Text = title },
		{ Background = { Color = edge_background } },
		{ Foreground = { Color = edge_foreground } },
		{ Text = SOLID_RIGHT_ARROW },
	}
end)

----------------------------------------------------
-- Claude Code 完了時にフォーカスを戻す
----------------------------------------------------
wezterm.on("user-var-changed", function(window, pane, name, value)
	if name == "claude_code_stop" then
		pane:tab():activate()
		pane:activate()
		window:focus()
	end
end)

----------------------------------------------------
-- keybinds
----------------------------------------------------
config.disable_default_key_bindings = true
config.keys = require("keybinds").keys
config.key_tables = require("keybinds").key_tables
config.leader = { key = "q", mods = "CTRL", timeout_milliseconds = 2000 }

return config
