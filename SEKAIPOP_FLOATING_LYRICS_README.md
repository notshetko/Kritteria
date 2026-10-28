# SekaiPop-inspired floating lyrics for end4-pC

This patch adds a transparent, draggable desktop lyrics widget to end4-pC. It reuses
end4-pC's existing `LyricsService` and `MprisController`; it does not install or copy
SekaiPop code. Lyrics availability remains dependent on the existing LRCLIB synced-lyrics
lookup in `scripts/lyrics/lyrics.py`.

## Install

1. Back up the current shell config:
   `cp -a ~/.config/quickshell/end4-pC ~/.config/quickshell/end4-pC.backup-lyrics`
2. Extract this patch archive into `~/.config/quickshell/end4-pC/`, preserving folders
   and allowing the four files to merge/overwrite.
3. Restart Quickshell:
   `pkill qs; qs -c end4-pC`

The widget is enabled by default but remains invisible unless synced lyrics are available.
Its initial position is around the center/lower-middle of a 1920x1080 screen. In the
desktop widget settings, move it to your preferred location or disable it.

## Rollback

Restore the backup folder, or revert the three modified files and remove
`modules/ii/background/widgets/lyrics/LyricsDesktopWidget.qml`.
