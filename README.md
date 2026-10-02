# TWRP device tree for Xiaomi SM8750 / SM8850

## Devices

One tree serves both platforms; each image carries one of them and serves every device on it.

- `recovery/root/` holds what both platforms share.
- `recovery/root/platform/<platform>/` holds each platform's vendor stack, rc
  files, fstab and device variants.
- `/init.recovery.qcom.rc` imports `/platform/sku/${ro.boot.hardware.sku}.rc`,
  which pulls in that SKU's platform. At early-init the platform's
  `early.sh` hard links its files into place and sets the platform
  properties.
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

`piano` has a landscape panel, so init sets persist.twrp.rotation for it and
TWRP scales the portrait theme onto the rotated canvas. TW_ROTATION is only
the compile time default; the property overrides it per device.

### SM8850

| SKU | Device |
| --- | --- |
| `pudding` | Xiaomi 17 |
| `pandora` | Xiaomi 17 Pro |
| `popsicle` | Xiaomi 17 Pro Max \* |
| `nezha` | Xiaomi 17 Ultra |
| `byron` | Xiaomi 17 Max |
| `myron` | REDMI K90 Pro Max / POCO F8 Ultra |
| `athens` | REDMI K100 Pro / POCO F9 Pro |
| `songyuan` | REDMI K100 Pro Max / POCO F9 Ultra |

\* Primary SM8850 test device upstream

TWRP's haptics instance is fixed at build time to the SM8750 one
(`IVibrator/vibratorfeature`). The SM8850 service registers
`IVibrator/default`, so `vibrator_alias/` is preloaded into it and registers
the same binder under the SM8750 name as well.

The WLAN page is shown on both platforms and only works on SM8750.

Tested on hardware with SM8750-only builds: `warsaw`, `piano`.

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
- [X] WLAN (SM8750)

## Build it yourself
* [TWRP-Test/platform_manifest_twrp_aosp](https://github.com/TWRP-Test/platform_manifest_twrp_aosp)

```
lunch twrp_sm8750-bp2a-eng
mka recoveryimage                         # SM8750 image
YARP_PLATFORM=sm8850 mka recoveryimage    # SM8850 image
```

The two share one Soong analysis; only the ramdisk differs.
