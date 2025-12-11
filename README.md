# The Constellation Cursor
![recording-20251208-004815](https://github.com/user-attachments/assets/1c008e0d-f1ef-4f22-a0c7-6d5894d807c3)


[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Rust](https://img.shields.io/badge/Rust-1.70%2B-orange.svg)](https://www.rust-lang.org/)
![Status](https://img.shields.io/badge/Status-Beta-yellow)

A Rust LD_PRELOAD library that renders a vector cursor directly on the DRM hardware cursor plane.
Which allows for a true system cursor rendering without compositor involvement. 
Should works with any Wayland compositor using atomic modesetting.

> **Note:** This is a somewhat hacky workaround that intercepts DRM calls.
> Use at your own risk. See [Issues/Limitations](#issues-&-limitations) (out of order) look below.

## Why does this exist?

Many Wayland users has experience cursor issues (me included). Such as, and probably not limited to:
corruption, lag, or invisibility (especially on NVIDIA).
The common fix for this is `WLR_NO_HARDWARE_CURSORS=1` which *disables* hardware cursors entirely,
falling back to software rendering.

The Constellation Cursor takes the opposite approach: it *forces* the hardware cursor plane to work by intercepting
DRM calls and rendering a custom vector cursor directly to the cursor plane. Because, ofcourse it does.

**Features:**
- **Compositor agnostic** Which means it should Work with Hyprland, Sway, and others
- **Multi-Layer Design** Allowing for more detailed and targeted designs
- **Transparency** Make the cursor, or parts of the cursor, see-through.
- **System Cursor** Meaning, the same cursor for everything, not per app based.
- **Always on top** Means the Hardware cursor plane is your daddy...
                    Also, that it is composited by the GPU, not the compositor
- **Input passthrough** Means it should Work exactly like a normal cursor
- **Resolution independent** Because vector-based rendering scales cleanly

## Configuration File

The library automatically creates and reads a config file at `~/.config/constellation_cursor/cursor.conf`. This file is created with default values on first run.

### Config Options

```ini
# Constellation Cursor Config
# Edit this file to customize cursor behavior
#
# Changes are detected automatically when you save this file.
# To manually refresh use: touch /tmp/constellation_cursor_refresh

# Cursor size multiplier (default 1.5)
cursor_scale=2.5

# Outline thickness override (0 = use cursor default, 0.5-5.0 for custom)
outline_thickness=5

# Enable fade-out effect when cursor hides (runs in background thread)
# (Buggy)
fade_enabled=false

# Enable fade-in effect when cursor appears
# (Buggy)
fade_in_enabled=false

# Fade speed (1-255, higher = faster fade)
fade_speed=30

# Frosted glass intensity (0-100)
# (Doesn't look great at the moment)
frost_intensity=0

# Smooth hotspot transitions between cursor types
# For positional syncing, is likely to cause issues if not needed
hotspot_smoothing=false

# Threshold for hotspot change detection (pixels)
hotspot_threshold=0

# --- Config Hot-Reload Settings ---
# The cursor library can automatically detect when this file changes.
# Set to false to disable automatic reloading (saves a tiny bit of CPU).
# To re-enable: edit this file to set config_polling=true, then run:
#   touch /tmp/constellation_cursor_refresh
config_polling=true

# How often to check for config changes (number of cursor moves between checks)
# Lower = more responsive, Higher = less CPU. Default: 50
config_poll_interval=50

```

### Config Details

| Setting | Values | Description |
|---------|--------|-------------|
| `cursor_scale` | `0.5-10.0` | Cursor size multiplier (1.5 = default) |
| `outline_thickness` | `0-5.0` | Outline thickness override (0 = use cursor default) |
| `fade_enabled` | `true`/`false` | Enable smooth fade-out when cursor hides (runs in background) |
| `fade_in_enabled` | `true`/`false` | Enable smooth fade-in when cursor appears |
| `fade_speed` | `1-255` | How fast cursor fades (higher = faster) |
| `frost_intensity` | `0-100` | Frosted glass effect strength (0 = disabled, 100 = full) |
| `hotspot_smoothing` | `true`/`false` | Smooth cursor position when hotspot changes |
| `hotspot_threshold` | `0-50` | Pixel threshold before hotspot smoothing triggers |
| `config_polling` | `true`/`false` | Enable automatic config reload on file save |
| `config_poll_interval` | `1-1000` | Cursor moves between config file checks (50 = default) |

### Editing Config

```bash
# Edit with your preferred editor
nano ~/.config/constellation_cursor/cursor.conf

# Or use sed for quick changes
sed -i 's/fade_enabled=false/fade_enabled=true/' ~/.config/constellation_cursor/cursor.conf
```

**Note:** By default, config changes are detected automatically when you save the file - just move the cursor and the new settings apply. No restart needed.

If you've disabled `config_polling`, or the automatic config reload does not work, manually trigger a refresh with:
```bash
touch /tmp/constellation_cursor_refresh
```

## Environment Variables

Environment variables are read at startup and **override config file settings**.

| Variable | Description | Example |
|----------|-------------|---------|
| `CONSTELLATION_CURSOR_TYPE` | Initial cursor type | `CONSTELLATION_CURSOR_TYPE=pointer` |
| `CONSTELLATION_CURSOR_SCALE` | Initial cursor scale | `CONSTELLATION_CURSOR_SCALE=2.0` |
| `CONSTELLATION_CURSOR_DEBUG` | Enable debug logging | `CONSTELLATION_CURSOR_DEBUG=1` |
| `CONSTELLATION_CURSOR_INFO` | Show version info | `CONSTELLATION_CURSOR_INFO=1` |
| `CONSTELLATION_CURSOR_FADE` | Enable fade effect | `CONSTELLATION_CURSOR_FADE=1` |
### Important: The Refresh File

You can change some of these at runtime with the refresh file. 
If type or scale files are **not applied automatically**.
You must touch the refresh file to trigger a re-render:

```bash
# This WILL NOT change the scale of the cursor:
echo "2.1" > /tmp/constellation_cursor_scale

# This WILL change the cursor:
echo "2.1" > /tmp/constellation_cursor_scale && touch /tmp/constellation_cursor_refresh
```

The same applies to runtime cursor shape changes

```bash
# Change to hourglass/wait cursor
echo "wait" > /tmp/constellation_cursor_type && touch /tmp/constellation_cursor_refresh

# Change back to default arrow
echo "default" > /tmp/constellation_cursor_type && touch /tmp/constellation_cursor_refresh
```

**Available cursor types:**
- `default` / `arrow` - Standard constellation arrow cursor (will change)
- `pointer` / `hand` - Clickable element cursor (a normal copy/pasted cursor) 
- `text` / `ibeam` - Text input cursor (I-beam, if you squint)
- `crosshair` / `cross` - Precision selection cursor (currently off-center for extra precision)
- `wait` / `loading` / `busy` - Loading/busy cursor (hourglass if you are generous)
- `grab` / `grabbing` - Draggable element cursor (a testament to my superior design capabilities)
- `not-allowed` / `forbidden` / `no` - Prohibited action cursor (slightly missaligned for hotspot alignment)


## Custom Cursor Design

### Using the Designer

Open `cursor_designer.html` in your browser to create custom cursor shapes.

**Drawing Controls:**
- **Click empty space** - Add point
- **Drag point** - Move it
- **Shift+drag point** - Convert to Bezier curve
- **Right-click point** - Delete it
- **Ctrl+drag** - Box select multiple points
- **Multiple points selected + Shift+drag point** - Rotate the points
- **Delete key** - Remove selected points

**Multi-Select Features:**
When multiple points are selected (via Ctrl+drag), a Transform panel appears:
- **Rotate slider** - Rotate selected points around their center
- **Scale slider** - Scale selected points
- **Apply** - Commit the transformation
- **Reset** - Revert to original positions

**Bounds Validation:**
The designer warns if the first point (cursor hotspot) is not near (0,0). 
The hotspot should be at the cursor's "tip" for proper click positioning.

### Applying Custom Designs

1. Design your cursor in the designer
2. Go to **Export** tab
3. Click **Download All Cursors** to get Rust code
4. Replace the cursor functions in `src/lib.rs`
5. Rebuild: `cargo build --release`
6. **Restart your compositor** to load the new design

**Note:** Custom designs require a rebuild and compositor restart.
For the moment the runtime control files only switch between the built-in cursor types.

## Issues & Limitations

Known Issues
- Slight cursor re-adjustments happen when moving across certain areas
  this is likely due to the compositor/app changing the hotspot position.
  Seems to happen because the underlying cursor shape changes.
- The fade out effect currently hinders keyboard input at cursor position
  when keyboard input is tied to hiding the mouse cursor
- The frost effect AND the fade out/in effects look bad.
- Import function in the designer is currently not loading and displaying the
  imported design.
- Slight hotspot miss-alignment most likely caused by runtime scale change
  and/or compositor sync instructions.

Limitations
- May not work with all GPU vendors (tested on my NVIDIA RTX 3080)
- Might conflict with future kernel/driver changes
- LD_PRELOAD approach is likely fragile
- Needs manual cursor signaling to for changing the cursor
  

## Installation

As I am currently on Hyprland, I will be using it in the examples.
You do not need to use Hyprland for the cursor to work. It bypasses
the Wayland compositor by using evdev and intercepting instructions
between the compossitor and the drm cursor plane.

### From Source

```bash
# Clone the repository
git clone https://github.com/Mauitron/the_constellation_cursor
cd the_constellation_cursor

# Build release
cargo build --release

# The library is at:
# target/release/libthe_constellation_cursor.so
```

### NixOS (Flakes + Home Manager)

**1. Add the flake input**
```nix
constellation-cursor = {
  url = "github:keygenesis/The_Constellation_Cursor";
  inputs.nixpkgs.follows = "nixpkgs";
};
```
**2. Add the Home Manager module to your system configuration**
```nix
modules = [
  home-manager.nixosModules.home-manager
  inputs.constellation-cursor.homeManagerModules.constellation-cursor
];
```
**3. Enable the program in home.nix and configure**
```nix
programs.constellation-cursor = {
  enable = true;
  
  # Required: install the package from the flake
  package = inputs.constellation-cursor.packages.${pkgs.system}.default;

  # Optional
  settings = {
    cursor_scale = 1.5;
    outline_thickness = 0.0;
    fade_enabled = false;
    fade_in_enabled = false;
    fade_speed = 30;
    frost_intensity = 0;
    hotspot_smoothing = false;
    hotspot_threshold = 0;
    config_polling = true;
    config_poll_interval = 50;
  };
  
  # Required: ensure Hyprland loads the library at runtime
  systemd.user.services.hyprland.Service.Environment = [
    "LD_PRELOAD=${inputs.constellation-cursor.packages.${pkgs.system}.default}/lib/libthe_constellation_cursor.so"
  ];
  
};
```

**The module will:**

Write the configuration file to ~/.config/constellation_cursor/cursor.conf

Set LD_PRELOAD to load the cursor library

**Note:** A logout/login may be required after rebuilding

## Usage

### Quick Start

```bash
# Launch your compositor with the cursor. If you are on hyprland, like so:
LD_PRELOAD=/path/to/libthe_constellation_cursor.so Hyprland
```

### With a Display Manager (greetd, etc.)

```
Add the above flag to your start command.
LD_PRELOAD=/path/to/the/libthe_constellation_cursor.so Hyprland
or replace 'Hyprland' with whatever compositor you are using

```

## Environment Variables

| Variable | Description |
|----------|-------------|
| `CONSTELLATION_CURSOR_INFO=1` | Print version and intercepted DRM calls |
| `CONSTELLATION_CURSOR_DEBUG=1` | Enable verbose debug logging |

Example:

```bash
CONSTELLATION_CURSOR_INFO=1 LD_PRELOAD=./target/release/libthe_constellation_cursor.so hyprland
```

Output:
```
  DRM Constellation Cursor v0.1.0
  ─────────────────────────────────────
  Intercepted DRM calls:
    ioctl            MODE_CURSOR, MODE_CURSOR2
    drmModeSetCursor   legacy cursor set
    drmModeSetCursor2  legacy cursor set v2
    drmModeMoveCursor  cursor position update
    drmModeGetPlane    cursor plane detection
    drmModeAtomicAddProperty  FB_ID replacement

  Environment variables:
    CONSTELLATION_CURSOR_DEBUG=1  verbose logging
    CONSTELLATION_CURSOR_INFO=1   show this info
```

## Custom Cursors

### Using the Designer

Open `cursor_designer.html` in your browser to create custom cursor shapes:

1. Click on the canvas to add polygon points
2. Right-click to undo
3. Adjust colors, scale, and shadow
4. Go to **Export** tab and copy the Rust code
5. Replace the `render_arrow_cursor()` function in `src/lib.rs`
6. Rebuild

### Built-in Presets

The designer includes these presets:
- Arrow (default)
- Pointer
- Crosshair
- I-Beam
- Hand
- Wait/Loading

## How It Works

```
┌─────────────────────────────────────────────────────────────┐
│                    Your Compositor                          │
│   (Hyprland, Sway, etc.)                                    │
│                                                             │
│   Sets cursor image ──────┐                                 │
│                           ▼                                 │
│   ┌─────────────────────────────────────────────────────┐   │
│   │         libthe_constellation_cursor.so              │   │
│   │                                                     │   │
│   │  1. Intercepts drmModeAtomicAddProperty             │   │
│   │  2. Detects cursor plane via "type" property        │   │
│   │  3. Creates our own framebuffer with vector cursor  │   │
│   │  4. Replaces compositor's FB_ID with ours           │   │
│   └─────────────────────────────────────────────────────┘   │
│                           │                                 │
│                           ▼                                 │
│                     DRM Kernel API                          │
│                                                             │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
              ┌─────────────────────────┐
              │   Hardware Cursor Plane │
              │   (Always on top)       │
              └─────────────────────────┘
```

## Requirements

- Linux with DRM/KMS
- Wayland compositor using atomic modesetting, legacy mode untested
- Rust 1.70+ (for building)

## Tested Compositors

| Compositor |     Status     |
|------------|----------------|
| Hyprland   | ✅ Working     |
| Sway       | 🔄 Should work |
| KWin       | ❓ Untested    |
| Mutter     | ❓ Untested    |

## Troubleshooting

### Cursor not appearing

Enable debug mode to see what's happening:

```bash
CONSTELLATION_CURSOR_DEBUG=1 LD_PRELOAD=... hyprland 2>&1 | tee cursor.log
```

Look for:
- "Captured DRM fd" would mean library is intercepting calls
- "Detected cursor plane" means it found the cursor plane
- "Created cursor buffer" gave birth to our buffer
- "Replacing FB_ID" managed to successfully replace cursor image

### Wrong cursor size

The default is 256x256 buffer with 1.5x scale (~32px cursor). Edit `src/lib.rs`:

```rust
let scale = 2.0;  // Larger cursor
```

### Compositor crashes

With some prophet like guesswork, I suspect some compositors may not handle the
FB replacement gracefully. If that is the case try:
1. Update your compositor to the latest version
2. Check if your GPU driver supports the required DRM features
3. File an issue with debug logs and I'll get around to it eventually

## Contributing
***If you like The Constellation Cursor and want to support the project, please consider feeding me some [Pizza](https://buymeacoffee.com/charon0) 🍕***

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run `cargo build --release` to verify
5. Submit a pull request
6. Await JUDGEMENT!

Extra bonus points if you fix my awesome cursor designs...
Or just create your own and share them!

## License

MIT License - see [LICENSE](LICENSE) for details.

## Acknowledgments

- Inspired by my unending frustration over the Wayland cursor approach and the need for resolution-independent cursors
- Part of the Starwell::Constellation project

Circumventing compositor dictatorship since 2025
