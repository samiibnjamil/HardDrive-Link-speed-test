#!/bin/bash

log_directory="/home/sami/Documents/logs3"
log_file="$log_directory/sata_log.txt"
counter_file="$log_directory/run_counter.txt"
remote_user="sami"
remote_server="10.88.9.17"
remote_directory="/home/sami/Documents/sataTestLogs"
max_runs=100

echo "Creating log directory if it doesn't exist..."
mkdir -p "$log_directory"

echo "Checking if the counter file exists..."
if [ -f "$counter_file" ]; then
    run_count=$(<"$counter_file")
	echo "Counter File Exists! checking max count"
    if [ "$run_count" -ge "$max_runs" ]; then
        cat "$counter_file"
	cat "$log_file"
        rm "$counter_file"
        echo "Maximum run count reached. Deleting the counter file"
        exit 0
    fi
fi

echo "Initializing the counter if it doesn't exist..."
if [ ! -f "$counter_file" ]; then
    echo 0 > "$counter_file"
fi

echo "Reading the current run count..."
run_count=$(<"$counter_file")

echo "Starting the loop until the maximum run count is reached..."
while [ "$run_count" -lt "$max_runs" ]; do
    echo "Incrementing the run count..."
    run_count=$((run_count + 1))

    echo "Getting the current timestamp..."
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")

    echo "Running dmesg command and filtering for SATA link up messages..."
    output=$(sudo dmesg | grep -i sata | grep 'link up')

    echo "Running Hard Drive speed test"
    speed=$(sudo hdparm -Tt /dev/sda | grep 'Timing')

    echo "Logging the data with number and timestamp to the file..."
    echo -e "Run $run_count\n$timestamp:\n$output\n$speed\n" >> "$log_file"

    echo "Saving the updated run count..."
    echo "$run_count" > "$counter_file"

    echo "25 sec remaining"
    sleep 15

    echo "Transferring log files to the remote server..."
    scp "$log_file" "$remote_user@$remote_server:$remote_directory"
    scp "$counter_file" "$remote_user@$remote_server:$remote_directory"

   # echo "Delaying for 3 minutes before restarting..."
   # sleep 60  # sleep 60

    echo "10sec remaining"
    sleep 10


   # echo "Displaying text prompt 1 minute before reboot..."
   # notify-send --urgency=critical --expire-time=60000 "System will reboot in 1 minute. Save your work!"

    echo "Restarting the system..."
    sudo reboot
done

echo "Maximum run count reached. Exiting..."


#echo "modified file"
