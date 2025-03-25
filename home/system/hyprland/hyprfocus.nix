{
  lib,
  mkHyprlandPlugin,
  hyprland,
  fetchFromGitHub,
  nix-update-script,
}:

mkHyprlandPlugin hyprland {
  pluginName = "hyprfocus";
  version = "0-unstable-2025-01-04";

  src = fetchFromGitHub {
    owner = "daxisunder";
    repo = "hyprfocus";
    rev = "227378fe742034c87a36fdb0681083da49bd6c99";
    hash = "sha256-ST5FFxyw5El4A7zWLaWbXb9bD9C/tunU+flmNxWCcEY=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib
    mv hyprfocus.so $out/lib/libhyprfocus.so

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { extraArgs = [ "--version=branch" ]; };
  meta = {
    homepage = "https://github.com/pyt0xic/hyprfocus";
    description = "Focus animation plugin for Hyprland inspired by Flashfocus";
    license = lib.licenses.bsd3;
    maintainers = with lib.maintainers; [ donovanglover ];
    platforms = lib.platforms.linux;
    # broken = true; # Doesn't work on Hyprland v0.47.0+
  };
}
