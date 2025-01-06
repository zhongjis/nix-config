{lib, ...}: {
  myHomeManagerLinux.xremap.enable = lib.mkDefault true;
  myHomeManagerLinux.pipewire-noise-cancling-input.enable = lib.mkDefault true;
}
