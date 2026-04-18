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

## Requirements

### Core Dependencies
- **Hyprland** (>= 0.35) - Wayland compositor
- **Waybar** - Status bar
- **Rofi** - App launcher
- **Kitty** - Terminal emulator
- **Fish** or **Zsh** - Shell

### Optional Dependencies
- **swww** or **awww** - Wallpaper daemon
- **Hyprlock** - Screen locker
- **Hypridle** - Idle daemon
- **Wlogout** - Logout menu
- **fastfetch** - System info display

### Installation (Arch Linux)
```bash
sudo pacman -S hyprland waybar rofi kitty fish zsh swww wlogout fastfetch
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
cp -r ~/.config/hypr ~/.config.backup/
cp -r ~/.config/waybar ~/.config.backup/
cp -r ~/.config/rofi ~/.config.backup/

# Copy configs
cp -r hypr ~/.config/
cp -r waybar ~/.config/
cp -r rofi ~/.config/
cp -r kitty ~/.config/
cp -r fish ~/.config/
cp -r zsh ~/.config/
cp -r abix ~/.config/

# Copy scripts
cp scripts/* ~/.local/bin/
chmod +x ~/.local/bin/*

# Reload Hyprland
hyprctl reload
```

## Usage

### Theme Selection
```bash
# Open theme selector
abix-shell themeselect

# Or use keybinding
SUPER + SHIFT + T
```

### Wallpaper Selection
```bash
# Open wallpaper selector
abix-shell wallpaper

# Or use keybinding
SUPER + SHIFT + W
```

### Wallbash Toggle
```bash
# Toggle wallpaper-based colors
abix-shell wallbashtoggle -m
```

## Keybindings

| Key | Action |
|-----|--------|
| `SUPER + SHIFT + T` | Theme selector |
| `SUPER + SHIFT + W` | Wallpaper selector |
| `SUPER + ALT + Left/Right` | Previous/Next wallpaper |
| `SUPER + SHIFT + R` | Wallbash toggle |
| `SUPER + ALT + Up/Down` | Waybar layout cycle |

## Configuration

### Adding Custom Themes
Place theme files in `abix/themes/<ThemeName>/`:
- `hypr.theme` - Hyprland colors
- `waybar.theme` - Waybar colors
- `kitty.theme` - Terminal colors
- `rofi.theme` - Launcher colors

### Customizing Waybar
Edit `waybar/config.jsonc` to add/remove modules.

## Troubleshooting

### Waybar not starting
```bash
# Check for errors
waybar

# Restart
killall waybar
waybar &
```

### Wallpaper not working
```bash
# Check which wallpaper backend is configured
abix-shell wallpaper -v

# Try different backends
abix-shell wallpaper.swww.sh
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
│       ├── scripts/
│       ├── themes/
│       └── wallpapers/
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

**Note:** This configuration uses dynamic paths (`$HOME`, `$USER`) to work on any Linux system. Some features may require additional setup depending on your distribution.Note: This repository contains large wallpaper files.
GitHub has a 100MB file size limit. If you encounter errors,
you may need to use Git LFS or remove some wallpapers.

