# NetEase Music for Omarchy

An [Omarchy](https://omarchy.org) plugin for [NetEase Cloud Music](https://music.163.com)
(网易云音乐). It runs NetEase's own web player as an app, with a bar button and a
key to show or hide it, media keys, and the current song in the bar.

Unofficial. Not affiliated with NetEase. The player is NetEase's web player
(<https://music.163.com/st/webplayer>) in a Chromium app window. You log in
with your own NetEase account, and VIP songs play if your account has VIP.
No developer key is needed.

## What you get

- **A bar button.** Click to show or hide the player (it starts it if
  needed). Middle click plays or pauses, right click skips to the next song,
  and the tooltip shows the current song. The icon is dimmed unless NetEase
  is playing.
- **An app.** "NetEase Cloud Music" in the app launcher (Super+Space), in its
  own window and browser profile, with everything the web player has: 每日推荐,
  私人漫游, 心动模式, lyrics, playlists and search.
- **Show/hide key (optional).** Super+Shift+M shows the player over whatever
  you are doing and hides it again. Hiding keeps the music playing.
- **Media keys.** Play/pause, next and previous work through Omarchy.
- **A cleaner home page.** The top row (banner, recent playlists, scene card)
  is hidden.
- **Dark theme.** If your Omarchy theme is dark, the player starts in
  NetEase's own dark theme. Change it any time with the skin (shirt) icon at
  the top right of the player.

## Requirements

- Omarchy 4 with Chromium as the browser (Omarchy's default)
- A NetEase Cloud Music account
- To play most songs, a mainland-China internet connection (see
  [Outside mainland China](#outside-mainland-china-or-behind-a-vpn))

## Install

```bash
omarchy plugin add https://github.com/CheeseGrinder231/omarchy-netease-music --enable
```

Click the music note in the bar. The first click adds **NetEase Cloud Music**
to the app launcher and opens the player. Log in there (scanning the QR code
with the NetEase Cloud Music phone app is quickest).

To also show and hide it with Super+Shift+M:

```bash
~/.config/omarchy/plugins/netease.music/install.sh --bind
```

In Omarchy that key opens Spotify by default; `--bind` replaces it in
`~/.config/hypr/bindings.lua`, inside a marked block that `uninstall.sh`
removes again.

## Use

| Action | How |
| --- | --- |
| Show / hide the player | Click the bar button, or Super+Shift+M (with `--bind`) |
| Play-pause | Middle click the bar button, or the media key |
| Next song | Right click the bar button, or the media key |
| From scripts | `omarchy-shell netease.music toggle`, `playPause`, `next`, `status` |

The player lives on a Hyprland special workspace called `music`.

Omarchy's built-in media widget can show the scrolling song title too:
`omarchy bar put omarchy.media --before omarchy.clock`.

## Outside mainland China or behind a VPN

NetEase streams most songs only to mainland-China IP addresses. Abroad, many
songs will show as unavailable. That is NetEase's restriction, and this
plugin can't change it.

If you are in mainland China but a VPN sends your traffic abroad, give the
player a local proxy that goes direct. Most VPN apps have a local "direct"
port:

```bash
mkdir -p ~/.config/omarchy-netease-music
echo http://127.0.0.1:PORT > ~/.config/omarchy-netease-music/proxy
```

The player uses it only while that port is listening, so it still works with
the VPN off. It's checked when the player starts.

## Update

```bash
omarchy plugin update netease.music
omarchy restart shell
```

The shell loads the bar button's code when it starts, so restart it after an
update. The player picks up its changes the next time it starts; if closing
its window doesn't stop it, run `pkill -f netease-music-webapp`.

## Customize

- **Hide more of the page:** add CSS to `extension/netease.css`. NetEase's
  class names end in build hashes, so match on their stable start, for
  example `[class*="RecentListenContainer_"]`.
- **Theme:** use the skin icon in the player. The dark theme is set only once,
  so your choice sticks.

## How it works

| File | What it does |
| --- | --- |
| `manifest.json`, `BarWidget.qml` | The Omarchy plugin: the bar button |
| `bin/netease-music-webapp` | Opens the web player with `omarchy-launch-webapp` in its own profile (`~/.local/share/netease-music-webapp`), with the window class `netease-music`, the extension, and the proxy if set |
| `bin/netease-music-toggle` | Shows or hides the player on the special workspace `music`, and starts it if needed |
| `extension/` | A small Chromium extension, loaded only in this app: CSS that hides the top row, and a script that picks the dark theme once |
| `install.sh` | Adds the app launcher entry (with `omarchy webapp install`) and, with `--bind`, the key. The bar button runs it on first use |
| `uninstall.sh` | Removes what `install.sh` and the app added |

The player gets its own browser profile so it can have its own window class,
extension and proxy without touching your main browser. The bar button finds
it by that window class and by its MPRIS player, so media playing in other
browsers doesn't count.

## Uninstall

```bash
~/.config/omarchy/plugins/netease.music/uninstall.sh            # keeps your login
~/.config/omarchy/plugins/netease.music/uninstall.sh --purge    # also deletes the login and proxy file
omarchy plugin remove netease.music
```

## Development

```bash
tests/run.sh               # set up, launch and remove in a throwaway home, with Omarchy commands stubbed
omarchy plugin validate .  # Omarchy's manifest checks
```

CI runs shellcheck, checks both manifests and runs the tests. The bar button
needs a real shell to test: install the plugin, then `omarchy restart shell`.

This project started as a bar plugin built on NetEase's
[ncm-cli](https://music.163.com/st/ncmcli). It moved to the web player
because the CLI's open-platform access refuses VIP songs, and every user
needs their own NetEase developer key.

Not on Omarchy? [Netease-Cloud-Music-Web-Player](https://github.com/feng-yifan/Netease-Cloud-Music-Web-Player)
wraps the same web player as a standalone Electron app for any Linux desktop.

## 中文说明

Omarchy 的网易云音乐插件：把网易云音乐网页版播放器（<https://music.163.com/st/webplayer>）做成应用，状态栏按钮和快捷键一键显示/隐藏，支持媒体键，状态栏显示正在播放。非官方项目，与网易无关；用你自己的网易云账号登录，VIP 歌曲随账号可播，不需要开发者密钥。

1. 安装：`omarchy plugin add https://github.com/CheeseGrinder231/omarchy-netease-music --enable`
2. 点击状态栏的音符图标：首次点击会把 **NetEase Cloud Music** 加入应用启动器并打开播放器，扫码登录即可。
3. 点击图标显示/隐藏播放器（隐藏后继续播放），中键播放/暂停，右键下一首。
4. 可选：`~/.config/omarchy/plugins/netease.music/install.sh --bind`，用 Super+Shift+M 显示/隐藏（会替换 Omarchy 默认打开 Spotify 的这个快捷键）。

网易云的大部分歌曲只对中国大陆 IP 提供。如果你在大陆但开着 VPN，把 VPN 软件的本地直连端口写入 `~/.config/omarchy-netease-music/proxy`（例如 `http://127.0.0.1:端口`），播放器只在该端口可用时才会使用它。

更新：`omarchy plugin update netease.music` 然后 `omarchy restart shell`。卸载：先运行插件目录里的 `uninstall.sh`（加 `--purge` 会删除登录信息），再 `omarchy plugin remove netease.music`。

## License

MIT. See [LICENSE](LICENSE).
