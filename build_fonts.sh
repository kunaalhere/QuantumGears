#!/bin/sh
# Convert TTF fonts to GRUB .pf2 format
# Requires: grub-mkfont (from grub-common package)
# Place your .ttf files in the fonts/ directory before running.

set -e

FONT_DIR="fonts"
mkdir -p "$FONT_DIR"

# Convert Orbitron Bold
if [ -f "${FONT_DIR}/Orbitron-Bold.ttf" ]; then
    grub-mkfont -o "${FONT_DIR}/Orbitron-Bold.pf2" \
                -s 18 "${FONT_DIR}/Orbitron-Bold.ttf"
    echo "[+] Created Orbitron-Bold.pf2"
else
    echo "[-] Orbitron-Bold.ttf not found; skipping."
fi

# Convert JetBrains Mono Regular
if [ -f "${FONT_DIR}/JetBrainsMono-Regular.ttf" ]; then
    grub-mkfont -o "${FONT_DIR}/JetBrainsMono-Regular.pf2" \
                -s 16 "${FONT_DIR}/JetBrainsMono-Regular.ttf"
    echo "[+] Created JetBrainsMono-Regular.pf2"
else
    echo "[-] JetBrainsMono-Regular.ttf not found; skipping."
fi

echo "[✓] Font conversion complete."
