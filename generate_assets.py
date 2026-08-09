#!/usr/bin/env python3
"""
Quantum Gear GRUB Theme Asset Generator
--------------------------------------
Generates:
  - background.png: deep black + blueprint grid + interlocking gears
  - gear_slices/menu_*.png: 9‑slice menu borders with gear‑tooth patterns
  - progress_*.png: progress bar slices (empty/full)

Usage:
    python3 generate_assets.py [--width W] [--height H] [--output-dir DIR]

Dependencies:
    Pillow (pip install Pillow)
"""

import argparse
import math
import random
import os
import sys
from pathlib import Path

try:
    from PIL import Image, ImageDraw, ImageFilter, ImageColor
except ImportError as e:
    print("ERROR: Pillow is required. Install with: pip install Pillow")
    sys.exit(1)

# ----- Configuration -----
DEFAULT_WIDTH = 1920
DEFAULT_HEIGHT = 1080

# Colours (RGB tuples)
BG_COLOR = (10, 10, 10)           # matte black
GRID_COLOR = (45, 45, 55)         # subtle grid
LINEWORK_COLOR = (230, 230, 240)  # off‑white chalk
GLOW_COLOR = (0, 245, 255)        # cyan (motion particles)
ACCENT_COLOR = (180, 74, 255)     # purple (secondary)


def draw_gear(draw, cx, cy, outer_r, teeth=18, angle_offset=0,
              color=LINEWORK_COLOR, width=2):
    """
    Draw a parametric gear (polygon) with inner hub and crosshairs.
    """
    inner_r = outer_r * 0.75
    points = []
    for i in range(teeth * 2):
        angle = (i / (teeth * 2)) * 2 * math.pi + angle_offset
        r = outer_r if i % 2 == 0 else inner_r
        x = cx + r * math.cos(angle)
        y = cy + r * math.sin(angle)
        points.append((x, y))
    draw.polygon(points, outline=color, fill=None, width=width)

    # Inner hub
    draw.ellipse([cx - 10, cy - 10, cx + 10, cy + 10],
                 outline=color, width=width)
    # Crosshair (schematic touch)
    draw.line([cx - outer_r * 0.9, cy, cx + outer_r * 0.9, cy],
              fill=color, width=1)
    draw.line([cx, cy - outer_r * 0.9, cx, cy + outer_r * 0.9],
              fill=color, width=1)


def draw_gear_particles(draw, cx, cy, outer_r, teeth=18, color=GLOW_COLOR):
    """
    Scatter glowing particles along the gear's edge to simulate motion.
    """
    for _ in range(40):
        angle = random.uniform(0, 2 * math.pi)
        radius = outer_r * random.uniform(0.95, 1.1)
        x = cx + radius * math.cos(angle)
        y = cy + radius * math.sin(angle)
        size = random.randint(2, 6)
        # Radial glow
        for r in range(size, 0, -1):
            alpha = int(120 * (r / size))
            draw.ellipse([x - r, y - r, x + r, y + r],
                         fill=(color[0], color[1], color[2], alpha))


def draw_rotation_arrows(draw, cx, cy, radius, color=GLOW_COLOR):
    """
    Add circular motion arrows around a gear.
    """
    for angle in [0, math.pi / 2, math.pi, 3 * math.pi / 2]:
        x1 = cx + radius * math.cos(angle)
        y1 = cy + radius * math.sin(angle)
        x2 = cx + (radius + 30) * math.cos(angle + 0.2)
        y2 = cy + (radius + 30) * math.sin(angle + 0.2)
        draw.line([(x1, y1), (x2, y2)], fill=color, width=3)
        # Arrowhead
        ax = x2 - 5 * math.cos(angle + 0.2 + 0.5)
        ay = y2 - 5 * math.sin(angle + 0.2 + 0.5)
        draw.line([(x2, y2), (ax, ay)], fill=color, width=2)


def generate_background(width, height, output_path):
    """
    Render the full background image.
    """
    img = Image.new("RGB", (width, height), BG_COLOR)
    draw = ImageDraw.Draw(img)

    # ---- 1. Blueprint Grid ----
    step = 60
    for x in range(0, width, step):
        draw.line([(x, 0), (x, height)], fill=GRID_COLOR, width=1)
    for y in range(0, height, step):
        draw.line([(0, y), (width, y)], fill=GRID_COLOR, width=1)
    # Heavy structural lines every 300px
    for x in range(0, width, 300):
        draw.line([(x, 0), (x, height)], fill=(60, 60, 80), width=2)
    for y in range(0, height, 300):
        draw.line([(0, y), (width, y)], fill=(60, 60, 80), width=2)

    # ---- 2. Dimension Lines (schematic style) ----
    margin = 40
    # Left vertical dimension
    draw.line([(margin, 100), (margin, height - 100)], fill=LINEWORK_COLOR, width=1)
    draw.line([(margin - 10, 100), (margin + 10, 100)], fill=LINEWORK_COLOR, width=1)
    draw.line([(margin - 10, height - 100), (margin + 10, height - 100)],
              fill=LINEWORK_COLOR, width=1)
    # Top horizontal
    draw.line([(100, margin), (width - 100, margin)], fill=LINEWORK_COLOR, width=1)
    draw.line([(100, margin - 10), (100, margin + 10)], fill=LINEWORK_COLOR, width=1)
    draw.line([(width - 100, margin - 10), (width - 100, margin + 10)],
              fill=LINEWORK_COLOR, width=1)

    # ---- 3. Interlocking Gears ----
    gears = [
        (550, height // 2, 220, 24, 0),          # left main
        (1370, height // 2, 220, 24, math.pi / 24), # right main (meshed)
        (width // 2, 240, 140, 16, math.pi / 8),   # top center
        (width // 2, height - 240, 140, 16, math.pi / 6), # bottom center
        (280, 300, 90, 12, 0.2)                    # small left
    ]
    for cx, cy, r, teeth, offset in gears:
        draw_gear(draw, cx, cy, r, teeth, offset)
        draw_gear_particles(draw, cx, cy, r, teeth)
        draw_rotation_arrows(draw, cx, cy, r + 30)

    # ---- 4. Schematic Labels ----
    # (PIL's default font is small, but we can use draw.text with optional font)
    try:
        from PIL import ImageFont
        # Try to load a system monospace font for labels
        font = ImageFont.truetype("/usr/share/fonts/truetype/liberation/LiberationMono-Regular.ttf", 16)
    except:
        font = None  # fallback to default

    draw.text((480, 350), "R=220mm", fill=LINEWORK_COLOR, font=font)
    draw.text((1300, 350), "TEETH=24", fill=LINEWORK_COLOR, font=font)
    draw.text((width // 2 - 80, 100), "QUANTUM TORQUE", fill=ACCENT_COLOR, font=font)

    # Save
    img.save(output_path, dpi=(300, 300))
    print(f"[+] Generated {output_path}")


def generate_slices(output_dir):
    """
    Generate all 9‑slice images for menu borders.
    GRUB expects: menu_{c,n,s,w,e,ne,nw,se,sw}.png
    """
    slice_dir = Path(output_dir) / "gear_slices"
    slice_dir.mkdir(parents=True, exist_ok=True)

    # Center (transparent)
    Image.new("RGBA", (10, 10), (0, 0, 0, 0)).save(slice_dir / "menu_c.png")

    # Edge slices with gear‑tooth patterns
    # We'll generate each as a small PNG with a dashed/chiseled line
    for name, (w, h) in [
        ("menu_n", (100, 10)), ("menu_s", (100, 10)),
        ("menu_w", (10, 40)), ("menu_e", (10, 40)),
        ("menu_ne", (10, 10)), ("menu_nw", (10, 10)),
        ("menu_se", (10, 10)), ("menu_sw", (10, 10))
    ]:
        img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        color = LINEWORK_COLOR + (255,)  # full opacity

        if "n" in name and "w" not in name and "e" not in name:
            # North edge: horizontal dashes
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
            # Corners: simple L‑shapes
            draw.line([(0, 0), (w, 0)], fill=color, width=2)
            draw.line([(0, 0), (0, h)], fill=color, width=2)

        # Add a subtle cyan glow around the edge
        img = img.filter(ImageFilter.GaussianBlur(radius=1))
        img.save(slice_dir / f"{name}.png")

    print(f"[+] Generated 9‑slices in {slice_dir}")


def generate_progress_bars(output_dir):
    """
    Generate progress bar slices: progress_full_c.png and progress_empty_c.png
    """
    progress_dir = Path(output_dir)
    progress_dir.mkdir(parents=True, exist_ok=True)

    # Full bar (cyan gradient)
    full = Image.new("RGBA", (100, 4), (0, 0, 0, 0))
    draw = ImageDraw.Draw(full)
    for i in range(100):
        alpha = int(255 * (i / 100))
        draw.line([(i, 0), (i, 4)], fill=(0, 245, 255, alpha), width=1)
    full.save(progress_dir / "progress_full_c.png")

    # Empty bar (dark, transparent)
    empty = Image.new("RGBA", (100, 4), (0, 0, 0, 0))
    draw = ImageDraw.Draw(empty)
    draw.rectangle([0, 0, 100, 4], outline=(60, 60, 80, 100), width=1)
    empty.save(progress_dir / "progress_empty_c.png")

    print(f"[+] Generated progress bar slices in {progress_dir}")


def main():
    parser = argparse.ArgumentParser(
        description="Generate assets for the Quantum Gear GRUB theme"
    )
    parser.add_argument("--width", type=int, default=DEFAULT_WIDTH,
                        help=f"Background width (default: {DEFAULT_WIDTH})")
    parser.add_argument("--height", type=int, default=DEFAULT_HEIGHT,
                        help=f"Background height (default: {DEFAULT_HEIGHT})")
    parser.add_argument("--output-dir", type=str, default="assets",
                        help="Output directory for assets (default: assets)")
    args = parser.parse_args()

    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    # Generate background
    bg_path = output_dir / "background.png"
    generate_background(args.width, args.height, bg_path)

    # Generate menu slices
    generate_slices(output_dir)

    # Generate progress bar
    generate_progress_bars(output_dir)

    print("\n[✓] All assets generated successfully.")
    print(f"    Theme directory: {output_dir.absolute()}")


if __name__ == "__main__":
    main()
