# hypryahm

`hypryahm`, Hypr-Yet-Another-Hyprpaper-Manager, is a lightweight bash script designed to simplify wallpaper management for [hyprpaper](https://github.com/hyprwm/hyprpaper) on Hyprland. It adds functionality like cycling through wallpapers, choosing random images, and automatically handling multiple monitors.

## Features

- **Cycle Wallpapers**: Move forward or backward through your wallpaper collection.
- **Randomize**: Quickly set a random wallpaper from your specified directory.
- **Multi-monitor Support**: Automatically detects active monitors and applies the wallpaper to all of them.
- **State Management**: Remembers the last used wallpaper to allow sequential cycling.
- **Intelligent Loading**: Automatically starts `hyprpaper` if it's not running and unloads unused wallpapers to save memory.

## Installation

1. Download the `hypryahm.sh` script.
2. Make it executable:
   ```bash
   chmod +x hypryahm.sh
   ```
3. (Optional) Move it to your PATH for easier access:
   ```bash
   mv hypryahm.sh ~/.local/bin/hypryahm
   ```

## Usage

```bash
hypryahm [options]
```

### Options

- `-n`: Cycle forward to the next wallpaper.
- `-p`: Cycle backward to the previous wallpaper.
- `-r`: Set a random wallpaper.
- `-w <directory>`: Specify a custom directory to search for images.
- `-i <file>`: Set a specific image file as your wallpaper.
- `-h`: Show help information.

### Examples

**Set a random wallpaper from default locations:**
```bash
hypryahm -r
```

**Cycle to the next wallpaper in a specific folder:**
```bash
hypryahm -w ~/Pictures/Nature -n
```

**Set a specific image:**
```bash
hypryahm -i ~/Pictures/Wallpapers/mountain.jpg
```

## Default Search Directories

If no directory is specified with `-w`, `hypryahm` will search for images in the following locations:
- `~/Wallpapers`
- `~/Pictures/Wallpapers`
- `~/Pictures/wallpaper`
- `~/.config/wallpapers`

## Integration with Hyprland

You can bind `hypryahm` to keybindings in your `hyprland.conf`:

```ini
bind = $mainMod, W, exec, hypryahm -r
bind = $mainMod SHIFT, W, exec, hypryahm -n
```
