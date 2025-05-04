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
  version = "0-unstable-2025-05-04";

  src = fetchFromGitHub {
    owner = "nasirHo";
    repo = "hyprscroller";
    rev = "35ee6662ab3b6911b3c6adab8e7807b739b087af";
    hash = "sha256-ccuwXn9psnZPMRGyUCKTcU3eFiw3c2mqweuaLpvjnnU=";
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
