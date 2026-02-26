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
  };

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
