#!/bin/bash
# Remove what install.sh and the app added. Run it before
# `omarchy plugin remove netease.music`.
#
#   ./uninstall.sh          keep your NetEase login and settings
#   ./uninstall.sh --purge  also delete the app's browser profile (login,
#                           settings) and the proxy file
set -euo pipefail

purge=false
case ${1:-} in
"") ;;
--purge) purge=true ;;
*)
  echo "Usage: ./uninstall.sh [--purge]" >&2
  exit 1
  ;;
esac

data="${XDG_DATA_HOME:-$HOME/.local/share}"
config="${XDG_CONFIG_HOME:-$HOME/.config}"
bindings="$config/hypr/bindings.lua"

if pgrep -f -- "--user-data-dir=$data/netease-music-webapp( |$)" >/dev/null 2>&1; then
  echo "Quit the NetEase Cloud Music app first." >&2
  exit 1
fi

rm -f "$HOME/.local/share/applications/NetEase Cloud Music.desktop" \
  "$HOME/.local/share/icons/hicolor/256x256/apps/netease-cloud-music.png"
rm -rf -- "$data/netease-music-webapp-ext"
for old in netease-music-webapp netease-music-toggle; do
  f="$HOME/.local/bin/$old"
  [[ -f $f ]] && grep -q 'music.163.com\|netease-music' "$f" && rm -f "$f"
done

if [[ -f $bindings ]] && grep -qE '^-- >>> omarchy-(netease-music|ncm)' "$bindings"; then
  sed -i -E '/^-- >>> omarchy-(netease-music|ncm)/,/^-- <<< omarchy-(netease-music|ncm)/d' "$bindings"
  if command -v hyprctl >/dev/null; then hyprctl reload >/dev/null 2>&1 || true; fi
  echo "Removed the Super+Shift+M binding."
fi

if $purge; then
  rm -rf -- "$data/netease-music-webapp" "$config/omarchy-netease-music"
  echo "Removed. Login, settings and proxy file deleted too."
else
  echo "Removed. Your login and settings are kept in $data/netease-music-webapp (./uninstall.sh --purge deletes them)."
fi
