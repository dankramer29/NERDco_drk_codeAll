ID=$(xinput list --id-only "Logitech USB-PS/2 Optical Mouse")
## disable the mouse as a user input
echo "sudo xinput set-prop $ID \"Device Enabled\" 0"
sudo xinput set-prop $ID "Device Enabled" 0

## find out where the glove is
IS0=$(udevadm info --query=property --name=/dev/usb/hiddev0 --attribute-walk 2> /dev/null |grep 5DT | wc -l)
IS1=$(udevadm info --query=property --name=/dev/usb/hiddev1 --attribute-walk 2> /dev/null |grep 5DT | wc -l)
IS2=$(udevadm info --query=property --name=/dev/usb/hiddev2 --attribute-walk 2> /dev/null |grep 5DT | wc -l)

if [ "$IS0" -gt 0 ]
then
  HID=0
fi
if [ "$IS1" -gt 0 ]
then
  HID=1
fi
if [ "$IS2" -gt 0 ]
then
  HID=2
fi
sudo nice -n -20 ./usbEthernetBridge.out /dev/input/by-id/usb-Logitech_USB-PS_2_Optical_Mouse-event-mouse 1 /dev/usb/hiddev$HID
