{...}: {
  services.podman = {
    enable = true;
    autoUpdate.enable = true;
    podman.containers = {
      "openwebui" = {
        image = "ghcr.io/open-webui/open-webui:main";
        autoStart = true;
        autoUpdate = "registry";
        ports = ["3000:8080"];
      };
    };
  };
}
