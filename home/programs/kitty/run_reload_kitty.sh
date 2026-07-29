# sleep 0.5 && killall -USR1 kitty

# 配置文件路径
CONFIG_FILE="/home/zerone/.config/niri/config.kdl"
INDEX_FILE="/home/zerone/.config/niri/current_animation_index"

# 动画配置数组
ANIMATIONS=(
    'include "./animations_config/ribbons.kdl"'
    'include "./animations_config/glass.kdl"'
    'include "./animations_config/blackhole.kdl"'
    'include "./animations_config/pixel-drift.kdl"'
    'include "./animations_config/liquid-flow.kdl"'
    'include "./animations_config/quantum-ripple.kdl"'
    'include "./animations_config/burn-ashes.kdl"'
    'include "./animations_config/roll-drop.kdl"'
    'include "./animations_config/glitch.kdl"'
    'include "./animations_config/smoke.kdl"'
    'include "./animations_config/throw.kdl"'
)

# 读取当前索引，如果不存在则从0开始
if [ -f "$INDEX_FILE" ]; then
    CURRENT_INDEX=$(cat "$INDEX_FILE")
    CURRENT_INDEX=$((CURRENT_INDEX + 1))

    # 如果超过数组长度，回到第一个
    if [ $CURRENT_INDEX -ge ${#ANIMATIONS[@]} ]; then
        CURRENT_INDEX=0
    fi
else
    CURRENT_INDEX=0
fi

# 保存新的索引
echo $CURRENT_INDEX > "$INDEX_FILE"

# 获取要添加的动画配置行
ANIMATION_LINE="${ANIMATIONS[$CURRENT_INDEX]}"

# 备份原始配置文件
cp "$CONFIG_FILE" "${CONFIG_FILE}.backup"

# 删除所有包含 nirimation/animations 的行
sed -i '/animations_config/d' "$CONFIG_FILE"

# 在文件末尾添加新的动画配置
echo "$ANIMATION_LINE" >> "$CONFIG_FILE"

# ===== 同步 noctalia.kdl 的 active-color 到 layout2.kdl =====
sleep 1
NOCTALIA_KDL="/home/zerone/.config/niri/noctalia.kdl"
LAYOUT2_KDL="/home/zerone/.config/niri/layout2.kdl"

# 提取纯颜色值（不带引号）
ACTIVE_COLOR=$(grep -oP 'active-color\s+"\K[^"]*' "$NOCTALIA_KDL" | head -1)
brightness=35   # 目标亮度百分比
alpha=1.0

hsla=$(python3 -c "
import colorsys
h = '$ACTIVE_COLOR'.lstrip('#')
r, g, b = int(h[0:2],16)/255, int(h[2:4],16)/255, int(h[4:6],16)/255
hue, l, s = colorsys.rgb_to_hls(r, g, b)
print(f'hsla({hue*360:.0f}, {s*100:.0f}%, $brightness%, $alpha)')
")

if [ -n "$ACTIVE_COLOR" ]; then
    # 替换 layout2.kdl 中 color 和 inactive-color
    sed -i 's/color\s\+"[^"]*"/color "'"$ACTIVE_COLOR"'"/' "$LAYOUT2_KDL"
    sed -i 's/inactive-color\s\+"[^"]*"/inactive-color "'"$hsla"'"/' "$LAYOUT2_KDL"

    # 替换 noctalia.kdl 中所有 active-color 为 hsla 值
    sed -i 's/active-color\s\+"[^"]*"/active-color "'"$hsla"'"/' "$NOCTALIA_KDL"

    # echo "将 active-color $ACTIVE_COLOR 同步到了 layout2.kdl"
    # echo "将 noctalia.kdl 中所有 active-color 替换为 $hsla"
else
    echo "警告: 未在 noctalia.kdl 中找到 active-color"
fi
