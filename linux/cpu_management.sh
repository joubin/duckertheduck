#!/usr/bin/env bash
# Function to throttle CPU to minimum speed
cpu_min() {
    local min_freq
    min_freq=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq)
    for cpu in /sys/devices/system/cpu/cpu[0-9]*; do
        echo "$min_freq" | sudo tee "$cpu/cpufreq/scaling_max_freq" >/dev/null
    done
    echo "CPU max frequency set to minimum: $((min_freq/1000)) MHz"
}

# Function to reset CPU scaling to default max
cpu_reset() {
    local max_freq
    max_freq=$(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq)
    for cpu in /sys/devices/system/cpu/cpu[0-9]*; do
        echo "$max_freq" | sudo tee "$cpu/cpufreq/scaling_max_freq" >/dev/null
    done
    echo "CPU max frequency reset to: $((max_freq/1000)) MHz"
}

# Function to show current min/max per core
cpu_get() {
    for cpu in /sys/devices/system/cpu/cpu[0-9]*; do
        local cur max min
        cur=$(cat "$cpu/cpufreq/scaling_cur_freq")
        min=$(cat "$cpu/cpufreq/scaling_min_freq")
        max=$(cat "$cpu/cpufreq/scaling_max_freq")
        echo "$(basename "$cpu"): current=$((cur/1000)) MHz, min=$((min/1000)) MHz, max=$((max/1000)) MHz"
    done
}

# CLI entry point
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  case "$1" in
    cpu_min|min)
      cpu_min
      ;;
    cpu_reset|reset)
      cpu_reset
      ;;
    cpu_get|get|status)
      cpu_get
      ;;
    -h|--help|help|"" )
      echo "Usage: $0 {min|reset|get}" >&2
      exit 1
      ;;
    *)
      echo "Unknown command: $1" >&2
      echo "Usage: $0 {min|reset|get}" >&2
      exit 1
      ;;
  esac
fi