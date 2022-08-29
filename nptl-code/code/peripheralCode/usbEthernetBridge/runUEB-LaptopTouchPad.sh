ID=$(xinput list --id-only "SynPS/2 Synaptics TouchPad")
echo "sudo xinput set-prop $ID \"Device Enabled\" 0"
sudo xinput set-prop $ID "Device Enabled" 0
sudo nice -n -20 ./usbEthernetBridge-mouseOnly.out /dev/input/by-path/platform-i8042-serio-1-event-mouse 2
