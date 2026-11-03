#!/bin/bash
# Set up, launch and remove the app in a throwaway home directory, with
# Omarchy and Hyprland commands stubbed. Needs bash, jq and python3.
# check() evals its condition string, so its variables expand later:
# shellcheck disable=SC2016,SC2034
set -euo pipefail

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
tmp=$(mktemp -d)
listener=""
cleanup() {
  [[ -n $listener ]] && kill "$listener" 2>/dev/null
  rm -rf -- "$tmp"
}
trap cleanup EXIT

export HOME="$tmp/home"
unset XDG_DATA_HOME XDG_CONFIG_HOME
mkdir -p "$HOME" "$tmp/stubs"
export PATH="$tmp/stubs:$PATH" LAUNCH_LOG="$tmp/launch.log"

cat >"$tmp/stubs/omarchy-launch-webapp" <<'EOF'
#!/bin/bash
printf '%s\n' "$@" >"$LAUNCH_LOG"
EOF
cat >"$tmp/stubs/omarchy-webapp-install" <<'EOF'
#!/bin/bash
mkdir -p "$HOME/.local/share/applications"
printf '[Desktop Entry]\nName=%s\nExec=%s\nIcon=%s\n' "$1" "$4" "${3:-netease-cloud-music}" \
  >"$HOME/.local/share/applications/$1.desktop"
EOF
printf '#!/bin/bash\nexit 0\n' >"$tmp/stubs/hyprctl"
chmod +x "$tmp/stubs"/*

pass=0
check() {
  if eval "$2"; then
    pass=$((pass + 1))
    echo "ok - $1"
  else
    echo "not ok - $1" >&2
    exit 1
  fi
}

desktop="$HOME/.local/share/applications/NetEase Cloud Music.desktop"
ext="$HOME/.local/share/netease-music-webapp-ext"
bindings="$HOME/.config/hypr/bindings.lua"
launcher="$repo/bin/netease-music-webapp"

# An earlier version's leftovers: script copies and a binding block.
mkdir -p "$HOME/.local/bin" "$HOME/.config/hypr"
printf '#!/bin/bash\nexec omarchy-launch-webapp "https://music.163.com/st/webplayer"\n' >"$HOME/.local/bin/netease-music-webapp"
printf '#!/bin/bash\necho unrelated\n' >"$HOME/.local/bin/netease-music-toggle-other"
cat >"$bindings" <<'EOF'
o.bind("SUPER + CTRL + A", "Mine", "true")

-- >>> omarchy-ncm: Music key shows/hides NetEase Cloud Music (default: Spotify)
hl.unbind("SUPER + SHIFT + M")
o.bind("SUPER + SHIFT + M", "NetEase Music", "/old/path/netease-music-toggle")
-- <<< omarchy-ncm
EOF

"$repo/install.sh" --bind >/dev/null
check "launcher entry runs this checkout" 'grep -qx "Exec=$launcher" "$desktop"'
check "launcher entry has window class" 'grep -qx "StartupWMClass=netease-music" "$desktop"'
check "old script copies removed, others kept" '[[ ! -e $HOME/.local/bin/netease-music-webapp && -e $HOME/.local/bin/netease-music-toggle-other ]]'
check "old binding block replaced by one new block" '[[ $(grep -cE "^-- >>> omarchy-" "$bindings") == 1 ]] && grep -q "^-- >>> omarchy-netease-music" "$bindings" && grep -qF "\"$repo/bin/netease-music-toggle\")" "$bindings"'
check "other bindings kept" 'grep -q "\"Mine\"" "$bindings"'

"$repo/install.sh" --bind >/dev/null
check "reinstall keeps one binding block" '[[ $(grep -cE "^-- >>> omarchy-" "$bindings") == 1 ]]'
check "reinstall keeps one window class line" '[[ $(grep -c "^StartupWMClass=" "$desktop") == 1 ]]'

"$launcher"
check "launch opens the web player" '[[ $(head -1 "$LAUNCH_LOG") == https://music.163.com/st/webplayer ]]'
check "launch sets profile, class and extension" 'grep -qx -- "--class=netease-music" "$LAUNCH_LOG" && grep -qx -- "--user-data-dir=$HOME/.local/share/netease-music-webapp" "$LAUNCH_LOG" && grep -qx -- "--load-extension=$ext" "$LAUNCH_LOG"'
check "launch copies the extension with the theme script" '[[ $(jq -r ".content_scripts[0].js[0]" "$ext/manifest.json") == theme.js && -f $ext/theme.js && -f $ext/netease.css ]]'
check "no proxy without a proxy file" '! grep -q -- "--proxy-server" "$LAUNCH_LOG"'

mkdir -p "$HOME/.config/omarchy/current/theme"
touch "$HOME/.config/omarchy/current/theme/light.mode"
"$launcher"
check "light Omarchy theme leaves out the dark theme script" '[[ $(jq -r ".content_scripts[0].js // \"none\"" "$ext/manifest.json") == none && ! -e $ext/theme.js && -f $ext/netease.css ]]'
rm "$HOME/.config/omarchy/current/theme/light.mode"

mkdir -p "$HOME/.config/omarchy-netease-music"
python3 -c 'import socket,sys,time
s=socket.socket(); s.bind(("127.0.0.1",0)); s.listen(8)
print(s.getsockname()[1], flush=True); time.sleep(60)' >"$tmp/port" &
listener=$!
for _ in $(seq 50); do [[ -s $tmp/port ]] && break; sleep 0.1; done
port=$(cat "$tmp/port")
echo "http://127.0.0.1:$port" >"$HOME/.config/omarchy-netease-music/proxy"
"$launcher"
check "proxy used while its port listens" 'grep -qx -- "--proxy-server=http://127.0.0.1:$port" "$LAUNCH_LOG"'
kill "$listener"
wait "$listener" 2>/dev/null || true
listener=""
"$launcher"
check "proxy skipped when its port is closed" '! grep -q -- "--proxy-server" "$LAUNCH_LOG"'

mkdir -p "$HOME/.local/share/netease-music-webapp"
"$repo/uninstall.sh" >/dev/null
check "uninstall removes the launcher entry and extension copy" '[[ ! -e $desktop && ! -e $ext ]]'
check "uninstall removes only our binding block" '! grep -q "omarchy-" "$bindings" && grep -q "\"Mine\"" "$bindings"'
check "uninstall keeps login profile" '[[ -d $HOME/.local/share/netease-music-webapp ]]'
"$repo/uninstall.sh" --purge >/dev/null
check "purge removes profile and proxy file" '[[ ! -e $HOME/.local/share/netease-music-webapp && ! -e $HOME/.config/omarchy-netease-music ]]'

jq -e '.schemaVersion == 1 and .id == "netease.music" and (.kinds | index("bar-widget")) != null' "$repo/manifest.json" >/dev/null
check "plugin manifest points at an existing widget" '[[ -f $repo/$(jq -r .entryPoints.barWidget "$repo/manifest.json") ]]'

echo "$pass passed"
