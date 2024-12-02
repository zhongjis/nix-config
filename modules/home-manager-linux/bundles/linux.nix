{lib, ...}: {
  myHomeManagerLinux.xremap.enable = lib.mkDefault true;
  myHomeManagerLinux.pipewire.enable = lib.mkDefault true;
}
