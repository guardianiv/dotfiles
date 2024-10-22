#!/bin/bash

# Configuration
DOTFILES_DIR="$HOME/dotfiles"
CONFIG_DIR="$DOTFILES_DIR/config"

# Colors for output
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Function to print status messages
log() {
    echo -e "${GREEN}==>${NC} $1"
}

# Function to copy configuration
copy_config() {
    local source=$1
    local dest=$2
    
    if [ -e "$source" ]; then
        # Create destination directory
        mkdir -p "$(dirname "$dest")"
        
        # Copy the configuration
        cp -R "$source" "$dest"
        log "Copied $source to $dest"
    else
        log "Skipping $source (not found)"
    fi
}

# Create directories
mkdir -p "$CONFIG_DIR"

# Copy configurations
log "Gathering configurations..."

# Neovim
copy_config "$HOME/.config/nvim" "$CONFIG_DIR/nvim"

# Zsh
mkdir -p "$CONFIG_DIR/zsh"
copy_config "$HOME/.zshrc" "$CONFIG_DIR/zsh/.zshrc"
copy_config "$HOME/.zshenv" "$CONFIG_DIR/zsh/.zshenv"

# Git
mkdir -p "$CONFIG_DIR/git"
copy_config "$HOME/.gitconfig" "$CONFIG_DIR/git/.gitconfig"

# Tmux
mkdir -p "$CONFIG_DIR/tmux"
copy_config "$HOME/.tmux.conf" "$CONFIG_DIR/tmux/.tmux.conf"

# Hyprland
copy_config "$HOME/.config/hypr" "$CONFIG_DIR/hypr"

# Waybar
copy_config "$HOME/.config/waybar" "$CONFIG_DIR/waybar"

# Create initial mappings file if it doesn't exist
if [ ! -f "$DOTFILES_DIR/mappings" ]; then
    cat > "$DOTFILES_DIR/mappings" << EOL
# Shell
zsh/.zshrc=.zshrc
zsh/.zshenv=.zshenv

# Neovim
nvim=.config/nvim

# Git
git/.gitconfig=.gitconfig

# Tmux
tmux/.tmux.conf=.tmux.conf

# Hyprland
hypr=.config/hypr

# Waybar
waybar=.config/waybar
EOL
    log "Created mappings file"
fi

# Create .gitignore
cat > "$DOTFILES_DIR/.gitignore" << EOL
.DS_Store
*.log
*.swp
EOL

# Initialize git repository
cd "$DOTFILES_DIR" || exit
if [ ! -d .git ]; then
    git init
    log "Initialized git repository"
fi

log "Configuration gathering complete!"
log "Your configurations have been copied to: $CONFIG_DIR"
log ""
log "Next steps:"
log "1. Review the gathered files"
log "2. Review and adjust the mappings file"
log "3. Create a repository on GitHub"
log "4. Add and commit your files"
log "5. Push to GitHub"
