{ pkgs, ... }:
{
  # Home Manager の状態バージョン。更新時はリリースノート確認後に上げる。
  home.stateVersion = "24.11";

  # direnv + nix-direnv を有効化（use flake を高速化）。
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # Home Manager で入れるユーザー向けパッケージ。
  home.packages = with pkgs; [
    # BEAM (Erlang/Elixir) — OTP バージョンの整合性を beam.packages で保証。
    beam.packages.erlang_28.erlang
    beam.packages.erlang_28.elixir

    rainfrog
    bat
    eza
    fd
    ripgrep
    jq
    yq-go
    fzf
    zoxide
    delta
    tealdeer
    gh
    ghq
    tree
    inetutils # telnet, ftp, ping 等
    watch
    starship
    gum

    # Nix の日常運用を楽にするツール群。
    nh
    nix-output-monitor
    nixfmt
    statix
    deadnix
    nixd
  ];

  # Home Manager 自身の管理を有効化。
  programs.home-manager.enable = true;
}
