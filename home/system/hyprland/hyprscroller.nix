{
  lib,
  hyprland,
  hyprlandPlugins,
  cmake,
  fetchFromGitHub,
  nix-update-script,
}:

hyprlandPlugins.mkHyprlandPlugin hyprland {
  pluginName = "hyprscroller";
  version = "0-unstable-2025-07-28";

  src = fetchFromGitHub {
    owner = "cpiber";
    repo = "hyprscroller";
    rev = "b0dfb7b1844eece9e15650b963f8e343baf63106";
    hash = "sha256-dA8fKlDPReinuP4SkOqPwkebv43himKpN4wvoLctTKE=";
  };

  nativeBuildInputs = [ cmake ];

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
