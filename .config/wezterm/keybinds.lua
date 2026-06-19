local wezterm = require("wezterm")
local act = wezterm.action
local finder = require("finder")

-- 前回アクティブだったタブのインデックスを記録（ウィンドウごと）
local prev_tab_idx = {}
local current_tab_idx = {}

-- Show which key table is active in the status area + pane info
wezterm.on("update-right-status", function(window, pane)
    local status = {}

    -- キーテーブル表示
    local name = window:active_key_table()
    if name then
        table.insert(status, "TABLE: " .. name)
    end

    -- ペイン情報表示（複数ペインがある場合のみ）
    local tab = window:active_tab()
    if tab then
        local panes = tab:panes()
        if #panes > 1 then
            local active_pane = tab:active_pane()
            for i, p in ipairs(panes) do
                if p:pane_id() == active_pane:pane_id() then
                    table.insert(status, string.format("Pane %d/%d", i, #panes))
                    break
                end
            end
        end
    end

    -- タブ変更の追跡
    local win_id = window:window_id()
    local tabs = window:mux_window():tabs()
    local active_idx = 0
    for i, t in ipairs(tabs) do
        if t:tab_id() == pane:tab():tab_id() then
            active_idx = i - 1
            break
        end
    end
    if current_tab_idx[win_id] ~= active_idx then
        prev_tab_idx[win_id] = current_tab_idx[win_id]
        current_tab_idx[win_id] = active_idx
    end

    window:set_right_status(table.concat(status, " | "))
end)

return {
    keys = {
        {
            -- workspaceの切り替え
            key = "w",
            mods = "LEADER",
            action = act.ShowLauncherArgs({ flags = "WORKSPACES", title = "Select workspace" }),
        },
        {
            -- 統合ファインダー: 開いてる pane（cwd+プロセス）と zoxide dir を横断 fuzzy →
            -- 既存ならジャンプ・無ければ workspace 作成
            key = "f",
            mods = "LEADER",
            action = finder.jump_action(),
        },
        {
            --workspaceの名前変更
            key = "$",
            mods = "LEADER",
            action = act.PromptInputLine({
                description = "(wezterm) Set workspace title:",
                action = wezterm.action_callback(function(win, pane, line)
                    if line then
                        wezterm.mux.rename_workspace(wezterm.mux.get_active_workspace(), line)
                    end
                end),
            }),
        },
        {
            key = "W",
            mods = "LEADER|SHIFT",
            action = act.PromptInputLine({
                description = "(wezterm) Create new workspace:",
                action = wezterm.action_callback(function(window, pane, line)
                    if line then
                        window:perform_action(
                            act.SwitchToWorkspace({
                                name = line,
                            }),
                            pane
                        )
                    end
                end),
            }),
        },
        -- コマンドパレット表示
        { key = "p", mods = "SUPER", action = act.ActivateCommandPalette },
        -- Tab移動
        { key = "Tab", mods = "CTRL", action = act.ActivateTabRelative(1) },
        { key = "Tab", mods = "SHIFT|CTRL", action = act.ActivateTabRelative(-1) },
        { key = "=", mods = "SUPER", action = act.ActivateTabRelative(1) },
        -- 前のタブに戻る
        {
            key = "-",
            mods = "SUPER",
            action = wezterm.action_callback(function(window, pane)
                local win_id = window:window_id()
                local idx = prev_tab_idx[win_id]
                if idx ~= nil then
                    window:perform_action(act.ActivateTab(idx), pane)
                end
            end),
        },
        -- Tab入れ替え
        { key = "{", mods = "LEADER", action = act({ MoveTabRelative = -1 }) },
        -- Window 新規作成
        { key = "n", mods = "SUPER", action = act.SpawnWindow },
        -- Tab新規作成
        { key = "t", mods = "SUPER", action = act({ SpawnTab = "CurrentPaneDomain" }) },
        -- Tabを閉じる
        { key = "w", mods = "SUPER", action = act({ CloseCurrentTab = { confirm = true } }) },
        { key = "}", mods = "LEADER", action = act({ MoveTabRelative = 1 }) },

        -- 画面フルスクリーン切り替え
        { key = "Enter", mods = "ALT", action = act.ToggleFullScreen },

        -- コピーモード
        -- { key = 'X', mods = 'LEADER', action = act.ActivateKeyTable{ name = 'copy_mode', one_shot =false }, },
        { key = "[", mods = "LEADER", action = act.ActivateCopyMode },
        -- コピー
        { key = "c", mods = "SUPER", action = act.CopyTo("Clipboard") },
        -- 貼り付け
        { key = "v", mods = "SUPER", action = act.PasteFrom("Clipboard") },

        -- Pane作成 leader + r or d
        { key = "d", mods = "LEADER", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
        { key = "r", mods = "LEADER", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
        -- Paneを閉じる leader + x
        { key = "x", mods = "LEADER", action = act({ CloseCurrentPane = { confirm = true } }) },
        -- Pane移動 leader + hlkj
        { key = "h", mods = "LEADER", action = act.ActivatePaneDirection("Left") },
        { key = "l", mods = "LEADER", action = act.ActivatePaneDirection("Right") },
        { key = "k", mods = "LEADER", action = act.ActivatePaneDirection("Up") },
        { key = "j", mods = "LEADER", action = act.ActivatePaneDirection("Down") },
        -- SUPER key を使った Pnae の移動。
        { key = "[", mods = "SUPER", action = act.ActivatePaneDirection("Left") },
        { key = "]", mods = "SUPER", action = act.ActivatePaneDirection("Right") },
        -- Pane選択
        { key = "[", mods = "CTRL|SHIFT", action = act.PaneSelect },
        -- 選択中のPaneのみ表示
        { key = "z", mods = "LEADER", action = act.TogglePaneZoomState },

        -- フォントサイズ切替
        { key = "+", mods = "CTRL", action = act.IncreaseFontSize },
        { key = "-", mods = "CTRL", action = act.DecreaseFontSize },
        -- フォントサイズのリセット
        { key = "0", mods = "CTRL", action = act.ResetFontSize },

        -- タブ切替 Cmd + 数字
        { key = "1", mods = "SUPER", action = act.ActivateTab(0) },
        { key = "2", mods = "SUPER", action = act.ActivateTab(1) },
        { key = "3", mods = "SUPER", action = act.ActivateTab(2) },
        { key = "4", mods = "SUPER", action = act.ActivateTab(3) },
        { key = "5", mods = "SUPER", action = act.ActivateTab(4) },
        { key = "6", mods = "SUPER", action = act.ActivateTab(5) },
        { key = "7", mods = "SUPER", action = act.ActivateTab(6) },
        { key = "8", mods = "SUPER", action = act.ActivateTab(7) },
        { key = "9", mods = "SUPER", action = act.ActivateTab(-1) },

        -- ペイン切替 Leader + 数字
        { key = "1", mods = "LEADER", action = act.ActivatePaneByIndex(0) },
        { key = "2", mods = "LEADER", action = act.ActivatePaneByIndex(1) },
        { key = "3", mods = "LEADER", action = act.ActivatePaneByIndex(2) },
        { key = "4", mods = "LEADER", action = act.ActivatePaneByIndex(3) },
        { key = "5", mods = "LEADER", action = act.ActivatePaneByIndex(4) },
        { key = "6", mods = "LEADER", action = act.ActivatePaneByIndex(5) },
        { key = "7", mods = "LEADER", action = act.ActivatePaneByIndex(6) },
        { key = "8", mods = "LEADER", action = act.ActivatePaneByIndex(7) },
        { key = "9", mods = "LEADER", action = act.ActivatePaneByIndex(8) },

        -- コマンドパレット
        { key = "p", mods = "SHIFT|CTRL", action = act.ActivateCommandPalette },
        -- 設定再読み込み
        { key = "r", mods = "SHIFT|CTRL", action = act.ReloadConfiguration },
        -- キーテーブル用
        { key = "s", mods = "LEADER", action = act.ActivateKeyTable({ name = "resize_pane", one_shot = false }) },
        {
            key = "a",
            mods = "LEADER",
            action = act.ActivateKeyTable({ name = "activate_pane", timeout_milliseconds = 1000 }),
        },
        -- Shift+Enterで改行を送信
        {
            key = 'Enter',
            mods = 'SHIFT',
            action = wezterm.action.SendString('\n')
        },
    },
    -- キーテーブル
    -- https://wezfurlong.org/wezterm/config/key-tables.html
    key_tables = {
        -- Paneサイズ調整 leader + s
        resize_pane = {
            { key = "h", action = act.AdjustPaneSize({ "Left", 1 }) },
            { key = "l", action = act.AdjustPaneSize({ "Right", 1 }) },
            { key = "k", action = act.AdjustPaneSize({ "Up", 1 }) },
            { key = "j", action = act.AdjustPaneSize({ "Down", 1 }) },

            -- Cancel the mode by pressing escape
            { key = "Enter", action = "PopKeyTable" },
        },
        activate_pane = {
            { key = "h", action = act.ActivatePaneDirection("Left") },
            { key = "l", action = act.ActivatePaneDirection("Right") },
            { key = "k", action = act.ActivatePaneDirection("Up") },
            { key = "j", action = act.ActivatePaneDirection("Down") },
        },
        -- copyモード leader + [
        copy_mode = {
            -- 移動
            { key = "h", mods = "NONE", action = act.CopyMode("MoveLeft") },
            { key = "j", mods = "NONE", action = act.CopyMode("MoveDown") },
            { key = "k", mods = "NONE", action = act.CopyMode("MoveUp") },
            { key = "l", mods = "NONE", action = act.CopyMode("MoveRight") },
            -- 最初と最後に移動
            { key = "^", mods = "NONE", action = act.CopyMode("MoveToStartOfLineContent") },
            { key = "$", mods = "NONE", action = act.CopyMode("MoveToEndOfLineContent") },
            -- 左端に移動
            { key = "0", mods = "NONE", action = act.CopyMode("MoveToStartOfLine") },
            { key = "o", mods = "NONE", action = act.CopyMode("MoveToSelectionOtherEnd") },
            { key = "O", mods = "NONE", action = act.CopyMode("MoveToSelectionOtherEndHoriz") },
            --
            { key = ";", mods = "NONE", action = act.CopyMode("JumpAgain") },
            -- 単語ごと移動
            { key = "w", mods = "NONE", action = act.CopyMode("MoveForwardWord") },
            { key = "b", mods = "NONE", action = act.CopyMode("MoveBackwardWord") },
            { key = "e", mods = "NONE", action = act.CopyMode("MoveForwardWordEnd") },
            -- ジャンプ機能 t f
            { key = "t", mods = "NONE", action = act.CopyMode({ JumpForward = { prev_char = true } }) },
            { key = "f", mods = "NONE", action = act.CopyMode({ JumpForward = { prev_char = false } }) },
            { key = "T", mods = "NONE", action = act.CopyMode({ JumpBackward = { prev_char = true } }) },
            { key = "F", mods = "NONE", action = act.CopyMode({ JumpBackward = { prev_char = false } }) },
            -- 一番下へ
            { key = "G", mods = "NONE", action = act.CopyMode("MoveToScrollbackBottom") },
            -- 一番上へ
            { key = "g", mods = "NONE", action = act.CopyMode("MoveToScrollbackTop") },
            -- viweport
            { key = "H", mods = "NONE", action = act.CopyMode("MoveToViewportTop") },
            { key = "L", mods = "NONE", action = act.CopyMode("MoveToViewportBottom") },
            { key = "M", mods = "NONE", action = act.CopyMode("MoveToViewportMiddle") },
            -- スクロール
            { key = "b", mods = "CTRL", action = act.CopyMode("PageUp") },
            { key = "f", mods = "CTRL", action = act.CopyMode("PageDown") },
            { key = "d", mods = "CTRL", action = act.CopyMode({ MoveByPage = 0.5 }) },
            { key = "u", mods = "CTRL", action = act.CopyMode({ MoveByPage = -0.5 }) },
            -- 範囲選択モード
            { key = "v", mods = "NONE", action = act.CopyMode({ SetSelectionMode = "Cell" }) },
            { key = "v", mods = "CTRL", action = act.CopyMode({ SetSelectionMode = "Block" }) },
            { key = "V", mods = "NONE", action = act.CopyMode({ SetSelectionMode = "Line" }) },
            -- コピー
            { key = "y", mods = "NONE", action = act.CopyTo("Clipboard") },

            -- コピーモードを終了
            {
                key = "Enter",
                mods = "NONE",
                action = act.Multiple({ { CopyTo = "ClipboardAndPrimarySelection" }, { CopyMode = "Close" } }),
            },
            { key = "Escape", mods = "NONE", action = act.CopyMode("Close") },
            { key = "c", mods = "CTRL", action = act.CopyMode("Close") },
            { key = "q", mods = "NONE", action = act.CopyMode("Close") },
        },
    },
}

