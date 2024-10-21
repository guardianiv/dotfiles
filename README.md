# dotfiles
# Dotfiles

My personal dotfiles for Linux setup. These dotfiles are managed using GNU Stow.

## Contents

- `nvim/` - Neovim configuration
- `zsh/` - Zsh shell configuration
- `git/` - Git configuration
- `tmux/` - Tmux configuration
- `hypr/` - Hyprland configuration
- `waybar/` - Waybar configuration

## Prerequisites

- Git
- GNU Stow
- Zsh (if using zsh configuration)
- Neovim (if using neovim configuration)
- Tmux (if using tmux configuration)
- Hyprland (if using hyprland configuration)
- Waybar (if using waybar configuration)

## Installation

1. Clone this repository:
   ```bash
   git clone https://github.com/yourusername/dotfiles.git ~/dotfiles
   ```

2. Run the installation script:
   ```bash
   cd ~/dotfiles
   ./install.sh
   ```

## Manual Installation

If you prefer to install manually:

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/dotfiles.git ~/dotfiles
   ```

2. Use stow to create symlinks:
   ```bash
   cd ~/dotfiles
   stow nvim  # For neovim config
   stow zsh   # For zsh config
   # etc...
   ```

## Update

To update the dotfiles:

1. Pull the latest changes:
   ```bash
   cd ~/dotfiles
   git pull
   ```

2. Re-run stow if needed:
   ```bash
   stow -R */  # Restow all configurations
   ```

## Customization

Feel free to modify any of these configurations to suit your needs. The configurations are organized by application, making it easy to add or remove specific configurations.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

