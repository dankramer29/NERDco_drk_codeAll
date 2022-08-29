ID=$(xinput list --id-only "christineblabe’s trackpad")
echo "sudo xinput set-prop $ID \"Device Enabled\" 0"
sudo xinput set-prop $ID "Device Enabled" 0

DEV=$(xinput --list-props $ID |grep "Device Node" |grep -o "/dev/input/event[0-9]*")

echo The apple trackpad device is at $DEV

#sudo nice -n -20 ./usbEthernetBridge-mouseOnly.out /dev/input/by-path/platform-i8042-serio-1-event-mouse 2
sudo nice -n -20 ./usbEthernetBridge-mouseOnly.out $DEV 2
