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
	'include "./animations_config/withstar.kdl"'
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
WINDOW_PICKER="/home/zerone/.config/niri/window_picker.kdl"

# 提取纯颜色值（不带引号）
ACTIVE_COLOR=$(grep -oP 'active-color\s+"\K[^"]*' "$NOCTALIA_KDL" | head -1)
brightness=30   # 目标亮度百分比
alpha=0.55


b_brightness=10   # 目标亮度百分比
b_alpha=0.15

# 去掉 ACTIVE_COLOR 首尾空白，避免误判
ACTIVE_COLOR="$(printf '%s' "$ACTIVE_COLOR" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"

hsla=""
b_hsla=""
# 仅当 ACTIVE_COLOR 是合法的 #RRGGBB 颜色时才计算 hsla
if [[ "$ACTIVE_COLOR" =~ ^#[0-9a-fA-F]{6}$ ]]; then
    hsla=$(python3 -c "
import colorsys
h = '$ACTIVE_COLOR'.lstrip('#')
r, g, b = int(h[0:2],16)/255, int(h[2:4],16)/255, int(h[4:6],16)/255
hue, l, s = colorsys.rgb_to_hls(r, g, b)
s += 0.2
print(f'hsla({hue*360:.0f}, {s*100:.0f}%, $brightness%, $alpha)')
")

    b_hsla=$(python3 -c "
import colorsys
h = '$ACTIVE_COLOR'.lstrip('#')
r, g, b = int(h[0:2],16)/255, int(h[2:4],16)/255, int(h[4:6],16)/255
hue, l, s = colorsys.rgb_to_hls(r, g, b)
s += 0.2
print(f'hsla({hue*360:.0f}, {s*100:.0f}%, $b_brightness%, $b_alpha)')
")
fi

# 去掉 hsla 首尾空白
hsla="$(printf '%s' "$hsla" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
b_hsla="$(printf '%s' "$b_hsla" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"

# 如果 hsla 为空字符串、空或空格等不合法，就用 ACTIVE_COLOR 赋值
if [ -z "$hsla" ]; then
    hsla="$ACTIVE_COLOR"
fi

# 如果 ACTIVE_COLOR 也是空的，hsla 就赋值成默认值 #161a22e6
if [ -z "$hsla" ]; then
    hsla="#161a22e6"
fi

if [ -n "$ACTIVE_COLOR" ]; then
    # 替换 layout2.kdl 中 color 和 inactive-color
    sed -i 's/color\s\+"[^"]*"/color "'"$ACTIVE_COLOR"'"/' "$LAYOUT2_KDL"
    sed -i 's/inactive-color\s\+"[^"]*"/inactive-color "'"$hsla"'"/' "$LAYOUT2_KDL"

    # 替换 noctalia.kdl 中所有 active-color 为 hsla 值
    sed -i 's/active-color\s\+"[^"]*"/active-color "'"$hsla"'"/' "$NOCTALIA_KDL"


    sed -i 's/text-color\s\+"[^"]*"/text-color "'"$hsla"'"/' "$WINDOW_PICKER"
    sed -i 's/border-color\s\+"[^"]*"/border-color "'"$hsla"'"/' "$WINDOW_PICKER"
    sed -i 's/active-color\s\+"[^"]*"/active-color "'"$hsla"'"/' "$WINDOW_PICKER"
    sed -i 's/backdrop-color\s\+"[^"]*"/backdrop-color "'"$b_hsla"'"/' "$WINDOW_PICKER"
    # echo "将 active-color $ACTIVE_COLOR 同步到了 layout2.kdl"
    # echo "将 noctalia.kdl 中所有 active-color 替换为 $hsla"
else
    echo "警告: 未在 noctalia.kdl 中找到 active-color"
fi

# oh-my-pi themes: 仅将 .pi 的 vars 同步到 .omp，其余字段保持不动
python3 - <<'EOF'
import json
from pathlib import Path

src = Path.home() / ".pi/agent/themes/noctalia.json"
dst = Path.home() / ".omp/agent/themes/noctalia.json"

src_text = src.read_text()
dst_text = dst.read_text()
decoder = json.JSONDecoder()

def vars_span(text):
    """返回顶层 'vars' 值的原始 (start, end) 区间"""
    key = text.index('"vars"')
    colon = text.index(':', key)
    start = colon + 1
    while start < len(text) and text[start] in ' \t\r\n':
        start += 1
    _, end = decoder.raw_decode(text, start)
    return start, end

s_start, s_end = vars_span(src_text)
d_start, d_end = vars_span(dst_text)

# 用 .pi 的 vars 原文替换 .omp 的 vars 区间，其余字节原样保留
dst.write_text(dst_text[:d_start] + src_text[s_start:s_end] + dst_text[d_end:])
print("noctalia.json vars 已同步到 ~/.omp/agent/themes/")
EOF

#===========fcitx5=================
fcitx5 -r

