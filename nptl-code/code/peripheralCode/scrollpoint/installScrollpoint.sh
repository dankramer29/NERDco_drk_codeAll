## requires the .ko files for hid.ko and hid-lenovo-scrollpoint.ko
##  are in the hid-drivers/ directory
## also need ./rc.local to exist
sudo cp -R hid-drivers/* /lib/modules/`uname -r`/kernel/drivers/hid
sudo cp -R rc.local /etc/rc.local
sudo rmmod -f usbhid
sudo insmod hid-drivers/hid-scrollpoint.ko
sudo insmod hid-drivers/usbhid/usbhid.ko
sudo depmod -a