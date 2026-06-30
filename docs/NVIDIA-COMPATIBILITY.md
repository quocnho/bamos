# NVIDIA Compatibility Reference for BamOS
#
# This document maps NVIDIA GPU generations to the appropriate driver
# and describes known limitations for each generation.
#
# Driver Types:
#   nvidia-open  - Open GPU kernel modules (modern, recommended for Turing+)
#   nvidia       - Proprietary/closed driver (required for Maxwell/Pascal)
#   nvidia-legacy - Legacy 470xx series (Kepler only, EOL)
#
# =============================================================================

# Blackwell (RTX 50 series) - 2025+
GPU_GEN_BLACKWELL:
  codenames: ["GB202", "GB203", "GB205", "GB206", "GB207"]
  products:
    - "GeForce RTX 5090, 5080, 5070 Ti, 5070, 5060 Ti, 5060"
  driver: "nvidia-open"
  min_driver: "570"
  wayland: true
  nvenc: "9th Gen"
  cuda: "12.8+"
  notes: "Requires nvidia-open driver. Closed driver NOT supported."

# Ada Lovelace (RTX 40 series) - 2022-2024
GPU_GEN_ADA_LOVELACE:
  codenames: ["AD102", "AD103", "AD104", "AD106", "AD107"]
  products:
    - "GeForce RTX 4090, 4080, 4070 Ti, 4070, 4060 Ti, 4060"
    - "RTX 4000 Ada, RTX 5000 Ada, RTX 6000 Ada"
  driver: "nvidia-open"
  min_driver: "525"
  wayland: true
  nvenc: "8th Gen (dual encoder on AD102/AD103)"
  cuda: "8.9"
  notes: "Open driver recommended. Closed driver also works for non-RTX 50."

# Ampere (RTX 30 series) - 2020-2022
GPU_GEN_AMPERE:
  codenames: ["GA102", "GA103", "GA104", "GA106", "GA107"]
  products:
    - "GeForce RTX 3090 Ti, 3090, 3080 Ti, 3080, 3070 Ti, 3070, 3060 Ti, 3060, 3050"
    - "RTX A6000, RTX A5000, RTX A4000, RTX A2000"
  driver: "nvidia-open"  # or nvidia
  min_driver: "470"
  wayland: true
  nvenc: "7th Gen"
  cuda: "8.6"
  notes: "Both open and closed drivers work. Open recommended."

# Turing (RTX 20 / GTX 16 series) - 2018-2020
GPU_GEN_TURING:
  codenames: ["TU102", "TU104", "TU106", "TU116", "TU117"]
  products:
    - "GeForce RTX 2080 Ti, 2080 Super, 2080, 2070 Super, 2070, 2060 Super, 2060"
    - "GeForce GTX 1660 Ti, 1660 Super, 1660, 1650 Super, 1650"
    - "Quadro RTX 8000, 6000, 5000, 4000"
    - "Tesla T4"
  driver: "nvidia-open"  # or nvidia
  min_driver: "440"
  wayland: true
  nvenc: "6th/7th Gen"
  cuda: "7.5"
  notes: "First generation supporting open kernel modules (experimental). Both work."

# Volta - 2017-2018
GPU_GEN_VOLTA:
  codenames: ["GV100", "GV100GL"]
  products:
    - "Titan V, Titan V CEO Edition"
    - "Quadro GV100"
    - "Tesla V100, V100S"
  driver: "nvidia"  # Closed driver only
  min_driver: "390"
  wayland: true
  nvenc: "6th Gen (GV100 only)"
  cuda: "7.0"
  notes: "Workstation/server GPUs only. No consumer cards."

# Pascal (GTX 10 series) - 2016-2018
GPU_GEN_PASCAL:
  codenames: ["GP102", "GP104", "GP106", "GP107", "GP108", "GP100"]
  products:
    - "GeForce GTX 1080 Ti, 1080, 1070 Ti, 1070, 1060, 1050 Ti, 1050"
    - "GeForce GT 1030, 1010"
    - "Quadro P6000, P5000, P4000, P2000, P1000, P600, P400"
    - "Tesla P100, P40, P4"
  driver: "nvidia"  # Closed driver ONLY
  min_driver: "375"
  wayland: true  # Works with modeset=1
  nvenc: "4th/5th Gen"
  cuda: "6.0-6.1"
  notes: "No open driver support. Closed driver works well with modeset=1."

# Maxwell v2 (GTX 900 series) - 2014-2016
GPU_GEN_MAXWELL_V2:
  codenames: ["GM200", "GM204", "GM206"]
  products:
    - "GeForce GTX 980 Ti, 980, 970, 960, 950"
    - "GeForce GTX Titan X"
    - "Quadro M6000, M5000, M4000, M2000"
    - "Tesla M60, M40, M6, M4"
  driver: "nvidia"  # Closed driver ONLY
  min_driver: "345"
  wayland: true  # Works with modeset=1
  nvenc: "4th Gen (GM20x only)"
  cuda: "5.2"
  notes: "Works with current closed driver. Set modeset=1 for Wayland."

# Maxwell v1 (GTX 700 series Maxwell) - 2014
GPU_GEN_MAXWELL_V1:
  codenames: ["GM107", "GM108"]
  products:
    - "GeForce GTX 750 Ti, 750"
    - "GeForce GTX 745, 740 (OEM)"
  driver: "nvidia"  # Closed driver ONLY
  min_driver: "340"
  wayland: true  # Limited support
  nvenc: "4th Gen (GM107)"
  cuda: "5.0"
  notes: "First generation Maxwell. Still supported by current drivers."

# Kepler (GTX 600/700 series) - 2012-2014
GPU_GEN_KEPLER:
  codenames: ["GK104", "GK106", "GK107", "GK110", "GK208", "GK210"]
  products:
    - "GeForce GTX 780 Ti, 780, 770, 760 Ti, 760, 660 Ti, 660, 650 Ti, 650, 640, 630, 620"
    - "GeForce GT 730, 720, 710, 705"
    - "GeForce GTX Titan, Titan Black, Titan Z"
    - "Quadro K6000, K5200, K5000, K4200, K4000, K2200, K2000, K600, K420"
  driver: "nvidia-legacy"  # 470xx legacy series ONLY
  min_driver: "470"
  wayland: false  # NO Wayland support with legacy driver
  nvenc: "1st/2nd Gen"
  cuda: "3.0-3.7"
  notes: |
    EOL (End of Life) as of September 2021.
    Last driver: 470.xx series (security fixes only).
    NO Wayland support - X11 only.
    Limited CUDA support (compute capability 3.0-3.7).
    Consider upgrading GPU for modern features.
    BamOS provides best-effort support only.

# Fermi and older - NOT SUPPORTED
# GeForce 500 series and older - No driver support in modern kernels
