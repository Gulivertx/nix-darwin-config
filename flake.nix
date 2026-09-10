{
  description = "Flake for Informatic-Solution on Darwin";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs }:
  let
    configuration = { pkgs, ... }: {
      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      environment.systemPackages = [
        pkgs.bat
        pkgs.codex
        pkgs.vim
        pkgs.neovim
        pkgs.devenv
        pkgs.fastfetch
        pkgs.htop
        pkgs.btop
        pkgs.tmux
        pkgs.cocoapods
        pkgs.sketchybar
        pkgs.opencode
        pkgs.go
        pkgs.gh
        pkgs.jq
        pkgs.poppler
        pkgs.tree
        pkgs.ripgrep
        pkgs.fd
        pkgs.lazygit
        pkgs.gcc
        pkgs.gnumake
        pkgs.curl
        pkgs.unzip
        pkgs.nodejs_24
        pkgs.yarn
        pkgs.tree-sitter
        pkgs.gdtoolkit_4
        pkgs.imagemagick
        pkgs.gsl
        pkgs.apple-sdk_15
      ];

      fonts.packages = [
        pkgs.nerd-fonts.hack
        pkgs.nerd-fonts.jetbrains-mono
      ];

      # Declarative Homebrew management (for GUI/casks not in nixpkgs).
      homebrew = {
        enable = true;
        brews = [
          "firefoxpwa"
          "ruby"
          "vapor"
        ];
        onActivation = {
          autoUpdate = true;
          upgrade = true;
          # "uninstall" = automatically uninstalls any brew/cask not declared
          # above (Homebrew is fully managed declaratively).
          # CLIs migrated to nix will therefore be removed from Homebrew on
          # their own. ("zap" would additionally remove associated config files.)
          cleanup = "uninstall";
        };
      };

      system.primaryUser = "cedricbapst";
      nix.settings.experimental-features = "nix-command flakes";

      # Enable alternative shell support in nix-darwin.
      # programs.fish.enable = true;

      # Set Git commit hash for darwin-version.
      system.configurationRevision = self.rev or self.dirtyRev or null;

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      system.stateVersion = 6;

      # The platform the configuration will be used on.
      nixpkgs.hostPlatform = "aarch64-darwin";
    };
  in
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#Cedrics-MacBook-Pro
    darwinConfigurations."Cedrics-MacBook-Pro" = nix-darwin.lib.darwinSystem {
      modules = [
        configuration
      ];
    };
  };
}
