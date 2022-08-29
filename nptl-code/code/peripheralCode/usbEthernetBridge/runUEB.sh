ID=$(xinput list --id-only "Razer Razer DeathAdder")
echo "sudo xinput set-prop $ID \"Device Enabled\" 0"
sudo xinput set-prop $ID "Device Enabled" 0
sudo nice -n -20 ./usbEthernetBridge.out /dev/input/by-id/usb-Razer_Razer_DeathAdder-event-mouse 1
