#!/usr/bin/env bash
WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
LAST_WALLPAPER="$HOME/.config/hypr/current-wallpaper"

if [[ -f "$LAST_WALLPAPER" ]]; then
    WALLPAPER=$(cat "$LAST_WALLPAPER")
    [[ ! -f "$WALLPAPER" ]] && WALLPAPER=""
fi

FRESH=""
if [[ -z "$WALLPAPER" ]]; then
    WALLPAPER=$(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) | shuf -n 1)
    FRESH=1
fi

[[ -z "$WALLPAPER" ]] && exit 0

BLACK="${XDG_RUNTIME_DIR:-/tmp}/qs-greet-black"
for i in $(seq 1 60); do
    [[ -e "$BLACK" ]] && break
    sleep 0.2
done

for i in $(seq 1 20); do
    pgrep -x awww-daemon &>/dev/null && break
    sleep 0.3
done

if [[ -n "$FRESH" ]]; then
    WALL_INSTANT=1 "$HOME/.config/hypr/scripts/wallpaper/set-wallpaper.sh" "$WALLPAPER"
else
    WALL_INSTANT=1 "$HOME/.config/hypr/scripts/wallpaper/set-wallpaper.sh" "$WALLPAPER" --no-theme
fi
