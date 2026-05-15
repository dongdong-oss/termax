#!/bin/bash

# Ubuntu to macOS Transformation Script
# This script transforms Ubuntu desktop to look like macOS

set -e

echo "========================================="
echo "  Ubuntu macOS Transformation Script"
echo "========================================="
echo ""

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root or with sudo"
    exit 1
fi

# Detect desktop environment
if [ "$XDG_CURRENT_DESKTOP" = "ubuntu:GNOME" ] || [ "$XDG_CURRENT_DESKTOP" = "GNOME" ]; then
    DE="gnome"
elif [ "$XDG_CURRENT_DESKTOP" = "X-Cinnamon" ]; then
    DE="cinnamon"
else
    DE="unknown"
    echo "Warning: Unsupported desktop environment: $XDG_CURRENT_DESKTOP"
fi

echo "Detected Desktop Environment: $DE"
echo ""

# Update system
echo "Step 1: Updating system packages..."
apt update && apt upgrade -y

# Install required packages
echo "Step 2: Installing required packages..."
apt install -y wget curl git gnome-tweaks gnome-shell-extensions chrome-gnome-shell

# Install GNOME Shell Extension Manager if not present
if ! command -y gnome-extensions &> /dev/null; then
    echo "Installing GNOME Extensions Manager..."
    apt install -y gnome-shell-extension-manager 2>/dev/null || true
fi

# Create themes directory
mkdir -p ~/.themes
mkdir -p ~/.icons
mkdir -p ~/Pictures/Wallpapers

# Download WhiteSur GTK Theme (macOS Big Sur style)
echo "Step 3: Installing WhiteSur GTK Theme..."
if [ ! -d ~/.themes/WhiteSur-dark ]; then
    cd /tmp
    git clone https://github.com/vinceliuice/WhiteSur-gtk-theme.git
    cd WhiteSur-gtk-theme
    ./install.sh -d ~/.themes -t all -c dark -N stable -s 200
    ./install.sh -d ~/.themes -t all -c light -N stable -s 200
    cd ~
    rm -rf /tmp/WhiteSur-gtk-theme
else
    echo "WhiteSur theme already installed"
fi

# Download WhiteSur Icons
echo "Step 4: Installing WhiteSur Icons..."
if [ ! -d ~/.icons/WhiteSur ]; then
    cd /tmp
    git clone https://github.com/vinceliuice/WhiteSur-icon-theme.git
    cd WhiteSur-icon-theme
    ./install.sh -d ~/.icons
    cd ~
    rm -rf /tmp/WhiteSur-icon-theme
else
    echo "WhiteSur icons already installed"
fi

# Install WhiteSur Wallpapers
echo "Step 5: Installing macOS Wallpapers..."
cd /tmp
if [ ! -d WhiteSur-wallpapers ]; then
    git clone https://github.com/vinceliuice/WhiteSur-wallpapers.git
    cp WhiteSur-wallpapers/wallpapers/*.jpg ~/Pictures/Wallpapers/ 2>/dev/null || true
    cp WhiteSur-wallpapers/wallpapers/*.png ~/Pictures/Wallpapers/ 2>/dev/null || true
    rm -rf WhiteSur-wallpapers
fi
cd ~

# Install McMojave Wallpapers as backup
echo "Step 6: Installing McMojave Wallpapers..."
cd /tmp
if [ ! -d McMojave-wallpapers ]; then
    git clone https://github.com/vinceliuice/McMojave-wallpapers.git
    cp McMojave-wallpapers/*.jpg ~/Pictures/Wallpapers/ 2>/dev/null || true
    cp McMojave-wallpapers/*.png ~/Pictures/Wallpapers/ 2>/dev/null || true
    rm -rf McMojave-wallpapers
fi
cd ~

# Install Dash to Dock (GNOME)
echo "Step 7: Installing Dash to Dock..."
if [ "$DE" = "gnome" ]; then
    gnome-extensions enable dash-to-dock@micxgx.gmail.com 2>/dev/null || true
fi

# Install Plank Dock (Alternative macOS-style dock)
echo "Step 8: Installing Plank Dock..."
apt install -y plank

# Configure GNOME Settings
echo "Step 9: Configuring GNOME Settings..."

# Set theme
gsettings set org.gnome.desktop.interface gtk-theme 'WhiteSur-dark'
gsettings set org.gnome.desktop.interface icon-theme 'WhiteSur'

# Set cursor theme
gsettings set org.gnome.desktop.interface cursor-theme 'WhiteSur-cursors'

# Set dark mode
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

# Set font to macOS-like
gsettings set org.gnome.desktop.interface font-name 'SF Pro Display 11'
gsettings set org.gnome.desktop.interface document-font-name 'SF Pro Text 11'
gsettings set org.gnome.desktop.interface monospace-font-name 'SF Mono 11'

# Configure GNOME Shell to hide top bar except on hover
gsettings set org.gnome.shell.extensions.dash-to-dock autohide true
gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'BOTTOM'
gsettings set org.gnome.shell.extensions.dash-to-dock dock-alignment 'CENTER'

# Set window button layout (close, minimize, maximize on left - macOS style)
gsettings set org.gnome.desktop.wm.preferences button-layout 'close,minimize,maximize:'

# Disable window titles centered
gsettings set org.gnome.desktop.wm.preferences titlebar-center-layout true

# Set wallpaper (choose one of the macOS wallpapers)
if [ -f ~/Pictures/Wallpapers/BigSur-light.jpg ]; then
    gsettings set org.gnome.desktop.background picture-uri "file:///home/$SUDO_USER/Pictures/Wallpapers/BigSur-light.jpg"
    gsettings set org.gnome.desktop.background picture-uri-dark "file:///home/$SUDO_USER/Pictures/Wallpapers/BigSur-dark.jpg"
fi

# Enable dark mode for desktop
gsettings set org.gnome.desktop.background primary-color '#000000'

echo "Step 10: Installing GNOME Shell Extensions..."

# Install User Themes extension
apt install -y gnome-shell-extension-user-theme

# Install Top Bar Extensions
if ! gnome-extensions list | grep -q "hidetopbar"; then
    wget -q https://extensions.gnome.org/extension-data/hidetopbar@philip.scot/hidetopbar@philip.scot.v46.shell-extension.zip -O /tmp/hidetopbar.zip
    gnome-extensions install --force /tmp/hidetopbar.zip 2>/dev/null || true
    rm /tmp/hidetopbar.zip
fi

# Install Blur My Shell (for transparent panels)
if ! gnome-extensions list | grep -q "blur-my-shell"; then
    wget -q https://extensions.gnome.org/extension-data/blur-my-shell@aunetx/blur-my-shell@aunetx.v69.shell-extension.zip -O /tmp/blur-my-shell.zip
    gnome-extensions install --force /tmp/blur-my-shell.zip 2>/dev/null || true
    rm /tmp/blur-my-shell.zip
fi

echo ""
echo "========================================="
echo "  Installation Complete!"
echo "========================================="
echo ""
echo "Next Steps:"
echo "1. Log out and log back in"
echo "2. Open 'GNOME Tweaks' and configure:"
echo "   - Enable 'User Themes' extension"
echo "   - Set shell theme to 'WhiteSur-dark'"
echo "3. For macOS Dock:"
echo "   - Run 'plank' from applications"
echo "   - Right-click dock → Preferences"
echo "   - Enable 'Dock on top'"
echo "   - Set theme to transparent/docky"
echo "4. Restart GNOME Shell (Alt+F2, type 'r', Enter)"
echo ""
echo "To revert changes:"
echo "   ./uninstall-macos-theme.sh"
echo ""

# Create uninstall script
cat > ~/uninstall-macos-theme.sh << 'UNINSTALL_EOF'
#!/bin/bash

echo "Reverting to default Ubuntu theme..."

# Revert themes
gsettings set org.gnome.desktop.interface gtk-theme 'Yaru'
gsettings set org.gnome.desktop.interface icon-theme 'Yaru'
gsettings set org.gnome.desktop.interface cursor-theme 'Yaru'

# Revert fonts
gsettings set org.gnome.desktop.interface font-name 'Ubuntu 11'
gsettings set org.gnome.desktop.interface document-font-name 'Ubuntu 11'
gsettings set org.gnome.desktop.interface monospace-font-name 'Ubuntu Mono 11'

# Revert window buttons
gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close'

echo "Theme reverted. Please log out and log back in."
UNINSTALL_EOF

chmod +x ~/uninstall-macos-theme.sh

echo "Uninstall script created: ~/uninstall-macos-theme.sh"
