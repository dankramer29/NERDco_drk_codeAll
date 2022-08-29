## Chethan Pandarinath, 20140423
## compiles driver that supports scrollpoint devices

## IMPORTANT NOTE: All of the below, though written in a general way, is
##  specific to the linux kernel being compiled for (3.2.0-35-generic)
##  hopefully it will serve as a good base for future kernels.
## HOWEVER: All of the files being copied in below are based on that specific
##  kernel version, and compile will break if these files are used on another
##  version.

## relies on an internet connection 

# current directory (should be where the scrollpoint sources are)
CD=`pwd`

# directory where we will compile
myHID=~/localbuild

# below must be checked against the output of uname -r
V="-35-generic"


mkdir $myHID
cd $myHID

## this is a necessary step, but takes forever... so run it once/
git clone git://kernel.ubuntu.com/ubuntu/ubuntu-precise.git

# (current) configuration files for building kernel
cp /usr/src/linux-headers-`uname -r`/Module.symvers .
cp /boot/config-`uname -r` .config

# unfortunately this is specific to whatever linux was just downloaded
cd ubuntu-precise
git checkout Ubuntu-3.2.0-35.55

#exit 

## this should really use diffs/patches instead of overwriting files...
cp $CD/hid-core.c drivers/hid/
cp $CD/hid-scrollpoint.c drivers/hid/
cp $CD/hid-ids.h drivers/hid/
cp $CD/Makefile drivers/hid/
cp $CD/Kconfig drivers/hid/
# # overwrite with the config that has lenovo enabled
cp $CD/.config ../


make EXTRAVERSION=$V O=$myHID oldconfig
make EXTRAVERSION=$V O=$myHID prepare
exit
make EXTRAVERSION=$V O=$myHID outputmakefile
make EXTRAVERSION=$V O=$myHID archprepare
make EXTRAVERSION=$V O=$myHID modules SUBDIRS=scripts
make EXTRAVERSION=$V O=$myHID modules SUBDIRS=drivers/hid

#cp -R ../drivers/hid/hid.ko $CD/hid-drivers/
#cp -R ../drivers/hid/hid-scrollpoint.ko $CD/hid-drivers/
cp -R ../drivers/hid/* $CD/hid-drivers/



## this code uses apt-get, which gets wrong version of kernel:

## get all the utilities for building the kernel (for this version)
#sudo apt-get build-dep --no-install-recommends linux-image-$(uname -r)

## get the kernel source (for this version)
#apt-get source linux-image-$(uname -r)

# ...
#cd linux-3.2.0/
