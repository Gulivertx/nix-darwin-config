# Packages specific to Cedric-FZ-DEV (added on top of the common configuration).
{ pkgs, ... }: {
  # Grouped by category, alphabetical within each group.
  environment.systemPackages = with pkgs; [
    # Git
    glab

    # PHP CLI tools: bundle their own nix PHP, independent of reeve's
    # Homebrew PHP versions (which reeve requires and keeps managing).
    phpPackages.php-cs-fixer
    phpstan

    # Shopify
    shopify-cli
  ];

  # Runs `brew shellenv` in zsh so /opt/homebrew/bin is on PATH
  # (needed for reeve and the formulae it installs).
  homebrew.enableZshIntegration = true;

  # "none" = brews/casks/taps not declared in the config are left alone.
  # Required because reeve installs its own formulae on demand
  # (shivammathur/php tap, caddy/nginx/httpd, dnsmasq, mkcert,
  # mysql, redis, ...); the common "uninstall" would remove them on every
  # rebuild. ("check" would abort activation as soon as reeve installs anything.)
  # Consequence: removing a brew from the config does NOT uninstall it on
  # this host — run `brew uninstall` manually.
  homebrew.onActivation.cleanup = "none";

  homebrew.taps = [
    "yetidevworks/reeve"
  ];

  homebrew.brews = [
    # Localhost web dev stack manager (web servers, per-vhost PHP, SSL, DNS).
    "yetidevworks/reeve/reeve"
  ];

  homebrew.casks = [
  ];
}
