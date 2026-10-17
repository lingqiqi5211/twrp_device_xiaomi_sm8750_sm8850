# TWRP device tree for Xiaomi SM8750 / SM8850

## Devices

One tree serves both platforms; each image carries one of them and serves every device on it.

- `recovery/root/` holds what both platforms share.
- `recovery/root/platform/<platform>/` holds each platform's vendor stack, rc
  files, fstab and device variants.
- `/init.recovery.qcom.rc` imports `/platform/sku/${ro.boot.hardware.sku}.rc`,
  which pulls in that SKU's platform. At early-init the platform's
  `early.sh` hard links its files into place and sets the platform
  properties. The layer's `lib/` is the exception: it holds firmware for
  drivers that probe in first stage, so the build puts it straight into the
  ramdisk's `/lib`.
- Within a platform, `variant-script.sh` reads `ro.boot.hardware.sku` and sets
  the per-device properties.

Adding a device means adding its `platform/sku/<sku>.rc` as well as its
variant. A SKU without one boots TWRP without the vendor stack.

### SM8750

The WLAN chip is read from the kernel's cnss device tree node.

| SKU | Device | Weaver | WLAN |
| --- | --- | --- | --- |
| `dada` | Xiaomi 15 | Thales eSE | peach_v2 |
| `haotian` | Xiaomi 15 Pro | Thales eSE | peach_v2 |
| `xuanyuan` | Xiaomi 15 Ultra | Thales eSE | peach_v2 |
| `warsaw` | REDMI K90 Ultra | NXP eSE | kiwi_v2 |
| `annibale` | REDMI K90 / POCO F8 Pro | NXP eSE | kiwi_v2 |
| `miro` | REDMI K80 Pro / POCO F7 Ultra | NXP eSE | detected |
| `piano` | Xiaomi Pad 8 Pro | TEE (miweaver) | peach_v2 |

`piano` has no secure element: no eSE node in its device tree, so the eSE HAL
never finds one and nothing can reach an applet. Its weaver slots live in the
TEE and Xiaomi's own `android.hardware.weaver` is the service that reads them.

`piano` uses the panel's reported orientation; the device tree does not force
`persist.twrp.rotation`.

### SM8850

| SKU | Device | Weaver |
| --- | --- | --- |
| `pudding` | Xiaomi 17 | Thales eSE |
| `pandora` | Xiaomi 17 Pro | NXP eSE |
| `popsicle` | Xiaomi 17 Pro Max \* | NXP eSE |
| `nezha` | Xiaomi 17 Ultra | Goodix / Thales eSE (detected) |
| `byron` | Xiaomi 17 Max | NXP eSE |
| `myron` | REDMI K90 Pro Max / POCO F8 Ultra | NXP eSE |
| `athens` | REDMI K100 Pro / POCO F9 Pro | NXP eSE |
| `songyuan` | REDMI K100 Pro Max / POCO F9 Ultra | Thales eSE |

\* Primary SM8850 test device upstream

`nezha` has two secure-element variants. After the variant files are copied
and kernel modules are loaded, init runs
[`weaver-vendor.sh`](recovery/root/platform/sm8850/overlay/system/bin/weaver-vendor.sh).
It follows the stock `ro.special_edition` property: `true` selects Goodix,
`false` selects Thales. If Recovery does not have that property, the script
mounts the installed ROM's ODM read-only at a separate temporary mountpoint
and reads its `build.prop` imports to resolve the edition. It does not keep
a hardware-version table or use `/dev/st54spi_gpio` to select a vendor.
An unreadable or unsupported ROM configuration leaves the vendor unselected
and logs the reason. A successfully read stock configuration without the
edition property retains the stock Thales default.
[`init.recovery.sm8850.rc`](recovery/root/platform/sm8850/init/init.recovery.sm8850.rc)
then starts the matching services. The SKU script does not force a vendor
for `nezha`.

To check the selection in Recovery:

```sh
adb shell getprop ro.twrp.weaver
adb shell 'grep "weaver-vendor.sh:" /tmp/recovery.log'
```

This is hardware selection, not a fallback after a rejected password.
Both hardware variants still need device-specific decryption validation.

TWRP's haptics instance is fixed at build time to the SM8750 one
(`IVibrator/vibratorfeature`). The SM8850 service registers
`IVibrator/default`, so `vibrator_alias/` is preloaded into it and registers
the same binder under the SM8750 name as well.

`TW_INCLUDE_WIFI` defaults to `true`; this tree provides the WLAN stack for
SM8750 only.
SM8850 test releases disable the WLAN UI and exclude the supplicant modules
with a local build override; that override is not part of this tree.

The device tables describe the configured variants, not a complete test
matrix. Hardware testing on this branch includes `warsaw` and `piano`.

## Features

- [X] ADB
- [X] Decryption
- [X] Display
- [X] Fastbootd
- [X] Flashing
- [X] MTP
- [X] Sideload
- [X] USB-OTG
- [X] Vibrator
- [X] WLAN vendor stack (SM8750)

## Build it yourself

Use [TWRP-Test/platform_manifest_twrp_aosp](https://github.com/TWRP-Test/platform_manifest_twrp_aosp)
and place this branch at `device/xiaomi/sm8750`:

```sh
git clone -b twrp-16.0 https://github.com/lingqiqi5211/twrp_device_xiaomi_sm8750_sm8850.git device/xiaomi/sm8750
source build/envsetup.sh
export YARP_PLATFORM=sm8750
lunch twrp_sm8750-bp2a-eng
mka recoveryimage
```

Both platforms use the same lunch target. To build SM8850, select it before
lunch. When reusing an output directory from the other platform, clean the
installed files before building to avoid mixing platform contents:

```sh
export YARP_PLATFORM=sm8850
lunch twrp_sm8750-bp2a-eng
mka installclean
mka recoveryimage
```

`YARP_PLATFORM` defaults to `sm8750` and accepts only `sm8750` or `sm8850`.
Packaging selects that platform's fstab, keeps its platform layer and SKU
imports, and removes the other platform. Build separate images for the two
platforms; a single image does not serve both.

The product name remains `sm8750` in either case, so the image is written to
`${OUT_DIR:-out}/target/product/sm8750/recovery.img`. Copy it to a filename
that identifies the selected platform before switching builds.
