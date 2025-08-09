#!/bin/bash
DDD_HOME="/root/duckertheduck"
set -e 

# Check if nice.sh exists and run it
if [ -f "./nice.sh" ]; then
    echo "Found nice.sh in current directory, running it..."
    ./nice.sh
elif [ -f "${DDD_HOME}/nice.sh" ]; then
    echo "Found nice.sh in ${DDD_HOME}, running it..."
    ${DDD_HOME}/nice.sh
else
    echo "Error: nice.sh not found. Please ensure nice.sh is in the current directory or in ${DDD_HOME}"
    exit 1
fi