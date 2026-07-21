# WPA2 4-Way Handshake Capture Tool

A Bash script that automates the process of capturing a WPA2 4-way EAPOL
handshake using the `aircrack-ng` suite. Built as a hands-on project to learn
wireless security fundamentals: monitor mode, 802.11 management frames,
deauthentication attacks, and the EAPOL handshake itself.

## ⚠️ Disclaimer

This tool is for **educational purposes and authorized security testing
only**. Only use it against networks and devices you **own** or have
**explicit written permission** to test. Unauthorized access to computer
networks, and deauthenticating clients on networks you don't control, is
illegal in most jurisdictions (e.g. under the U.S. Computer Fraud and Abuse
Act, the UK Computer Misuse Act, etc.). The author takes no responsibility
for misuse of this tool.

## What it does

1. Checks that a compatible wireless adapter is connected (`lsusb`)
2. Kills conflicting network processes (`airmon-ng check kill`)
3. Enables monitor mode on the wireless interface
4. Scans nearby networks (`airodump-ng`) and lists them
5. Prompts for a target BSSID and channel
6. Starts a background packet capture on that target
7. Sends deauthentication frames to force a client to reconnect
8. Waits for and saves the resulting 4-way EAPOL handshake
9. Optionally restores the interface to managed mode afterward

## Requirements

- Linux (tested on Debian/Ubuntu-based distros)
- [`aircrack-ng`](https://www.aircrack-ng.org/) suite (`airmon-ng`,
  `airodump-ng`, `aireplay-ng`)
- A wireless adapter that supports monitor mode and packet injection
- `sudo` privileges

Install aircrack-ng on Debian/Ubuntu:
```bash
sudo apt update && sudo apt install aircrack-ng
```

## Usage

```bash
chmod +x capture_handshake.sh
sudo ./capture_handshake.sh
```

You'll be prompted for:
- The channel number of your target network
- The BSSID (MAC address) of your target network

The script saves the capture as `wificapture23-01.cap` in the current
directory.

## Verifying the handshake

Once captured, you can check that a valid handshake was recorded with:

```bash
aircrack-ng wificapture23-01.cap
```

If a handshake was captured, `aircrack-ng` will report it next to the target
BSSID. From there, you can optionally attempt a dictionary attack against a
password you already know (e.g. to test your own router's password
strength) using a wordlist:

```bash
aircrack-ng -w /path/to/wordlist.txt -b <BSSID> wificapture23-01.cap
```

## What I learned

- How the WPA2 4-way handshake authenticates clients using a PSK and nonces
- Why deauthentication frames are unauthenticated in 802.11 (and therefore
  trivially spoofable) — a core weakness WPA3's SAE handshake addresses
- How monitor mode differs from normal Wi-Fi adapter operation
- Practical use of the aircrack-ng toolchain for wireless auditing

## License

MIT — see [LICENSE](LICENSE).
