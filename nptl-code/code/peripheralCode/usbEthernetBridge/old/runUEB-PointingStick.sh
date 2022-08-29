ID=$(xinput list --id-only "PS/2 Generic Mouse")
echo "sudo xinput set-prop $ID \"Device Enabled\" 0"
sudo xinput set-prop $ID "Device Enabled" 0
sudo nice -n -20 ./usbEthernetBridge.out /dev/input/by-path/platform-i8042-serio-2-event-mouse 1
