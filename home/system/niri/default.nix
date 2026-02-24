{ pkgs, inputs, ... }:
{
  nixpkgs.overlays = [
    inputs.niri.overlays.niri

  #   (final: prev: {
  #     niri = prev.niri.overrideAttrs (old: {
		# # version = "${old.version}-blur-${inputs.my-niri-src.shortRev or "dirty"}";
  #       src = inputs.my-niri-src;  # 使用自定义源码
  #       # src = inputs.my-fork-niri;  # 使用自定义源码
  #       cargoDeps = final.rustPlatform.fetchCargoVendor {
  #         src = inputs.my-niri-src;
  #         # src = inputs.my-fork-niri;
  #         hash = "sha256-i9YG3xDe8JsBgwQABfQeEaz4kzH+ZO2IaPZ7hhmpgN0=";
		#   # hash = "sha256-/jmV5mWYW3khDmyioSRj10IsfLtj5EYDIVSMK4KAc4A=";
  #       };
  #       doCheck = false;
  #       postPatch = ''
  #         # 仅当文件包含 /usr/bin 时才替换
  #         if [ -f resources/niri.service ] && grep -q '/usr/bin' resources/niri.service 2>/dev/null; then
  #           substituteInPlace resources/niri.service --replace /usr/bin ${final.coreutils}/bin
  #         else
  #           echo "Warning: /usr/bin not found in niri.service, skipping substitution (custom source)"
  #         fi
		#
  #         # 修复 niri-session 的 shebang
  #         patchShebangs resources/niri-session
  #       '';
  #     });
  #   })
  ];

  # 导入 niri 模块
  # imports = [ inputs.niri.nixosModules.niri ];

  # 启用 niri 并指定包
  programs.niri = {
    enable = true;
    package = pkgs.niri-unstable;
  };

  # 如果需要传递 inputs 到其他模块（可选，根据你的需求）
  # _module.args = { inherit inputs; };

  # 如果有其他 niri 相关配置（如 environment.systemPackages 中的 niri 依赖），可以在这里添加
  environment.systemPackages = with pkgs; [ 
	  xdg-desktop-portal-gtk
	  xdg-desktop-portal
	  xdg-desktop-portal-gnome
	  # xdg-desktop-portal-wlr
	  slurp
  ];
}
