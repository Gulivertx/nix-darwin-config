# nix-darwin configuration

Configuration système déclarative pour macOS avec [nix-darwin](https://github.com/nix-darwin/nix-darwin), gérée via [Nix Flakes](https://nixos.wiki/wiki/Flakes). Couvre les paquets Nix, les polices, et les formules/casks Homebrew gérés de façon déclarative.

- Machine cible : `Cedrics-MacBook-Pro` (Apple Silicon, `aarch64-darwin`)
- Utilisateur principal : `cedricbapst`

## Prérequis

1. **Xcode Command Line Tools**

   ```sh
   xcode-select --install
   ```

2. **Nix** (avec les flakes activés). Le plus simple est l'installeur [Determinate Systems](https://github.com/DeterminateSystems/nix-installer) qui active les flakes par défaut :

   ```sh
   curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
   ```

   (Alternative : l'installeur officiel Nix, en activant ensuite `experimental-features = nix-command flakes` dans `/etc/nix/nix.conf`.)

3. **Homebrew** — requis car ce flake gère des formules Homebrew (`homebrew.enable = true`). nix-darwin ne l'installe pas lui-même, il faut l'avoir en amont :

   ```sh
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

## Installation sur un nouveau poste

1. Cloner ce repo à l'emplacement standard attendu par nix-darwin :

   ```sh
   sudo mkdir -p /etc/nix-darwin
   sudo chown "$(whoami)" /etc/nix-darwin
   git clone git@github.com:Gulivertx/nix-darwin-config.git /etc/nix-darwin
   cd /etc/nix-darwin
   ```

2. Vérifier que le nom de la config dans `flake.nix` correspond au hostname de la machine (`darwinConfigurations."Cedrics-MacBook-Pro"`). Sur une nouvelle machine avec un autre nom :

   ```sh
   scutil --get LocalHostName   # ou: hostname
   ```

   Soit tu renommes ton Mac pour matcher (`sudo scutil --set HostName Cedrics-MacBook-Pro`), soit tu ajoutes/renomme une entrée `darwinConfigurations."<ton-hostname>"` dans `flake.nix`.

3. Premier build et activation (aucun `darwin-rebuild` n'existe encore, on l'exécute via `nix run`) :

   ```sh
   sudo nix run nix-darwin -- switch --flake /etc/nix-darwin#Cedrics-MacBook-Pro
   ```

   Cette première exécution installe la commande `darwin-rebuild` dans le PATH pour les fois suivantes.

## Utilisation quotidienne

Toutes les commandes sont à lancer depuis `/etc/nix-darwin` (ou en précisant `--flake /etc/nix-darwin`).

### Mettre à jour les inputs du flake

Met à jour `flake.lock` (nixpkgs, nix-darwin) vers les dernières révisions :

```sh
nix flake update
```

Pour ne mettre à jour qu'un seul input :

```sh
nix flake update nixpkgs
```

### Appliquer la configuration (switch)

Après une modification de `flake.nix` (nouveaux paquets, etc.) ou après un `nix flake update` :

```sh
sudo darwin-rebuild switch --flake .
```

### Construire sans activer

Utile pour vérifier que la config build correctement avant de l'appliquer :

```sh
darwin-rebuild build --flake .
```

### Revenir en arrière (rollback)

```sh
sudo darwin-rebuild --rollback
```

Lister les générations disponibles :

```sh
darwin-rebuild --list-generations
```

### Nettoyer le store (garbage collection)

Supprime les anciennes générations et paquets Nix non référencés pour libérer de l'espace disque :

```sh
sudo nix-collect-garbage -d
```

Pour ne garder que les X derniers jours :

```sh
sudo nix-collect-garbage --delete-older-than 30d
```

Optimiser le store (dédoublonnage par hardlinks) :

```sh
nix store optimise
```

## Structure du repo

- `flake.nix` — définition de la configuration système (paquets, polices, Homebrew, réglages nix-darwin).
- `flake.lock` — verrouillage des versions des inputs (nixpkgs, nix-darwin). Généré/mis à jour par `nix flake update`.

## Notes

- `result` (symlink créé par `nix build`) est ignoré par git — il pointe vers le store Nix local et n'a pas à être versionné.
- Le nettoyage Homebrew (`onActivation.cleanup = "uninstall"`) désinstalle automatiquement toute formule/cask non déclarée dans `flake.nix` lors d'un `switch`.
