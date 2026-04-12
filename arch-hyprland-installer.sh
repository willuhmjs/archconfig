#!/bin/bash
# Arch Linux Hyprland Workstation Interactive Installer
# A guided TUI installer for setting up a complete Hyprland desktop environment
# Based on the ansible configuration but adapted to work on any machine

set -e

# Colors for pretty output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Configuration variables (to be set by user)
USER_HOME="${HOME}"
GPU_TYPE=""
MONITOR_CONFIG=""
INSTALL_NVIDIA=false
INSTALL_DISCORD=false
INSTALL_FIREFOX=false
ENABLE_ANIMATIONS=true
ENABLE_BLUR=true
HAS_TOUCHPAD=false
NATURAL_SCROLL=false
SCALE_FACTOR="1.0"

# Helper functions
print_header() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  ${BOLD}Arch Linux Hyprland Workstation Installer${NC}               ${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_step() {
    echo -e "\n${BLUE}▶${NC} ${BOLD}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${CYAN}ℹ${NC} $1"
}

prompt_yes_no() {
    local prompt="$1"
    local default="${2:-n}"
    local response

    if [[ "$default" == "y" ]]; then
        echo -en "${YELLOW}?${NC} $prompt [Y/n]: "
    else
        echo -en "${YELLOW}?${NC} $prompt [y/N]: "
    fi

    read -r response
    response=${response,,} # to lowercase

    if [[ -z "$response" ]]; then
        response="$default"
    fi

    [[ "$response" == "y" || "$response" == "yes" ]]
}

prompt_choice() {
    local prompt="$1"
    shift
    local options=("$@")
    local choice

    echo -e "${YELLOW}?${NC} $prompt"
    for i in "${!options[@]}"; do
        echo "  $((i+1))) ${options[$i]}"
    done

    while true; do
        echo -n "Enter choice [1-${#options[@]}]: "
        read -r choice

        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#options[@]}" ]; then
            echo "${options[$((choice-1))]}"
            return 0
        else
            print_error "Invalid choice. Please try again."
        fi
    done
}

prompt_input() {
    local prompt="$1"
    local default="$2"
    local response

    if [[ -n "$default" ]]; then
        echo -en "${YELLOW}?${NC} $prompt [${default}]: "
    else
        echo -en "${YELLOW}?${NC} $prompt: "
    fi

    read -r response

    if [[ -z "$response" && -n "$default" ]]; then
        echo "$default"
    else
        echo "$response"
    fi
}

detect_gpu() {
    print_step "Detecting GPU Hardware"

    local nvidia_detected=false
    local amd_detected=false
    local intel_detected=false

    if lspci | grep -i vga | grep -iq nvidia; then
        nvidia_detected=true
        print_info "NVIDIA GPU detected"
    fi

    if lspci | grep -i vga | grep -iq amd; then
        amd_detected=true
        print_info "AMD GPU detected"
    fi

    if lspci | grep -i vga | grep -iq intel; then
        intel_detected=true
        print_info "Intel GPU detected"
    fi

    echo ""
    GPU_TYPE=$(prompt_choice "Select your GPU configuration:" \
        "NVIDIA (proprietary drivers)" \
        "AMD (mesa)" \
        "Intel (mesa)" \
        "Hybrid NVIDIA + Intel" \
        "None / Other")

    case "$GPU_TYPE" in
        "NVIDIA (proprietary drivers)"|"Hybrid NVIDIA + Intel")
            INSTALL_NVIDIA=true
            ;;
    esac
}

detect_monitors() {
    print_step "Monitor Configuration"

    print_info "Detecting connected displays..."

    # Try to detect monitors if in a graphical environment
    if command -v wlr-randr &> /dev/null; then
        echo -e "\n${CYAN}Current displays:${NC}"
        wlr-randr | grep -E "^[^ ]" || true
    elif command -v xrandr &> /dev/null 2>&1; then
        echo -e "\n${CYAN}Current displays:${NC}"
        xrandr | grep " connected" || true
    else
        print_warning "Cannot detect displays (not in graphical environment)"
        print_info "This is normal if you're in TTY. We'll configure monitors manually."
    fi

    echo ""
    local setup_type=$(prompt_choice "Select your monitor setup:" \
        "Laptop (single built-in display)" \
        "Desktop (single external monitor)" \
        "Desktop (multiple monitors - manual configuration)" \
        "Auto-detect (let Hyprland handle it)")

    MONITOR_CONFIG="$setup_type"

    if [[ "$MONITOR_CONFIG" == "Laptop (single built-in display)" ]]; then
        HAS_TOUCHPAD=true
        SCALE_FACTOR=$(prompt_input "HiDPI scale factor (1.0 for 1080p, 1.25-2.0 for 4K)" "1.0")
    fi

    if [[ "$HAS_TOUCHPAD" == true ]]; then
        if prompt_yes_no "Enable natural (reverse) scrolling for touchpad?" "y"; then
            NATURAL_SCROLL=true
        fi
    fi
}

gather_preferences() {
    print_header
    print_step "Installation Preferences"

    echo -e "${CYAN}Let's customize your installation!${NC}\n"

    if prompt_yes_no "Install Firefox?" "y"; then
        INSTALL_FIREFOX=true
    fi

    if prompt_yes_no "Install Discord?" "y"; then
        INSTALL_DISCORD=true
    fi

    if prompt_yes_no "Enable window animations? (disable for better performance)" "y"; then
        ENABLE_ANIMATIONS=true
    fi

    if prompt_yes_no "Enable blur effects? (disable for better performance)" "y"; then
        ENABLE_BLUR=true
    fi
}

show_summary() {
    print_header
    print_step "Installation Summary"

    echo -e "${CYAN}Please review your configuration:${NC}\n"
    echo -e "  ${BOLD}GPU:${NC}           $GPU_TYPE"
    echo -e "  ${BOLD}NVIDIA Drivers:${NC} $([[ $INSTALL_NVIDIA == true ]] && echo 'Yes' || echo 'No')"
    echo -e "  ${BOLD}Monitor Setup:${NC}  $MONITOR_CONFIG"
    echo -e "  ${BOLD}Scale Factor:${NC}   $SCALE_FACTOR"
    echo -e "  ${BOLD}Touchpad:${NC}       $([[ $HAS_TOUCHPAD == true ]] && echo "Yes (Natural scroll: $NATURAL_SCROLL)" || echo 'No')"
    echo -e "  ${BOLD}Firefox:${NC}        $([[ $INSTALL_FIREFOX == true ]] && echo 'Yes' || echo 'No')"
    echo -e "  ${BOLD}Discord:${NC}        $([[ $INSTALL_DISCORD == true ]] && echo 'Yes' || echo 'No')"
    echo -e "  ${BOLD}Animations:${NC}     $([[ $ENABLE_ANIMATIONS == true ]] && echo 'Yes' || echo 'No')"
    echo -e "  ${BOLD}Blur Effects:${NC}   $([[ $ENABLE_BLUR == true ]] && echo 'Yes' || echo 'No')"

    echo ""
    if ! prompt_yes_no "Proceed with installation?" "y"; then
        print_error "Installation cancelled by user"
        exit 1
    fi
}

install_packages() {
    print_header
    print_step "Installing Core Packages"

    print_info "Updating package database..."
    sudo pacman -Sy

    # Core packages (always installed)
    local core_packages=(
        git base-devel
        bluez bluez-utils
        waybar wofi mako
        hyprlock hypridle
        cliphist
        polkit-kde-agent
        xdg-desktop-portal-hyprland
        grim slurp wl-clipboard
        kitty dolphin
        pipewire pipewire-pulse wireplumber pipewire-alsa pipewire-jack sof-firmware alsa-ucm-conf
        network-manager-applet
        blueman pavucontrol
        playerctl brightnessctl pamixer
        power-profiles-daemon
        mpv btop
        ttf-jetbrains-mono-nerd otf-font-awesome
        rsync wlr-randr
        qt5-graphicaleffects qt5-quickcontrols2 qt5-svg
        uwsm greetd greetd-tuigreet terminus-font
    )

    print_info "Removing conflicting packages if present..."
    sudo pacman -Rdd --noconfirm jack2 2>/dev/null || true

    print_info "Installing core packages..."
    sudo pacman -S --needed --noconfirm "${core_packages[@]}"

    # Optional packages
    local optional_packages=()

    if [[ $INSTALL_FIREFOX == true ]]; then
        optional_packages+=(firefox)
    fi

    if [[ $INSTALL_DISCORD == true ]]; then
        optional_packages+=(discord)
    fi

    if [ ${#optional_packages[@]} -gt 0 ]; then
        print_info "Installing optional packages: ${optional_packages[*]}"
        sudo pacman -S --needed --noconfirm "${optional_packages[@]}"
    fi

    # NVIDIA drivers
    if [[ $INSTALL_NVIDIA == true ]]; then
        print_info "Installing NVIDIA drivers..."
        sudo pacman -S --needed --noconfirm nvidia-dkms nvidia-utils libva-nvidia-driver

        print_info "Configuring NVIDIA for Wayland..."
        sudo mkdir -p /etc/modprobe.d
        echo "options nvidia_drm modeset=1 fbdev=1" | sudo tee /etc/modprobe.d/nvidia.conf

        print_warning "IMPORTANT: You'll need to regenerate initramfs after installation"
        print_info "Run: sudo mkinitcpio -P"
    fi

    print_success "Core packages installed"
}

install_aur_helper() {
    print_header
    print_step "Installing AUR Helper (yay)"

    if command -v yay &> /dev/null; then
        print_success "yay is already installed"
        return 0
    fi

    print_info "Cloning yay repository..."
    rm -rf /tmp/yay
    git clone https://aur.archlinux.org/yay.git /tmp/yay

    print_info "Building yay..."
    cd /tmp/yay
    makepkg -si --noconfirm
    cd - > /dev/null

    print_success "yay installed successfully"
}

install_aur_packages() {
    print_header
    print_step "Installing AUR Packages"

    local aur_packages=(
        hyprland-git
        avizo
        nwg-look
        nwg-displays
        wlogout
        awww
    )

    print_info "Installing AUR packages: ${aur_packages[*]}"
    print_warning "This may take a while as packages are built from source..."

    # Temporarily allow passwordless sudo for pacman (yay needs this)
    echo "$USER ALL=(ALL) NOPASSWD: /usr/bin/pacman" | sudo tee /etc/sudoers.d/10-installer-pacman
    sudo chmod 0440 /etc/sudoers.d/10-installer-pacman

    print_info "Removing conflicting hyprland packages before installing git versions..."
    for pkg in hyprland hyprutils hyprlang hyprcursor hyprwayland-scanner aquamarine hyprwire; do sudo pacman -Rdd --noconfirm $pkg 2>/dev/null || true; done

    yay -S --needed --noconfirm "${aur_packages[@]}"

    # Remove temporary sudo rule
    sudo rm -f /etc/sudoers.d/10-installer-pacman

    print_success "AUR packages installed"
}

create_directories() {
    print_step "Creating Configuration Directories"

    local config_dirs=(
        hypr waybar wofi kitty
        wallpapers avizo
    )

    for dir in "${config_dirs[@]}"; do
        mkdir -p "${USER_HOME}/.config/${dir}"
        print_success "Created ~/.config/${dir}"
    done

    # Create empty monitors.conf to prevent Hyprland crash
    touch "${USER_HOME}/.config/hypr/monitors.conf"

    # Create system backgrounds directory
    sudo mkdir -p /usr/share/backgrounds
}

generate_hyprland_config() {
    print_step "Generating Hyprland Configuration"

    local config_file="${USER_HOME}/.config/hypr/hyprland.conf"

    # Generate monitor configuration
    local monitor_line="monitor=,preferred,auto,${SCALE_FACTOR}"

    case "$MONITOR_CONFIG" in
        "Laptop (single built-in display)")
            monitor_line="monitor=,highres,auto,${SCALE_FACTOR}"
            ;;
        "Desktop (single external monitor)")
            monitor_line="monitor=,preferred,auto,${SCALE_FACTOR}"
            ;;
        "Desktop (multiple monitors - manual configuration)")
            monitor_line="# Configure your monitors manually below or use nwg-displays\nmonitor=,preferred,auto,${SCALE_FACTOR}"
            ;;
        "Auto-detect (let Hyprland handle it)")
            monitor_line="monitor=,preferred,auto,${SCALE_FACTOR}"
            ;;
    esac

    # Generate environment variables based on GPU
    local env_vars=""
    case "$GPU_TYPE" in
        "NVIDIA (proprietary drivers)"|"Hybrid NVIDIA + Intel")
            env_vars="env = LIBVA_DRIVER_NAME,nvidia
env = XDG_SESSION_TYPE,wayland
env = GBM_BACKEND,nvidia-drm
env = __GLX_VENDOR_LIBRARY_NAME,nvidia
env = ELECTRON_OZONE_PLATFORM_HINT,auto"
            ;;
        "AMD (mesa)")
            env_vars="env = LIBVA_DRIVER_NAME,radeonsi
env = XDG_SESSION_TYPE,wayland
env = ELECTRON_OZONE_PLATFORM_HINT,auto"
            ;;
        "Intel (mesa)")
            env_vars="env = LIBVA_DRIVER_NAME,i965
env = XDG_SESSION_TYPE,wayland
env = ELECTRON_OZONE_PLATFORM_HINT,auto"
            ;;
        *)
            env_vars="env = XDG_SESSION_TYPE,wayland
env = ELECTRON_OZONE_PLATFORM_HINT,auto"
            ;;
    esac

    # Input configuration
    local input_config="input {
    kb_layout = us
"

    if [[ $HAS_TOUCHPAD == true ]]; then
        input_config+="    touchpad {
        natural_scroll = $([[ $NATURAL_SCROLL == true ]] && echo 'true' || echo 'false')
    }
"
    fi

    input_config+="}"

    # Animations
    local animations_config=""
    if [[ $ENABLE_ANIMATIONS == true ]]; then
        animations_config="animations {
    enabled = true
    bezier = overshot, 0.05, 0.9, 0.1, 1.05
    bezier = smoothOut, 0.36, 0, 0.66, -0.56
    bezier = smoothIn, 0.25, 1, 0.5, 1

    animation = windows, 1, 5, overshot, slide
    animation = windowsOut, 1, 4, smoothOut, slide
    animation = windowsMove, 1, 4, default
    animation = border, 1, 10, default
    animation = fade, 1, 10, smoothIn
    animation = fadeDim, 1, 10, smoothIn
    animation = workspaces, 1, 6, default
}"
    else
        animations_config="animations {
    enabled = false
}"
    fi

    # Blur configuration
    local blur_config=""
    if [[ $ENABLE_BLUR == true ]]; then
        blur_config="    blur {
        enabled = true
        size = 12
        passes = 4
        new_optimizations = true
        ignore_opacity = true
        xray = true
    }"
    else
        blur_config="    blur {
        enabled = false
    }"
    fi

    # Generate the full config file
    cat > "$config_file" << EOF
# Monitor Configuration
${monitor_line}
source = ~/.config/hypr/monitors.conf

# Environment Variables
${env_vars}
env = GTK_THEME,adw-gtk3-dark

# Dark theme by default
exec = gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
exec = gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'

# Input Configuration
${input_config}

general {
    gaps_in = 6
    gaps_out = 12
    border_size = 2
    col.active_border = rgba(555555aa) rgba(888888aa) 45deg
    col.inactive_border = rgba(222222aa)
    resize_on_border = true
    hover_icon_on_border = true
}

decoration {
    rounding = 12
${blur_config}
    shadow {
        enabled = true
        range = 20
        render_power = 3
        color = rgba(00000088)
    }
}

${animations_config}

# Mouse bindings
bindm = SUPER, mouse:272, movewindow
bindm = SUPER, mouse:273, resizewindow

# Application keybinds
bind = SUPER, RETURN, exec, kitty
bind = SUPER, Q, killactive,
bind = SUPER, SPACE, exec, wofi --show drun
bind = SUPER, E, exec, dolphin
EOF

    if [[ $INSTALL_FIREFOX == true ]]; then
        echo "bind = SUPER, B, exec, firefox" >> "$config_file"
    fi

    if [[ $INSTALL_DISCORD == true ]]; then
        echo "bind = SUPER, D, exec, discord" >> "$config_file"
    fi

    cat >> "$config_file" << 'EOF'
bind = SUPER, F, fullscreen,
bind = SUPER, V, togglefloating,
bind = SUPER SHIFT, S, exec, grim -g "$(slurp)" - | wl-copy
bind = SUPER, L, exec, hyprlock
bind = SUPER, C, exec, cliphist list | wofi --dmenu | cliphist decode | wl-copy
bind = SUPER, ESCAPE, exec, wlogout

# Workspace navigation
bind = SUPER, 1, workspace, 1
bind = SUPER, 2, workspace, 2
bind = SUPER, 3, workspace, 3
bind = SUPER, 4, workspace, 4
bind = SUPER, 5, workspace, 5
bind = SUPER, 6, workspace, 6
bind = SUPER, 7, workspace, 7
bind = SUPER, 8, workspace, 8
bind = SUPER, 9, workspace, 9
bind = SUPER, 0, workspace, 10

# Move windows to workspaces
bind = SUPER SHIFT, 1, movetoworkspace, 1
bind = SUPER SHIFT, 2, movetoworkspace, 2
bind = SUPER SHIFT, 3, movetoworkspace, 3
bind = SUPER SHIFT, 4, movetoworkspace, 4
bind = SUPER SHIFT, 5, movetoworkspace, 5
bind = SUPER SHIFT, 6, movetoworkspace, 6
bind = SUPER SHIFT, 7, movetoworkspace, 7
bind = SUPER SHIFT, 8, movetoworkspace, 8
bind = SUPER SHIFT, 9, movetoworkspace, 9
bind = SUPER SHIFT, 0, movetoworkspace, 10

# Window focus
bind = SUPER, left, movefocus, l
bind = SUPER, right, movefocus, r
bind = SUPER, up, movefocus, u
bind = SUPER, down, movefocus, d

# Window movement
bind = SUPER SHIFT, left, movewindow, l
bind = SUPER SHIFT, right, movewindow, r
bind = SUPER SHIFT, up, movewindow, u
bind = SUPER SHIFT, down, movewindow, d

# Hardware controls
bindle = , XF86AudioRaiseVolume, exec, volumectl -u up
bindle = , XF86AudioLowerVolume, exec, volumectl -u down
bindl = , XF86AudioMute, exec, volumectl toggle
bindl = , XF86AudioPlay, exec, playerctl play-pause
bindl = , XF86AudioPause, exec, playerctl play-pause
bindle = , XF86MonBrightnessUp, exec, lightctl up
bindle = , XF86MonBrightnessDown, exec, lightctl down

# Autostart
exec-once = waybar
exec-once = nm-applet --indicator
exec-once = avizo-service
exec-once = mako
exec-once = /usr/lib/polkit-kde-authentication-agent-1
exec-once = wl-paste --type text --watch cliphist store
exec-once = wl-paste --type image --watch cliphist store
exec-once = hypridle
EOF

    if [[ -f "${USER_HOME}/.config/wallpapers/current_wallpaper.jpg" ]]; then
        echo 'exec-once = awww-daemon & sleep 1 && awww img ~/.config/wallpapers/current_wallpaper.jpg --transition-type simple' >> "$config_file"
    fi

    # Window opacity rules
    cat >> "$config_file" << 'EOF'

# Window rules for transparency
windowrule = opacity 0.90 0.90, ^(kitty)$
windowrule = opacity 0.90 0.90, ^(dolphin)$
EOF

    if [[ $INSTALL_FIREFOX == true ]]; then
        echo 'windowrule = opacity 0.95 0.95, ^(firefox)$' >> "$config_file"
    fi

    print_success "Generated hyprland.conf"
}

copy_config_files() {
    print_step "Deploying Configuration Files"

    local ansible_dir="$(dirname "$(readlink -f "$0")")"
    local templates_dir="${ansible_dir}/roles/workstation/templates"
    local files_dir="${ansible_dir}/roles/workstation/files"

    # Copy template files (simple copy since we're not using Jinja2)
    if [[ -d "$templates_dir" ]]; then
        # Waybar
        if [[ -f "${templates_dir}/waybar_config.j2" ]]; then
            cp "${templates_dir}/waybar_config.j2" "${USER_HOME}/.config/waybar/config"
            print_success "Deployed waybar config"
        fi

        if [[ -f "${templates_dir}/waybar_style.css.j2" ]]; then
            cp "${templates_dir}/waybar_style.css.j2" "${USER_HOME}/.config/waybar/style.css"
            print_success "Deployed waybar style"
        fi

        # Wofi
        if [[ -f "${templates_dir}/wofi_config.j2" ]]; then
            cp "${templates_dir}/wofi_config.j2" "${USER_HOME}/.config/wofi/config"
            print_success "Deployed wofi config"
        fi

        if [[ -f "${templates_dir}/wofi_style.css.j2" ]]; then
            cp "${templates_dir}/wofi_style.css.j2" "${USER_HOME}/.config/wofi/style.css"
            print_success "Deployed wofi style"
        fi

        # Kitty
        if [[ -f "${templates_dir}/kitty.conf.j2" ]]; then
            cp "${templates_dir}/kitty.conf.j2" "${USER_HOME}/.config/kitty/kitty.conf"
            print_success "Deployed kitty config"
        fi

        # Hyprlock
        if [[ -f "${templates_dir}/hyprlock.conf.j2" ]]; then
            cp "${templates_dir}/hyprlock.conf.j2" "${USER_HOME}/.config/hypr/hyprlock.conf"
            print_success "Deployed hyprlock config"
        fi

        # Avizo
        if [[ -f "${templates_dir}/avizo_config.ini.j2" ]]; then
            cp "${templates_dir}/avizo_config.ini.j2" "${USER_HOME}/.config/avizo/config.ini"
            print_success "Deployed avizo config"
        fi

        if [[ -f "${templates_dir}/avizo_style.css.j2" ]]; then
            cp "${templates_dir}/avizo_style.css.j2" "${USER_HOME}/.config/avizo/style.css"
            print_success "Deployed avizo style"
        fi
    fi

    # Copy wallpaper if it exists
    if [[ -f "${files_dir}/placeholder_wallpaper.jpg" ]]; then
        cp "${files_dir}/placeholder_wallpaper.jpg" "${USER_HOME}/.config/wallpapers/current_wallpaper.jpg"
        print_success "Deployed wallpaper"
    fi
}

configure_system() {
    print_step "Configuring System Services"

    # Console font for HiDPI
    print_info "Setting console font for HiDPI..."
    echo "KEYMAP=us
FONT=ter-v32n" | sudo tee /etc/vconsole.conf

    # Configure greetd
    print_info "Configuring greetd login manager..."
    sudo mkdir -p /etc/greetd
    echo '[terminal]
vt = 1

[default_session]
command = "tuigreet --time --remember --remember-user-session --asterisks --cmd '"'uwsm start hyprland-uwsm.desktop'"'"
user = "greeter"' | sudo tee /etc/greetd/config.toml

    # Enable services
    print_info "Enabling system services..."
    sudo systemctl enable --now bluetooth
    sudo systemctl enable --now power-profiles-daemon
    sudo systemctl enable --now NetworkManager
    sudo systemctl enable greetd

    print_success "System services configured"
}

post_install_notes() {
    print_header
    print_step "Installation Complete!"

    echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║${NC}  ${BOLD}Your Hyprland workstation is ready!${NC}                       ${GREEN}║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"

    echo -e "\n${CYAN}${BOLD}Next Steps:${NC}\n"

    if [[ $INSTALL_NVIDIA == true ]]; then
        print_warning "NVIDIA users: Regenerate initramfs"
        echo -e "  ${YELLOW}→${NC} sudo mkinitcpio -P"
        echo ""
    fi

    print_info "To start Hyprland:"
    echo -e "  ${CYAN}→${NC} Reboot and select Hyprland from greetd"
    echo -e "  ${CYAN}→${NC} Or run: uwsm start hyprland-uwsm.desktop"

    echo -e "\n${CYAN}${BOLD}Key Shortcuts:${NC}"
    echo -e "  ${CYAN}SUPER + RETURN${NC}    Terminal (Kitty)"
    echo -e "  ${CYAN}SUPER + SPACE${NC}     App Launcher (Wofi)"
    echo -e "  ${CYAN}SUPER + E${NC}         File Manager"
    echo -e "  ${CYAN}SUPER + L${NC}         Lock Screen"
    echo -e "  ${CYAN}SUPER + Q${NC}         Close Window"

    if [[ "$MONITOR_CONFIG" == "Desktop (multiple monitors - manual configuration)" ]]; then
        echo -e "\n${YELLOW}${BOLD}Monitor Configuration:${NC}"
        print_info "You selected manual monitor configuration"
        echo -e "  ${CYAN}→${NC} Edit ~/.config/hypr/monitors.conf"
        echo -e "  ${CYAN}→${NC} Or use the GUI tool: nwg-displays"
        echo -e "  ${CYAN}→${NC} Example:"
        echo -e "      monitor=DP-1,2560x1440@144,0x0,1.0"
        echo -e "      monitor=HDMI-A-1,1920x1080@60,2560x0,1.0"
    fi

    echo -e "\n${CYAN}${BOLD}Customization:${NC}"
    echo -e "  ${CYAN}→${NC} GTK Theme: Run 'nwg-look'"
    echo -e "  ${CYAN}→${NC} Displays: Run 'nwg-displays'"
    echo -e "  ${CYAN}→${NC} Config: Edit ~/.config/hypr/hyprland.conf"

    echo -e "\n${GREEN}Enjoy your new Hyprland desktop!${NC}\n"
}

# Main installation flow
main() {
    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should NOT be run as root!"
        print_info "It will ask for sudo password when needed."
        exit 1
    fi

    # Check if on Arch Linux
    if [[ ! -f /etc/arch-release ]]; then
        print_error "This script is designed for Arch Linux only!"
        exit 1
    fi

    # Welcome screen
    print_header
    echo -e "${CYAN}Welcome to the Arch Linux Hyprland Workstation Installer!${NC}\n"
    echo "This script will guide you through setting up a complete"
    echo "Hyprland desktop environment tailored to your hardware."
    echo ""
    echo "The installation includes:"
    echo "  • Hyprland (Wayland compositor)"
    echo "  • Waybar (status bar)"
    echo "  • Wofi (application launcher)"
    echo "  • Complete system configuration"
    echo ""

    if ! prompt_yes_no "Ready to begin?" "y"; then
        print_error "Installation cancelled"
        exit 0
    fi

    # Hardware detection and preferences
    detect_gpu
    detect_monitors
    gather_preferences
    show_summary

    # Installation steps
    install_packages
    install_aur_helper
    install_aur_packages
    create_directories
    generate_hyprland_config
    copy_config_files
    configure_system

    # Finish
    post_install_notes
}

# Run the installer
main "$@"
