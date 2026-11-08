{...}: {
  # better power consumption
  # powerManagement = {
  #   enable = true;
  #   powertop.enable = true;
  #   cpuFreqGovernor = "schedutil";
  #   cpuFreqGovernor = "powersave";
  # };

  # Framework recommends power-profiles-daemon over TLP on Ryzen 7040: PPD drives
  # amd-pmf platform_profile and amd-pstate EPP together (balanced = balance_performance
  # on AC). It persists the chosen profile in /var/lib/power-profiles-daemon/state.ini.
  # https://wiki.nixos.org/wiki/Hardware/Framework/Laptop_16
  services.power-profiles-daemon.enable = true;

  # services.auto-cpufreq.enable = true;
  # services.auto-cpufreq.settings = {
  #   battery = {
  #     governor = "powersave";
  #     turbo = "never";
  #   };
  #   charger = {
  #     governor = "performance";
  #     turbo = "auto";
  #   };
  # };

  # thermald supports Intel CPUs only.
  services.thermald.enable = false;
  # TLP conflicts with PPD; nixos-hardware enables it by mkDefault when PPD is off.
  services.tlp.enable = false;

  # Disable CPU boost at boot. Measured on the Framework 16 under agent load:
  # boost cost +24°C, +15W and a 100% fan for 0-2% faster tsc/vitest runs,
  # because the chip is thermal-limited around 4.3 GHz anyway.
  # Re-enable at runtime: echo 1 | sudo tee /sys/devices/system/cpu/cpufreq/boost
  systemd.tmpfiles.rules = ["w /sys/devices/system/cpu/cpufreq/boost - - - - 0"];
}
