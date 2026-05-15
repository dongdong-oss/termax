#!/bash/bin

# Termux macOS 一键转换脚本 v2.0
# 直接在 Termux 中运行，自动配置完整桌面环境

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

clear
echo -e "${CYAN}╔══════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║  Termux macOS 桌面转换器 v2.0              ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════╝${NC}"
echo ""

# 检查 Termux 环境
check_termux() {
    if [ ! -d "/data/data/com.termux" ] && [ "$PREFIX" = "" ]; then
        echo -e "${RED}错误: 请在 Termux 环境中运行此脚本${NC}"
        exit 1
    fi
}

# 主菜单
show_menu() {
    echo -e "${BOLD}请选择安装模式：${NC}"
    echo ""
    echo -e "  ${GREEN}[1]${NC} 完整安装 (推荐新手) - 安装所有组件"
    echo -e "  ${GREEN}[2]${NC} 仅安装桌面环境"
    echo -e "  ${GREEN}[3]${NC} 仅安装 macOS 主题"
    echo -e "  ${GREEN}[4]${NC} 卸载 macOS 主题"
    echo -e "  ${GREEN}[5]${NC} 启动桌面"
    echo ""
    echo -ne "${BOLD}请输入选项 [1-5]: ${NC}"
}

# 安装 X11 相关包
install_x11() {
    echo -e "\n${BLUE}▶ 安装 X11 环境...${NC}"
    pkg update -y
    pkg install -y x11-repo
    pkg install -y xfce4 xfce4-goodies xorgxrdp tigervnc dbus-x11
    
    # 安装 Termux:X11 启动脚本
    cat > "$PREFIX/bin/startxfce4" << 'STARTXFCE4'
#!/bin/bash
export DISPLAY=:1
vncserver :1 -geometry 1920x1080 -dpi 124 2>/dev/null || true
dbus-launch --exit-with-session startxfce4 &
sleep 2
echo -e "\n✅ 桌面已启动！"
echo "连接方式："
echo "1. Termux:X11 (推荐)"
echo "2. VNC Viewer 连接 localhost:5901"
echo ""
while pgrep -f "xfce4-session" > /dev/null; do
    sleep 10
done
echo "桌面会话已结束"
STARTXFCE4
    chmod +x "$PREFIX/bin/startxfce4"
}

# 安装 macOS 主题
install_macos_theme() {
    echo -e "\n${BLUE}▶ 安装 macOS 风格主题...${NC}"
    
    # 安装主题和图标目录
    mkdir -p ~/.local/share/themes
    mkdir -p ~/.local/share/icons
    mkdir -p ~/Pictures
    
    # 下载 WhiteSur GTK 主题
    echo "下载 WhiteSur GTK 主题..."
    cd /tmp
    rm -rf WhiteSur-gtk-theme
    git clone --depth 1 https://github.com/vinceliuice/WhiteSur-gtk-theme.git
    cd WhiteSur-gtk-theme
    ./install.sh -d ~/.local/share/themes -t all -c dark -N default -s 150 2>/dev/null || true
    cd ~
    rm -rf /tmp/WhiteSur-gtk-theme
    
    # 下载 WhiteSur 图标
    echo "下载 WhiteSur 图标..."
    cd /tmp
    rm -rf WhiteSur-icon-theme
    git clone --depth 1 https://github.com/vinceliuice/WhiteSur-icon-theme.git
    cd WhiteSur-icon-theme
    ./install.sh -d ~/.local/share/icons 2>/dev/null || true
    cd ~
    rm -rf /tmp/WhiteSur-icon-theme
    
    # 下载 macOS 壁纸
    echo "下载 macOS 壁纸..."
    cd /tmp
    rm -rf WhiteSur-wallpapers
    git clone --depth 1 https://github.com/vinceliuice/WhiteSur-wallpapers.git
    cp WhiteSur-wallpapers/wallpapers/*.jpg ~/Pictures/ 2>/dev/null || true
    cp WhiteSur-wallpapers/wallpapers/*.png ~/Pictures/ 2>/dev/null || true
    cp WhiteSur-wallpapers/backgrounds/*.jpg ~/Pictures/ 2>/dev/null || true
    rm -rf /tmp/WhiteSur-wallpapers
    cd ~
    
    # 配置 GTK 主题
    echo "配置主题..."
    cat > ~/.config/gtk-3.0/settings.ini << 'GTKCONF'
[Settings]
gtk-theme-name=WhiteSur-dark
gtk-icon-theme-name=WhiteSur
gtk-font-name=Sans 10
gtk-cursor-theme-name=WhiteSur
gtk-cursor-theme-size=24
gtk-toolbar-style=GTK_TOOLBAR_BOTH_HORIZ
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=0
gtk-menu-images=0
gtk-enable-event-sounds=1
gtk-enable-input-feedback-sounds=0
gtk-xft-antialias=1
gtk-xft-hintstyle=hintslight
gtk-xft-rgba=rgb
gtk-application-prefer-dark-theme=1
GTKCONF
    
    # 创建 GTK4 配置
    mkdir -p ~/.config/gtk-4.0
    cat > ~/.config/gtk-4.0/settings.ini << 'GTK4CONF'
[Settings]
gtk-theme-name=WhiteSur-dark
gtk-icon-theme-name=WhiteSur
gtk-font-name=Sans 10
gtk-application-prefer-dark-theme=1
GTK4CONF
    
    # 配置 XFCE4 外观
    mkdir -p ~/.config/xfce4
    cat > ~/.config/xfce4/xfwm4/xfwm4.xml << 'XFWMCONF'
<?xml version="1.0" encoding="UTF-8"?>
<xfconf-channel type="monitor" version="1.0">
  <property name="general" type="empty">
    <property name="button_layout" type="string" value="O|FSMC"/>
    <property name="title_alignment" type="string" value="center"/>
    <property name="snap_to_windows" type="bool" value="true"/>
    <property name="wrap_windows" type="bool" value="true"/>
    <property name="click_to_raise" type="bool" value="false"/>
    <property name="raise_on_click" type="bool" value="true"/>
    <property name="raise_on_focus" type="bool" value="false"/>
    <property name="focus_delay" type="int" value="0"/>
    <property name="raise_delay" type="int" value="0"/>
    <property name="maximized_offset" type="int" value="0"/>
    <property name="cycle_minimized" type="bool" value="true"/>
    <property name="cycle_minimized" type="bool" value="true"/>
    <property name="workspace_count" type="int" value="2"/>
    <property name="theme" type="string" value="WhiteSur-dark"/>
  </property>
</xfconf-channel>
XFWMCONF
    
    # 配置 XFCE4 面板为 macOS 风格底部 Dock
    mkdir -p ~/.config/xfce4/panel
    cat > ~/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml << 'PANELCONF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-panel" version="1.0">
  <property name="panels" type="array">
    <value type="int">1</value>
  </property>
  <property name="panel-1" type="empty">
    <property name="position" type="string">p=6;x=0;y=-50</property>
    <property name="length" type="int">100</property>
    <property name="position-locked" type="bool">true</property>
    <property name="level" type="int">100</property>
    <property name="autohide-behavior" type="uint">1</property>
    <property name="size" type="uint">48</property>
    <property name="plugin-ids" type="array">
      <value type="int">1</value>
      <value type="int">2</value>
      <value type="int">3</value>
    </property>
  </property>
  <property name="plugin-1" type="string">launcher</property>
  <property name="plugin-2" type="string">tasklist</property>
  <property name="plugin-3" type="string">pager</property>
</channel>
PANELCONF
    
    # 配置桌面背景
    WALLPAPER=$(ls ~/Pictures/*.jpg 2>/dev/null | head -1 || ls ~/Pictures/*.png 2>/dev/null | head -1)
    if [ -n "$WALLPAPER" ]; then
        cat > ~/.config/xfce4/xfconf/xfce-perchannel-xml/xfdesktop.xml << 'DESKTOPCONF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-desktop" version="1.0">
  <property name="backdrop" type="empty">
    <property name="screen0" type="empty">
      <property name="monitor0" type="empty">
        <property name="image-path" type="string">'"$WALLPAPER"'</property>
        <property name="image-style" type="int">6</property>
      </property>
    </property>
  </property>
</channel>
DESKTOPCONF
    fi
    
    # 配置窗口管理器主题
    mkdir -p ~/.config/xfce4/xfconf/xfce-perchannel-xml
    cat > ~/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml << 'XFWM4CONF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0">
  <property name="general" type="empty">
    <property name="button_layout" type="string" value="O|SHMC"/>
    <property name="title_alignment" type="string" value="center"/>
    <property name="theme" type="string">WhiteSur-dark</property>
  </property>
</channel>
XFWM4CONF
    
    # 配置 Thunar 文件管理器
    mkdir -p ~/.config/Thunar
    cat > ~/.config/xfce4/xfconf/xfce-perchannel-xml/thunar.xml << 'THUNARCONF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="thunar" version="1.0">
  <property name="last-view" type="string">ThunarDetailsView</property>
  <property name="last-icon-view-zoom" type="int">2</property>
</channel>
THUNARCONF
    
    echo -e "${GREEN}✅ macOS 主题安装完成！${NC}"
}

# 完整安装
full_install() {
    echo -e "\n${BOLD}${GREEN}▶ 开始完整安装...${NC}\n"
    
    echo -e "${YELLOW}步骤 1/3: 安装 X11 环境...${NC}"
    install_x11
    
    echo -e "\n${YELLOW}步骤 2/3: 安装 macOS 主题...${NC}"
    install_macos_theme
    
    echo -e "\n${YELLOW}步骤 3/3: 配置桌面设置...${NC}"
    
    # 创建快速启动脚本
    cat > "$PREFIX/bin/macos" << 'MACOSSHORTCUT'
#!/bin/bash
echo -e "\n启动 macOS 风格桌面..."
echo "请在 Termux:X11 或 VNC Viewer 中查看"
echo "VNC 地址: localhost:5901"
startxfce4
MACOSSHORTCUT
    chmod +x "$PREFIX/bin/macos"
    
    # 创建卸载脚本
    cat > "$PREFIX/bin/uninstall-macos" << 'UNINSTALL'
#!/bin/bash
echo "卸载 macOS 主题..."
rm -rf ~/.local/share/themes/WhiteSur*
rm -rf ~/.local/share/icons/WhiteSur*
rm -rf ~/.config/xfce4/xfwm4/xfwm4.xml
rm -rf ~/.config/gtk-3.0/settings.ini
rm -rf ~/.config/gtk-4.0/settings.ini
echo "已卸载！"
UNINSTALL
    chmod +x "$PREFIX/bin/uninstall-macos"
    
    echo -e "\n${GREEN}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║           🎉 安装完成！                      ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BOLD}启动桌面：${NC}"
    echo "  方式1: ${CYAN}termux-x11${NC}"
    echo "  方式2: ${CYAN}vncviewer localhost:5901${NC}"
    echo "  方式3: 直接运行 ${CYAN}macos${NC}"
    echo ""
    echo -e "${BOLD}其他命令：${NC}"
    echo "  ${CYAN}startxfce4${NC}  - 启动桌面"
    echo "  ${CYAN}vncserver :1${NC} - 启动 VNC"
    echo "  ${CYAN}vncserver -kill :1${NC} - 停止 VNC"
    echo "  ${CYAN}uninstall-macos${NC} - 卸载 macOS 主题"
    echo ""
}

# 仅安装桌面
install_desktop_only() {
    echo -e "\n${BLUE}▶ 安装桌面环境...${NC}"
    install_x11
    echo -e "${GREEN}✅ 桌面环境安装完成！${NC}"
    echo "运行 ${CYAN}startxfce4${NC} 启动桌面"
}

# 仅安装主题
install_theme_only() {
    install_macos_theme
}

# 卸载
uninstall() {
    echo -e "\n${YELLOW}▶ 卸载 macOS 主题...${NC}"
    rm -rf ~/.local/share/themes/WhiteSur*
    rm -rf ~/.local/share/icons/WhiteSur*
    rm -f ~/.config/xfce4/xfwm4/xfwm4.xml
    rm -f ~/.config/gtk-3.0/settings.ini
    rm -f ~/.config/gtk-4.0/settings.ini
    echo -e "${GREEN}✅ 卸载完成！${NC}"
}

# 启动桌面
start_desktop() {
    if command -v startxfce4 &> /dev/null; then
        echo -e "\n${GREEN}启动 macOS 风格桌面...${NC}"
        echo ""
        echo "连接方式："
        echo "  1. Termux:X11 (推荐) - 自动连接"
        echo "  2. VNC Viewer - 连接 localhost:5901"
        echo ""
        startxfce4
    else
        echo -e "${RED}错误: 桌面环境未安装${NC}"
        echo "请先选择选项 1 进行完整安装"
    fi
}

# 主程序
main() {
    check_termux
    
    if [ "$1" != "" ]; then
        # 命令行参数模式
        case $1 in
            1|"full")
                full_install
                ;;
            2|"desktop")
                install_desktop_only
                ;;
            3|"theme")
                install_theme_only
                ;;
            4|"uninstall")
                uninstall
                ;;
            5|"start")
                start_desktop
                ;;
            *)
                echo -e "${RED}未知参数: $1${NC}"
                ;;
        esac
    else
        # 交互模式
        show_menu
        read choice
        case $choice in
            1)
                full_install
                ;;
            2)
                install_desktop_only
                ;;
            3)
                install_theme_only
                ;;
            4)
                uninstall
                ;;
            5)
                start_desktop
                ;;
            *)
                echo -e "\n${RED}无效选项${NC}"
                exit 1
                ;;
        esac
    fi
}

main "$@"
