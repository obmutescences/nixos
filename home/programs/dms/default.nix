{ pkgs, config, inputs, ... }: {
	imports = [
		inputs.dms.homeModules.dank-material-shell
	];
	 programs.dank-material-shell = {
		  enable = true;

		  systemd = {
			enable = true;             # Systemd service for auto-start
			restartIfChanged = true;   # Auto-restart dms.service when dank-material-shell changes
		  };

		  # Core features
		  enableSystemMonitoring = true;     # System monitoring widgets (dgop)
		  enableDynamicTheming = true;       # Wallpaper-based theming (matugen)
		  enableAudioWavelength = true;      # Audio visualizer (cava)
		  enableCalendarEvents = true;       # Calendar integration (khal)
		  enableClipboardPaste = true;       # Pasting items from the clipboard (wtype)
	   };
}
