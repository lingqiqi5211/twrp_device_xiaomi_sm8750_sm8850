#!/system/bin/sh
# Names the weaver vendor of each SKU in ro.twrp.weaver. init runs it with exec
# at init, so the property is there before any trigger that tests it.
# StrongBox is not started in recovery: its applet only answers once the
# bootloader has sent it the boot state, which a recovery boot never does, and
# keystore2 then retries the shared secret every second for good.

vendor=""
case "$(getprop ro.boot.hardware.sku)" in
warsaw | annibale | miro)
    vendor="nxp"
    ;;
dada | haotian | xuanyuan)
    vendor="thales"
    ;;
# piano is a tablet and has no secure element at all: no eSE node in its device
# tree, so neither /dev/nq-nci nor /dev/st54spi_gpio ever appears and the eSE
# HAL exits on "eseGetVendorId: Unknown eSE HW". Its weaver slots live in the
# TEE and Xiaomi's own android.hardware.weaver is what reads them.
piano)
    vendor="mi"
    ;;
esac

if [ -n "${vendor}" ]; then
    setprop ro.twrp.weaver "${vendor}"
fi
