ID=$(xinput list --id-only "Wacom Bamboo Pen Pen stylus")
echo "sudo xinput set-prop $ID \"Device Enabled\" 0"
sudo xinput set-prop $ID "Device Enabled" 0

ID=$(xinput list --id-only "Wacom Bamboo Pen Finger touch")
echo "sudo xinput set-prop $ID \"Device Enabled\" 0"
sudo xinput set-prop $ID "Device Enabled" 0

ID=$(xinput list --id-only "Wacom Bamboo Pen Pen eraser")
echo "sudo xinput set-prop $ID \"Device Enabled\" 0"
sudo xinput set-prop $ID "Device Enabled" 0

ID=$(xinput list --id-only "Wacom Bamboo Pen Finger pad")
echo "sudo xinput set-prop $ID \"Device Enabled\" 0"
sudo xinput set-prop $ID "Device Enabled" 0



sudo nice -n -20 ./usbEthernetBridge-mouseOnly.out /dev/input/wacom 2
