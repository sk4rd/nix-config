#!/bin/sh

wallpaper_directory="$1"  # Subdirectory within wallpapers

# Check if swww is already running
if ! ps aux | grep -v grep | grep -q "swww"; then
    swww init
fi

while true; do
  for wallpaper in "$wallpaper_directory"/*.{jpg,png}; do
    [ -f "$wallpaper" ] || continue
    swww img "$wallpaper" -t wipe --transition-fps 60
    sleep 15m
  done
done
