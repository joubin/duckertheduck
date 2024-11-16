#!/bin/bash

# Exit on any error
set -ex

# Function to log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Load environment file
ENV_FILE="/root/duckertheduck/db_sensor/.env"
if [ ! -f "$ENV_FILE" ]; then
    log "Error: Environment file not found at $ENV_FILE"
    exit 1
fi

# Source the environment file
source "$ENV_FILE"

# Check if TAILSCALE_AUTH_KEY is set
if [ -z "$TAILSCALE_AUTH_KEY" ]; then
    log "Error: TAILSCALE_AUTH_KEY not set in $ENV_FILE"
    exit 1
fi

# Remove existing Tailscale repo file (allowed to fail)
log "Attempting to remove existing Tailscale repo file..."
rm -rf /etc/yum.repos.d/tailscale.repo || true

# Function to check internet connectivity
check_internet() {
    if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Wait for internet connectivity
log "Checking internet connectivity..."
while ! check_internet; do
    log "No internet connection. Waiting for 60 seconds..."
    sleep 60
done
log "Internet connectivity confirmed"

# Set hostname based on current date
NEW_HOSTNAME="sensor$(date '+%d%m%Y')"
log "Setting hostname to: $NEW_HOSTNAME"
hostnamectl set-hostname "$NEW_HOSTNAME"
# Update /etc/hosts to prevent sudo warnings
sed -i "s/127.0.1.1.*/127.0.1.1\t$NEW_HOSTNAME/g" /etc/hosts

# Install Tailscale
log "Installing Tailscale..."
if ! curl -fsSL https://tailscale.com/install.sh | sh; then
    log "Error: Failed to install Tailscale"
    exit 1
fi

# Reset the flags because the tailscail script unsets them 
set -ex

# Enable and start Tailscale daemon service
log "Enabling and starting Tailscale daemon service..."
systemctl enable tailscaled.service
systemctl start tailscaled.service

# Wait a moment for the service to fully start
sleep 5

# Run Tailscale up command
log "Running Tailscale up command..."
/usr/bin/tailscale up --auth-key="$TAILSCALE_AUTH_KEY" --hostname "$NEW_HOSTNAME"

# Remove the systemd service file
log "Removing first_boot service..."
if [ -f "/etc/systemd/system/first_boot.service" ]; then
    systemctl stop first_boot.service
    systemctl disable first_boot.service
    rm /etc/systemd/system/first_boot.service
    systemctl daemon-reload
fi


# Remove this script
log "Removing first boot script..."
if [ -f "/first_boot.sh" ]; then
    rm /first_boot.sh
fi

# Final log message before reboot
log "Setup completed successfully. Rebooting system..."

# Reboot the system
/sbin/reboot