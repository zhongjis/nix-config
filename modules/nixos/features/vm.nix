{...}: {
  programs.virt-manager.enable = true;
  users.groups.libvirtd.members = ["zshen"];
  virtualisation.libvirtd.enable = true;
  virtualisation.spiceUSBRedirection.enable = true;
}
