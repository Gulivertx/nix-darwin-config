# User configuration (home-manager), shared by every Mac.
#
# Files are linked with mkOutOfStoreSymlink: they point straight at this repo
# (not at a read-only copy in /nix/store), so apps can still write to them and
# every change shows up in `git diff`.
# This assumes the repo is cloned at /etc/nix-darwin (see README).
{ config, lib, pkgs, ... }:
let
  repo = "/etc/nix-darwin/home";
  link = path: config.lib.file.mkOutOfStoreSymlink "${repo}/${path}";

  # The only Claude Code settings shared between Macs. ~/.claude/settings.json
  # itself stays per-machine (autoMode, plugins, ...): these keys are merged
  # into it on every switch, the rest of the file is left untouched.
  claudeSettings = {
    statusLine = {
      type = "command";
      command = "bash ~/.claude/statusline-command.sh";
      hideVimModeIndicator = true;
    };
    theme = "custom:xcode-dark";
  };
in
{
  home.file = {
    # Claude Code
    ".claude/statusline-command.sh".source = link "claude/statusline-command.sh";
    ".claude/themes/xcode-dark.json".source = link "claude/themes/xcode-dark.json";

    # Ghostty
    "Library/Application Support/com.mitchellh.ghostty/config".source = link "ghostty/config";
    "Library/Application Support/com.mitchellh.ghostty/shaders/focus-background.glsl".source =
      link "ghostty/shaders/focus-background.glsl";
  };

  home.activation.claudeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    settings="$HOME/.claude/settings.json"
    patch=${lib.escapeShellArg (builtins.toJSON claudeSettings)}
    current='{}'
    [ -s "$settings" ] && current=$(cat "$settings")

    if ! printf '%s' "$current" | ${pkgs.jq}/bin/jq -e . >/dev/null 2>&1; then
      echo "warning: $settings is not valid JSON, Claude settings not merged" >&2
    elif ! printf '%s' "$current" \
        | ${pkgs.jq}/bin/jq -e --argjson p "$patch" '(. * $p) == .' >/dev/null; then
      tmp=$(mktemp)
      printf '%s' "$current" | ${pkgs.jq}/bin/jq --argjson p "$patch" '. * $p' > "$tmp"
      run mkdir -p "$HOME/.claude"
      # cp (not mv) keeps the existing file's permissions.
      run cp "$tmp" "$settings"
      rm -f "$tmp"
    fi
  '';

  # Read the home-manager changelog before changing this.
  home.stateVersion = "26.11";
}
