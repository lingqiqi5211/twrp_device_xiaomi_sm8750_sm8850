#!/system/bin/sh

[ "$(getprop ro.boot.hardware.sku)" = "nezha" ] || exit 0

# Match Thales' libEseUtils detection after kernel modules have loaded.
tries=0
while [ ! -e /dev/st54spi_gpio ] && [ "$tries" -lt 50 ]; do
    sleep 0.1
    tries=$((tries + 1))
done

vendor=goodix
[ ! -e /dev/st54spi_gpio ] || vendor=thales
setprop ro.twrp.weaver "$vendor"
echo "weaver-vendor.sh: nezha selected $vendor" >> /tmp/recovery.log
