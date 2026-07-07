# modules/editions/studio.nix
# Lưu ý: Chỉ dùng các package có sẵn trong pinned nixpkgs
{ pkgs, lib, ... }: {
  # tuned profile: latency-performance — độ trễ thấp cho studio (audio/video)
  bamos.power-management.profile = lib.mkDefault "latency-performance";

  environment.systemPackages = with pkgs; [
    # 3D/CAD
    blender
    # Video
    # kdenlive (xem xét bổ sung sau — cần aptUpdate của nixpkgs)
    # Image
    gimp
    inkscape
    krita
    darktable
    # Audio
    ardour
    lmms
    audacity
    # Graphics tools
    obs-studio
  ];
  # Low-latency audio config cho PipeWire (client context)
  services.pipewire.extraConfig.client = {
    "99-lowlatency.conf" = {
      context.properties = {
        "default.clock.min-quantum" = 32;
        "default.clock.max-quantum" = 256;
      };
    };
  };
}
