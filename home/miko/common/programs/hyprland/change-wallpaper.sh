#!/bin/sh

wallpaper_directory="$1"  # Subdirectory within wallpapers
sleep_duration="${2:-15m}"  # Sleep duration, default to 15 minutes if not provided

# Kill all running instances of swww
swww kill

# Initialize swww
swww init

# Create an array of wallpapers and shuffle them
wallpapers=($(find "$wallpaper_directory" -type f \( -iname "*.jpg" -o -iname "*.png" \) | shuf))

# Main loop for changing wallpapers
while true; do
  for wallpaper in "${wallpapers[@]}"; do
    [ -f "$wallpaper" ] || continue
    swww img "$wallpaper" -t wipe --transition-fps 60
    sleep "$sleep_duration"
  done
done

