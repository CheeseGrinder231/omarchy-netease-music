import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import qs.Ui

// NetEase Music bar button.
//
// Left click shows or hides the player (bin/netease-music-toggle), and on
// first use runs install.sh to add the app launcher entry. Middle click plays
// or pauses, right click skips to the next song, and the tooltip shows the
// current song. The icon is dimmed unless NetEase is playing. Scripts can use
// `omarchy-shell netease.music status|toggle|playPause|next`.
//
// The player is found by its window class (netease-music, set by the
// launcher) and the browser's MPRIS name, chromium.instance<pid>, so other
// browsers playing media don't count.
Item {
  id: root

  property var bar
  property string moduleName
  property var settings

  readonly property string dir: {
    var path = String(Qt.resolvedUrl("."))
    if (path.indexOf("file://") === 0) path = path.substring(7)
    try {
      path = decodeURIComponent(path)
    } catch (e) {}
    return path.replace(/\/$/, "")
  }

  // Browser pid of the NetEase window, 0 when it isn't open.
  property int appPid: 0

  readonly property var player: {
    if (appPid <= 0 || !Mpris.players) return null
    var name = "org.mpris.MediaPlayer2.chromium.instance" + appPid
    var list = Mpris.players.values
    for (var i = 0; i < list.length; i++) {
      if (list[i] && list[i].dbusName === name) return list[i]
    }
    return null
  }
  readonly property bool running: appPid > 0
  readonly property bool playing: !!(player && player.isPlaying)
  readonly property string song: {
    if (!player || !player.trackTitle) return ""
    return player.trackArtist ? player.trackTitle + " – " + player.trackArtist : player.trackTitle
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  // The plugin folder goes in as $1, so no quoting is needed. (The bar API that
  // third-party plugins get has run() but no shellQuote().)
  function toggle() {
    Quickshell.execDetached(["bash", "-lc",
      "[ -f \"$HOME/.local/share/applications/NetEase Cloud Music.desktop\" ] || \"$1/install.sh\" >/dev/null 2>&1; "
        + "exec \"$1/bin/netease-music-toggle\"",
      "netease-music", dir])
  }

  function playPause() {
    if (player && player.canTogglePlaying) player.togglePlaying()
    else if (!running) toggle()
  }

  function next() {
    if (player && player.canGoNext) player.next()
  }

  function refresh() {
    if (!finder.running) finder.running = true
  }

  Process {
    id: finder
    command: ["hyprctl", "clients", "-j"]
    stdout: StdioCollector {
      onStreamFinished: {
        var pid = 0
        try {
          var clients = JSON.parse(text)
          for (var i = 0; i < clients.length; i++) {
            if (clients[i].class === "netease-music") {
              pid = Number(clients[i].pid) || 0
              break
            }
          }
        } catch (e) {}
        root.appPid = pid
      }
    }
  }

  Connections {
    target: Hyprland
    function onRawEvent(event) {
      var name = String(event && event.name ? event.name : "")
      if (name === "openwindow" || name === "closewindow") root.refresh()
    }
  }

  Component.onCompleted: refresh()

  // omarchy-shell netease.music status | toggle | playPause | next
  IpcHandler {
    target: "netease.music"
    function status(): string {
      return JSON.stringify({
        running: root.running,
        pid: root.appPid,
        playing: root.playing,
        title: root.player ? (root.player.trackTitle || "") : "",
        artist: root.player ? (root.player.trackArtist || "") : ""
      })
    }
    function toggle(): void { root.toggle() }
    function playPause(): void { root.playPause() }
    function next(): void { root.next() }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: String.fromCodePoint(0xF075A) // nf-md-music_note
    dimmed: !root.playing
    tooltipText: root.song !== "" ? root.song
      : root.running ? "NetEase Music"
      : "NetEase Music: click to open"
    onPressed: function(b) {
      if (b === Qt.MiddleButton) root.playPause()
      else if (b === Qt.RightButton) root.next()
      else root.toggle()
    }
  }
}
