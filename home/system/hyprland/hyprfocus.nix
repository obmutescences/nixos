{
  lib,
  hyprland,
  hyprlandPlugins,
  fetchFromGitHub,
  nix-update-script,
}:

hyprlandPlugins.mkHyprlandPlugin (finalAttrs: {
  pluginName = "hyprfocus";
  version = "0-unstable-2026-03-06";

  src = fetchFromGitHub {
    owner = "daxisunder";
    repo = "hyprfocus";
    rev = "126bfa4d528d08770807700f9fd65a6bef9420b4";
    hash = "sha256-VNQ23Mq0lYXgYTWcMXHMxB8c89mws1GdKtgY0YZim4g=";
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
})
