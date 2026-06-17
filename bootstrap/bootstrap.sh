#!/usr/bin/env bash
# bootstrap.sh — dev environment setup
# Usage: curl -fsSL https://raw.githubusercontent.com/guardianiv/dotfiles/main/bootstrap/bootstrap.sh | bash
# Or: bash ~/dotfiles/bootstrap/bootstrap.sh
set -eo pipefail

DOTFILES_REPO="https://github.com/guardianiv/dotfiles.git"
DOTFILES_DIR="${HOME}/dotfiles"

# ─── Color output ────────────────────────────────────────────────────────────
info()    { echo "[INFO]  $*"; }
success() { echo "[OK]    $*"; }
warn()    { echo "[WARN]  $*"; }
error()   { echo "[ERR]   $*"; exit 1; }

# ─── Detect OS and distro ────────────────────────────────────────────────────
detect_os() {
    OS="$(uname -s)"
    case "${OS}" in
        Darwin) PLATFORM="macos" ;;
        Linux)
            if grep -q "ID=fedora" /etc/os-release 2>/dev/null; then
                PLATFORM="fedora"
            elif grep -q "ID=\"rhel\"\|ID=rhel\|ID=rocky" /etc/os-release 2>/dev/null; then
                PLATFORM="rhel"
            elif grep -q "ID=arch" /etc/os-release 2>/dev/null; then
                PLATFORM="arch"
            else
                PLATFORM="linux"
            fi
            ;;
        *) error "Unsupported OS: ${OS}" ;;
    esac

    # Detect WSL
    if grep -qi microsoft /proc/version 2>/dev/null; then
        WSL=true
    else
        WSL=false
    fi

    info "Platform: ${PLATFORM} (WSL: ${WSL})"
}

# ─── Package installation ─────────────────────────────────────────────────────
install_packages_fedora() {
    info "Installing packages via dnf..."
    sudo dnf install -y \
        neovim \
        git \
        make \
        cmake \
        ninja-build \
        gcc \
        gcc-gfortran \
        python3 \
        python3-pip \
        fd-find \
        ripgrep \
        tree \
        tmux \
        zsh \
        stow \
        curl \
        wget \
        podman
    sudo dnf clean all
    success "dnf packages installed"
}

install_packages_macos() {
    info "Installing packages via Homebrew..."
    if ! command -v brew &>/dev/null; then
        info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    brew install \
        neovim \
        git \
        make \
        cmake \
        ninja \
        gcc \
        python3 \
        fd \
        ripgrep \
        tree \
        tmux \
        zsh \
        stow \
        curl \
        wget \
        podman
    success "Homebrew packages installed"
}

install_packages_arch() {
    info "Installing packages via pacman..."
    sudo pacman -Syu --noconfirm \
        neovim \
        git \
        make \
        cmake \
        ninja \
        gcc \
        gcc-fortran \
        python \
        python-pip \
        fd \
        ripgrep \
        tree \
        tmux \
        zsh \
        stow \
        curl \
        wget \
        podman
    success "pacman packages installed"
}

install_packages() {
    case "${PLATFORM}" in
        fedora|rhel) install_packages_fedora ;;
        macos)       install_packages_macos ;;
        arch)        install_packages_arch ;;
        *)           warn "Unknown platform — skipping package install" ;;
    esac
}

# ─── Python tools ─────────────────────────────────────────────────────────────
install_python_tools() {
    info "Installing Python tools..."
    pip3 install --user fortls fparser
    success "Python tools installed"
}

# ─── Dotfiles ─────────────────────────────────────────────────────────────────
clone_dotfiles() {
    if [[ -d "${DOTFILES_DIR}/.git" ]]; then
        info "Dotfiles already cloned, pulling latest..."
        git -C "${DOTFILES_DIR}" pull
    else
        info "Cloning dotfiles..."
        git clone "${DOTFILES_REPO}" "${DOTFILES_DIR}"
    fi
    success "Dotfiles ready"
}

stow_dotfiles() {
    info "Stowing shared dotfiles..."
    mkdir -p "${HOME}/.config"
    cd "${DOTFILES_DIR}"

    for pkg in shared/*/; do
        pkg_name=$(basename "${pkg}")
        info "Stowing shared/${pkg_name}..."
        stow -d shared -t ~ --restow "${pkg_name}" || warn "Failed to stow ${pkg_name}"
    done

    case "${PLATFORM}" in
        fedora|rhel|arch|linux)
            if [[ -d "${DOTFILES_DIR}/linux" ]]; then
                info "Stowing linux dotfiles..."
                for pkg in linux/*/; do
                    pkg_name=$(basename "${pkg}")
                    stow -d linux -t ~ --restow "${pkg_name}" || warn "Failed to stow linux/${pkg_name}"
                done
            fi
            ;;
        macos)
            if [[ -d "${DOTFILES_DIR}/macos" ]]; then
                info "Stowing macOS dotfiles..."
                for pkg in macos/*/; do
                    pkg_name=$(basename "${pkg}")
                    stow -d macos -t ~ --restow "${pkg_name}" || warn "Failed to stow macos/${pkg_name}"
                done
            fi
            ;;
    esac

    success "Dotfiles stowed"
}

# ─── Shell ────────────────────────────────────────────────────────────────────
set_zsh_default() {
    if [[ "${SHELL}" != "$(command -v zsh)" ]]; then
        info "Setting zsh as default shell..."
        if [[ "${PLATFORM}" == "macos" ]]; then
            chsh -s "$(command -v zsh)"
        else
            sudo chsh -s "$(command -v zsh)" "${USER}"
        fi
        success "zsh set as default shell — restart your terminal"
    else
        success "zsh already default"
    fi
}

# ─── SSH key ──────────────────────────────────────────────────────────────────
setup_ssh_key() {
    KEY="${HOME}/.ssh/id_ed25519"
    if [[ -f "${KEY}" ]]; then
        info "SSH key already exists at ${KEY}"
    else
        info "Generating SSH key..."
        mkdir -p "${HOME}/.ssh"
        chmod 700 "${HOME}/.ssh"
        ssh-keygen -t ed25519 -C "${USER}@$(hostname)" -f "${KEY}" -N ""
        success "SSH key generated"
        echo ""
        info "Add this public key to GitHub and your GitLab instance:"
        cat "${KEY}.pub"
        echo ""
    fi
}

# ─── Main ─────────────────────────────────────────────────────────────────────
main() {
    info "Starting bootstrap..."
    detect_os
    install_packages
    install_python_tools
    clone_dotfiles
    stow_dotfiles
    set_zsh_default
    setup_ssh_key
    success "Bootstrap complete"
    info "Next steps:"
    echo "  1. Restart your terminal (or: exec zsh)"
    echo "  2. Add ~/.ssh/id_ed25519.pub to GitHub and GitLab"
    echo "  3. Launch dev container: ~/dev/configs/devcontainer/dev.sh"
}

main "$@"
