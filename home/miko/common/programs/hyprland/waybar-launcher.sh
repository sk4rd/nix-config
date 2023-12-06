#!/bin/sh

# Get the PID of the current script
script_pid=$$

# Find all PIDs of waybar, excluding the script's own PID
process_ids=$(ps aux | grep '[w]aybar' | awk -v spid=$script_pid '{if ($2 != spid) print $2}')

# Check if any waybar process IDs exist
if [ -n "$process_ids" ]
then
    echo "Killing all running instances of Waybar..."
    for pid in $process_ids
    do
        # Kill each waybar process
        kill $pid
    done
    # Wait a bit to ensure all processes are killed
    sleep 1
fi

echo "Starting a new instance of Waybar..."
# Start waybar
waybar &
