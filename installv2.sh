#!/bin/bash

# Exit on error
set -e

# Function to log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Function to check if running as root
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        log "Error: This script must be run as root"
        exit 1
    fi
}

# Function to detect package manager
detect_pkg_manager() {
    if command -v apt-get >/dev/null 2>&1; then
        echo "apt"
    elif command -v yum >/dev/null 2>&1; then
        echo "yum"
    else
        log "Error: No supported package manager found (apt or yum)"
        exit 1
    fi
}

# Function to ensure required commands are available
ensure_requirements() {
    local pkg_manager="$1"
    local packages=()

    # Check for curl
    if ! command -v curl >/dev/null 2>&1; then
        packages+=("curl")
    fi

    # If packages need to be installed
    if [ ${#packages[@]} -ne 0 ]; then
        log "Installing required packages: ${packages[*]}"
        if [ "$pkg_manager" = "apt" ]; then
            apt-get update
            apt-get install -y "${packages[@]}"
        else
            yum install -y "${packages[@]}"
        fi
    fi
}

# Main installation function
main() {
    check_root

    log "Starting installation..."

    # Detect package manager
    PKG_MANAGER=$(detect_pkg_manager)
    log "Detected package manager: $PKG_MANAGER"

    # Ensure requirements
    ensure_requirements "$PKG_MANAGER"

    # Create temporary directory
    TEMP_DIR=$(mktemp -d)
    trap 'rm -rf "$TEMP_DIR"' EXIT

    # Download files
    log "Downloading required files..."
    
    # Download service file
    curl -sSL -o "$TEMP_DIR/first_boot.service" "https://raw.githubusercontent.com/joubin/duckertheduck/refs/heads/main/linux/first_boot.service"
    
    # Download main script
    curl -sSL -o "$TEMP_DIR/first_boot.sh" "https://raw.githubusercontent.com/joubin/duckertheduck/refs/heads/main/linux/first_boot.sh"

    # Verify downloads
    if [ ! -f "$TEMP_DIR/first_boot.service" ] || [ ! -f "$TEMP_DIR/first_boot.sh" ]; then
        log "Error: Failed to download required files"
        exit 1
    fi

    # Install files with correct permissions
    log "Installing files..."
    install -m 644 "$TEMP_DIR/first_boot.service" /etc/systemd/system/first_boot.service
    install -m 755 "$TEMP_DIR/first_boot.sh" /first_boot.sh

    # Create environment file if TAILSCALE_AUTH_KEY is provided
    if [ -n "$TAILSCALE_AUTH_KEY" ]; then
        log "Creating environment file..."
        echo "TAILSCALE_AUTH_KEY=$TAILSCALE_AUTH_KEY" | install -m 600 /dev/stdin /etc/first_boot.env
    else
        log "Warning: TAILSCALE_AUTH_KEY not provided. You'll need to create /etc/first_boot.env manually"
    fi

    # Reload systemd and enable service
    log "Configuring systemd..."
    systemctl daemon-reload
    systemctl enable first_boot.service

    log "Installation completed successfully"
    log "The system will configure itself on next boot"
}

# Run main function
main "$@"