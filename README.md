# The_Constellation_Cursor

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Rust](https://img.shields.io/badge/Rust-1.70%2B-orange.svg)](https://www.rust-lang.org/)

A Rust LD_PRELOAD library that renders a vector cursor directly on the DRM hardware cursor plane.
Works with any Wayland compositor using atomic modesetting.

> **Note:** This is an experimental workaround that intercepts DRM calls.
> Use at your own risk. See [Limitations](#limitations) below.

## Why does this exist?

Many Wayland users experience cursor issues. corruption, lag, or invisibility (especially on NVIDIA).
The common fix is `WLR_NO_HARDWARE_CURSORS=1` which *disables* hardware cursors entirely,
falling back to software rendering.

This library takes the opposite approach: it *forces* the hardware cursor plane to work by intercepting
DRM calls and rendering a custom vector cursor directly to the cursor plane. Because, ofcourse it does.

**Benefits:**
- **Always on top** Means the Hardware cursor plane is your daddy...
                    Also, that it is composited by the GPU, not the compositor
- **Input passthrough** Means it should Work exactly like a normal cursor
- **Resolution independent** Because vector-based rendering scales cleanly
- **Compositor agnostic** Which means it should Work with Hyprland, Sway, and others

## Limitations

- May not work with all GPU vendors (tested on my NVIDIA RTX 3080)
- Might conflict with future kernel/driver changes
- LD_PRELOAD approach is likely fragile
- Single cursor shape for now (no automatic hand/I-beam switching yet)

## Installation

### From Source

```bash
# Clone the repository
git clone https://github.com/user/drm_constellation_cursor
cd drm_constellation_cursor

# Build release
cargo build --release

# The library is at:
# target/release/libdrm_constellation_cursor.so
```

## Usage

### Quick Start

```bash
# Launch your compositor with the cursor. If you are on hyprland, like so:
LD_PRELOAD=/path/to/libdrm_constellation_cursor.so Hyprland
```

### Hyprland

Add to your Hyprland config or wrapper script:

```bash
#!/bin/bash
export LD_PRELOAD=/path/to/libdrm_constellation_cursor.so
exec Hyprland
```

### With a Display Manager (greetd, etc.)

Create a wrapper script:

```bash
# /usr/local/bin/hyprland-constellation
#!/bin/bash
export LD_PRELOAD=/usr/lib/libdrm_constellation_cursor.so
exec /usr/bin/Hyprland "$@"
```

Then point your display manager to use `hyprland-constellation` instead of `Hyprland`.

## Environment Variables

| Variable | Description |
|----------|-------------|
| `CONSTELLATION_CURSOR_INFO=1` | Print version and intercepted DRM calls |
| `CONSTELLATION_CURSOR_DEBUG=1` | Enable verbose debug logging |

Example:

```bash
CONSTELLATION_CURSOR_INFO=1 LD_PRELOAD=./target/release/libdrm_constellation_cursor.so hyprland
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
│   │         libdrm_constellation_cursor.so              │   │
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

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run `cargo build --release` to verify
5. Submit a pull request
6. Await JUDGEMENT!

## License

MIT License - see [LICENSE](LICENSE) for details.

## Acknowledgments

- Inspired by my unending frustration over the Wayland cursor approach and the need for resolution-independent cursors
- Part of the Starwell::Constellation project

Circumventing compositor dictatorship since 2025
