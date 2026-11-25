{
  description = "ryoko's NixOS, Home Manager and Niri desktop configuration";

  inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.zst";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dms = {
      url = "github:AvengeMedia/DankMaterialShell/v1.6.2";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Noctalia v5 bar. The cachix branch always points at a commit already
    # present in noctalia.cachix.org; do not add nixpkgs.follows or the cache
    # hashes change and the shell has to be compiled locally.
    noctalia.url = "github:noctalia-dev/noctalia/cachix";
    # ZEKniri desktop configuration source (niri, waybar, noctalia, cava...).
    zek-niri = {
      url = "github:sky1234762/ZEK-niri";
      flake = false;
    };
    mark-shot.url = "github:jswysnemc/mark-shot";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    xwayland-satellite = {
      url = "github:Supreeeme/xwayland-satellite";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.rust-overlay.follows = "rust-overlay";
    };
  };

  outputs = { self, nixpkgs, ... }@inputs:
    let
      inherit (import ./lib { inherit inputs; }) system mkHost;
    in
    {
      nixosConfigurations.ryoko = mkHost "ryoko";
      nixosConfigurations.nixos = self.nixosConfigurations.ryoko;

      # Live installer stays independent of the installed host's shared modules.
      nixosConfigurations.installer = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [ ./hosts/installer ];
      };

      packages.${system}.installer-iso = self.nixosConfigurations.installer.config.system.build.isoImage;

      templates.project = {
        path = ./templates/project/devshell;
        description = "Independent project devShells for Rust, C++, Node.js, Python and Java";
      };
      templates.java-webapp = {
        path = ./templates/project/java-webapp;
        description = "Minimal Java 8 + embedded Tomcat 9 + javax Servlet/JSP executable JAR";
      };

      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixpkgs-fmt;
    };
}
