ID=$(xinput list --id-only "christineblabe’s trackpad")
echo "sudo xinput set-prop $ID \"Device Enabled\" 0"
sudo xinput set-prop $ID "Device Enabled" 0
