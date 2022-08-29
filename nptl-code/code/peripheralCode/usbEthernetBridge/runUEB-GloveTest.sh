
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

sudo nice -n -20 ./usbEthernetBridge-GloveTest.out $HID
