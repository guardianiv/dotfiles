#!/bin/bash

# Configuration
DOTFILES_DIR="$HOME/dotfiles"
CONFIG_DIR="$DOTFILES_DIR/config"
BACKUP_DIR="$HOME/.dotfiles.backup.$(date +%Y%m%d%H%M%S)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print status messages
log() {
    echo -e "${GREEN}==>${NC} $1"
}

warn() {
    echo -e "${YELLOW}WARNING:${NC} $1"
}

error() {
    echo -e "${RED}ERROR:${NC} $1"
    exit 1
}

# Function to backup a file or directory
backup() {
    local path=$1
    if [ -e "$path" ]; then
        local backup_path="$BACKUP_DIR$path"
        log "Backing up $path to $backup_path"
        mkdir -p "$(dirname "$backup_path")"
        mv "$path" "$backup_path"
    fi
}

# Function to create a symlink
link() {
    local source=$1
    local target=$2
    
    # Create target directory if it doesn't exist
    mkdir -p "$(dirname "$target")"
    
    # Backup existing file/directory if it's not a symlink
    if [ -e "$target" ] && [ ! -L "$target" ]; then
        backup "$target"
    elif [ -L "$target" ]; then
        rm "$target"
    fi
    
    # Create the symlink
    ln -sf "$source" "$target"
    log "Linked $source -> $target"
}

# Ensure we're in the dotfiles directory
cd "$DOTFILES_DIR" || error "Cannot find dotfiles directory"

# Source the config file if it exists
if [ -f "$DOTFILES_DIR/install.conf" ]; then
    source "$DOTFILES_DIR/install.conf"
fi

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Read and process the mappings file
while IFS='=' read -r source target || [ -n "$source" ]; do
    # Skip comments and empty lines
    [[ $source =~ ^#.*$ ]] && continue
    [[ -z $source ]] && continue
    
    # Strip whitespace
    source=$(echo "$source" | xargs)
    target=$(echo "$target" | xargs)
    
    # Resolve paths
    source="$CONFIG_DIR/$source"
    target="$HOME/$target"
    
    # Create symlink if source exists
    if [ -e "$source" ]; then
        link "$source" "$target"
    else
        warn "Source not found: $source"
    fi
done < "$DOTFILES_DIR/mappings"

log "Dotfiles installation complete!"
if [ "$(ls -A "$BACKUP_DIR")" ]; then
    log "Backup of existing files can be found in: $BACKUP_DIR"
fi
log "Please restart your shell to apply changes."
