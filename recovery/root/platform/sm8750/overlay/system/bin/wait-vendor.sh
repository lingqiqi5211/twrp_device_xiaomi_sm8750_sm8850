#!/system/bin/sh
# Only the ramdisk's /vendor carries this marker, so its absence means the stock
# partition is still mounted over it.
tries=0
while [ ! -e /vendor/etc/twrp_ramdisk ] && [ "${tries}" -lt 300 ]; do
    /system/bin/sleep 0.1
    tries=$((tries + 1))
done
/system/bin/setprop twrp.vendor.visible 1
