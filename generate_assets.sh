#!/usr/bin/env bash
#
# generate_assets.sh - Quantum Gear GRUB Theme Asset Generator
#
# This script generates:
#   - background.png       (blueprint + gears + particles)
#   - gear_slices/*.png    (9‑slice menu borders)
#   - progress_*.png       (timer bar slices)
#
# Usage:
#   ./generate_assets.sh [--width W] [--height H] [--output-dir DIR]
#
# Dependencies: Python 3, Pillow (installed automatically if missing).
# -------------------------------------------------------------------

set -euo pipefail

# Defaults
DEFAULT_WIDTH=1920
DEFAULT_HEIGHT=1080
OUTPUT_DIR="assets"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --width)
            WIDTH="$2"
            shift 2
            ;;
        --height)
            HEIGHT="$2"
            shift 2
            ;;
        --output-dir)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 [--width W] [--height H] [--output-dir DIR]"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

WIDTH="${WIDTH:-$DEFAULT_WIDTH}"
HEIGHT="${HEIGHT:-$DEFAULT_HEIGHT}"

# -------------------------------------------------------------------
# 1. Check Python 3
# -------------------------------------------------------------------
if ! command -v python3 &>/dev/null; then
    echo "ERROR: python3 is required but not found in PATH."
    exit 1
fi

# -------------------------------------------------------------------
# 2. Ensure Pillow is installed
# -------------------------------------------------------------------
echo "Checking for Pillow..."
if ! python3 -c "import PIL" &>/dev/null; then
    echo "Pillow not found. Attempting to install it (user installation)..."
    python3 -m pip install --user pillow || {
        echo "ERROR: Failed to install Pillow. Please install it manually:"
        echo "       pip install pillow"
        exit 1
    }
    echo "Pillow installed successfully."
else
    echo "Pillow found."
fi

# -------------------------------------------------------------------
# 3. Run the embedded Python generator
# -------------------------------------------------------------------
# The Python script is passed as a heredoc. We forward the arguments.
python3 - "$WIDTH" "$HEIGHT" "$OUTPUT_DIR" << 'EOF'
import sys
import math
import random
from pathlib import Path

try:
    from PIL import Image, ImageDraw, ImageFilter
except ImportError:
    print("ERROR: Pillow still not available after installation attempt.")
    sys.exit(1)

# ------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------
BG_COLOR = (10, 10, 10)
GRID_COLOR = (45, 45, 55)
LINEWORK_COLOR = (230, 230, 240)
GLOW_COLOR = (0, 245, 255)
ACCENT_COLOR = (180, 74, 255)

def draw_gear(draw, cx, cy, outer_r, teeth=18, angle_offset=0,
              color=LINEWORK_COLOR, width=2):
    inner_r = outer_r * 0.75
    points = []
    for i in range(teeth * 2):
        angle = (i / (teeth * 2)) * 2 * math.pi + angle_offset
        r = outer_r if i % 2 == 0 else inner_r
        x = cx + r * math.cos(angle)
        y = cy + r * math.sin(angle)
        points.append((x, y))
    draw.polygon(points, outline=color, fill=None, width=width)
    draw.ellipse([cx - 10, cy - 10, cx + 10, cy + 10],
                 outline=color, width=width)
    draw.line([cx - outer_r * 0.9, cy, cx + outer_r * 0.9, cy],
              fill=color, width=1)
    draw.line([cx, cy - outer_r * 0.9, cx, cy + outer_r * 0.9],
              fill=color, width=1)

def draw_gear_particles(draw, cx, cy, outer_r, color=GLOW_COLOR):
    for _ in range(40):
        angle = random.uniform(0, 2 * math.pi)
        radius = outer_r * random.uniform(0.95, 1.1)
        x = cx + radius * math.cos(angle)
        y = cy + radius * math.sin(angle)
        size = random.randint(2, 6)
        for r in range(size, 0, -1):
            alpha = int(120 * (r / size))
            draw.ellipse([x - r, y - r, x + r, y + r],
                         fill=(color[0], color[1], color[2], alpha))

def draw_rotation_arrows(draw, cx, cy, radius, color=GLOW_COLOR):
    for angle in [0, math.pi / 2, math.pi, 3 * math.pi / 2]:
        x1 = cx + radius * math.cos(angle)
        y1 = cy + radius * math.sin(angle)
        x2 = cx + (radius + 30) * math.cos(angle + 0.2)
        y2 = cy + (radius + 30) * math.sin(angle + 0.2)
        draw.line([(x1, y1), (x2, y2)], fill=color, width=3)
        ax = x2 - 5 * math.cos(angle + 0.2 + 0.5)
        ay = y2 - 5 * math.sin(angle + 0.2 + 0.5)
        draw.line([(x2, y2), (ax, ay)], fill=color, width=2)

def generate_background(width, height, output_path):
    img = Image.new("RGB", (width, height), BG_COLOR)
    draw = ImageDraw.Draw(img)

    # Grid
    step = 60
    for x in range(0, width, step):
        draw.line([(x, 0), (x, height)], fill=GRID_COLOR, width=1)
    for y in range(0, height, step):
        draw.line([(0, y), (width, y)], fill=GRID_COLOR, width=1)
    for x in range(0, width, 300):
        draw.line([(x, 0), (x, height)], fill=(60, 60, 80), width=2)
    for y in range(0, height, 300):
        draw.line([(0, y), (width, y)], fill=(60, 60, 80), width=2)

    # Dimension lines
    margin = 40
    draw.line([(margin, 100), (margin, height - 100)],
              fill=LINEWORK_COLOR, width=1)
    draw.line([(margin - 10, 100), (margin + 10, 100)],
              fill=LINEWORK_COLOR, width=1)
    draw.line([(margin - 10, height - 100), (margin + 10, height - 100)],
              fill=LINEWORK_COLOR, width=1)
    draw.line([(100, margin), (width - 100, margin)],
              fill=LINEWORK_COLOR, width=1)
    draw.line([(100, margin - 10), (100, margin + 10)],
              fill=LINEWORK_COLOR, width=1)
    draw.line([(width - 100, margin - 10), (width - 100, margin + 10)],
              fill=LINEWORK_COLOR, width=1)

    # Gears
    gears = [
        (550, height // 2, 220, 24, 0),
        (1370, height // 2, 220, 24, math.pi / 24),
        (width // 2, 240, 140, 16, math.pi / 8),
        (width // 2, height - 240, 140, 16, math.pi / 6),
        (280, 300, 90, 12, 0.2)
    ]
    for cx, cy, r, teeth, offset in gears:
        draw_gear(draw, cx, cy, r, teeth, offset)
        draw_gear_particles(draw, cx, cy, r)
        draw_rotation_arrows(draw, cx, cy, r + 30)

    # Labels
    try:
        from PIL import ImageFont
        font = ImageFont.truetype("/usr/share/fonts/truetype/liberation/LiberationMono-Regular.ttf", 16)
    except:
        font = None
    draw.text((480, 350), "R=220mm", fill=LINEWORK_COLOR, font=font)
    draw.text((1300, 350), "TEETH=24", fill=LINEWORK_COLOR, font=font)
    draw.text((width // 2 - 80, 100), "QUANTUM TORQUE",
              fill=ACCENT_COLOR, font=font)

    img.save(output_path, dpi=(300, 300))
    print(f"[+] Generated {output_path}")

def generate_slices(output_dir):
    slice_dir = Path(output_dir) / "gear_slices"
    slice_dir.mkdir(parents=True, exist_ok=True)

    Image.new("RGBA", (10, 10), (0, 0, 0, 0)).save(slice_dir / "menu_c.png")

    for name, (w, h) in [
        ("menu_n", (100, 10)), ("menu_s", (100, 10)),
        ("menu_w", (10, 40)), ("menu_e", (10, 40)),
        ("menu_ne", (10, 10)), ("menu_nw", (10, 10)),
        ("menu_se", (10, 10)), ("menu_sw", (10, 10))
    ]:
        img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        color = LINEWORK_COLOR + (255,)

        if "n" in name and "w" not in name and "e" not in name:
            for i in range(0, w, 12):
                draw.line([(i, 0), (i + 6, h)], fill=color, width=2)
        elif "s" in name and "w" not in name and "e" not in name:
            for i in range(0, w, 12):
                draw.line([(i, h), (i + 6, 0)], fill=color, width=2)
        elif "w" in name and "n" not in name and "s" not in name:
            for i in range(0, h, 10):
                draw.line([(0, i), (w, i + 5)], fill=color, width=2)
        elif "e" in name and "n" not in name and "s" not in name:
            for i in range(0, h, 10):
                draw.line([(w, i), (0, i + 5)], fill=color, width=2)
        else:
            draw.line([(0, 0), (w, 0)], fill=color, width=2)
            draw.line([(0, 0), (0, h)], fill=color, width=2)

        img = img.filter(ImageFilter.GaussianBlur(radius=1))
        img.save(slice_dir / f"{name}.png")

    print(f"[+] Generated 9‑slices in {slice_dir}")

def generate_progress_bars(output_dir):
    progress_dir = Path(output_dir)
    progress_dir.mkdir(parents=True, exist_ok=True)

    full = Image.new("RGBA", (100, 4), (0, 0, 0, 0))
    draw = ImageDraw.Draw(full)
    for i in range(100):
        alpha = int(255 * (i / 100))
        draw.line([(i, 0), (i, 4)], fill=(0, 245, 255, alpha), width=1)
    full.save(progress_dir / "progress_full_c.png")

    empty = Image.new("RGBA", (100, 4), (0, 0, 0, 0))
    draw = ImageDraw.Draw(empty)
    draw.rectangle([0, 0, 100, 4], outline=(60, 60, 80, 100), width=1)
    empty.save(progress_dir / "progress_empty_c.png")

    print(f"[+] Generated progress bar slices in {progress_dir}")

def main():
    if len(sys.argv) != 4:
        print("Usage: python3 -c '...' <width> <height> <output_dir>")
        sys.exit(1)
    width = int(sys.argv[1])
    height = int(sys.argv[2])
    output_dir = Path(sys.argv[3])
    output_dir.mkdir(parents=True, exist_ok=True)

    generate_background(width, height, output_dir / "background.png")
    generate_slices(output_dir)
    generate_progress_bars(output_dir)

    print("\n[✓] All assets generated successfully.")
    print(f"    Theme directory: {output_dir.absolute()}")

if __name__ == "__main__":
    main()
EOF

# -------------------------------------------------------------------
# 4. Done
# -------------------------------------------------------------------
echo ""
echo "[✓] Asset generation complete."
