{...}: {
  services.podman = {
    enable = true;
    enableTypeChecks = true;
    autoUpdate.enable = true;
    containers = {
      "openwebui" = {
        image = "ghcr.io/open-webui/open-webui:main";
        autoStart = true;
        autoUpdate = "registry";
        ports = ["3000:8080"];
      };
    };
  };
}
