# Giao diện GNOME + GDM + cài đặt dconf mặc định.
# Tham khảo `environments/gnome.nix` của GLF-OS (bộ extensions & tools).
#
# LƯU Ý: cấu hình gesture/chuột giữ MẶC ĐỊNH của NixOS/GNOME (gesture 3
# ngón tay chuyển workspace, tap-to-click, cuộn tự nhiên...). Không cài
# libinput-gestures/xdotool nữa — đã bỏ khỏi packages.nix.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.gnome;
  localFonts = pkgs.callPackage ../assets/fonts/fonts.nix { };
in
{
  options.my.gnome = {
    enable = lib.mkEnableOption "GNOME desktop";

    store = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        GNOME Software ("App Store") + Flatpak backend.
        Bật cho máy người dùng cuối (cài app qua store). Máy DEVELOPER nên tắt
        (my.gnome.store = false): GNOME Software ~160MB + flatpak helper chạy
        ngầm + refresh kho Flathub định kỳ — developer cài app qua Nix là đủ.
      '';
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        services.xserver.enable = true;
        services.displayManager.gdm.enable = true;
        services.desktopManager.gnome.enable = true;

        environment.gnome.excludePackages = with pkgs; [
          gnome-tour
          totem
          yelp
          gnome-contacts
          gnome-weather
          gnome-maps
        ];

        environment.systemPackages = with pkgs; [
          gnome-tweaks

          # ==== GNOME Extensions (bộ của GLF-OS) ====
          gnomeExtensions.caffeine
          gnomeExtensions.appindicator
          # gnomeExtensions.gsconnect
          gnomeExtensions.dash-to-dock
          # gnomeExtensions.dash-to-panel
          gnomeExtensions.arcmenu
          gnomeExtensions.blur-my-shell
          gnomeExtensions.open-bar
          gnomeExtensions.burn-my-windows
          gnomeExtensions.tiling-shell
          gnomeExtensions.vitals
          gnomeExtensions.quick-settings-audio-panel
          gnomeExtensions.rounded-window-corners-reborn
          gnomeExtensions.bluetooth-battery-meter
          # gnomeExtensions.bing-wallpaper-changer
        ];

        programs.dconf.profiles.user.databases = [
          {
            settings = {
              # Tắt animation → giảm tải GPU/CPU (iGPU) — tiết kiệm pin đáng kể
              # khi dùng pin. Có thể bật lại nếu thích mượt.
              "org/gnome/desktop/interface" = {
                enable-animations = false;

                # Rendering font kiểu Windows (ClearType): subpixel AA + full hinting.
                # Đồng bộ với fonts.fontconfig trong assets.nix — Firefox & app GTK đều đậm nét hơn.
                font-antialiasing = "rgba";
                font-hinting = "full";
                font-rgba-order = "rgb";
              };

              "org/gnome/desktop/wm/keybindings" = {
                switch-to-workspace-left = [ "<Control><Super>Left" ];
                switch-to-workspace-right = [ "<Control><Super>Right" ];
                switch-applications = [
                  "<Super>Tab"
                  "<Alt>Tab"
                ];
              };

              # Numlock (không liên quan gesture/chuột)
              "org/gnome/desktop/peripherals/keyboard" = {
                numlock-state = true;
              };

              # Extension bật sẵn (UUID đã kiểm chứng trong nixpkgs)
              "org/gnome/shell" = {
                disable-user-extensions = false;
                enabled-extensions = [
                  "dash-to-dock@micxgx.gmail.com"
                  "arcmenu@arcmenu.com"
                  "blur-my-shell@aunetx"
                  "appindicatorsupport@rgcjonas.gmail.com"
                  "caffeine@patapon.info"
                  "quick-settings-audio-panel@rayzeq.github.io"
                  "bamai@bamos" # BamAI trên thanh trên cùng (assets/gnome-shell-extensions)
                ];
                favorite-apps = [
                  "firefox.desktop"
                  "org.gnome.Nautilus.desktop"
                  "org.bamos.troly.desktop"
                ]
                ++ lib.optionals cfg.store [ "org.gnome.Software.desktop" ];
              };

              # Dock (giá trị GLF-OS)
              "org/gnome/shell/extensions/dash-to-dock" = {
                click-action = "minimize-or-overview";
                disable-overview-on-startup = true;
                dock-position = "BOTTOM";
                running-indicator-style = "DOTS";
                isolate-monitor = false;
                multi-monitor = true;
                show-mounts-network = true;
                always-center-icons = true;
                custom-theme-shrink = true;
              };

              "org/gnome/mutter" = {
                dynamic-workspaces = true;
                edge-tiling = true;
              };
            };
          }
        ];
      }

      # ==== GNOME Software + Flatpak — chỉ khi my.gnome.store (máy end-user) ====
      (lib.mkIf cfg.store {
        services.gnome.gnome-software.enable = true;
        services.flatpak.enable = true;

        # Kho Flathub — BẮT BUỘC để GNOME Software hiện ứng dụng:
        # `services.flatpak.enable` chỉ cài flatpak, KHÔNG tự thêm remote nào cả
        # → store trống rỗng. Thêm kho thủ công khi boot (giống GLF-OS):
        systemd.services.flatpak-add-flathub = {
          wantedBy = [ "multi-user.target" ];
          requires = [ "network-online.target" ];
          after = [ "network-online.target" ];
          path = [ pkgs.flatpak ];
          script = ''
            flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
          '';
        };

        # Flatpak apps (GNOME Store): môi trường "sẵn sàng dùng" — app Flatpak
        # chạy trong sandbox, cần cho phép đọc theme WhiteSur + font hệ thống:
        systemd.user.services.flatpak-system-integration = {
          wantedBy = [ "default.target" ];
          path = [ pkgs.flatpak ];
          script = ''
            flatpak override --user --filesystem=xdg-config/gtk-3.0:ro
            flatpak override --user --filesystem=xdg-config/gtk-4.0:ro

            # Font hệ thống → hiển thị trong sandbox (cp -n: an toàn chạy lại)
            mkdir -p "$HOME/.local/share/fonts"
            cp -rn ${localFonts}/share/fonts/truetype/. "$HOME/.local/share/fonts/" 2>/dev/null || true
          '';
        };
      })
    ]
  );
}
