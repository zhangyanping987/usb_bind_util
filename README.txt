此脚本为自动绑定usb串口脚本

当usb串口插入Ubuntu时，会被识别成/dev/ttyUSB0或者/dev/ttyACM0等，当设备变多时，串口号会不固定

所以当插入一个串口，假设他为/dev/ttyUSB0,我们需要将他取一个固定的名字，确保后续每次插入这个设备，我们的系统都能识别到

我们在插入串口后，可以直接运行这个脚本

./generate_udev_rule.sh 当前识别的串口号 需要修改成的名称

例如当前识别到是/dev/ttyUSB0,我们需要修改成/dev/test,则可以输入以下指令运行脚本
./generate_udev_rule.sh /dev/ttyUSB0 test

随后重新插拔设备，运行以下指令查看是否绑定成功
ll /dev/test

如果绑定成功，可以看到/dev/test -> ttyUSB0

