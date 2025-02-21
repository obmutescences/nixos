{ pkgs, ... }:

let
  next-wallpaper = pkgs.writeShellScriptBin "next-wallpaper" ''
    #!/usr/bin/env bash

    # 壁纸目录
    WALLPAPER_DIR="/home/zerone/Pictures/Wallpapers"

    # 索引文件（隐藏文件，存储在用户目录）
    INDEX_FILE="$HOME/.wallpaper_index"

    # 获取所有壁纸文件（按修改时间排序）
    readarray -d "" wallpapers < <(find "$WALLPAPER_DIR" -type \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) -print0 | sort -z)

    # 检查壁纸文件是否存在
    if [ "''${#wallpapers[@]}" -eq 0 ]; then
        echo "Error: No wallpapers found in $WALLPAPER_DIR"
        exit 1
    fi

    # 读取或初始化索引
    if [[ -f "$INDEX_FILE" && -s "$INDEX_FILE" ]]; then
        current_index=$(< "$INDEX_FILE")
        # 验证索引有效性
        if ! [[ "$current_index" =~ ^[0-9]+$ ]] || (( current_index >= ''${#wallpapers[@]} )); then
            current_index=0
        fi
    else
        current_index=0
    fi

    # 计算下一个索引（循环播放）
    next_index=$(( (current_index + 1) % ''${#wallpapers[@]} ))

    # 应用新壁纸
    swww img --transition-type grow \
             --transition-pos 0.864,0.977 \
             --transition-step 90 \
             "''${wallpapers[next_index]}"

    # 保存新索引
    echo "$next_index" > "$INDEX_FILE"
  '';
in {
  home.packages = [ next-wallpaper ];
}
