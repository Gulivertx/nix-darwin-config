# nix-darwin configuration

Declarative macOS system configuration using [nix-darwin](https://github.com/nix-darwin/nix-darwin), managed via [Nix Flakes](https://nixos.wiki/wiki/Flakes). Covers Nix packages, fonts, and Homebrew formulae/casks, all managed declaratively.

- Target machine: Apple Silicon, `aarch64-darwin`
- Primary user: edit `flake.nix` and specify your own username
- Nix distribution: [Lix](https://lix.systems/)

## Prerequisites

1. **Xcode Command Line Tools**

   ```sh
   xcode-select --install
   ```

2. **Nix, via Lix** (flakes enabled by default). Lix is a friendly fork of Nix used here instead of upstream Nix/the Determinate Systems installer:

   ```sh
   curl -sSf -L https://install.lix.systems/lix | sh -s -- install
   ```

   See [lix.systems/install](https://lix.systems/install/) for details and other platforms.

3. **Homebrew** — required because this flake manages Homebrew formulae (`homebrew.enable = true`). nix-darwin does not install Homebrew itself, so it must be present beforehand:

   ```sh
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

## Setting up on a new machine

1. Clone this repo to the location nix-darwin expects:

   ```sh
   sudo mkdir -p /etc/nix-darwin
   sudo chown "$(whoami)" /etc/nix-darwin
   git clone git@github.com:Gulivertx/nix-darwin-config.git /etc/nix-darwin
   cd /etc/nix-darwin
   ```

2. Edit `flake.nix` for your machine:

   - Set `system.primaryUser` to your macOS username (`whoami`).
   - Rename the `darwinConfigurations."<hostname>"` key to match your Mac's hostname:

     ```sh
     scutil --get LocalHostName   # or: hostname
     ```

     Either rename your Mac to match an existing entry (`sudo scutil --set HostName <hostname>`), or rename the `darwinConfigurations` entry in `flake.nix` to match your machine's hostname.

3. First build and activation (no `darwin-rebuild` exists yet, so it's run via `nix run`):

   ```sh
   sudo nix run nix-darwin -- switch --flake "/etc/nix-darwin#$(scutil --get LocalHostName)"
   ```

   This first run installs the `darwin-rebuild` command into the `PATH` for subsequent use.

## Day-to-day usage

Run all commands from `/etc/nix-darwin` (or pass `--flake /etc/nix-darwin`).

### Update flake inputs

Updates `flake.lock` (nixpkgs, nix-darwin) to the latest revisions:

```sh
nix flake update
```

To update a single input only:

```sh
nix flake update nixpkgs
```

### Apply the configuration (switch)

After changing `flake.nix` (e.g. adding packages) or after `nix flake update`:

```sh
sudo darwin-rebuild switch --flake .
```

### Build without activating

Useful to check the configuration builds before applying it:

```sh
darwin-rebuild build --flake .
```

### Roll back

```sh
sudo darwin-rebuild --rollback
```

List available generations:

```sh
darwin-rebuild --list-generations
```

### Clean up the store (garbage collection)

Removes old generations and unreferenced Nix packages to free up disk space:

```sh
sudo nix-collect-garbage -d
```

To keep only the last N days:

```sh
sudo nix-collect-garbage --delete-older-than 30d
```

Optimize the store (deduplicate via hardlinks):

```sh
nix store optimise
```

## Repository structure

- `flake.nix` — system configuration definition (packages, fonts, Homebrew, nix-darwin settings).
- `flake.lock` — pinned versions of the inputs (nixpkgs, nix-darwin). Generated/updated by `nix flake update`.

## Notes

- `result` (the symlink created by `nix build`) is gitignored — it points into the local Nix store and shouldn't be versioned.
- Homebrew cleanup (`onActivation.cleanup = "uninstall"`) automatically uninstalls any brew/cask not declared in `flake.nix` on `switch`.
