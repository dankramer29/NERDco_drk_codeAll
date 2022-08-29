ID=$(xinput list --id-only "Lenovo ScrollPoint Mouse")

echo "sudo xinput set-prop $ID \"Device Enabled\" 0"
sudo xinput set-prop $ID "Device Enabled" 0

DEV=$(xinput --list-props $ID |grep "Device Node" |grep -o "/dev/input/event[0-9]*")




sudo nice -n -20 ./usbEthernetBridge-scrollOnly.out $DEV 1
