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


#sudo nice -n -20 ./usbEthernetBridge-mouseOnly.out /dev/input/by-path/platform-i8042-serio-1-event-mouse 2
sudo nice -n -20 ./usbEthernetBridge-mouseOnly.out $DEV 2 
