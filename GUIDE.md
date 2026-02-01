# postmarketOS Build & Flash Guide for Xiaomi Mi A3 (laurel-sprout)

This guide documents the complete procedure to build and flash postmarketOS to a Xiaomi Mi A3.

---

## Prerequisites

- A Linux host machine with USB connection to the phone
- Phone in fastboot mode (hold Volume Up + Power during boot)
- Unlocked bootloader
- `pmbootstrap` installed (v3.9.0+)

---

## Step 1: Install pmbootstrap

```bash
# Arch Linux
yay -S pmbootstrap

# Or via pip
pip install pmbootstrap
```

---

## Step 2: Initialize pmbootstrap

```bash
pmbootstrap init
```

When prompted, select:
- **Vendor**: `xiaomi`
- **Device**: `laurel`
- **Username**: your preferred username
- **Audio backend**: `pipewire` (i used)
- **WiFi backend**: `iwd` (i used)
- **UI**: `console` (i used)
- **Timezone**: your timezone
- **SSH keys**: `y` (copy SSH keys to device)

---

## Step 3: Build the Image

```bash
pmbootstrap install --password YOUR_PASSWORD
```

This will:
1. Prepare the native chroot
2. Create the device rootfs
3. Generate the boot image
4. Create the flashable rootfs image

---

## Step 4: Enter Fastboot Mode

On the phone:
1. Power off completely
2. Hold **Volume Down + Power** until "FASTBOOT" appears

Verify connection:
```bash
fastboot devices
# Should show: 66078170228a     fastboot
```

---

## Step 5: Erase DTBO Partitions (CRITICAL!)

> ⚠️ **This step is essential!** Without it, the device will boot loop.

```bash
fastboot erase dtbo_a
fastboot erase dtbo_b
```

---

## Step 6: Flash the Images

Flash in this exact order:

```bash
# 1. Flash vbmeta with verification disabled
pmbootstrap flasher flash_vbmeta

# 2. Flash rootfs to userdata partition
pmbootstrap flasher flash_rootfs

# 3. Flash kernel to boot partition
pmbootstrap flasher flash_kernel

# 4. (Optional) Flash kernel to both slots for redundancy
sudo cp ~/.local/var/pmbootstrap/chroot_rootfs_xiaomi-laurel/boot/boot.img /tmp/
fastboot flash boot_a /tmp/boot.img
fastboot flash boot_b /tmp/boot.img
```

---

## Step 7: Reboot

```bash
fastboot reboot
```

---

## Step 8: Connect via USB Networking

After boot, the phone creates a USB network interface. On the host:

```bash
# Find the new interface (usually enp*u* or usb0)
ip addr show

# Configure the interface
sudo ip link set enp3s0f3u1 up
sudo ip addr add 172.16.42.2/24 dev enp3s0f3u1

# Test connectivity
ping 172.16.42.1

# SSH into the phone
ssh YOUR_USERNAME@172.16.42.1
```

---

## Step 9: Enable Internet on the Phone

To give the phone internet access through the host:

On the **host machine**:
```bash
# Enable IP forwarding
sudo sysctl net.ipv4.ip_forward=1

# Set up NAT
sudo iptables -t nat -A POSTROUTING -s 172.16.42.0/24 -o wlan0 -j MASQUERADE
```

On the **phone** (via SSH):
```bash
doas ip route add default via 172.16.42.2
echo "nameserver 8.8.8.8" | doas tee /etc/resolv.conf

# Test internet
ping 8.8.8.8
```

---

## Step 10: Install Packages

```bash
doas apk update
doas apk add fastfetch htop vim  # or any packages you want
```

---

## Troubleshooting

### Device keeps rebooting to fastboot
- **Solution**: You missed the `fastboot erase dtbo` step. Re-run steps 5-7.

### "unknown command" when using `fastboot boot`
- This device has a locked fastboot that doesn't support the `boot` command. You must flash directly.

### No USB network interface appears
- Wait 30-60 seconds after boot
- Check `lsusb` or `/sys/bus/usb/devices/*/product` for "Xiaomi Mi A3"
- If it shows "Android", the device is in fastboot mode (boot failed)

### SSH connection refused
- The SSH daemon takes a few seconds to start after boot
- Wait 10-15 seconds and retry

---

## Quick Reference Commands

| Action | Command |
|--------|---------|
| Check device | `fastboot devices` |
| Erase dtbo | `fastboot erase dtbo_a && fastboot erase dtbo_b` |
| Flash vbmeta | `pmbootstrap flasher flash_vbmeta` |
| Flash rootfs | `pmbootstrap flasher flash_rootfs` |
| Flash kernel | `pmbootstrap flasher flash_kernel` |
| Reboot | `fastboot reboot` |
| SSH to phone | `ssh sykik@172.16.42.1` |

---

## System Info After Successful Boot

```
OS: postmarketOS edge aarch64
Host: Xiaomi Mi A3
Kernel: Linux 6.1.0-sm6125
CPU: sm6125 (8 cores)
Memory: 3.48 GiB
Storage: ~47 GB
```

---

## References

- [postmarketOS Wiki - Xiaomi Mi A3](https://wiki.postmarketos.org/wiki/Xiaomi_Mi_A3_(xiaomi-laurel))
- [pmaports MR#3105](https://gitlab.postmarketos.org/postmarketOS/pmaports/-/merge_requests/3105)
- [fastfetch](https://github.com/fastfetch-cli/fastfetch)
