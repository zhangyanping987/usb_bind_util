#!/bin/bash

# ✅ 默认设备和别名（可通过参数传入）
DEVICE=${1:-/dev/ttyUSB0}
SYMLINK_NAME=${2:-custom_usb}
RULE_FILE="${SYMLINK_NAME}.rules"

echo "🚀 开始绑定 USB 串口设备"
echo "📌 目标设备: $DEVICE"
echo "🔖 设备别名: /dev/$SYMLINK_NAME"

# 1️⃣ 检查设备是否存在
if [ ! -e "$DEVICE" ]; then
    echo "❌ 设备 $DEVICE 不存在，请确认插入正确的设备！"
    exit 1
fi

# 2️⃣ 获取 KERNELS 路径（用于唯一标识设备）
# KERNELS_PATH=$(udevadm info -a -n "$DEVICE" | grep -m 1 'KERNELS==' | head -n1 | sed 's/^[ \t]*//;s/"//g' | cut -d'=' -f2)
KERNELS_PATH=$(udevadm info -a -n "$DEVICE" | awk -F'==' '/KERNELS==/ { gsub(/"/, "", $2); print $2; exit }')
if [ -z "$KERNELS_PATH" ]; then
    echo "❌ 无法获取设备的 KERNELS 路径，无法区分设备。"
    exit 1
fi

# 3️⃣ 判断设备类型（ttyUSB / ttyACM）
KERNEL_TYPE=$(basename "$DEVICE" | grep -oE '^tty(USB|ACM)')

if [ -z "$KERNEL_TYPE" ]; then
    echo "❌ 不支持的设备类型。仅支持 ttyUSB* 或 ttyACM*"
    exit 1
fi

# 4️⃣ 构建 udev 规则
RULE="KERNEL==\"${KERNEL_TYPE}*\", KERNELS==\"${KERNELS_PATH}\", MODE=\"0777\", SYMLINK+=\"${SYMLINK_NAME}\""

# 5️⃣ 写入临时规则文件
echo "📝 正在生成规则文件：$RULE_FILE"
echo "$RULE" > "$RULE_FILE"

# 6️⃣ 拷贝规则文件到系统目录
echo "📂 拷贝规则文件到 /etc/udev/rules.d/"
sudo cp "$RULE_FILE" /etc/udev/rules.d/

# 7️⃣ 重载规则并触发
if command -v udevadm &>/dev/null; then
    echo "🔁 使用 udevadm 重载规则"
    sudo udevadm control --reload-rules
    sudo udevadm trigger
else
    echo "🔁 使用 service 重启 udev"
    sudo service udev reload
    sleep 2
    sudo service udev restart
fi

echo "✅ 绑定完成！请重新插拔设备并检查： /dev/$SYMLINK_NAME"
