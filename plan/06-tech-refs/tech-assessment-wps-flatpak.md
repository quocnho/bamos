# Technology Assessment: WPS Office Flatpak

**Date:** 2026-07-06
**Researched by:** AI Agent (tech skill)
**Status:** ✅ Complete

## Executive Summary

WPS Office Flatpak (`com.wps.Office`) is available on Flathub v11.1.0.11723 — cùng phiên bản với Nix package. Chạy trên runtime `org.freedesktop.Platform/x86_64/25.08`. Font và DPI issues có thể fix được qua `flatpak override` + host fonts.

## Sandbox Analysis (từ Flatpak manifest)

| Permission | Value | Issue? |
|-----------|-------|--------|
| Runtime | org.freedesktop.Platform 25.08 | ✅ Có sẵn font basic |
| Filesystem | xdg-documents, xdg-download, xdg-pictures, xdg-videos, /run/media, /media | ❌ **Không có host fonts** |
| Environment | QT_PLUGIN_PATH set | ❌ **Không có QT_AUTO_SCREEN_SCALE_FACTOR etc.** |
| Sockets | x11, pulseaudio | ✅ |
| Devices | dri | ✅ GPU acceleration |

## Issues & Fixes

### Issue 1: Missing fonts (Wingdings, Symbol, Chinese fonts)
- **Root cause**: Flatpak sandbox không có access đến host fonts
- **Fix**: `flatpak override --filesystem=/run/current-system/sw/share/fonts`
- **Host fonts cần**: noto-fonts-cjk, unifont, liberation_ttf

### Issue 2: "System DPI is asymmetric"
- **Root cause**: WPS bundles Qt 5.12 không set DPI env vars
- **Fix**: `flatpak override --env=QT_AUTO_SCREEN_SCALE_FACTOR=0 --env=QT_SCALE_FACTOR=1`

### Issue 3: Font hinting ignored
- **Root cause**: WPS's bundled Qt ignores fontconfig hinting
- **Fix**: `flatpak override --env=QT_ENABLE_HIGHDPI_SCALING=0`

## Flatpak Override Command

```bash
flatpak override com.wps.Office \
  --filesystem=/run/current-system/sw/share/fonts \
  --filesystem=xdg-config/fontconfig:ro \
  --env=QT_AUTO_SCREEN_SCALE_FACTOR=0 \
  --env=QT_SCALE_FACTOR=1 \
  --env=QT_ENABLE_HIGHDPI_SCALING=0
```

## Recommendation

✅ Cài WPS Office qua Flatpak + `flatpak override` để fix fonts và DPI.
Không cần module riêng — tích hợp vào `software-center.nix` sẵn có.
