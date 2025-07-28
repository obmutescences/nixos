{
  lib,
  hyprland,
  hyprlandPlugins,
  fetchFromGitHub,
  nix-update-script,
}:

hyprlandPlugins.mkHyprlandPlugin hyprland {
  pluginName = "hyprfocus";
  version = "0-unstable-2025-07-28";

  src = fetchFromGitHub {
    owner = "daxisunder";
    repo = "hyprfocus";
    rev = "b892a4dae74061a3721d0ad5744d4430cb46b57e";
    hash = "sha256-psn+Xu1CA68nWGQaRebJGPmq1rRfysH6SGCbWYB6kYc=";
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
