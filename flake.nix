{
  description = "Flake for Informatic-Solution on Darwin";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, home-manager }:
  let
    configuration = { pkgs, lib, ... }: {
      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      # Grouped by category, alphabetical within each group.
      environment.systemPackages = with pkgs; [
        # CLI essentials
        bat
        curl
        fd
        jq
        ripgrep
        tree
        unzip

        # System monitoring
        btop
        fastfetch
        htop

        # Editors & terminal
        neovim
        tmux
        tree-sitter
        vim

        # Git
        gh
        lazygit

        # Build toolchain
        apple-sdk_15
        gcc
        gnumake
        gsl

        # Languages & package managers
        cocoapods
        go
        nodejs_24
        uv
        yarn

        # Dev environments
        devenv

        # Files, documents & media
        imagemagick
        innoextract
        mdbtools
        poppler
        poppler-utils

        # Game dev (Godot)
        gdtoolkit_4

        # Desktop
        sketchybar

        # Maintenance commands for this repo, the same on every host.
        # nix-update [input...]: update all flake inputs (or only those given).
        (writeShellScriptBin "nix-update" ''
          exec nix flake update --flake /etc/nix-darwin "$@"
        '')
        # nix-upgrade [args...]: build and activate this Mac's configuration.
        (writeShellScriptBin "nix-upgrade" ''
          exec sudo /run/current-system/sw/bin/darwin-rebuild switch \
            --flake "/etc/nix-darwin#$(/usr/sbin/scutil --get LocalHostName)" "$@"
        '')
        # nix-collect-garbage-all: delete old generations of every profile
        # (system and user), then garbage-collect the store.
        (writeShellScriptBin "nix-collect-garbage-all" ''
          exec sudo "$(command -v nix-collect-garbage)" -d "$@"
        '')
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
        casks = [
          # Terminal web browser. No theme of its own: its UI derives
          # its colors from the terminal (Ghostty, Xcode Dark palette).
          "terminal-browser"
        ];
        onActivation = {
          autoUpdate = true;
          upgrade = true;
          # "uninstall" = automatically uninstalls any brew/cask not declared
          # above (Homebrew is fully managed declaratively).
          # CLIs migrated to nix will therefore be removed from Homebrew on
          # their own. ("zap" would additionally remove associated config files.)
          # mkDefault: a host can override it (see hosts/Cedric-FZ-DEV.nix).
          cleanup = lib.mkDefault "uninstall";
        };
      };

      system.primaryUser = "cedricbapst";
      users.users.cedricbapst.home = "/Users/cedricbapst";

      # User dotfiles (Claude Code, Ghostty), shared by every host: see home/.
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        # Files already present (first switch) are renamed *.before-hm
        # instead of making the activation fail.
        backupFileExtension = "before-hm";
        users.cedricbapst = import ./home;
      };
      nix.settings.experimental-features = "nix-command flakes";

      # Written to /etc/zshrc on every Mac (~/.zshrc stays unmanaged).
      # y: open yazi, and on quit cd into the directory it was left in.
      programs.zsh.interactiveShellInit = ''
        function y() {
          local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
          command yazi "$@" --cwd-file="$tmp"
          IFS= read -r -d "" cwd < "$tmp"
          [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
          rm -f -- "$tmp"
        }
      '';

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
    # $ darwin-rebuild build --flake .#<hostname>
    # Each host gets the common configuration plus its own module in hosts/.
    darwinConfigurations."Cedrics-MacBook-Pro" = nix-darwin.lib.darwinSystem {
      modules = [
        configuration
        home-manager.darwinModules.home-manager
        ./hosts/Cedrics-MacBook-Pro.nix
      ];
    };
    darwinConfigurations."Cedric-FZ-DEV" = nix-darwin.lib.darwinSystem {
      modules = [
        configuration
        home-manager.darwinModules.home-manager
        ./hosts/Cedric-FZ-DEV.nix
      ];
    };
  };
}
