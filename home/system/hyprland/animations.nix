{
  wayland.windowManager.hyprland.settings = {
    animations = {
      enabled = true;
      bezier = [
		"default, 0.05, 0.9, 0.1, 1.05"
    	"wind, 0.05, 0.9, 0.1, 1.05"
    	"overshot, 0.13, 0.99, 0.29, 1.08"
    	"liner, 1, 1, 1, 1"
		"easeOutCirc, 0, 0.55, 0.45, 1"
		"md3_decel, 0.05, 0.7, 0.1, 1"
		"md3_accel, 0.3, 0, 0.8, 0.15"
		"realsmooth, 0.28,0.29,.69,1.08"
      ];
      animation = [
		"windows, 1, 7, md3_decel, popin 5%"
    	"windowsIn, 1, 10, md3_decel, popin 5%"
    	"windowsOut, 1, 8, md3_accel, popin 5%"
    	# "hyprfocusIn, 1, 8, realsmooth"
    	# "hyprfocusOut, 1, 10, realsmooth"
    	"windowsMove, 1, 10, overshot, slide"
    	"layers, 1, 8, default, popin"
    	"fadeIn, 1, 10, overshot"
    	"fadeOut, 1, 10, overshot"
    	"fadeSwitch, 1, 10, default"
    	"fadeShadow, 1, 10, default"
    	"fadeDim, 1, 10, default"
    	"fadeLayers, 1, 10, default"
    	"workspaces, 1, 8, overshot, slidevert"
    	"border, 1, 1, liner"
    	"borderangle, 1, 30, liner, once"
      ];
    };
   };
}
