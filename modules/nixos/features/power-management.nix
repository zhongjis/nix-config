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
}
