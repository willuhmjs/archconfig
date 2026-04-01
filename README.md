# Ansible Hyprland Setup

ansible-playbook playbook.yml --limit local --ask-become-pass

This project uses Ansible to provision and configure a highly customized, premium Wayland/Hyprland desktop environment on Arch Linux.

## ⌨️ Keyboard Shortcuts (Keybinds)

The following default shortcuts are configured in the `hyprland.conf` template:

### Application Launchers
| Keybind | Action | Application |
|---|---|---|
| `SUPER` + `RETURN` | Open Terminal | Kitty |
| `SUPER` + `SPACE` | Open App Launcher | Wofi |
| `SUPER` + `E` | Open File Manager | Dolphin |
| `SUPER` + `C` | Open Clipboard History | Cliphist + Wofi |
| `SUPER` + `SHIFT` + `S` | Take Area Screenshot | Grim + Slurp (Copies to clipboard) |

### System Commands
| Keybind | Action | Application |
|---|---|---|
| `SUPER` + `L` | Lock Screen | Hyprlock |
| `SUPER` + `ESCAPE` | Power/Logout Menu | Wlogout |

### Window Management
| Keybind | Action |
|---|---|
| `SUPER` + `Q` | Close Active Window |
| `SUPER` + `F` | Toggle Fullscreen |
| `SUPER` + `V` | Toggle Floating Mode |
| `SUPER` + `Arrow Keys` | Change Window Focus (Left, Right, Up, Down) |
| `SUPER` + `SHIFT` + `Arrow Keys` | Move Active Window (Left, Right, Up, Down) |

### Workspace Management
| Keybind | Action |
|---|---|
| `SUPER` + `1-6` | Switch to Workspace 1 through 6 |
| `SUPER` + `SHIFT` + `1-6` | Move Active Window to Workspace 1 through 6 |

### Mouse Bindings
| Action | Binding |
|---|---|
| Move Floating Window | Hold `SUPER` + Left-Click & Drag anywhere in window |
| Resize Floating Window | Hold `SUPER` + Right-Click & Drag anywhere in window |
| Border Resize | Hover over the edge of a floating window, Left-Click & Drag |

### Hardware Controls (Laptop / Keyboard)
- **Volume Up / Down Keys:** Adjust system volume
- **Mute Key / Knob Click:** Toggle system audio mute (Supports Keychron knob click)
- **Brightness Up / Down Keys:** Adjust laptop screen brightness

---
*Note: The modifier key `SUPER` usually corresponds to the Windows key or Command key on your keyboard.*