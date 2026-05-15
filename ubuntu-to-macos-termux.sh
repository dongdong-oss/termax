#!/bin/bash

# Termux + Ubuntu 仿 macOS 桌面转换脚本
# 适用于 Termux-PRoot 环境中的 Ubuntu

set -e

echo "========================================="
echo "  Termux Ubuntu macOS 转换脚本"
echo "========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if we're in Termux environment
if [ -d "/data/data/com.termux" ]; then
    TERMUX_HOME="$HOME"
    echo -e "${GREEN}检测到 Termux 环境${NC}"
else
    echo -e "${YELLOW}警告: 未检测到 Termux 环境${NC}"
fi

# Check if running in proot
if [ -n "$PROOT_LOADER" ]; then
    echo -e "${GREEN}检测到 PRoot 环境${NC}"
fi

# Update package lists
echo "Step 1: 更新软件包..."
apt update

# Install basic dependencies
echo "Step 2: 安装基础工具..."
apt install -y wget curl git gnome-tweak-tool gnome-shell-extensions

# Check if GNOME Desktop is installed
if ! command -v gnome-shell &> /dev/null; then
    echo -e "${YELLOW}检测到未安装 GNOME 桌面${NC}"
    echo "请先安装 GNOME 桌面环境："
    echo "  apt install -y ubuntu-desktop"
    echo "或轻量版本："
    echo "  apt install -y gnome-session gnome-panel gnome-settings-daemon"
    echo ""
    read -p "是否继续安装 GNOME 桌面？(y/n): " install_gnome
    if [ "$install_gnome" = "y" ]; then
        apt install -y gnome-session gnome-panel gnome-settings-daemon metacity
    else
        echo "跳过 GNOME 安装，请手动安装后再运行此脚本"
        exit 1
    fi
fi

# Create directories
mkdir -p ~/.themes
mkdir -p ~/.icons
mkdir -p ~/Pictures/Wallpapers

# Download WhiteSur GTK Theme
echo "Step 3: 下载 WhiteSur GTK 主题..."
cd /tmp
if [ ! -d "WhiteSur-gtk-theme" ]; then
    git clone https://github.com/vinceliuice/WhiteSur-gtk-theme.git
fi
cd WhiteSur-gtk-theme
./install.sh -d ~/.themes -t all -c dark -N default -s 150
cd ~
rm -rf /tmp/WhiteSur-gtk-theme

# Download WhiteSur Icons
echo "Step 4: 下载 WhiteSur 图标..."
cd /tmp
if [ ! -d "WhiteSur-icon-theme" ]; then
    git clone https://github.com/vinceliuice/WhiteSur-icon-theme.git
fi
cd WhiteSur-icon-theme
./install.sh -d ~/.icons
cd ~
rm -rf /tmp/WhiteSur-icon-theme

# Download Wallpapers
echo "Step 5: 下载 macOS 壁纸..."
cd /tmp
if [ ! -d "WhiteSur-wallpapers" ]; then
    git clone https://github.com/vinceliuice/WhiteSur-wallpapers.git
    cp WhiteSur-wallpapers/wallpapers/*.jpg ~/Pictures/Wallpapers/ 2>/dev/null || true
    cp WhiteSur-wallpapers/wallpapers/*.png ~/Pictures/Wallpapers/ 2>/dev/null || true
fi
rm -rf /tmp/WhiteSur-wallpapers
cd ~

# Install Dash to Dock
echo "Step 6: 安装 Dash to Dock..."
apt install -y gnome-shell-extension-dash-to-dock

# Install User Themes extension
apt install -y gnome-shell-extension-user-themes

# Configure GNOME Settings
echo "Step 7: 配置 GNOME 设置..."

# Set theme
gsettings set org.gnome.desktop.interface gtk-theme 'WhiteSur-dark'
gsettings set org.gnome.desktop.interface icon-theme 'WhiteSur'

# Set dark mode
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

# Set window button layout (macOS style - left side)
gsettings set org.gnome.desktop.wm.preferences button-layout 'close,minimize,maximize:'

# Set wallpaper
WALLPAPER=$(ls ~/Pictures/Wallpapers/*.jpg 2>/dev/null | head -n 1 || ls ~/Pictures/Wallpapers/*.png 2>/dev/null | head -n 1)
if [ -n "$WALLPAPER" ]; then
    gsettings set org.gnome.desktop.background picture-uri "file://$WALLPAPER"
fi

# Configure Dash to Dock
gsettings set org.gnome.shell.extensions.dash-to-dock autohide true
gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'BOTTOM'
gsettings set org.gnome.shell.extensions.dash-to-dock dock-alignment 'CENTER'

# Enable extensions
gnome-extensions enable dash-to-dock@micxgx.gmail.com 2>/dev/null || true
gnome-extensions enable user-theme@gnome-shell-extensions.gcampax.github.com 2>/dev/null || true

echo ""
echo -e "${GREEN}========================================="
echo "  安装完成！"
echo "=========================================${NC}"
echo ""
echo "下一步操作："
echo "1. 注销并重新登录 GNOME 会话"
echo "2. 打开 '优化工具' (GNOME Tweaks)"
echo "3. 在 '外观' 中设置："
echo "   - 应用程序: WhiteSur-dark"
echo "   - 图标: WhiteSur"
echo "   - 光标: WhiteSur"
echo "   - Shell: WhiteSur-dark"
echo ""
echo "4. 在 '扩展' 中启用 Dash to Dock"
echo ""
echo "恢复默认设置请运行：~/uninstall-macos-theme.sh"

# Create uninstall script
cat > ~/uninstall-macos-theme.sh << 'UNINSTALL_EOF'
#!/bin/bash
echo "恢复 Ubuntu 默认主题..."
gsettings set org.gnome.desktop.interface gtk-theme 'Yaru'
gsettings set org.gnome.desktop.interface icon-theme 'Yaru'
gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close'
echo "完成！请重新登录。"
UNINSTALL_EOF

chmod +x ~/uninstall-macos-theme.sh
