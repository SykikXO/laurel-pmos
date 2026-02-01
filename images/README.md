# Pre-built Images for Xiaomi Mi A3 (laurel-sprout)

These are pre-built postmarketOS images for the Xiaomi Mi A3.

## Files

| File | Size | Description |
|------|------|-------------|
| `pmos_boot.img` | 19MB | Boot image (kernel + initramfs) |
| `pmos_rootfs.img.xz.part_aa` | 90MB | Rootfs image part 1 (split for GitHub) |
| `pmos_rootfs.img.xz.part_ab` | 52MB | Rootfs image part 2 (split for GitHub) |

## How to Use

### Step 1: Reassemble the rootfs image

```bash
cat pmos_rootfs.img.xz.part_* > pmos_rootfs.img.xz
xz -d pmos_rootfs.img.xz
```

### Step 2: Enter fastboot mode on your phone

Hold **Volume Down + Power** until "FASTBOOT" appears.

### Step 3: Erase DTBO (CRITICAL!)

```bash
fastboot erase dtbo_a
fastboot erase dtbo_b
```

### Step 4: Disable verified boot

Create and flash an empty vbmeta with verification disabled:

```bash
# Option 1: Using fastboot flags (if supported)
fastboot --disable-verity --disable-verification flash vbmeta vbmeta.img

# Option 2: Use pmbootstrap to generate and flash vbmeta
pmbootstrap flasher flash_vbmeta
```

> **Note**: If you don't have pmbootstrap, you can create a minimal disabled vbmeta:
> ```bash
> # The vbmeta just needs to have the disable flags set
> # pmbootstrap handles this automatically
> ```

### Step 5: Flash the images

```bash
fastboot flash userdata pmos_rootfs.img
fastboot flash boot_a pmos_boot.img
fastboot flash boot_b pmos_boot.img
```

### Step 6: Reboot

```bash
fastboot reboot
```

## After Boot

Configure USB network on your host:
```bash
sudo ip link set <usb_interface> up
sudo ip addr add 172.16.42.2/24 dev <usb_interface>
ssh sykik@172.16.42.1
```

Default password: `147147`

## Build Info

- **OS**: postmarketOS edge
- **Kernel**: 6.1.0-sm6125 (mainline)
- **Built**: February 2026
- **Architecture**: aarch64
