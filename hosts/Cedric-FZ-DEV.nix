# Packages specific to Cedric-FZ-DEV (added on top of the common configuration).
{ pkgs, ... }: {
  environment.systemPackages = [
    pkgs.shopify-cli
    pkgs.phpstan
    pkgs.phpPackages.php-cs-fixer
  ];

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
