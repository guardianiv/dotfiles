#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"
DISTROBOX_CONFIG="${PARENT_DIR}/distrobox.ini"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print status messages
log() { echo -e "${GREEN}==>${NC} $1"; }
warn() { echo -e "${YELLOW}WARNING:${NC} $1"; }
error() { echo -e "${RED}ERROR:${NC} $1"; exit 1; }

# Check if distrobox is installed
if ! command -v distrobox >/dev/null; then
    error "distrobox is not installed. Please install it first."
fi

# Function to create and setup distrobox
setup_distrobox() {
    local name=$1
    local image=$2

    log "Generating distrobox configuration..."
    "${SCRIPT_DIR}/install_deps.sh" generate-distrobox "$name" "$image"

    log "Creating distrobox container..."
    distrobox create --name "$name" --image "$image"

    log "Entering distrobox and installing dependencies..."
    distrobox enter "$name" -- ${SCRIPT_DIR}/install_deps.sh install

    log "Distrobox setup complete!"
    log "You can enter your development environment with: distrobox enter $name"
}

# Main script
main() {
    if [ $# -lt 2 ]; then
        error "Usage: $0 <container-name> <image>"
    fi

    setup_distrobox "$1" "$2"
}

# Run the script
main "$@"
