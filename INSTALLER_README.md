# Arch Linux Hyprland Interactive Installer

An interactive TUI installer that sets up a complete Hyprland desktop environment on Arch Linux, based on the ansible configuration but adapted to work on any machine with dynamic hardware detection.

## Features

✨ **Hardware-Aware**
- Automatic GPU detection (NVIDIA, AMD, Intel, Hybrid)
- Dynamic monitor configuration (laptop, desktop, multi-monitor)
- Touchpad detection and configuration
- No hardcoded display or GPU settings

🎨 **Customizable**
- Choose which applications to install
- Enable/disable animations and blur for performance
- Configure HiDPI scaling
- Natural scrolling options

📦 **Complete Setup**
- Core Hyprland and Wayland components
- Status bar (Waybar) with system tray
- Application launcher (Wofi)
- Terminal (Kitty), file manager (Dolphin)
- Audio/Bluetooth/Network management
- Screen locking and power management
- Clipboard history
- Optional: Firefox, Discord

## Prerequisites

1. **Fresh Arch Linux installation** with base system installed
2. **Booted into the system** (not from installation media)
3. **Internet connection** configured
4. **Sudo privileges** for your user

## Quick Start

### Method 1: Direct Download (Recommended)

```bash
# Download the installer
curl -O https://raw.githubusercontent.com/YOUR_USERNAME/ansible/main/arch-hyprland-installer.sh

# Make it executable
chmod +x arch-hyprland-installer.sh

# Run it
./arch-hyprland-installer.sh
```

### Method 2: From Git Repository

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/ansible.git
cd ansible

# Run the installer
./arch-hyprland-installer.sh
```

### Method 3: Minimal Base System Setup

If you just finished a minimal Arch install, here's a complete setup:

```bash
# 1. Connect to internet (if not already)
# For WiFi:
iwctl
# > station wlan0 connect "YourNetworkName"
# > exit

# For Ethernet, it should work automatically

# 2. Install git (if not already installed)
sudo pacman -S git

# 3. Clone and run the installer
git clone https://github.com/YOUR_USERNAME/ansible.git
cd ansible
./arch-hyprland-installer.sh
```

## What the Installer Does

### 1. Hardware Detection
- Detects your GPU type
- Identifies monitor setup
- Checks for touchpad

### 2. Interactive Configuration
The installer will ask you:
- Which GPU drivers to install
- How your monitors are configured
- Whether you want Firefox/Discord
- Performance preferences (animations, blur)
- Display scaling factors
- Input preferences (natural scrolling, etc.)

### 3. Package Installation
Installs from official repos:
- Hyprland dependencies
- Wayland tools (waybar, wofi, etc.)
- Audio/video (pipewire, wireplumber)
- System utilities
- GPU drivers (if selected)

Installs from AUR:
- hyprland-git (latest Hyprland)
- avizo (volume/brightness OSD)
- nwg-look (GTK theme selector)
- nwg-displays (display configuration)
- wlogout (logout menu)

### 4. Configuration Generation
- Creates Hyprland config tailored to your hardware
- Sets up proper environment variables for your GPU
- Configures monitor settings
- Deploys all config files (waybar, wofi, kitty, etc.)

### 5. System Setup
- Configures greetd login manager
- Enables necessary systemd services
- Sets up HiDPI console font
- Configures automatic login options

## After Installation

### For NVIDIA Users
If you selected NVIDIA drivers, you **must** regenerate initramfs:

```bash
sudo mkinitcpio -P
sudo reboot
```

### Starting Hyprland

1. **Reboot** your system:
   ```bash
   reboot
   ```

2. At the login screen (greetd), your user should be pre-selected
3. Enter your password and Hyprland will start automatically

Alternatively, start manually from TTY:
```bash
uwsm start hyprland-uwsm.desktop
```

### Key Shortcuts

| Shortcut | Action |
|----------|--------|
| `SUPER + RETURN` | Terminal (Kitty) |
| `SUPER + SPACE` | App Launcher (Wofi) |
| `SUPER + E` | File Manager (Dolphin) |
| `SUPER + B` | Browser (Firefox) |
| `SUPER + D` | Discord |
| `SUPER + Q` | Close Window |
| `SUPER + F` | Fullscreen |
| `SUPER + V` | Toggle Floating |
| `SUPER + L` | Lock Screen |
| `SUPER + ESC` | Power Menu (wlogout) |
| `SUPER + SHIFT + S` | Screenshot (area) |
| `SUPER + C` | Clipboard History |
| `SUPER + 1-9` | Switch Workspace |
| `SUPER + SHIFT + 1-9` | Move Window to Workspace |

### Multi-Monitor Setup

If you selected manual monitor configuration:

1. **Using GUI:**
   ```bash
   nwg-displays
   ```

2. **Manual configuration:**
   Edit `~/.config/hypr/monitors.conf`:
   ```conf
   # Example for dual monitors:
   monitor=DP-1,2560x1440@144,0x0,1.0
   monitor=HDMI-A-1,1920x1080@60,2560x0,1.0
   ```

3. **List available monitors:**
   ```bash
   hyprctl monitors
   ```

### Customization

**GTK Theme:**
```bash
nwg-look
```

**Hyprland Config:**
Edit `~/.config/hypr/hyprland.conf`

**Waybar:**
- Config: `~/.config/waybar/config`
- Style: `~/.config/waybar/style.css`

**Change Wallpaper:**
```bash
awww img /path/to/your/wallpaper.jpg --transition-type simple
```

## Troubleshooting

### Black Screen After Login
1. Check TTY2-7 with `Ctrl+Alt+F2`
2. View logs: `journalctl -xe`
3. Check Hyprland crash log: `~/.hyprland.log`

### NVIDIA Issues
- Ensure initramfs was regenerated: `sudo mkinitcpio -P`
- Check kernel parameters: `cat /proc/cmdline`
- Verify nvidia module: `lsmod | grep nvidia`

### Display Not Detected
1. List displays: `hyprctl monitors`
2. Manual configuration in `~/.config/hypr/monitors.conf`
3. Use `nwg-displays` for GUI configuration

### No Audio
```bash
systemctl --user status pipewire pipewire-pulse wireplumber
systemctl --user restart pipewire pipewire-pulse wireplumber
```

### Performance Issues
1. Disable blur: Edit `~/.config/hypr/hyprland.conf`, set `blur { enabled = false }`
2. Disable animations: Set `animations { enabled = false }`
3. Reduce shadow/blur intensity

## Differences from Ansible Version

This installer improves upon the ansible configuration:

| Feature | Ansible | Installer |
|---------|---------|-----------|
| Monitor Config | Hardcoded DP-3, DP-2 | Auto-detected/User-selected |
| GPU Setup | Assumes NVIDIA | Detects and asks |
| Display Settings | Hardcoded eDP-1, scale 1.25 | Dynamic based on setup |
| Workspace-Monitor | Fixed assignments | Generic (works anywhere) |
| Customization | Edit ansible vars | Interactive prompts |
| Portability | Machine-specific | Universal |

## File Locations

- **Hyprland:** `~/.config/hypr/`
- **Waybar:** `~/.config/waybar/`
- **Wofi:** `~/.config/wofi/`
- **Kitty:** `~/.config/kitty/`
- **Wallpapers:** `~/.config/wallpapers/`
- **Login Manager:** `/etc/greetd/config.toml`

## Uninstallation

To remove Hyprland and related packages:

```bash
# Remove AUR packages
yay -Rns hyprland-git avizo nwg-look nwg-displays wlogout awww

# Remove official packages
sudo pacman -Rns waybar wofi mako hyprlock hypridle xdg-desktop-portal-hyprland

# Remove configs (backup first!)
rm -rf ~/.config/hypr ~/.config/waybar ~/.config/wofi
```

## Contributing

Found a bug or want to suggest an improvement? This installer is based on the ansible configuration at `/home/will/ansible/`.

## License

This installer and configuration are provided as-is for personal use.
