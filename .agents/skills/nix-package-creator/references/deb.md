# Deb Package Extraction

Template for packaging software distributed as `.deb` files.

## Template

```nix
{
  pkgs,
  lib,
}:
let
  pname = "app-name";
  version = "1.0.0";

  srcs = {
    x86_64-linux = {
      url = "https://example.com/app_${version}_amd64.deb";
      sha256 = lib.fakeHash;
    };
    aarch64-linux = {
      url = "https://example.com/app_${version}_arm64.deb";
      sha256 = lib.fakeHash;
    };
  };

  srcInfo = srcs.${pkgs.system} or (throw "Unsupported system: ${pkgs.system}");

  src = pkgs.fetchurl {
    inherit (srcInfo) url sha256;
    name = "${pname}-${version}.deb";
  };
in
pkgs.stdenv.mkDerivation {
  inherit pname version src;

  nativeBuildInputs = [
    pkgs.dpkg
    pkgs.makeWrapper
    pkgs.autoPatchelfHook
  ];

  buildInputs = [
    pkgs.stdenv.cc.cc.lib
    # Add runtime library deps here (ldd the binary to find them)
  ];

  dontConfigure = true;
  dontBuild = true;
  dontPatchELF = true;

  unpackCmd = "dpkg-deb -x $src .";

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r usr/* $out/ || true
    cp -r opt/${pname}/* $out/ || true

    # Fix desktop file paths
    if [ -f $out/share/applications/${pname}.desktop ]; then
      substituteInPlace $out/share/applications/${pname}.desktop \
        --replace-fail "/opt/${pname}/${pname}" "${pname}"
    fi

    # Wrap binary with runtime deps
    wrapProgram $out/bin/${pname} \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ pkgs.stdenv.cc.cc.lib ]}

    runHook postInstall
  '';

  meta = {
    description = "Short description";
    homepage = "https://example.com";
    license = lib.licenses.mit;
    platforms = builtins.attrNames srcs;
    mainProgram = pname;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
```

## Key Points

- `dontPatchELF = true` — let `autoPatchelfHook` handle it instead
- `unpackCmd` uses `dpkg-deb -x` to extract without installing
- Check both `usr/` and `opt/` dirs — some debs put binaries in `/opt/<name>/`
- Desktop files often have absolute paths like `/opt/app/app` that need fixing
- Use `ldd` on the extracted binary to find missing library dependencies
- **Real example**: `packages/devtoys.nix` — uses `dpkg` + `makeWrapper` + `autoPatchelfHook`
