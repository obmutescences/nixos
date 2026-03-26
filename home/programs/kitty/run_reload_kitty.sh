sleep 0.5 && killall -USR1 kitty

# 配置文件路径
CONFIG_FILE="/home/zerone/.config/niri/config.kdl"
INDEX_FILE="/home/zerone/.config/niri/current_animation_index"

# 动画配置数组
ANIMATIONS=(
    'include "./nirimation/animations/ribbons.kdl"'
    'include "./nirimation/animations/glass.kdl"'
    'include "./nirimation/animations/blackhole.kdl"'
    'include "./nirimation/animations/pixel-drift.kdl"'
    'include "./nirimation/animations/liquid-flow.kdl"'
    'include "./nirimation/animations/quantum-ripple.kdl"'
    'include "./nirimation/animations/burn-ashes.kdl"'
    'include "./nirimation/animations/roll-drop.kdl"'
    'include "./nirimation/animations/glitch.kdl"'
    'include "./nirimation/animations/smoke.kdl"'
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
sed -i '/nirimation\/animations/d' "$CONFIG_FILE"

# 在文件末尾添加新的动画配置
echo "$ANIMATION_LINE" >> "$CONFIG_FILE"
