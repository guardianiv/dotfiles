# fuji dotfiles

MacBook Pro (Apple Silicon) development environment for Fortran library development.

## Structure
dotfiles/
├── shared/          # Cross-platform configs (macOS + Linux)
│   ├── nvim/        # Neovim (kickstart-based)
│   ├── tmux/        # tmux config
│   ├── git/         # gitconfig
│   ├── zsh/         # .zshrc + starship.toml
│   └── containers/  # Podman Containerfiles
├── macos/           # macOS-specific configs
│   └── aerospace/   # AeroSpace tiling WM
└── linux/           # Linux-specific configs (future)
├── hypr/        # Hyprland
└── waybar/      # Waybar

## Bootstrap (new machine)

```bash
# 1. Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Install core tools
brew install neovim tmux git stow starship podman
brew install --cask ghostty nikitabobko/tap/aerospace

# 3. Clone dotfiles
git clone git@github.com:guardianiv/dotfiles.git ~/dotfiles

# 4. Stow configs
cd ~/dotfiles
stow -d shared -t ~ nvim
stow -d shared -t ~ tmux
stow -d shared -t ~ git
stow -d shared -t ~ zsh
stow -d shared -t ~ starship
stow -d macos -t ~ aerospace
```

## Status / Resume Points

### Completed
- [x] AeroSpace tiling WM (alt-hjkl, workspaces 1-9)
- [x] Ghostty terminal (JetBrainsMono Nerd Font)
- [x] Neovim (kickstart + oil.nvim + treesitter)
- [x] tmux config
- [x] zsh + Oh My Zsh + Starship prompt
- [x] git config
- [x] Podman installed and working
- [x] SSH key configured for GitHub

### In Progress — Resume Here
- [ ] **Podman dev container (Rocky Linux 8 + IFX)**
  - Containerfile: `shared/containers/Containerfile.rockylinux8`
  - GPG key: `shared/containers/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB`
  - Blocked on: Intel oneAPI repo SSL/access issue during container build
  - Next step: Fix oneAPI repo setup in Containerfile, then install `intel-hpckit`
  - IFX sourcing: `source /opt/intel/oneapi/setvars.sh`

- [ ] **Windows cross-compilation container**
  - Containerfile: `shared/containers/Containerfile.windows-cross`
  - Must run as `--platform linux/amd64` (MinGW not available for aarch64)
  - Next step: Build and verify `x86_64-w64-mingw32-gfortran` works

- [ ] **Windows VM (UTM)**
  - Tabled — revisit after containers are working
  - Purpose: IFX on Windows for `.dll` builds, testing

### Not Started
- [ ] Ansible bootstrap playbook
- [ ] Brewfile
- [ ] Fortran LSP (fortls) in Neovim

## CAC/VPN Notes

openconnect + CAC setup is functional but VPN portal unreachable from civilian network.

```bash
sudo -E openconnect --protocol=gp \
  --certificate="pkcs11:model=PKCS%2315%20emulated;manufacturer=piv_II;serial=2a89a1843810a3ee;token=NAVARRO.RICK.L.1168185860;id=%01;object=Certificate%20for%20PIV%20Authentication;type=cert" \
  --sslkey="pkcs11:model=PKCS%2315%20emulated;manufacturer=piv_II;serial=2a89a1843810a3ee;token=NAVARRO.RICK.L.1168185860;id=%01;object=PIV%20AUTH%20key;type=private" \
  webvpn.sd.niwc.navy.mil
```

Requirements: CAC reader, `openconnect`, `opensc`, p11-kit module at
`/opt/homebrew/etc/pkcs11/modules/opensc.module`
