{ pkgs, inputs, ... }:
{
  # 添加 overlays，包括自定义 niri-unstable override
  nixpkgs.overlays = [
    inputs.niri.overlays.niri

    # 自定义 Overlay：覆盖 niri-unstable
    (final: prev: {
      niri-unstable = prev.niri-unstable.overrideAttrs (old: {
        src = inputs.my-niri-src;  # 使用自定义源码
        cargoDeps = final.rustPlatform.fetchCargoVendor {
          src = inputs.my-niri-src;
          hash = "sha256-Me8woNt30B77K3NPnEaB7YoT+2o64AiiYBhGzHfSUNM=";
        };
        doCheck = false;
      });
    })
  ];

  # 导入 niri 模块
  imports = [ inputs.niri.nixosModules.niri ];

  # 启用 niri 并指定包
  programs.niri = {
    enable = true;
    package = pkgs.niri-unstable;
  };

  # 如果需要传递 inputs 到其他模块（可选，根据你的需求）
  # _module.args = { inherit inputs; };

  # 如果有其他 niri 相关配置（如 environment.systemPackages 中的 niri 依赖），可以在这里添加
  # environment.systemPackages = with pkgs; [ /* niri 相关包 */ ];
}
