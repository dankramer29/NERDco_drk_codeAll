ID=$(xinput list --id-only "christineblabe’s trackpad")
## if it couldn't find one trackpad, try another
if [ -z $ID ]
then
ID=$(xinput list --id-only "gilja’s trackpad")
fi
## try another
if [ -z $ID ]
then
ID=$(xinput list --id-only "Apple Wireless Trackpad")
fi

## try manually connecting
if [ -z $ID ]
then
# CHRISTINE TRACKPAD
sudo hidd --connect 60:C5:47:82:07:7B

# GILJA TRACKPAD
#sudo hidd --connect 60:C5:47:82:0C:85
fi

ID=$(xinput list --id-only "christineblabe’s trackpad")
if [ -z $ID ]
then
ID=$(xinput list --id-only "Apple Wireless Trackpad")
fi
if [ -z $ID ]
then
ID=$(xinput list --id-only "gilja’s trackpad")
fi

echo "sudo xinput set-prop $ID \"Device Enabled\" 0"
sudo xinput set-prop $ID "Device Enabled" 0

DEV=$(xinput --list-props $ID |grep "Device Node" |grep -o "/dev/input/event[0-9]*")

echo The apple trackpad device is at $DEV

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

echo The glove is at $HID

#sudo nice -n -20 ./usbEthernetBridge-mouseOnly.out /dev/input/by-path/platform-i8042-serio-1-event-mouse 2
sudo nice -n -20 ./usbEthernetBridge-GloveAndMouse.out $DEV 2 /dev/usb/hiddev$HID
