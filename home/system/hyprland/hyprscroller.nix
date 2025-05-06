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
    rev = "59a66b860215d58632fe73a1c122c8c6ee354b32";
    hash = "sha256-DvFA8KxCGcc03DYOuxXp2cz77mjkJOxCQHpo5v5jTzg=";
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
