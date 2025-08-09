#!/bin/bash

# Exit on error
set -ex

CLONE_DIR=/root/duckertheduck
LOCK_FILE="/var/lock/duckertheduck_install.lock"

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

# Function to check if already installed
check_already_installed() {
    if [ -f "$LOCK_FILE" ]; then
        log "Installation already completed. Lock file exists: $LOCK_FILE"
        log "To reinstall, remove the lock file: rm $LOCK_FILE"
        exit 0
    fi
}

# Function to save SD card writes
save_sd_card_writes() {
    log "Configuring system to save SD card writes..."
    
    # Disable swap
    if systemctl is-active --quiet swap.target; then
        log "Disabling swap..."
        systemctl stop swap.target
        systemctl disable swap.target
    fi
    
    # Disable swap in fstab if it exists
    if grep -q "^/swap" /etc/fstab; then
        log "Commenting out swap in /etc/fstab..."
        sed -i 's/^\/swap/#\/swap/' /etc/fstab
    fi
    
    # Configure journald to use volatile storage
    if [ ! -f /etc/systemd/journald.conf.d/volatile.conf ]; then
        log "Configuring journald to use volatile storage..."
        mkdir -p /etc/systemd/journald.conf.d
        cat > /etc/systemd/journald.conf.d/volatile.conf << EOF
[Journal]
Storage=volatile
EOF
        systemctl restart systemd-journald
    fi
    
    # Use tmpfs for /tmp if not already configured
    if ! grep -q "tmpfs.*tmp.*tmpfs" /etc/fstab; then
        log "Configuring /tmp to use tmpfs..."
        echo "tmpfs /tmp tmpfs defaults,noatime,nosuid,size=100M 0 0" >> /etc/fstab
        mount -a
    fi
    
    # Use tmpfs for /var/tmp if not already configured
    if ! grep -q "tmpfs.*var/tmp.*tmpfs" /etc/fstab; then
        log "Configuring /var/tmp to use tmpfs..."
        echo "tmpfs /var/tmp tmpfs defaults,noatime,nosuid,size=50M 0 0" >> /etc/fstab
        mount -a
    fi
    
    # Disable unnecessary logging
    if [ ! -f /etc/systemd/journald.conf.d/reduce-logging.conf ]; then
        log "Reducing system logging..."
        mkdir -p /etc/systemd/journald.conf.d
        cat > /etc/systemd/journald.conf.d/reduce-logging.conf << EOF
[Journal]
MaxRetentionSec=1day
SystemMaxUse=50M
EOF
        systemctl restart systemd-journald
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

# Function to ensure required commands are available (idempotent)
ensure_requirements() {
    local pkg_manager="$1"
    local packages=()

    # Check for curl
    if ! command -v curl >/dev/null 2>&1; then
        packages+=("curl")
    fi

    # Check for git
    if ! command -v git >/dev/null 2>&1; then
        packages+=("git")
    fi

    # Check for python3-pip (which provides pip3)
    if ! command -v pip3 >/dev/null 2>&1; then
        packages+=("python3-pip")
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
    else
        log "All required packages already installed"
    fi
}

# Function to clone repository (idempotent)
clone_repository() {
    if [ -d "${CLONE_DIR}" ]; then
        log "Repository already exists at ${CLONE_DIR}, updating..."
        cd "${CLONE_DIR}"
        git fetch --all
        git reset --hard origin/main
    else
        log "Cloning repository..."
        git clone https://github.com/joubin/duckertheduck.git "${CLONE_DIR}"
    fi
    
    # Check if clone was successful
    if [ ! -d "${CLONE_DIR}" ]; then
        log "Error: Failed to clone repository"
        exit 1
    fi
}

# Function to install Tailscale (idempotent)
install_tailscale() {
    if command -v tailscale >/dev/null 2>&1; then
        log "Tailscale already installed"
    else
        log "Installing Tailscale..."
        curl -fsSL https://tailscale.com/install.sh | sh
    fi
}

# Function to install Python requirements (idempotent)
install_python_requirements() {
    if [ -f "${CLONE_DIR}/db_sensor/requirements.txt" ]; then
        log "Installing Python requirements..."
        pip3 install --break-system-packages -r "${CLONE_DIR}/db_sensor/requirements.txt"
    else
        log "Warning: requirements.txt not found at ${CLONE_DIR}/db_sensor/requirements.txt"
    fi
}

# Function to install systemd services (idempotent)
install_services() {
    log "Installing systemd services..."
    
    # Install sound_sensor.service
    if [ -f "${CLONE_DIR}/linux/sound_sensor.service" ]; then
        install -m 644 "${CLONE_DIR}/linux/sound_sensor.service" /etc/systemd/system/sound_sensor.service
        log "Installed sound_sensor.service"
    else
        log "Warning: sound_sensor.service not found"
    fi
    
    # Install first_boot.service (commented out as per user's change)
    # if [ -f "${CLONE_DIR}/linux/first_boot.service" ]; then
    #     install -m 644 "${CLONE_DIR}/linux/first_boot.service" /etc/systemd/system/first_boot.service
    #     log "Installed first_boot.service"
    # else
    #     log "Warning: first_boot.service not found"
    # fi
    
    # Install first_boot.sh (commented out as per user's change)
    # if [ -f "${CLONE_DIR}/linux/first_boot.sh" ]; then
    #     install -m 755 "${CLONE_DIR}/linux/first_boot.sh" /first_boot.sh
    #     log "Installed first_boot.sh"
    # else
    #     log "Warning: first_boot.sh not found"
    # fi
}

# Function to configure systemd (idempotent)
configure_systemd() {
    log "Configuring systemd..."
    systemctl daemon-reload
    
    # Enable sound_sensor.service
    if systemctl list-unit-files | grep -q "sound_sensor.service"; then
        systemctl enable sound_sensor.service
        log "Enabled sound_sensor.service"
    else
        log "Warning: sound_sensor.service not found in systemd"
    fi
    
    # Enable first_boot.service (commented out as per user's change)
    # if systemctl list-unit-files | grep -q "first_boot.service"; then
    #     systemctl enable first_boot.service
    #     log "Enabled first_boot.service"
    # else
    #     log "Warning: first_boot.service not found in systemd"
    # fi
}

# Function to create lock file
create_lock_file() {
    mkdir -p "$(dirname "$LOCK_FILE")"
    echo "$(date)" > "$LOCK_FILE"
    log "Created lock file: $LOCK_FILE"
}

# Main installation function
main() {
    check_root
    check_already_installed
    
    log "Starting idempotent installation..."
    
    # Save SD card writes first
    save_sd_card_writes
    
    # Detect package manager
    PKG_MANAGER=$(detect_pkg_manager)
    log "Detected package manager: $PKG_MANAGER"
    
    # Ensure requirements
    ensure_requirements "$PKG_MANAGER"
    
    # Clone repository
    clone_repository
    
    # Install Tailscale
    install_tailscale
    
    # Install Python requirements
    install_python_requirements
    
    # Install services
    install_services
    
    # Configure systemd
    configure_systemd
    
    # Create lock file
    create_lock_file
    
    log "Installation completed successfully"
    log "The system will configure itself on next boot"
    log "To reinstall, remove the lock file: rm $LOCK_FILE"
}

# Run main function
main "$@" 