{ pkgs, ... }:
{
  imports = [
    ./darwin-defaults.nix
    ./darwin-modifier-keys.nix
  ];

  # Home Manager の状態バージョン。更新時はリリースノート確認後に上げる。
  home.stateVersion = "24.11";

  # direnv + nix-direnv を有効化（use flake を高速化）。
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # ユーザー向け CLI ツールの所有者は Home Manager。
  # Brewfile には同じものを書かないこと。両方に置くと、どちらが使われるかが
  # PATH 順に依存して機械ごとに変わる。
  home.packages = with pkgs; [
    # BEAM (Erlang/Elixir) — OTP バージョンの整合性を beam.packages で保証。
    beam.packages.erlang_28.erlang
    beam.packages.erlang_28.elixir
    beam.packages.erlang_28.rebar3

    deno
    rainfrog
    maven
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
