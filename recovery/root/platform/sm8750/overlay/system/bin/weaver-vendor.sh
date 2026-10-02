#!/system/bin/sh
# servicemanager and keystore2 both read the device VINTF manifest within the
# first milliseconds of the init trigger, and each one caches it for its own
# lifetime. The manifest has to be correct before either of them starts.
# variant-script runs at post-fs, which is 7 ms too late: on piano keystore2
# had already read the strongbox declarations, and it then waited five seconds
# for services that a Thales device never starts. init runs this script with
# exec, so it completes before servicemanager.
#
# This is also the one place that names the weaver vendor of each SKU.

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

# Only the NXP keymint service provides IKeyMintDevice/strongbox,
# IRemotelyProvisionedComponent/strongbox and ISharedSecret/strongbox. An
# unknown SKU starts no strongbox service either, so it drops them too.
if [ "${vendor}" != "nxp" ]; then
    rm -f /odm/etc/vintf/manifest/android.hardware.security.keymint-service.strongbox.xml
    rm -f /odm/etc/vintf/manifest/android.hardware.security.sharedsecret-service.strongbox.xml
fi
