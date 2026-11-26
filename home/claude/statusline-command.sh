#!/bin/bash
# Claude Code status line - lualine look, Xcode Dark palette.
#
# Mirrors ~/.config/nvim/lua/custom/plugins/statusline.lua: flat blocks,
# no separators, palette from ~/.config/nvim/lua/custom/xcode.lua.
#
#   A (accent bg)  model            | Z (accent bg)  context gauge
#   B (bg_mid)     branch +add -del | Y (bg_mid)     quota 5h/7d, cost
#   C (bg_dark)    repo name ●      | X (bg_dark)    effort level
#
# The accent follows the vim mode (when vim mode is on), like lualine's
# per-mode colors, and the context block turns yellow/salmon as it fills.
# Previous flat version: ~/.claude/statusline-command.sh.bak-20261124

input=$(cat)

# --- Xcode Dark palette -----------------------------------------------------
BG='41;42;48'        # #292a30
BG_DARK='47;48;55'   # #2f3037
BG_MID='65;68;83'    # #414453
FG='223;223;224'     # #dfdfe0
COMMENT='127;140;152' # #7f8c98
BLUE='78;176;204'    # #4eb0cc
CYAN='107;223;255'   # #6bdfff
GREEN='132;179;96'   # #84b360
PURPLE='178;129;235' # #b281eb
YELLOW='217;201;124' # #d9c97c
PINK='255;122;178'   # #ff7ab2
SALMON='255;129;112' # #ff8170

RESET=$'\033[0m'
BOLD=$'\033[1m'
fg() { printf '\033[38;2;%sm' "$1"; }
bg() { printf '\033[48;2;%sm' "$1"; }

# Nerd Font glyphs as UTF-8 byte escapes (macOS bash 3.2 has no \u escapes).
BRANCH_ICON=$'\xef\x84\xa6' # U+F126
GAUGE_ICON=$'\xee\xba\x9c'  # U+EE9C (fa-brain in Nerd Fonts v3)

# --- read every field in one jq pass (\x1f-separated, empty when absent) ----
IFS=$'\x1f' read -r cwd model effort thinking vim_mode ctx_pct five_h seven_d \
  cost added removed <<EOF
$(printf '%s' "$input" | jq -r '[
  (.workspace.current_dir // .cwd // ""),
  (.model.display_name // ""),
  (.effort.level // ""),
  (.thinking.enabled // "" | tostring),
  (.vim.mode // ""),
  (.context_window.used_percentage // "" | tostring),
  (.rate_limits.five_hour.used_percentage // "" | tostring),
  (.rate_limits.seven_day.used_percentage // "" | tostring),
  (.cost.total_cost_usd // "" | tostring),
  (.cost.total_lines_added // "" | tostring),
  (.cost.total_lines_removed // "" | tostring)
] | join("\u001f")')
EOF
[ -z "$cwd" ] && cwd="$PWD"

round() { awk -v p="$1" 'BEGIN { printf "%d", p + 0.5 }'; }

# --- accent per mode (lualine: normal blue, insert green, visual purple) ----
case "$vim_mode" in
  INSERT) ACCENT=$GREEN ;;
  VISUAL*) ACCENT=$PURPLE ;;
  NORMAL) ACCENT=$BLUE ;;
  *) ACCENT=$BLUE ;;
esac

out=""

# --- A: model ---------------------------------------------------------------
label="$model"
[ -n "$vim_mode" ] && label="$vim_mode${model:+ · $model}"
[ -n "$label" ] && out+="$(bg "$ACCENT")$(fg "$BG")${BOLD} ${label} ${RESET}"

# --- B: git branch + session line counts ------------------------------------
repo_root=$(git -C "$cwd" --no-optional-locks rev-parse --show-toplevel 2>/dev/null)
b=""
if [ -n "$repo_root" ]; then
  branch=$(git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null)
  [ -z "$branch" ] && branch=$(git -C "$cwd" --no-optional-locks rev-parse --short HEAD 2>/dev/null)
  [ -n "$branch" ] && b+="$(fg "$ACCENT")${BRANCH_ICON} ${branch}"
fi
if [ -n "$added" ] && [ "$added" != "0" ]; then
  [ -n "$b" ] && b+=" "
  b+="$(fg "$GREEN")+${added}"
fi
if [ -n "$removed" ] && [ "$removed" != "0" ]; then
  [ -n "$b" ] && b+=" "
  b+="$(fg "$SALMON")-${removed}"
fi
[ -n "$b" ] && out+="$(bg "$BG_MID") ${b} ${RESET}"

# --- C: repo name (+ ● when the working tree is dirty, like nvim's buffer) ---
if [ -n "$repo_root" ]; then
  name=$(basename "$repo_root")
  if [ -n "$(git -C "$cwd" --no-optional-locks status --porcelain 2>/dev/null | head -1)" ]; then
    name+=" $(fg "$YELLOW")●"
  fi
else
  name=$(basename "$cwd")
fi
out+="$(bg "$BG_DARK")$(fg "$FG") ${name} ${RESET}"

left="$out"
out=""

# --- X: reasoning effort ------------------------------------------------------
x=""
if [ -n "$effort" ]; then
  x="$effort"
elif [ "$thinking" = "true" ]; then
  x="thinking"
fi
[ -n "$x" ] && out+="$(bg "$BG_DARK")$(fg "$CYAN") ${x} ${RESET}"

# --- Y: subscription quota + session cost -----------------------------------
y=""
[ -n "$five_h" ] && y+="5h:$(round "$five_h")%"
if [ -n "$seven_d" ]; then
  [ -n "$y" ] && y+=" "
  y+="7d:$(round "$seven_d")%"
fi
if [ -n "$cost" ]; then
  [ -n "$y" ] && y+=" $(fg "$COMMENT")·$(fg "$ACCENT") "
  y+=$(awk -v c="$cost" 'BEGIN { printf "$%.2f", c }')
fi
[ -n "$y" ] && out+="$(bg "$BG_MID")$(fg "$ACCENT") ${y} ${RESET}"

# --- Z: context gauge ---------------------------------------------------------
if [ -n "$ctx_pct" ]; then
  pct=$(round "$ctx_pct")
  z_color=$ACCENT
  [ "$pct" -ge 70 ] && z_color=$YELLOW
  [ "$pct" -ge 90 ] && z_color=$SALMON

  width=10
  filled=$(awk -v p="$ctx_pct" -v w="$width" \
    'BEGIN { v = (p / 100 * w) + 0.5; if (v > w) v = w; if (v < 0) v = 0; printf "%d", v }')
  bar=""
  for ((i = 0; i < filled; i++)); do bar+="█"; done
  for ((i = filled; i < width; i++)); do bar+="░"; done

  out+="$(bg "$z_color")$(fg "$BG")${BOLD} ${GAUGE_ICON} ${bar} ${pct}% ${RESET}"
fi

right="$out"

# --- fill the gap with C's background so the line spans the whole terminal,
# like lualine's globalstatus. Claude Code exports the terminal width as
# $COLUMNS; Claude Code pads the footer by 2 columns on each side (hard-coded,
# not configurable), hence the default margin of 4.
# Without $COLUMNS the two halves are simply joined.
# Width = characters once the color codes are stripped, counted without any
# locale: drop UTF-8 continuation bytes (0x80-0xBF), then count bytes. Works
# the same on macOS and Linux (no dependency on en_US.UTF-8 being installed).
visible_width() {
  printf '%s' "$1" | LC_ALL=C sed $'s/\033\\[[0-9;]*m//g' | LC_ALL=C tr -d '\200-\277' | wc -c | tr -d ' '
}
gap=""
if [ -n "$COLUMNS" ] && [ "$COLUMNS" -gt 0 ] 2>/dev/null; then
  margin=${STATUSLINE_MARGIN:-4}
  n=$(( COLUMNS - margin - $(visible_width "$left") - $(visible_width "$right") ))
  [ "$n" -gt 0 ] && gap="$(bg "$BG_DARK")$(printf '%*s' "$n" '')${RESET}"
fi

# Claude Code draws the status line dimmed (it prepends SGR 2). A leading
# reset cancels that, so the palette shows exactly as in nvim. Every block
# already ends with a reset, so only this first one was ever dimmed.
printf '%s' "${RESET}${left}${gap}${right}"
