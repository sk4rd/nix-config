#!/bin/sh

wallpaper_directory="$1"  # Subdirectory within wallpapers
sleep_duration="${2:-15m}"  # Sleep duration, default to 15 minutes if not provided

# Kill all running instances of swww
swww kill

# Wait a bit to ensure all processes are killed
sleep 1

# Initialize swww
swww init

# Main loop for changing wallpapers
while true; do
  for wallpaper in "$wallpaper_directory"/*.{jpg,png}; do
    [ -f "$wallpaper" ] || continue
    swww img "$wallpaper" -t wipe --transition-fps 60
    sleep "$sleep_duration"
  done
done
