echo "Enabling all mouse devices"

ID=$(xinput list --id-only "PS/2 Generic Mouse")
echo "sudo xinput set-prop $ID \"Device Enabled\" 1"
sudo xinput set-prop $ID "Device Enabled" 1

ID=$(xinput list --id-only "SynPS/2 Synaptics TouchPad")
echo "sudo xinput set-prop $ID \"Device Enabled\" 1"
sudo xinput set-prop $ID "Device Enabled" 1

ID=$(xinput list --id-only "christineblabe’s trackpad")
echo "sudo xinput set-prop $ID \"Device Enabled\" 1"
sudo xinput set-prop $ID "Device Enabled" 1

ID=$(xinput list --id-only "Razer Razer DeathAdder")
echo "sudo xinput set-prop $ID \"Device Enabled\" 1"
sudo xinput set-prop $ID "Device Enabled" 1
