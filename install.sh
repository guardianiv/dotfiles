#!/bin/bash

DOTFILES_DIR="$HOME/dotfiles"

# Function to create symbolic links
create_symlink() {
    local source=$1
    local target=$2
    
    # Create parent directory if it doesn't exist
    mkdir -p "$(dirname "$target")"
    
    # Backup existing file/directory
    if [ -e "$target" ]; then
        echo "Backing up $target to $target.backup"
        mv "$target" "$target.backup"
    fi
    
    # Create symbolic link
    echo "Creating symlink: $target -> $source"
    ln -sf "$source" "$target"
}

# Install stow if not present (for package managers other than dnf, modify accordingly)
if ! command -v stow &> /dev/null; then
    echo "Installing stow..."
    if command -v dnf &> /dev/null; then
        sudo dnf install -y stow
    elif command -v apt-get &> /dev/null; then
        sudo apt-get install -y stow
    fi
fi

# Use stow to create symlinks
cd "$DOTFILES_DIR"

# For each directory in the dotfiles repository
for dir in */; do
    dir=${dir%/}  # Remove trailing slash
    echo "Stowing $dir..."
    stow -t "$HOME" "$dir"
done

# Additional setup steps for specific applications

# Neovim setup
if [ -d "$HOME/.config/nvim" ]; then
    # Install vim-plug if using it
    if [ ! -f "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim ]; then
        sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
            https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
    fi
    
    # Install plugins if using vim-plug
    nvim --headless +PlugInstall +qall
fi

# Zsh setup
if [ -f "$HOME/.zshrc" ]; then
    # Install Oh My Zsh if you use it
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    fi
fi

echo "Dotfiles installation complete!"
echo "Please restart your shell to apply changes."
