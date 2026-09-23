# Catalogue các tính năng và nhóm ứng dụng BamOS.
# Source of truth duy nhất: sinh các options `bam.features.*` và file /etc/bam/customizer/catalog.json.

{
  groups = {
    office = {
      label = {
        vi = "Văn phòng";
        en = "Office";
      };
      description = {
        vi = "Bộ ứng dụng văn phòng, duyệt web và công việc trực tuyến.";
        en = "Office suites, web browser and online collaboration tools.";
      };
      apps = {
        libreoffice = {
          label = {
            vi = "LibreOffice (soạn thảo, bảng tính, trình chiếu)";
            en = "LibreOffice (Writer, Calc, Impress)";
          };
        };
        google-chrome = {
          label = {
            vi = "Google Chrome (trình duyệt web)";
            en = "Google Chrome (web browser)";
          };
        };
        google-docs = {
          label = {
            vi = "Google Docs / Sheets / Slides (Web Apps)";
            en = "Google Docs / Sheets / Slides (Web Apps)";
          };
        };
        zoom = {
          label = {
            vi = "Zoom (họp trực tuyến)";
            en = "Zoom (online meetings)";
          };
        };
        wpsoffice = {
          label = {
            vi = "WPS Office (tương thích MS Office)";
            en = "WPS Office (MS Office compatibility)";
          };
        };
      };
    };

    gaming = {
      label = {
        vi = "Trò chơi (Gaming)";
        en = "Gaming";
      };
      description = {
        vi = "Nền tảng chơi game và các công cụ tối ưu hiệu năng.";
        en = "Gaming platforms and performance optimization tools.";
      };
      apps = {
        steam = {
          label = {
            vi = "Steam (nền tảng game Valve)";
            en = "Steam (Valve game platform)";
          };
        };
        gamemode = {
          label = {
            vi = "Feral GameMode (tối ưu CPU/GPU khi chơi game)";
            en = "GameMode (CPU/GPU game optimizer)";
          };
        };
        mangohud = {
          label = {
            vi = "MangoHud (hiển thị FPS, nhiệt độ và thông số)";
            en = "MangoHud (FPS and hardware overlay)";
          };
        };
        heroic = {
          label = {
            vi = "Heroic Games Launcher (Epic Games & GOG)";
            en = "Heroic Games Launcher (Epic Games & GOG)";
          };
        };
        lutris = {
          label = {
            vi = "Lutris (quản lý game & Wine runner)";
            en = "Lutris (game manager & Wine runner)";
          };
        };
      };
    };

    dev = {
      label = {
        vi = "Lập trình (Development)";
        en = "Development";
      };
      description = {
        vi = "Môi trường phát triển, biên tập mã và các công cụ lập trình viên.";
        en = "Development tools, editors and developer toolchain.";
      };
      apps = {
        zed = {
          label = {
            vi = "Zed Editor (trình biên tập siêu tốc)";
            en = "Zed Editor (high-performance editor)";
          };
        };
        devenv = {
          label = {
            vi = "Devenv & Direnv (môi trường lập trình cô lập)";
            en = "Devenv & Direnv (reproducible developer environments)";
          };
        };
        neovim = {
          label = {
            vi = "Neovim (cấu hình BamOS chuẩn hóa)";
            en = "Neovim (BamOS tailored configuration)";
          };
        };
        git-tools = {
          label = {
            vi = "Git, Lazygit & Delta pager";
            en = "Git, Lazygit & Delta pager";
          };
        };
        docker = {
          label = {
            vi = "Docker / Podman container runtime";
            en = "Docker / Podman container runtime";
          };
        };
      };
    };

    studio = {
      label = {
        vi = "Sáng tạo nội dung (Studio)";
        en = "Content Creation";
      };
      description = {
        vi = "Phần mềm thu âm, quay màn hình, dựng phim và thiết kế.";
        en = "Recording, streaming, audio and video production tools.";
      };
      apps = {
        obs-studio = {
          label = {
            vi = "OBS Studio (quay màn hình, livestream NVENC/VAAPI)";
            en = "OBS Studio (recording & livestreaming)";
          };
        };
        audacity = {
          label = {
            vi = "Audacity (chỉnh sửa âm thanh)";
            en = "Audacity (audio editor)";
          };
        };
        kdenlive = {
          label = {
            vi = "Kdenlive (dựng video đa tính năng)";
            en = "Kdenlive (non-linear video editor)";
          };
        };
        gimp = {
          label = {
            vi = "GIMP (chỉnh sửa ảnh chuyên nghiệp)";
            en = "GIMP (image manipulation)";
          };
        };
        creator-fonts = {
          label = {
            vi = "Bộ phông chữ sáng tạo đồ họa (Google Fonts, Việt hóa)";
            en = "Creator typography & Vietnamese localized fonts";
          };
        };
      };
    };

    system = {
      label = {
        vi = "Tiện ích hệ thống";
        en = "System Utilities";
      };
      description = {
        vi = "Bộ gõ tiếng Việt, in ấn, quản lý điện năng và cập nhật tự động.";
        en = "Vietnamese input method, printing, power tuning and auto-updates.";
      };
      apps = {
        fcitx5-unikey = {
          label = {
            vi = "Bộ gõ tiếng Việt Unikey (Fcitx5)";
            en = "Vietnamese Input Method (Fcitx5 Unikey)";
          };
        };
        printing = {
          label = {
            vi = "Dịch vụ in ấn CUPS";
            en = "CUPS Printing Service";
          };
        };
        power-tuning = {
          label = {
            vi = "Tối ưu pin & nguồn (TLP + s2idle cho Laptop)";
            en = "Power tuning (TLP & suspend optimizations)";
          };
        };
        auto-update = {
          label = {
            vi = "Tự động cập nhật hệ thống định kỳ";
            en = "Periodic automated system updates";
          };
        };
      };
    };
  };

  # Presets: các nhóm kích hoạt mặc định theo profile
  profiles = {
    standard = [
      "office"
      "system"
    ];
    dev = [
      "office"
      "dev"
      "system"
    ];
    studio = [
      "office"
      "studio"
      "system"
    ];
    gaming = [
      "office"
      "gaming"
      "system"
    ];
    all = [
      "office"
      "dev"
      "studio"
      "gaming"
      "system"
    ];
  };

  # Ứng dụng ngoại lệ không bật mặc định dù nhóm được bật
  profileAppOverrides = {
    standard = {
      office = {
        wpsoffice = false;
      };
    };
    gaming = {
      office = {
        wpsoffice = false;
      };
    };
  };
}
