#!/bin/bash

# Update system
sudo apt update && sudo apt -y upgrade

# Install packages
sudo apt install -y \
    apt-transport-https \
    bat \
    build-essential \
    ca-certificates \
    cmake \
    curl \
    fzf \
    git \
    gpg \
    htop \
    neofetch \
    nodejs \
    ripgrep \
    ruby-full \
    software-properties-common \
    tmux \
    tree \
    vim \
    wget \
    zip \
    zsh

# create symlink to bat library
mkdir -p ~/.local/bin
ln -s /usr/bin/batcat ~/.local/bin/bat

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to print messages with colors
print_message() {
    local color=$1
    local message=$2
    case $color in
        "green")  echo -e "\033[0;32m$message\033[0m" ;;
        "yellow") echo -e "\033[1;33m$message\033[0m" ;;
        "red")    echo -e "\033[0;31m$message\033[0m" ;;
        *)        echo "$message" ;;
    esac
}

# Install Rust first as it's required for several other tools
if command_exists rustc; then
    RUST_VERSION=$(rustc --version)
    print_message "green" "Rust is already installed: $RUST_VERSION"
else
    print_message "yellow" "Rust is not installed. Installing now..."
    
    # Check if curl is available
    if ! command_exists curl; then
        print_message "red" "Error: curl is not installed. Please install curl first."
        exit 1
    fi
    
    # Download and run the Rust installation script
    if curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y; then
        print_message "green" "Rust has been successfully installed!"
        
        # Source the cargo environment
        source "$HOME/.cargo/env"
        
        # Verify installation
        if command_exists rustc; then
            NEW_RUST_VERSION=$(rustc --version)
            print_message "green" "Installed Rust version: $NEW_RUST_VERSION"
        else
            print_message "red" "Warning: Rust was installed but rustc command is not available."
            print_message "yellow" "Please restart your terminal or run: source $HOME/.cargo/env"
            exit 1
        fi
    else
        print_message "red" "Error: Failed to install Rust."
        exit 1
    fi
fi

# Ensure cargo is available
if ! command_exists cargo; then
    print_message "red" "Error: cargo is not available. Please restart your terminal or run: source $HOME/.cargo/env"
    exit 1
fi

# Install Zellij (requires Rust)
if command_exists zellij; then
    ZELLIJ_VERSION=$(zellij --version)
    print_message "green" "Zellij is already installed: $ZELLIJ_VERSION"
else
    print_message "yellow" "Installing Zellij..."
    if cargo install zellij; then
        print_message "green" "Zellij installed successfully!"
    else
        print_message "red" "Failed to install Zellij"
    fi
fi

# Install eza (requires Rust)
if command_exists eza; then
    EZA_VERSION=$(eza --version)
    print_message "green" "eza is already installed: $EZA_VERSION"
else
    print_message "yellow" "Installing eza..."
    if cargo install eza; then
        print_message "green" "eza installed successfully!"
    else
        print_message "red" "Failed to install eza"
    fi
fi

# Install Oh My Zsh
if [ -d "$HOME/.oh-my-zsh" ]; then
    print_message "green" "Oh My Zsh is already installed"
else
    print_message "yellow" "Installing Oh My Zsh..."
    if curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | sh; then
        print_message "green" "Oh My Zsh installed successfully!"
    else
        print_message "red" "Failed to install Oh My Zsh"
    fi
fi

# Install Oh My Posh and required fonts
if command_exists oh-my-posh; then
    print_message "green" "Oh My Posh is already installed"
else
    print_message "yellow" "Installing Oh My Posh and required fonts..."
    
    # Create fonts directory if it doesn't exist
    mkdir -p ~/.local/share/fonts
    
    # Install Hack font
    print_message "yellow" "Installing Hack font..."
    wget -O hack.zip https://github.com/source-foundry/Hack/releases/download/v3.003/Hack-v3.003-ttf.zip
    unzip -o hack.zip -d ~/.local/share/fonts/hack
    rm hack.zip
    
    # Install JetBrains Mono Nerd Font
    print_message "yellow" "Installing JetBrains Mono Nerd Font..."
    wget -O jetbrains.zip https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/JetBrainsMono.zip
    unzip -o jetbrains.zip -d ~/.local/share/fonts/jetbrains
    rm jetbrains.zip
    
    # Update font cache
    fc-cache -f -v
    print_message "green" "Fonts installed successfully!"
    
    # Install Oh My Posh
    print_message "yellow" "Installing Oh My Posh..."
    curl -s https://ohmyposh.dev/install.sh | bash -s

    # Add Oh My Posh initialization to .zshrc if not already present
    if ! grep -q "eval \"\$(oh-my-posh init zsh --config 'https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/jandedobbeleer.omp.json')\"" "$HOME/.zshrc"; then
        echo 'eval "$(oh-my-posh init zsh --config '"'https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/jandedobbeleer.omp.json'"')"' >> "$HOME/.zshrc"
        print_message "green" "Added Oh My Posh initialization with JanDeDobbeleer theme to .zshrc"
    fi
fi

# Install neovim
sudo add-apt-repository -y ppa:neovim-ppa/unstable
sudo apt update && sudo apt -y upgrade
sudo apt install -y neovim

# Install Lazygit
LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | \grep -Po '"tag_name": *"v\K[^"]*')
curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
tar xf lazygit.tar.gz lazygit
sudo install lazygit -D -t /usr/local/bin/

# Install colorls via Ruby gems
sudo gem install colorls

# Check if requirements.txt exists before pip install
if [ -f ~/user-default-efs/requirements.txt ]; then
    pip install -r ~/user-default-efs/requirements.txt
else
    echo "Warning: requirements.txt not found in ~/user-default-efs/"
fi

# Change default shell to zsh
if [ "$SHELL" != "$(which zsh)" ]; then
    sudo chsh -s $(which zsh)
    print_message "yellow" "Default shell changed to zsh. Please log out and log back in for changes to take effect."
fi

# Clean up
rm -f lazygit.tar.gz

# Launch zsh
exec zsh