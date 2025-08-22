#!/bin/bash

# ✅ 默认设备和别名（可通过参数传入）
DEVICE=${1:-/dev/video0}
SYMLINK_NAME=${2:-custom_usb}
RULE_FILE="${SYMLINK_NAME}.rules"

echo "🚀 开始绑定 USB 设备"
echo "📌 目标设备: $DEVICE"
echo "🔖 设备别名: /dev/$SYMLINK_NAME"

# 1️⃣ 检查设备是否存在
if [ ! -e "$DEVICE" ]; then
    echo "❌ 设备 $DEVICE 不存在，请确认插入正确的设备！"
    exit 1
fi

# 2️⃣ 获取 KERNELS 路径（用于唯一标识设备）
KERNELS_PATH=$(udevadm info -a -n "$DEVICE" | awk -F'==' '/KERNELS==/ { gsub(/"/, "", $2); print $2; exit }')
if [ -z "$KERNELS_PATH" ]; then
    echo "❌ 无法获取设备的 KERNELS 路径，无法区分设备。"
    exit 1
fi

# 3️⃣ 获取摄像头的唯一标识符（如 idVendor, idProduct, serial）
VENDOR_ID=$(udevadm info -a -n "$DEVICE" | grep -m 1 'ATTRS{idVendor}' | sed 's/.*"//;s/"//')
PRODUCT_ID=$(udevadm info -a -n "$DEVICE" | grep -m 1 'ATTRS{idProduct}' | sed 's/.*"//;s/"//')
SERIAL_NUMBER=$(udevadm info -a -n "$DEVICE" | grep -m 1 'ATTRS{serial}' | sed 's/.*"//;s/"//')

if [ -z "$VENDOR_ID" ] || [ -z "$PRODUCT_ID" ]; then
    echo "❌ 无法获取摄像头的 Vendor ID 或 Product ID，无法稳定绑定设备。"
    exit 1
fi

# 4️⃣ 判断设备类型（video）
KERNEL_TYPE=$(basename "$DEVICE" | grep -oE '^video')

if [ -z "$KERNEL_TYPE" ]; then
    echo "❌ 不支持的设备类型。仅支持 video* 类型"
    exit 1
fi

# 5️⃣ 构建 udev 规则
RULE="SUBSYSTEM==\"video4linux\", ATTRS{idVendor}==\"$VENDOR_ID\", ATTRS{idProduct}==\"$PRODUCT_ID\", ATTRS{serial}==\"$SERIAL_NUMBER\", MODE=\"0777\", SYMLINK+=\"${SYMLINK_NAME}_$SERIAL_NUMBER\""

# 6️⃣ 写入临时规则文件
echo "📝 正在生成规则文件：$RULE_FILE"
echo "$RULE" > "$RULE_FILE"

# 7️⃣ 拷贝规则文件到系统目录
echo "📂 拷贝规则文件到 /etc/udev/rules.d/"
sudo cp "$RULE_FILE" /etc/udev/rules.d/

# 8️⃣ 重载规则并触发
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

echo "✅ 绑定完成！请重新插拔设备并检查： /dev/${SYMLINK_NAME}_$SERIAL_NUMBER"
