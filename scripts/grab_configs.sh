#!/bin/bash

# Define the dotfiles directory
DOTFILES_DIR="$HOME/dotfiles"

# Create the necessary directories
mkdir -p "$DOTFILES_DIR"/{nvim,zsh,git,tmux,hypr,waybar}

# Function to backup existing file
backup_if_exists() {
    if [ -f "$1" ]; then
        echo "Backing up $1 to $1.backup"
        cp "$1" "$1.backup"
    fi
}

# Function to copy file/directory if it exists
copy_if_exists() {
    local source=$1
    local dest=$2
    if [ -e "$source" ]; then
        echo "Copying $source to $dest"
        mkdir -p "$(dirname "$dest")"
        cp -r "$source" "$dest"
    else
        echo "Warning: $source does not exist, skipping..."
    fi
}

# Neovim configuration
copy_if_exists "$HOME/.config/nvim" "$DOTFILES_DIR/nvim/.config/nvim"

# Zsh configuration
copy_if_exists "$HOME/.zshrc" "$DOTFILES_DIR/zsh/.zshrc"
copy_if_exists "$HOME/.zshenv" "$DOTFILES_DIR/zsh/.zshenv"
copy_if_exists "$HOME/.zprofile" "$DOTFILES_DIR/zsh/.zprofile"

# Git configuration
copy_if_exists "$HOME/.gitconfig" "$DOTFILES_DIR/git/.gitconfig"

# Tmux configuration
copy_if_exists "$HOME/.tmux.conf" "$DOTFILES_DIR/tmux/.tmux.conf"

# Hyprland configuration
copy_if_exists "$HOME/.config/hypr" "$DOTFILES_DIR/hypr/.config/hypr"

# Waybar configuration
copy_if_exists "$HOME/.config/waybar" "$DOTFILES_DIR/waybar/.config/waybar"

# Create a .gitignore file
cat > "$DOTFILES_DIR/.gitignore" << EOL
*.backup
.DS_Store
*.log
node_modules/
*.swp
EOL

# Initialize git repository
cd "$DOTFILES_DIR"
git init

echo "Dotfiles have been gathered in $DOTFILES_DIR"
echo "Next steps:"
echo "1. Review the gathered files"
echo "2. Create a repository on GitHub"
echo "3. Add and commit your files"
echo "4. Push to GitHub"
