# Description: Cấu hình TLP chi tiết (CPU policy, GPU denylist, Sound power save)
{ ... }:

{
  services.power-profiles-daemon.enable = false;
  services.tlp.enable = true;

  services.tlp.settings = {
    # Ngưỡng sạc pin LG (80 hoặc 100)
    STOP_CHARGE_THRESH_BAT0 = "100";

    # CPU Energy Performance Policy
    CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
    CPU_ENERGY_PERF_POLICY_ON_AC = "balance_performance";
    CPU_BOOST_ON_BAT = 0;
    CPU_BOOST_ON_AC = 1;

    # Không can thiệp driver NVIDIA RTD3
    RUNTIME_PM_DRIVER_DENYLIST = "amdgpu mei_me nouveau nvidia xhci_hcd";

    # Tránh mất codec analog
    SOUND_POWER_SAVE = "0";
  };
}
