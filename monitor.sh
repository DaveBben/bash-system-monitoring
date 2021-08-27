#!/bin/bash
# Author : Dave Bennett
# A script to monitor system resources and output to serial (optional)

while :
do
############################
### System Memory
############################
# Run Top in batch mode with 1 iteration, displaying the values in megabytes
# Only grab the lines which contain MiB
memoryInfo=$(top -b -n1 -E m | grep "MiB")

# Get total memory available from $memoryInfo
total=$(echo "$memoryInfo" | grep "MiB Mem" | awk '{print $4}')

#Get memory marked as available
available=$(echo "$memoryInfo" | grep "MiB Swap" | awk '{print $9}')

#calculate percent by passing into bc
percentmem=$(echo "scale=2 ;((($total-$available)/$total)*100)" | bc)
############################################################

############################
### CPU Temp
############################
# Get Package ID 0 temp
temp=$(echo "scale=1; $(cat /sys/class/thermal/thermal_zone3/temp)/1000" | bc )
###########################################################

############################
### CPU Frequency
############################
freq=$(lscpu | grep "MHz". | head -n 1 | awk '{print $3}')
######################################

############################
### CPU Usage
############################
# Run top in batch mode with a delay of 0.5 seconds between each iteration
# Set for 3 iterations (must be at least 2 for accurate results)
# Subtract CPU% idle from 100 
cpu=$(top -d 0.5 -b -n3 | grep "Cpu(s)"|tail -n 1 | awk '{print 100-$8}')
############################################################


gpuinfo=$(nvidia-smi --format=csv --query-gpu=utilization.gpu,temperature.gpu,utilization.memory)
gpu_usage=$(echo "$gpuinfo" | tail -n1 | awk '{print $1}')
gpu_temp=$(echo "$gpuinfo" | tail -n1 | awk '{print $3}')
gpu_mem_usage=$(echo "$gpuinfo" | tail -n1 | awk '{print $4}')

echo "CPU%: ${cpu}, CPU Frequency (MHZ): ${freq}, Memory%: ${percentmem}, Temperature (C): ${temp}"
echo "GPU%: ${gpu_usage},  GPU Memory%: ${gpu_mem_usage}, GPU Temperature (C): ${gpu_temp}"


data=(${cpu} ${freq} ${percentmem} ${temp} ${gpu_usage} ${gpu_mem_usage} ${gpu_temp})
printf -v joined '%.0f,' "${data[@]}"


echo "${joined%,}" > /dev/ttyACM0

sleep 1
done
