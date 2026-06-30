# BamOS Font Strategy
#
# Vietnamese font ecosystem for BamOS — three-tier approach:
#
# =============================================================================
# Tier 1: Open-Source Fonts (RPM packages, pre-installed in image)
# =============================================================================
#
# Font                    | RPM Package                       | Usage
# ----------------------- | --------------------------------- | -------------------
# Noto Sans Vietnamese    | google-noto-sans-vietnamese-fonts | Default UI font
# Noto Serif Vietnamese   | google-noto-serif-vietnamese-fonts| Reading, e-books
# Noto Sans Mono VN       | google-noto-sans-mono-vietnamese  | Terminal, code
# Noto Sans CJK           | google-noto-sans-cjk-fonts        | Fallback CJK
# Inter                   | rsms-inter-fonts                  | Modern UI (GNOME)
# Maple Mono NF           | maple-fonts                       | Monospace with icons
# Liberation Sans/Serif   | liberation-fonts                  | MS font replacements
#
# =============================================================================
# Tier 2: Microsoft Font Replacements (Open-source equivalents)
# =============================================================================
#
# MS Font        | Replacement      | Notes
# -------------- | ---------------- | -----------------------------------
# Times New Roman| Liberation Serif | Metric-compatible
# Arial          | Liberation Sans  | Metric-compatible  
# Tahoma         | Liberation Sans  | Close match
# Courier New    | Liberation Mono  | Metric-compatible
#
# These are pre-installed so .docx files render correctly without
# the actual Microsoft fonts.
#
# =============================================================================
# Tier 3: Proprietary Vietnamese Fonts (User-installed)
# =============================================================================
#
# These fonts are commercial/proprietary and CANNOT be bundled:
#
# VNI Fonts:       vni-times.ttf, vni-helve.ttf, vni-aptima.ttf
# VN-Times Fonts:  .VnTime.ttf, .VnArial.ttf, .VnTimeH.ttf
# Microsoft Fonts: times.ttf, arial.ttf, tahoma.ttf
#
# Users can install them via:
#   1. bamos setup-fonts-vn-proprietary (copies from Windows dual-boot)
#   2. bamos setup-fonts-ms (downloads MS Core Fonts via cabextract)
#
# =============================================================================
# Build-time font strategy
# =============================================================================
#
# Fonts are bundled into the image through three mechanisms:
#
# 1. RPM packages (Tier 1) — installed by rpm-ostree in Containerfile:
#    RUN rpm-ostree install google-noto-* rsms-inter-fonts maple-fonts
#
# 2. Fontconfig configuration (Tier 1+2) — copied from system_files/fonts/:
#    COPY system_files/fonts/fontconfig-vn.conf /etc/fonts/conf.d/
#    COPY system_files/fonts/liberation-replacements.conf /etc/fonts/conf.d/
#
# 3. User-installed (Tier 3) — deferred to first boot via bamos CLI:
#    bamos setup-fonts-vn-proprietary   # Import from Windows partition
#    bamos setup-fonts-ms               # Download MS Core Fonts
#
# After all fonts are in place, fc-cache -fv rebuilds the font cache.
