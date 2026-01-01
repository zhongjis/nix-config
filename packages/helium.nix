{ pkgs, lib }:

let
  version = "0.7.7.1";
  
  # Map from Nix system to architecture suffix and hash
  srcs = {
    x86_64-linux = {
      url = "https://github.com/imputnet/helium-linux/releases/download/${version}/helium-${version}-x86_64.AppImage";
      sha256 = "1dxyyp9nh6iva0zh586vpyb7av53n2nhnhmi6j2jrc5h60bx8hd8";
    };
    aarch64-linux = {
      url = "https://github.com/imputnet/helium-linux/releases/download/${version}/helium-${version}-arm64.AppImage";
      sha256 = "0s05bd0jk2fjgyz41v5a2jm830la0jqgkvr83ky52h3dc96i52m3";
    };
  };

  srcInfo = srcs.${pkgs.system} or (throw "Unsupported system: ${pkgs.system}");
  
  src = pkgs.fetchurl {
    url = srcInfo.url;
    sha256 = srcInfo.sha256;
    name = "helium-${version}-${pkgs.system}.AppImage";
  };
in
pkgs.appimageTools.wrapType2 {
  pname = "helium";
  inherit version src;
  
  extraPkgs = pkgs: with pkgs; [
    # Add any missing libraries that might be needed
    # Most AppImages are self-contained, but we can add dependencies here if needed
  ];
  
  meta = with lib; {
    description = "Helium Linux - A fast, lightweight Linux distribution";
    homepage = "https://github.com/imputnet/helium-linux";
    license = licenses.mit;
    platforms = [ "x86_64-linux" "aarch64-linux" ];
    mainProgram = "helium";
  };
}