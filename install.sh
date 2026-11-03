#!/bin/bash
# Set up the NetEase Music app. The bar button runs this on first use.
#
#   ./install.sh          add "NetEase Cloud Music" to the app launcher
#   ./install.sh --bind   also bind Super+Shift+M to show/hide it (replaces
#                         Omarchy's default Music key, which opens Spotify)
#
# The launcher entry and key run the scripts in this folder, so keep it where
# it is (normally ~/.config/omarchy/plugins/netease.music). ./uninstall.sh
# removes everything this adds.
set -euo pipefail

bind=false
for arg in "$@"; do
  case $arg in
  --bind) bind=true ;;
  -h | --help)
    sed -n '2,10s/^# \{0,1\}//p' "$0"
    exit 0
    ;;
  *)
    echo "Unknown option: $arg (try --help)" >&2
    exit 1
    ;;
  esac
done

for cmd in omarchy-launch-webapp omarchy-webapp-install jq; do
  command -v "$cmd" >/dev/null || {
    echo "Missing $cmd. This needs Omarchy (https://omarchy.org)." >&2
    exit 1
  }
done

src=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
name="NetEase Cloud Music"
url="https://music.163.com/st/webplayer"
icon_dir="$HOME/.local/share/icons/hicolor/256x256/apps"
desktop="$HOME/.local/share/applications/$name.desktop"
bindings="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/bindings.lua"
# Binding blocks this project wrote, including under its earlier name.
marker='^-- >>> omarchy-(netease-music|ncm)'
end_marker='^-- <<< omarchy-(netease-music|ncm)'

chmod +x "$src/bin/netease-music-webapp" "$src/bin/netease-music-toggle"

# Earlier versions copied the scripts into ~/.local/bin; they now run from here.
for old in netease-music-webapp netease-music-toggle; do
  f="$HOME/.local/bin/$old"
  [[ -f $f ]] && grep -q 'music.163.com\|netease-music' "$f" && rm -f "$f"
done

# App launcher entry. Reuse the icon if it is already there, otherwise let
# Omarchy fetch the site's icon.
icon=""
[[ -f $icon_dir/netease-cloud-music.png ]] && icon=netease-cloud-music
omarchy-webapp-install "$name" "$url" "$icon" "$src/bin/netease-music-webapp"
grep -q '^StartupWMClass=' "$desktop" || echo "StartupWMClass=netease-music" >>"$desktop"

if $bind; then
  mkdir -p "$(dirname "$bindings")"
  touch "$bindings"
  sed -i -E "/$marker/,/$end_marker/d" "$bindings"
  cat >>"$bindings" <<EOF
-- >>> omarchy-netease-music: Music key shows/hides NetEase Cloud Music (default: Spotify)
hl.unbind("SUPER + SHIFT + M")
o.bind("SUPER + SHIFT + M", "NetEase Music", "$src/bin/netease-music-toggle")
-- <<< omarchy-netease-music
EOF
  if command -v hyprctl >/dev/null && hyprctl reload >/dev/null 2>&1; then
    errors=$(hyprctl configerrors 2>/dev/null || true)
    [[ -z ${errors//[[:space:]]/} ]] || echo "Hyprland reports config errors:"$'\n'"$errors" >&2
  fi
  echo "Bound Super+Shift+M in $bindings."
fi

echo "Ready. Open \"$name\" from the bar button or the app launcher, and log in."
$bind || echo "Optional: $src/install.sh --bind to show/hide it with Super+Shift+M."
