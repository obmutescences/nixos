{
  lib,
  hyprland,
  hyprlandPlugins,
  fetchFromGitHub,
  nix-update-script,
}:

hyprlandPlugins.mkHyprlandPlugin hyprland {
  pluginName = "hyprscroller";
  version = "0-unstable-2025-04-24";

  src = fetchFromGitHub {
    owner = "nasirHo";
    repo = "hyprscroller";
    rev = "de39157e11de72f3be23a83b4e72f8fdae21cfa2";
    hash = "sha256-ST5FFxyw5El4A7zWLaWbXb9bD9C/tunU+flmNxWCcEY=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib
	mv hyprscroller.so $out/lib/libhyprscroller.so

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { extraArgs = [ "--version=branch" ]; };
  meta = {
    homepage = "https://github.com/dawsers/hyprscroller";
	description = "Hyprland layout plugin providing a scrolling layout like PaperWM";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ donovanglover ];
    platforms = lib.platforms.linux;
    # broken = true; # Doesn't work on Hyprland v0.47.0+
  };
}
