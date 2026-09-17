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

  # ユーザースコープの macOS 設定は nix/home/darwin-defaults.nix が持つ。
  # ここには root 権限でしか書けないものだけを置く。
  system.defaults = {
    loginwindow = {
      # ゲストログインを無効へ変更。
      GuestEnabled = false;
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
