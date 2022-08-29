find /sys/devices -type d -wholename '/sys/devices/pci*/net' -print |awk -F/ '{printf "%s eth%u\n",$(NF-1),NR-1;}'
