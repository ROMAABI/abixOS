# AbixOS

A HyDE (Hyprland Desktop Environment) inspired dotfiles repository for a beautiful, modern Linux desktop experience.

![Hyprland](https://img.shields.io/badge/Hyprland-2024-blue)
![Waybar](https://img.shields.io/badge/Waybar-2024-blue)
![Rofi](https://img.shields.io/badge/Rofi-2024-blue)

## Features

- **Modern Wayland Desktop** - Hyprland-based setup with beautiful animations
- **Customizable Themes** - Multiple anime-themed wallpapers and color schemes
- **Status Bar** - Waybar with modules for system monitoring, network, battery, etc.
- **App Launcher** - Rofi-based launcher with custom themes
- **Terminal** - Kitty terminal with custom color schemes
- **Shell Support** - Fish and Zsh configurations
- **Abix Scripts** - Custom independent scripting system (no HyDE dependency)

## Architecture

AbixOS is built as a layer on top of HyDE, providing:
- Independent scripts that don't require hyde-shell or hydectl
- Clean separation between HyDE core and Abix customizations
- Portable configuration that works on any Hyprland setup

```
~/.config/
├── hypr/      # Hyprland core config
├── waybar/    # Status bar
├── rofi/      # App launcher
├── hyde/      # HyDE system (DO NOT MODIFY)
└── abix/      # Abix custom layer
    ├── abix.conf
    ├── scripts/
    ├── themes/
    ├── wallpapers/
    ├── packages.lst
    └── config_map.lst
```

## Requirements

### Core Dependencies
- **Hyprland** (>= 0.35) - Wayland compositor
- **Waybar** - Status bar
- **Rofi** - App launcher
- **swaync** - Notifications

### Optional Dependencies
- **swww** - Wallpaper daemon
- **kitty** - Terminal emulator
- **grim** + **slurp** - Screenshot
- **zsh** or **fish** - Shell

### Installation (Arch Linux)
```bash
sudo pacman -S hyprland waybar rofi swaync swww kitty grim slurp zsh fish
```

## Installation

### Quick Install
```bash
# Clone the repository
git clone git@github.com:ROMAABI/abixOS.git

# Enter the directory
cd abixOS

# Run the installer
chmod +x install.sh
./install.sh
```

### Manual Install
```bash
# Backup existing configs
cp -r ~/.config ~/.config_backup

# Copy configs
cp -r config/* ~/.config/
cp -r local/share/hypr ~/.local/share/

# Reload Hyprland
hyprctl reload
```

## AbixOS Scripts

All scripts are located in `~/.config/abix/scripts/`:

### abix-wall.sh - Wallpaper Management
```bash
# Set specific wallpaper
abix-wall.sh ~/Pictures/wall.jpg

# Random wallpaper
abix-wall.sh -r

# With color generation
abix-wall.sh -c ~/Pictures/wall.jpg

# Interactive selection
abix-wall.sh
```

### abix-theme.sh - Theme Switching
```bash
# List available themes
abix-theme.sh --list

# Select random theme
abix-theme.sh --random

# Select specific theme
abix-theme.sh "Catppuccin Mocha"

# Interactive rofi selector
abix-theme.sh

# Previous/Next theme
abix-theme.sh --previous
abix-theme.sh --next

# With wallpaper
abix-theme.sh --with-wall "Theme Name"
```

### abix-notify.sh - Notifications
```bash
# Simple notification
abix-notify.sh "Hello World"

# With title
abix-notify.sh -t "Warning" "Something happened"

# Critical urgency
abix-notify.sh -u critical "System Error"

# Custom icon
abix-notify.sh -i /path/to/icon.png "Message"
```

### abix-start.sh - Startup Initialization
```bash
# Full initialization (default)
abix-start.sh

# Quick mode (skip optional services)
abix-start.sh --quick

# Start services only
abix-start.sh --services

# Check system status
abix-start.sh --check
```

### abix-pkg.sh - Package Management
```bash
# Install packages from list
abix-pkg.sh --install

# Show package list
abix-pkg.sh --list

# Add package to list
abix-pkg.sh --add package_name

# Remove package from list
abix-pkg.sh --remove package_name

# Check installed status
abix-pkg.sh --check

# Update system
abix-pkg.sh --update
```

### abix-shell.sh - Shell Configuration
```bash
# Set default shell
abix-shell.sh --set zsh
abix-shell.sh --set fish

# Show current shell
abix-shell.sh --get

# Install shell dependencies
abix-shell.sh --install
```

### abix-version.sh - System Information
```bash
# Show version info
abix-version.sh
```

### abix-screenshot.sh - Screenshot Utility
```bash
# Screenshot entire screen
abix-screenshot.sh

# Screenshot active window
abix-screenshot.sh --window

# Screenshot region (selection)
abix-screenshot.sh --region

# Copy to clipboard
abix-screenshot.sh --clipboard

# With delay (seconds)
abix-screenshot.sh --delay 5

# Open after taking
abix-screenshot.sh --open
```

### abix-restore.sh - Config Restoration
```bash
# Show available configs
abix-restore.sh --list

# Show restoration status
abix-restore.sh --status

# Dry run
abix-restore.sh --dry-run

# Force overwrite
abix-restore.sh --force
```

## Keybindings

| Key | Action |
|-----|--------|
| `SUPER + T` | Theme selector (abix-theme.sh) |
| `SUPER + SHIFT + W` | Wallpaper selector |
| `SUPER + SHIFT + S` | Screenshot |
| `SUPER + N` | Toggle notifications |

Add to `~/.config/hypr/keybindings.conf`:
```hyprlang
# Abix bindings
bind = SUPER, T, exec, $HOME/.config/abix/scripts/abix-theme.sh
bind = SUPER SHIFT, W, exec, $HOME/.config/abix/scripts/abix-wall.sh -r
bind = SUPER SHIFT, S, exec, $HOME/.config/abix/scripts/abix-screenshot.sh
```

## Configuration

### Adding Custom Themes
Place theme files in `~/.config/abix/themes/<ThemeName>/`:
- `hypr.theme` - Hyprland colors
- `waybar.theme` - Waybar colors
- `kitty.theme` - Terminal colors
- `rofi.theme` - Launcher colors

### Package List
Edit `~/.config/abix/packages.lst` to add packages for automatic installation.

### Config Mapping
Edit `~/.config/abix/config_map.lst` to customize config restoration paths.

## Troubleshooting

### Waybar not starting
```bash
# Check for errors
waybar

# Restart
killall waybar
waybar &
```

### Scripts not working
```bash
# Make sure scripts are executable
chmod +x ~/.config/abix/scripts/*.sh

# Check PATH includes ~/.local/bin
echo $PATH
```

### Hyprland not starting
```bash
# Check config syntax
hyprctl version

# Validate config
cat ~/.config/hypr/hyprland.conf
```

## Project Structure

```
abixOS/
├── config/
│   ├── hypr/           # Hyprland configuration
│   ├── waybar/         # Waybar configuration
│   ├── rofi/           # Rofi themes
│   ├── hyde/           # HyDE system config
│   └── abix/           # Abix custom layer
│       ├── abix.conf
│       ├── scripts/    # AbixOS scripts
│       ├── themes/
│       ├── wallpapers/
│       ├── packages.lst
│       └── config_map.lst
├── local/share/
│   └── hypr/           # Shared Hyprland configs
├── install.sh          # Installation script
└── README.md           # This file
```

## Credits

- [HyDE](https://github.com/HyDE-Project/HyDE) - Original Hyprland Desktop Environment
- [Hyprland](https://github.com/hyprwm/Hyprland) - Awesome Wayland compositor
- [Waybar](https://github.com/Alexays/Waybar) - Highly customizable status bar

## License

MIT License - Feel free to use and modify!

---

**Note:** This configuration uses dynamic paths (`$HOME`, `$USER`) to work on any Linux system. Some features may require additional setup depending on your distribution.