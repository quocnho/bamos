# modules/boot/calamares.nix
# Calamares installer — Unified Installer + Ổ C — Ổ D + Branding
#
# ═══════════════════════════════════════════════════════════════
# Tích hợp:
#   1. Partition: Btrfs Ổ C — Ổ D  (EFI + @ + @home + @nix + @data)
#   2. Edition selection: Standard/Developers/Gaming/Studio
#   3. Machine type: Laptop/Desktop/Server
#   4. Ổ D icon + Nautilus bookmark (custom drive icon)
#   5. Branding: logo, images, fonts (GLF-OS inspired)
#   6. /iso-cfg: post-install flake template cho updates
# ═══════════════════════════════════════════════════════════════
#
# Calamares config load từ:
#   1. /etc/calamares/modules/*.conf  (cao nhất — override)
#   2. /etc/calamares/bamos-modules/  (custom Python module)
#   3. Package calamares-nixos-extensions (mặc định)

{ config, lib, pkgs, ... }:

let
  # ═══════════════════════════════════════════════════════════
  # Ổ D icon — giống biểu tượng ổ đĩa Windows (D:)
  # Tự động thêm vào Nautilus sidebar sau cài đặt
  # ═══════════════════════════════════════════════════════════
  dataDriveIcon = pkgs.runCommand "data-drive-icon"
    {
      nativeBuildInputs = [ pkgs.librsvg ];
      preferLocalBuild = true;
    } ''
    mkdir -p $out/share/icons/hicolor/scalable/emblems
    mkdir -p $out/share/icons/hicolor/48x48/emblems

    # SVG icon — ổ D với nhãn DATA
    cat > $out/share/icons/hicolor/scalable/emblems/drive-data.svg << 'SVGEOF'
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
      <rect x="4" y="12" width="40" height="28" rx="3" fill="#4A90D9" stroke="#2C5F8A" stroke-width="2"/>
      <rect x="8" y="16" width="32" height="20" rx="2" fill="#E8F0FE"/>
      <text x="24" y="31" font-family="sans-serif" font-size="16" font-weight="bold" fill="#2C5F8A" text-anchor="middle">DATA</text>
    </svg>
    SVGEOF

    # PNG icon 48x48 từ SVG (with bootstrap fallback)
    if command -v rsvg-convert >/dev/null 2>&1; then
      rsvg-convert -w 48 -h 48 \
        $out/share/icons/hicolor/scalable/emblems/drive-data.svg \
        -o $out/share/icons/hicolor/48x48/emblems/drive-data.png
      echo "rsvg-convert: PNG icon created successfully"
    else
      echo "WARNING: rsvg-convert not found — using SVG as fallback"
      # Fallback: symlink SVG as PNG (GNOME will still render it)
      ln -sf \
        $out/share/icons/hicolor/scalable/emblems/drive-data.svg \
        $out/share/icons/hicolor/48x48/emblems/drive-data.png
    fi
  '';

  # ═══════════════════════════════════════════════════════════
  # Calamares branding assets (GLF-OS inspired)
  # ═══════════════════════════════════════════════════════════
  calamaresBranding = pkgs.runCommand "calamares-bamos-branding"
    {
      nativeBuildInputs = [ pkgs.librsvg ];
    } ''
    mkdir -p $out/share/calamares/branding/bamos/images
    mkdir -p $out/share/calamares/branding/bamos/lang

    # Logo
    cp ${pkgs.bamos-branding}/share/icons/hicolor/scalable/apps/bamos-logo.svg \
      $out/share/calamares/branding/bamos/images/bamos-logo.svg

    # ── Screenshots for packagechooser (SVG, Nord-themed) ──
    # Standard edition
    cat > $out/share/calamares/branding/bamos/images/standard.svg << 'EOF'
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 320 200">
      <defs><linearGradient id="std-bg" x1="0%" y1="0%" x2="100%" y2="100%">
        <stop offset="0%" stop-color="#2E3440"/><stop offset="100%" stop-color="#3B4252"/>
      </linearGradient></defs>
      <rect width="320" height="200" fill="url(#std-bg)"/>
      <rect x="8" y="8" width="304" height="184" rx="8" fill="none" stroke="#88C0D0" stroke-width="1.5" opacity="0.4"/>
      <circle cx="160" cy="70" r="28" fill="none" stroke="#88C0D0" stroke-width="2"/>
      <polygon points="160,48 166,62 180,62 169,72 173,86 160,78 147,86 151,72 140,62 154,62" fill="#88C0D0" opacity="0.8"/>
      <text x="160" y="125" font-family="sans-serif" font-size="16" font-weight="bold" fill="#ECEFF4" text-anchor="middle">Standard</text>
      <text x="160" y="145" font-family="sans-serif" font-size="10" fill="#81A1C1" text-anchor="middle">Desktop phổ thông</text>
      <text x="160" y="165" font-family="sans-serif" font-size="10" fill="#81A1C1" text-anchor="middle">Browser · Office · Media</text>
    </svg>
    EOF

    # Developers edition
    cat > $out/share/calamares/branding/bamos/images/developers.svg << 'EOF'
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 320 200">
      <defs><linearGradient id="dev-bg" x1="0%" y1="0%" x2="100%" y2="100%">
        <stop offset="0%" stop-color="#1a1a2e"/><stop offset="100%" stop-color="#16213e"/>
      </linearGradient></defs>
      <rect width="320" height="200" fill="url(#dev-bg)"/>
      <rect x="8" y="8" width="304" height="184" rx="8" fill="none" stroke="#8FBCBB" stroke-width="1.5" opacity="0.4"/>
      <text x="160" y="70" font-family="monospace" font-size="28" fill="#8FBCBB" text-anchor="middle">&lt;/&gt;</text>
      <text x="160" y="125" font-family="sans-serif" font-size="16" font-weight="bold" fill="#ECEFF4" text-anchor="middle">Developers</text>
      <text x="160" y="145" font-family="sans-serif" font-size="10" fill="#81A1C1" text-anchor="middle">Dành cho lập trình viên</text>
      <text x="160" y="165" font-family="sans-serif" font-size="10" fill="#81A1C1" text-anchor="middle">devenv · Podman · Distrobox</text>
    </svg>
    EOF

    # Gaming edition
    cat > $out/share/calamares/branding/bamos/images/gaming.svg << 'EOF'
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 320 200">
      <defs><linearGradient id="game-bg" x1="0%" y1="0%" x2="100%" y2="100%">
        <stop offset="0%" stop-color="#1a1a2e"/><stop offset="100%" stop-color="#191724"/>
      </linearGradient></defs>
      <rect width="320" height="200" fill="url(#game-bg)"/>
      <rect x="8" y="8" width="304" height="184" rx="8" fill="none" stroke="#BF616A" stroke-width="1.5" opacity="0.4"/>
      <!-- Gamepad icon -->
      <rect x="132" y="55" width="56" height="32" rx="6" fill="none" stroke="#BF616A" stroke-width="2"/>
      <circle cx="132" cy="71" r="4" fill="#BF616A"/>
      <circle cx="188" cy="71" r="4" fill="#BF616A"/>
      <line x1="132" y1="87" x2="132" y2="95" stroke="#BF616A" stroke-width="2"/>
      <line x1="188" y1="87" x2="188" y2="95" stroke="#BF616A" stroke-width="2"/>
      <text x="160" y="125" font-family="sans-serif" font-size="16" font-weight="bold" fill="#ECEFF4" text-anchor="middle">Gaming</text>
      <text x="160" y="145" font-family="sans-serif" font-size="10" fill="#81A1C1" text-anchor="middle">Tối ưu cho chơi game</text>
      <text x="160" y="165" font-family="sans-serif" font-size="10" fill="#81A1C1" text-anchor="middle">Steam · Lutris · GameScope</text>
    </svg>
    EOF

    # Studio edition
    cat > $out/share/calamares/branding/bamos/images/studio.svg << 'EOF'
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 320 200">
      <defs><linearGradient id="studio-bg" x1="0%" y1="0%" x2="100%" y2="100%">
        <stop offset="0%" stop-color="#2E3440"/><stop offset="100%" stop-color="#3B4252"/>
      </linearGradient></defs>
      <rect width="320" height="200" fill="url(#studio-bg)"/>
      <rect x="8" y="8" width="304" height="184" rx="8" fill="none" stroke="#B48EAD" stroke-width="1.5" opacity="0.4"/>
      <!-- Palette icon -->
      <circle cx="160" cy="70" r="22" fill="none" stroke="#B48EAD" stroke-width="2"/>
      <circle cx="160" cy="70" r="6" fill="#B48EAD"/>
      <rect x="145" y="58" width="6" height="6" rx="1" fill="#BF616A"/>
      <rect x="170" y="58" width="6" height="6" rx="1" fill="#88C0D0"/>
      <rect x="157" y="75" width="6" height="6" rx="1" fill="#A3BE8C"/>
      <text x="160" y="125" font-family="sans-serif" font-size="16" font-weight="bold" fill="#ECEFF4" text-anchor="middle">Studio</text>
      <text x="160" y="145" font-family="sans-serif" font-size="10" fill="#81A1C1" text-anchor="middle">Dành cho sáng tạo</text>
      <text x="160" y="165" font-family="sans-serif" font-size="10" fill="#81A1C1" text-anchor="middle">Blender · GIMP · OBS</text>
    </svg>
    EOF

    # Machine types — Laptop
    cat > $out/share/calamares/branding/bamos/images/laptop.svg << 'EOF'
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 320 200">
      <defs><linearGradient id="lap-bg" x1="0%" y1="0%" x2="100%" y2="100%">
        <stop offset="0%" stop-color="#2E3440"/><stop offset="100%" stop-color="#3B4252"/>
      </linearGradient></defs>
      <rect width="320" height="200" fill="url(#lap-bg)"/>
      <rect x="8" y="8" width="304" height="184" rx="8" fill="none" stroke="#88C0D0" stroke-width="1.5" opacity="0.4"/>
      <rect x="120" y="45" width="80" height="52" rx="4" fill="none" stroke="#88C0D0" stroke-width="2"/>
      <rect x="100" y="97" width="120" height="6" rx="2" fill="#88C0D0" opacity="0.6"/>
      <rect x="110" y="97" width="100" height="3" rx="1" fill="#81A1C1"/>
      <text x="160" y="130" font-family="sans-serif" font-size="16" font-weight="bold" fill="#ECEFF4" text-anchor="middle">Laptop</text>
      <text x="160" y="152" font-family="sans-serif" font-size="10" fill="#81A1C1" text-anchor="middle">Tiết kiệm pin · Suspend</text>
      <text x="160" y="168" font-family="sans-serif" font-size="10" fill="#81A1C1" text-anchor="middle">ASPM powersupersave</text>
    </svg>
    EOF

    # Machine types — Desktop
    cat > $out/share/calamares/branding/bamos/images/desktop.svg << 'EOF'
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 320 200">
      <defs><linearGradient id="desk-bg" x1="0%" y1="0%" x2="100%" y2="100%">
        <stop offset="0%" stop-color="#1a1a2e"/><stop offset="100%" stop-color="#16213e"/>
      </linearGradient></defs>
      <rect width="320" height="200" fill="url(#desk-bg)"/>
      <rect x="8" y="8" width="304" height="184" rx="8" fill="none" stroke="#A3BE8C" stroke-width="1.5" opacity="0.4"/>
      <rect x="115" y="40" width="90" height="56" rx="4" fill="none" stroke="#A3BE8C" stroke-width="2"/>
      <rect x="150" y="96" width="20" height="8" fill="#A3BE8C" opacity="0.6"/>
      <rect x="140" y="104" width="40" height="4" rx="1" fill="#A3BE8C" opacity="0.4"/>
      <text x="160" y="130" font-family="sans-serif" font-size="16" font-weight="bold" fill="#ECEFF4" text-anchor="middle">Desktop / PC</text>
      <text x="160" y="152" font-family="sans-serif" font-size="10" fill="#81A1C1" text-anchor="middle">Hiệu năng tối đa</text>
      <text x="160" y="168" font-family="sans-serif" font-size="10" fill="#81A1C1" text-anchor="middle">Không giới hạn năng lượng</text>
    </svg>
    EOF

    # Machine types — Server
    cat > $out/share/calamares/branding/bamos/images/server.svg << 'EOF'
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 320 200">
      <defs><linearGradient id="srv-bg" x1="0%" y1="0%" x2="100%" y2="100%">
        <stop offset="0%" stop-color="#2E3440"/><stop offset="100%" stop-color="#3B4252"/>
      </linearGradient></defs>
      <rect width="320" height="200" fill="url(#srv-bg)"/>
      <rect x="8" y="8" width="304" height="184" rx="8" fill="none" stroke="#EBCB8B" stroke-width="1.5" opacity="0.4"/>
      <rect x="130" y="40" width="60" height="72" rx="4" fill="none" stroke="#EBCB8B" stroke-width="2"/>
      <circle cx="160" cy="58" r="3" fill="#A3BE8C"/>
      <circle cx="160" cy="72" r="3" fill="#A3BE8C"/>
      <circle cx="160" cy="86" r="3" fill="#A3BE8C"/>
      <circle cx="160" cy="100" r="3" fill="#EBCB8B"/>
      <text x="160" y="135" font-family="sans-serif" font-size="16" font-weight="bold" fill="#ECEFF4" text-anchor="middle">Server</text>
      <text x="160" y="155" font-family="sans-serif" font-size="10" fill="#81A1C1" text-anchor="middle">Không GUI · throughput</text>
      <text x="160" y="171" font-family="sans-serif" font-size="10" fill="#81A1C1" text-anchor="middle">Tối ưu cho server workload</text>
    </svg>
    EOF

    # ── Slideshow HTML (API 1 — HTML-based) ──
    cat > $out/share/calamares/branding/bamos/slideshow.html << 'SLIDEEOF'
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8"/>
      <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
          background: #3B4252;
          color: #ECEFF4;
          font-family: 'Inter', 'Segoe UI', sans-serif;
          overflow: hidden;
          height: 100vh;
        }
        .slide {
          display: none;
          flex-direction: column;
          align-items: center;
          justify-content: center;
          height: 100vh;
          padding: 40px 60px;
          text-align: center;
        }
        .slide.active { display: flex; }
        .slide h1 {
          font-size: 32px;
          font-weight: 700;
          margin-bottom: 12px;
          color: #88C0D0;
        }
        .slide h2 {
          font-size: 20px;
          font-weight: 600;
          margin-bottom: 20px;
          color: #81A1C1;
        }
        .slide p {
          font-size: 15px;
          line-height: 1.7;
          max-width: 600px;
          color: #D8DEE9;
        }
        .slide p.vn {
          font-size: 14px;
          color: #81A1C1;
          margin-top: 8px;
        }
        .logo {
          width: 80px;
          height: 80px;
          margin-bottom: 16px;
        }
        .features {
          display: flex;
          gap: 24px;
          margin-top: 24px;
          flex-wrap: wrap;
          justify-content: center;
        }
        .feature {
          background: rgba(136,192,208,0.08);
          border: 1px solid rgba(136,192,208,0.2);
          border-radius: 12px;
          padding: 16px 20px;
          width: 140px;
          text-align: center;
        }
        .feature-icon {
          font-size: 28px;
          margin-bottom: 8px;
        }
        .feature-label {
          font-size: 12px;
          color: #81A1C1;
        }
        .nav-dots {
          position: fixed;
          bottom: 20px;
          left: 50%;
          transform: translateX(-50%);
          display: flex;
          gap: 10px;
        }
        .nav-dot {
          width: 10px;
          height: 10px;
          border-radius: 50%;
          background: #4C566A;
          cursor: pointer;
          transition: all 0.3s;
        }
        .nav-dot.active {
          background: #88C0D0;
          width: 24px;
          border-radius: 5px;
        }
      </style>
    </head>
    <body>

    <!-- SLIDE 1: Welcome -->
    <div class="slide active" data-slide="0">
      <img class="logo" src="images/bamos-logo.svg" alt="BamOS"/>
      <h1>Welcome to BamOS</h1>
      <p>NixOS distribution for the Vietnamese community</p>
      <p class="vn">Hệ điều hành NixOS dành cho cộng đồng Việt Nam</p>
      <div class="features">
        <div class="feature"><div class="feature-icon">🎋</div><div class="feature-label">Bamboo Modular</div></div>
        <div class="feature"><div class="feature-icon">🔄</div><div class="feature-label">Declarative</div></div>
        <div class="feature"><div class="feature-icon">🎨</div><div class="feature-label">Nord Design</div></div>
        <div class="feature"><div class="feature-icon">🛡️</div><div class="feature-label">Reproducible</div></div>
      </div>
    </div>

    <!-- SLIDE 2: Ổ C — Ổ D Partitioning -->
    <div class="slide" data-slide="1">
      <h1>💾 Ổ C — Ổ D Partitioning</h1>
      <p>Automatic Btrfs layout with separate data volume.<br/>
      Your system stays clean while your files live on Ổ D.</p>
      <p class="vn">Phân vùng tự động Btrfs: Ổ C cho hệ thống, Ổ D cho dữ liệu.</p>
      <div class="features">
        <div class="feature"><div class="feature-icon">💻</div><div class="feature-label">Ổ C: System</div></div>
        <div class="feature"><div class="feature-icon">📁</div><div class="feature-label">Ổ D: /data</div></div>
        <div class="feature"><div class="feature-icon">🔐</div><div class="feature-label">LUKS Encryption</div></div>
        <div class="feature"><div class="feature-icon">📦</div><div class="feature-label">Btrfs Snapshots</div></div>
      </div>
    </div>

    <!-- SLIDE 3: Editions -->
    <div class="slide" data-slide="2">
      <h1>📦 Four Editions</h1>
      <p>Choose the edition that fits your workflow.</p>
      <p class="vn">Chọn phiên bản phù hợp với nhu cầu của bạn.</p>
      <div class="features">
        <div class="feature"><div class="feature-icon">🖥️</div><div class="feature-label">Standard</div></div>
        <div class="feature"><div class="feature-icon">💻</div><div class="feature-label">Developers</div></div>
        <div class="feature"><div class="feature-icon">🎮</div><div class="feature-label">Gaming</div></div>
        <div class="feature"><div class="feature-icon">🎬</div><div class="feature-label">Studio</div></div>
      </div>
    </div>

    <!-- SLIDE 4: Machine Types -->
    <div class="slide" data-slide="3">
      <h1>💻 Machine Optimization</h1>
      <p>Tell us your hardware — we tune the kernel for you.</p>
      <p class="vn">Chọn loại máy để tối ưu hiệu năng.</p>
      <div class="features">
        <div class="feature"><div class="feature-icon">🔋</div><div class="feature-label">Laptop</div></div>
        <div class="feature"><div class="feature-icon">⚡</div><div class="feature-label">Desktop</div></div>
        <div class="feature"><div class="feature-icon">🖧</div><div class="feature-label">Server</div></div>
      </div>
    </div>

    <!-- SLIDE 5: NixOS Power -->
    <div class="slide" data-slide="4">
      <h1>⚙️ Built on NixOS</h1>
      <p>Declarative configuration, atomic upgrades, rollback at will.<br/>
      Your system is a function of its config file.</p>
      <p class="vn">Cấu hình khai báo, nâng cấp nguyên tử, khôi phục dễ dàng.</p>
      <div class="features">
        <div class="feature"><div class="feature-icon">📜</div><div class="feature-label">Declarative</div></div>
        <div class="feature"><div class="feature-icon">⏪</div><div class="feature-label">Rollback</div></div>
        <div class="feature"><div class="feature-icon">🔁</div><div class="feature-label">Atomic</div></div>
        <div class="feature"><div class="feature-icon">❄️</div><div class="feature-label">Reproducible</div></div>
      </div>
    </div>

    <!-- Navigation dots -->
    <div class="nav-dots">
      <div class="nav-dot active" onclick="goSlide(0)"></div>
      <div class="nav-dot" onclick="goSlide(1)"></div>
      <div class="nav-dot" onclick="goSlide(2)"></div>
      <div class="nav-dot" onclick="goSlide(3)"></div>
      <div class="nav-dot" onclick="goSlide(4)"></div>
    </div>

    <script>
      var current = 0;
      var total = 5;

      function goSlide(n) {
        document.querySelectorAll('.slide').forEach(function(s) { s.classList.remove('active'); });
        document.querySelectorAll('.nav-dot').forEach(function(d) { d.classList.remove('active'); });
        document.querySelector('.slide[data-slide="'+n+'"]').classList.add('active');
        document.querySelectorAll('.nav-dot')[n].classList.add('active');
        current = n;
      }

      // Auto-advance every 8 seconds
      setInterval(function() {
        goSlide((current + 1) % total);
      }, 8000);
    </script>
    </body>
    </html>
    SLIDEEOF

    # ── Branding descriptor ──
    cat > $out/share/calamares/branding/bamos/branding.desc << 'EOF'
    ---
    componentName: bamos
    name: BamOS
    version: "0.5.0"
    short: BamOS Linux
    description: A professional NixOS distribution for the Vietnamese community
    author: Nguyen Quoc Nho
    homepage: https://github.com/quocnho/bamos

    # Slideshow
    slideshow: "slideshow"
    slideshowAPI: 1

    # Style
    style:
      sidebarBackground: "#1a1a2e"
      sidebarText: "#ECEFF4"
      sidebarTextSelect: "#81A1C1"
      sidebarHighlight: "#88C0D0"
      headerBackground: "#2E3440"
      headerText: "#ECEFF4"
      headerFont: "Inter 11"
      bodyBackground: "#3B4252"
      bodyText: "#ECEFF4"
      bodyFont: "Inter 11"
      linkColor: "#88C0D0"

    # Strings
    strings:
      productName: BamOS
      shortProductName: BamOS
      version: 0.5.0
      welcomeMessage: "<h1>Welcome to BamOS.</h1><br/>NixOS distribution for the Vietnamese community.<br/>Please choose your language to begin."
      welcomeMessageVn: "<h1>Chào mừng đến với BamOS.</h1><br/>Hệ điều hành NixOS cho cộng đồng Việt Nam.<br/>Vui lòng chọn ngôn ngữ để bắt đầu."
      loadingMessage: "Please wait while BamOS prepares your installation environment..."
      installChoice: "Install BamOS"
      installationPrompt: "BamOS will be installed on your computer. All data on the selected disk will be lost."
      installationPromptVn: "BamOS sẽ được cài đặt trên máy tính của bạn. Toàn bộ dữ liệu trên ổ đĩa đã chọn sẽ bị mất."
    EOF
  '';

  # ═══════════════════════════════════════════════════════════
  # Custom Calamares Python module: bamos-config
  # Sinh edition-config.nix + /iso-cfg để người dùng update sau
  # ═══════════════════════════════════════════════════════════
  bamosCalamaresModule = pkgs.writeTextDir "lib/calamares/modules/bamos-config/module.desc" ''
    ---
    type:       "job"
    name:       "bamos-config"
    interface:  "python"
    script:     "main.py"
  '' // pkgs.writeTextDir "lib/calamares/modules/bamos-config/main.py" ''
        #!/usr/bin/env python3
        # BamOS Calamares module
        # Copies iso-cfg template → /etc/nixos/, applies user selections

        import libcalamares
        import os
        import shutil
        import stat

        def sed_inplace(filename, old, new):
            with open(filename, "r") as f:
                content = f.read()
            content = content.replace(old, new)
            with open(filename, "w") as f:
                f.write(content)

        def run():
            edition = libcalamares.globalStorage.value("packagechooser_edition") or "standard"
            machine = libcalamares.globalStorage.value("packagechooser_machine") or "desktop"
            hostname = libcalamares.globalStorage.value("hostname") or "bamos"
            root = libcalamares.globalStorage.value("rootMountPoint") or "/mnt"

            # Target: installed system's /etc/nixos/
            target = os.path.join(root, "etc", "nixos")
            os.makedirs(target, exist_ok=True)

            # Source: ISO's bundled iso-cfg template (from environment.etc)
            # On the ISO live, these are at /etc/nixos-template/
            template_dir = "/etc/nixos-template"

            if os.path.exists(template_dir):
                # Copy template files recursively
                for item in os.listdir(template_dir):
                    src = os.path.join(template_dir, item)
                    dst = os.path.join(target, item)
                    if os.path.isdir(src):
                        shutil.copytree(src, dst, dirs_exist_ok=True)
                    else:
                        shutil.copy2(src, dst)
            else:
                # Fallback: create minimal files
                with open(os.path.join(target, "flake.nix"), "w") as f:
                    f.write('''{
      description = "BamOS — My Configuration";
      inputs = {
        nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
        bamos.url = "github:quocnho/bamos";
      };
      outputs = { self, nixpkgs, bamos, ... }: {
        nixosConfigurations."'"'"' + hostname + '''"'"'"' = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [ ./configuration.nix bamos.nixosModules.default
            bamos.nixosModules."'"'"' + edition + '''"'"'"' ./hardware-configuration.nix ];
        };
      };
    }''')

            # Apply user selections to customized.nix
            customized_path = os.path.join(target, "customized.nix")
            if os.path.exists(customized_path):
                # Set edition
                edition_map = {
                    "standard": "bamos.nixosModules.standard",
                    "developers": "bamos.nixosModules.developers",
                    "gaming": "bamos.nixosModules.gaming",
                    "studio": "bamos.nixosModules.studio",
                }
                if edition in edition_map:
                    sed_inplace(customized_path,
                        "bamos.nixosModules.standard",
                        edition_map[edition])

                # Set machine type (battery or not)
                if machine == "laptop":
                    sed_inplace(customized_path,
                        "batteryOptimized = false;",
                        "batteryOptimized = true;")

            # Set hostname in configuration.nix
            config_path = os.path.join(target, "configuration.nix")
            if os.path.exists(config_path):
                sed_inplace(config_path, '"'"'"'bamos"'"'"', '"'"'"' + hostname + '"'"'"')

            return libcalamares.job.succeed(
                "BamOS config deployed: edition=%s, machine=%s, hostname=%s"
                % (edition, machine, hostname)
            )
  '';

  bamosModulePkg = pkgs.symlinkJoin {
    name = "calamares-bamos-module";
    paths = [ bamosCalamaresModule ];
  };

  # ═══════════════════════════════════════════════════════════
  # Partition layout: EFI + Btrfs Ổ C — Ổ D
  # ═══════════════════════════════════════════════════════════
  partitionConf = builtins.toJSON {
    efi = {
      mountPoint = "/boot";
      recommendedSize = "1GiB";
      minimumSize = "32MiB";
      label = "EFI";
    };
    userSwapChoices = [ "none" "small" "suspend" ];
    luksGeneration = "luks2";
    defaultFileSystemType = "btrfs";
    availableFileSystemTypes = [ "ext4" "btrfs" "xfs" "f2fs" ];
    showNotEncryptedBootMessage = false;
    partitionLayout = [{
      name = "root";
      filesystem = "btrfs";
      noEncrypt = false;
      mountPoint = "/";
      size = "100%";
    }];
  };

  mountConf = builtins.toJSON {
    extraMounts = [
      { device = "proc"; fs = "proc"; mountPoint = "/proc"; }
      { device = "sys"; fs = "sysfs"; mountPoint = "/sys"; }
      { device = "/dev"; mountPoint = "/dev"; options = [ "bind" ]; }
      { device = "tmpfs"; fs = "tmpfs"; mountPoint = "/run"; }
      { device = "/run/udev"; mountPoint = "/run/udev"; options = [ "bind" ]; }
      { device = "efivarfs"; fs = "efivarfs"; mountPoint = "/sys/firmware/efi/efivars"; efi = true; }
    ];
    btrfsSubvolumes = [
      { mountPoint = "/"; subvolume = ""; }
      { mountPoint = "/home"; subvolume = "/home"; }
      { mountPoint = "/nix"; subvolume = "/nix"; }
      { mountPoint = "/data"; subvolume = "/data"; }
    ];
    mountOptions = [
      { filesystem = "efi"; options = [ "fmask=0077" "dmask=0077" ]; }
      { filesystem = "btrfs"; options = [ "compress=zstd" "noatime" ]; }
    ];
  };

  # ═══════════════════════════════════════════════════════════
  # Packagechooser: Edition selector
  # ═══════════════════════════════════════════════════════════
  editionConf = builtins.toJSON {
    mode = "required";
    method = "legacy";
    labels = { step = "Edition"; };
    default = "standard";
    items = [
      {
        id = "standard";
        name = "BamOS Standard";
        description = "<html>Desktop pho thong — browser, office, media.<br/>Phu hop cho nguoi dung van phong, hoc tap, giai tri co ban.</html>";
        screenshot = "images/standard.svg";
        packages = [ ];
      }
      {
        id = "developers";
        name = "BamOS Developers";
        description = "<html>Danh cho lap trinh vien — devenv, Podman, Distrobox, dev tools.<br/>Bao gom VM tools, Git, CI/CD tools.</html>";
        screenshot = "images/developers.svg";
        packages = [ ];
      }
      {
        id = "gaming";
        name = "BamOS Gaming";
        description = "<html>Toi uu cho choi game — Steam, Lutris, Heroic, GameScope, MangoHud.<br/>Kernel XanMod + tuned latency-performance.</html>";
        screenshot = "images/gaming.svg";
        packages = [ ];
      }
      {
        id = "studio";
        name = "BamOS Studio";
        description = "<html>Danh cho sang tao — Blender, GIMP, Krita, Ardour, OBS.<br/>Low-latency audio + color management.</html>";
        screenshot = "images/studio.svg";
        packages = [ ];
      }
    ];
  };

  # Packagechooser: Machine type selector
  machineConf = builtins.toJSON {
    mode = "required";
    method = "legacy";
    labels = { step = "Machine Type"; };
    default = "desktop";
    items = [
      {
        id = "laptop";
        name = "Laptop";
        description = "<html>Toi uu cho laptop — tiet kiem pin, ASPM powersupersave, WiFi power saving, suspend/hibernate.</html>";
        screenshot = "images/laptop.svg";
        packages = [ ];
      }
      {
        id = "desktop";
        name = "Desktop / PC";
        description = "<html>Cau hinh cho PC ban — hieu nang toi da, khong gioi han nang luong.</html>";
        screenshot = "images/desktop.svg";
        packages = [ ];
      }
      {
        id = "server";
        name = "Server";
        description = "<html>Khong GUI, throughput-performance, toi uu cho server workload.</html>";
        screenshot = "images/server.svg";
        packages = [ ];
      }
    ];
  };

  # Override settings.conf — custom sequence
  settingsConf = builtins.toJSON {
    modules-search = [
      "local"
      "/nix/store/1jwbzck0dvj00vqvxnymgpc3s4k8yl2z-calamares-nixos-extensions-0.3.23/lib/calamares/modules"
      "${bamosModulePkg}/lib/calamares/modules"
    ];
    instances = [
      { id = "edition"; module = "packagechooser"; config = "packagechooser-edition.conf"; }
      { id = "machine"; module = "packagechooser"; config = "packagechooser-machine.conf"; }
      { id = "unfree"; module = "notesqml"; config = "unfree.conf"; }
      { module = "nixos"; weight = 48; }
      { module = "bamos-config"; weight = 1; }
    ];
    sequence = [
      { show = [ "welcome" "locale" "keyboard" "users" "packagechooser@edition" "packagechooser@machine" "notesqml@unfree" "partition" "summary" ]; }
      { exec = [ "partition" "mount" "bamos-config" "nixos" "users" "umount" ]; }
      { show = [ "finished" ]; }
    ];
    branding = "bamos";
    prompt-install = false;
    dont-chroot = false;
    oem-setup = false;
    disable-cancel = false;
    disable-cancel-during-exec = false;
    quit-at-end = false;
  };

in
{
  environment.etc = {
    "calamares/modules/partition.conf".text = partitionConf;
    "calamares/modules/mount.conf".text = mountConf;
    "calamares/modules/packagechooser-edition.conf".text = editionConf;
    "calamares/modules/packagechooser-machine.conf".text = machineConf;
    "calamares/settings.conf".text = settingsConf;
    "calamares/branding/bamos/branding.desc".source = "${calamaresBranding}/share/calamares/branding/bamos/branding.desc";
  };

  environment.systemPackages = with pkgs; [
    bamosModulePkg
    calamaresBranding
    dataDriveIcon
  ];

  # ── Expose iso-cfg template to ISO live environment ──
  # Calamares Python module sẽ copy từ đây vào /etc/nixos/ khi cài đặt
  environment.etc."nixos-template/flake.nix".source = ../../iso-cfg/flake.nix;
  environment.etc."nixos-template/configuration.nix".source = ../../iso-cfg/configuration.nix;
  environment.etc."nixos-template/customized.nix".source = ../../iso-cfg/customized.nix;
  environment.etc."nixos-template/customConfig/default.nix".source = ../../iso-cfg/customConfig/default.nix;
}
