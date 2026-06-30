#!/bin/bash
# bamos-dpi.sh — Consistent DPI across all toolkits
# Prevents "System DPI asymmetric" warnings in Qt/GTK/WPS Office
# Sets 96 DPI as the consistent baseline across:
#   - Xft (X11 font rendering)
#   - GTK (via GDK_DPI_SCALE)
#   - Qt (via QT_SCALE_FACTOR / QT_FONT_DPI)
#   - XWayland

# Xft DPI (applied to all X11/XWayland apps)
export XFT_DPI=96

# GDK/GTK scaling (1.0 = no extra scaling, base 96 DPI)
export GDK_DPI_SCALE=1
export GDK_SCALE=1

# Qt scaling
export QT_SCALE_FACTOR=1
export QT_FONT_DPI=96
export QT_AUTO_SCREEN_SCALE_FACTOR=0

# XWayland (prevents blurry fonts in XWayland apps like WPS Office)
export XWAYLAND_FORCE_DPI=96

# Electron apps (VSCode, etc.)
export ELECTRON_ENABLE_WAYLAND=1
