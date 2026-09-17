{
  description = "dotfiles managed with nix-darwin + home-manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      nix-darwin,
      home-manager,
      ...
    }:
    let
      # ローカル固有情報（Git 管理外）
      identity = import ./nix/local/identity.nix;
      username = identity.username;
      hostname = identity.hostname;
      system = identity.system;
    in
    {
      # ユーザー環境だけを sudo なしで適用する経路。
      # root 権限が要る設定（/etc, launchd, pmset）は含まれない。
      # username はドットを含みうるため、flake 属性パスが割れないよう hostname で引く。
      #
      # 同一マシンで darwinConfigurations と併用しないこと。
      # homeConfigurations はパッケージを ~/.nix-profile へ、
      # darwinConfigurations は useUserPackages により /etc/profiles/per-user へ置くため、
      # 同居させるとどちらの世代が有効かが決まらなくなる。
      homeConfigurations.${hostname} = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.${system};
        modules = [
          ./nix/home/identity.nix
          {
            home.username = username;
            home.homeDirectory = "/Users/${username}";
          }
        ];
      };

      darwinConfigurations.${hostname} = nix-darwin.lib.darwinSystem {
        inherit system;
        # 読み込むモジュールへ渡す追加引数。
        specialArgs = { inherit inputs username hostname; };
        modules = [
          # システムレベル（nix-darwin）の設定本体。
          ./nix/darwin/configuration.nix
          # Home Manager を nix-darwin モジュールとして有効化。
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.${username} = import ./nix/home/identity.nix;
          }
        ];
      };
    };
}
