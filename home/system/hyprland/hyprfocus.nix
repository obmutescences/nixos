{
  lib,
  hyprland,
  hyprlandPlugins,
  fetchFromGitHub,
  nix-update-script,
}:

hyprlandPlugins.mkHyprlandPlugin hyprland {
  pluginName = "hyprfocus";
  version = "0-unstable-2025-05-04";

  src = fetchFromGitHub {
    owner = "obmutescences";
    repo = "hyprfocus";
    rev = "6ebd23ccefc14cf3e7310789f2ea09b4bc83fee0";
    hash = "sha256-au+LLE/7CfqhH1ExAzbcrkBNz+DPxs0Qewt3Vcqk/2c=";
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
