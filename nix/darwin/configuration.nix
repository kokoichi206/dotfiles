{
  username,
  ...
}:
{
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # マシンのターゲットプラットフォーム。
  nixpkgs.hostPlatform = "aarch64-darwin";

  users.users.${username}.home = "/Users/${username}";

  system.defaults = {
    dock = {
      # Dock を自動で隠す。
      autohide = true;
      # ホバー時のアイコン拡大を有効化。
      magnification = true;
      # 通常時のアイコンサイズ。
      tilesize = 51;
      # 拡大時のアイコンサイズ。
      largesize = 95;
      # Dock の表示位置。
      orientation = "bottom";
      # 3/4 本指スワイプで App Expose。
      showAppExposeGestureEnabled = true;
      # 右下ホットコーナーをクイックメモに設定。
      wvous-br-corner = 14;
    };

    NSGlobalDomain = {
      # キーリピート開始までの待機時間。
      InitialKeyRepeat = 15;
      # キーリピート開始後の速度。
      KeyRepeat = 2;

      # トラックパッドのカーソル速度（0.0 - 3.0）。
      "com.apple.trackpad.scaling" = 3.0;
      # Force Click を有効化。
      "com.apple.trackpad.forceClick" = true;

      # テキスト入力時の自動補助設定。
      NSAutomaticCapitalizationEnabled = true;
      NSAutomaticPeriodSubstitutionEnabled = true;
      # フォルダ/ファイルのスプリングロード設定。
      "com.apple.springing.enabled" = true;
      "com.apple.springing.delay" = 0.5;
      # 外観をダークに固定。
      AppleInterfaceStyle = "Dark";
    };

    trackpad = {
      # 触覚フィードバック。
      ActuateDetents = true;
      # タップでクリック。
      Clicking = true;
      # ドラッグロックは無効。
      DragLock = false;
      # タップでドラッグは無効。
      Dragging = false;
      # 通常クリックの押し込み強度。
      FirstClickThreshold = 1;
      # Force Click を無効化しない。
      ForceSuppressed = false;
      # Force Click 時の押し込み強度。
      SecondClickThreshold = 1;
      # 副ボタン設定（0 = 2本指クリック）。
      TrackpadCornerSecondaryClick = 0;
      # 4本指の横スワイプ。
      TrackpadFourFingerHorizSwipeGesture = 2;
      # 4本指ピンチジェスチャ。
      TrackpadFourFingerPinchGesture = 2;
      # 4本指の縦スワイプ。
      TrackpadFourFingerVertSwipeGesture = 2;
      # 慣性スクロール。
      TrackpadMomentumScroll = true;
      # ピンチでズーム。
      TrackpadPinch = true;
      # 2本指で右クリック。
      TrackpadRightClick = true;
      # 2本指回転。
      TrackpadRotate = true;
      # 3本指ドラッグ。
      TrackpadThreeFingerDrag = false;
      # 3本指の横スワイプ。
      TrackpadThreeFingerHorizSwipeGesture = 2;
      # 3本指タップ動作。
      TrackpadThreeFingerTapGesture = 0;
      # 3本指の縦スワイプ。
      TrackpadThreeFingerVertSwipeGesture = 2;
      # 2本指ダブルタップでスマートズーム。
      TrackpadTwoFingerDoubleTapGesture = true;
      # 右端スワイプで通知センター。
      TrackpadTwoFingerFromRightEdgeSwipeGesture = 3;
    };

    screencapture = {
      # 保存先を既定の Desktop から ~/Documents/imgs へ変更。
      location = "/Users/${username}/Documents/imgs";
    };

    WindowManager = {
      # Stage Manager 利用時は同一アプリのウィンドウをまとめて表示。
      AppWindowGroupingBehavior = true;
      # タイル配置時のウィンドウ余白を無効へ変更。
      EnableTiledWindowMargins = false;
    };

    menuExtraClock = {
      # 午前/午後を表示。
      ShowAMPM = true;
      # 日付は「スペースがある場合のみ表示」。
      ShowDate = 0;
      # 曜日を表示。
      ShowDayOfWeek = true;
    };

    loginwindow = {
      # ゲストログインを無効へ変更。
      GuestEnabled = false;
    };

    CustomUserPreferences = {
      # Spotlight / 入力切替など、独自に変更したショートカットのみを固定。
      # AppleSymbolicHotKeys の ID 一覧（非公式）:
      # - https://gist.github.com/aca/bb6d936325fc59b2b61090d14f9852a5
      # - https://stackoverflow.com/a/78820725 (例: 184 = Screenshot and recording options)
      "com.apple.symbolichotkeys" = {
        AppleSymbolicHotKeys = {
          "15" = { enabled = false; };
          "16" = { enabled = false; };
          "17" = { enabled = false; };
          "18" = { enabled = false; };
          "19" = { enabled = false; };
          "20" = { enabled = false; };
          "21" = { enabled = false; };
          "22" = { enabled = false; };
          "23" = { enabled = false; };
          "24" = { enabled = false; };
          "25" = { enabled = false; };
          "26" = { enabled = false; };
          "28" = {
            enabled = false;
            value = {
              type = "standard";
              parameters = [
                51
                20
                1179648
              ];
            };
          };
          "29" = {
            enabled = false;
            value = {
              type = "standard";
              parameters = [
                51
                20
                1441792
              ];
            };
          };
          "30" = {
            enabled = false;
            value = {
              type = "standard";
              parameters = [
                52
                21
                1179648
              ];
            };
          };
          "31" = {
            enabled = false;
            value = {
              type = "standard";
              parameters = [
                52
                21
                1441792
              ];
            };
          };
          "60" = {
            enabled = true;
            value = {
              type = "standard";
              parameters = [
                32
                49
                1048576
              ];
            };
          };
          "61" = {
            enabled = true;
            value = {
              type = "standard";
              parameters = [
                32
                49
                786432
              ];
            };
          };
          "64" = {
            enabled = true;
            value = {
              type = "standard";
              parameters = [
                32
                49
                262144
              ];
            };
          };
          "79" = { enabled = true; };
          "80" = { enabled = true; };
          "81" = { enabled = true; };
          "82" = { enabled = true; };
          "164" = {
            enabled = false;
            value = {
              type = "standard";
              parameters = [
                65535
                65535
                0
              ];
            };
          };
          "184" = {
            enabled = false;
            value = {
              type = "standard";
              parameters = [
                53
                23
                1179648
              ];
            };
          };
        };
      };
    };
  };

  # スリープまでの時間（分）。
  # power.sleep.* は per-source 指定不可のため pmset で直接設定する。
  # -b: battery, -c: power adapter
  system.activationScripts.extraActivation.text = ''
    /usr/bin/pmset -b displaysleep 20 sleep 20
    /usr/bin/pmset -c displaysleep 120 sleep 120
  '';

  system.keyboard = {
    # 明示適用にして、既存 remap を activation 時にクリアする。
    enableKeyMapping = true;
    # macOS 標準の修飾キー挙動（remap なし）を維持。
    userKeyMapping = [ ];
  };

  # zsh を nix-darwin 管理下で有効化。
  programs.zsh.enable = true;

  # user defaults と Home Manager 連携に必要。
  system.primaryUser = username;

  # 初回設定後は基本的に固定する。
  system.stateVersion = 6;
}
