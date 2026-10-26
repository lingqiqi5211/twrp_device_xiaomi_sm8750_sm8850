#!/system/bin/sh
# Helpers must not pick up libraries from the first-stage-mounted stock vendor.
export LD_LIBRARY_PATH=/system/lib64:/sbin

fail() {
    echo "E:wait-vendor: $*" >> /tmp/recovery.log
    exit 1
}

# Only the ramdisk's /vendor carries this marker.
tries=0
while [ ! -e /vendor/etc/twrp_ramdisk ] && [ "${tries}" -lt 300 ]; do
    /system/bin/sleep 0.1
    tries=$((tries + 1))
done
[ -e /vendor/etc/twrp_ramdisk ] || fail "Ramdisk vendor is still hidden after 30 seconds."

# Init's mount builtin cannot propagate failure to the following write/setprop.
# Do the binds here and undo partial staging if any step fails.
mounted=""
complete=0
trap 'if [ "$complete" != 1 ]; then
    for target in $mounted; do
        /system/bin/umount "$target"
    done
fi' EXIT

stage() {
    /system/bin/mkdir -p "$2" || fail "Cannot create $2."
    /system/bin/mount -o bind "$1" "$2" || fail "Cannot bind $1 to $2."
    mounted="$2 $mounted"
}

# Pin and check the source before binding its children. If recovery remounts
# stock vendor meanwhile, it cannot substitute stock files in these binds.
stage /vendor /twrplib/.vendor
[ -e /twrplib/.vendor/etc/twrp_ramdisk ] || fail "Captured vendor is not the ramdisk."
stage /twrplib/.vendor/lib64 /twrplib/vendor
stage /twrplib/.vendor/lib64/hw /twrplib/vendorhw
stage /twrplib/.vendor/bin/hw /twrplib/vendorbin
# ProcessFstab unmounts ODM first, but that operation can fail independently.
/system/bin/grep -q ' /odm ' /proc/mounts
case $? in
    0) fail "Stock ODM is still mounted." ;;
    1) ;;
    *) fail "Cannot check ODM mount state." ;;
esac
stage /odm/lib64 /twrplib/odm
stage /odm/bin/hw /twrplib/odmbin
/system/bin/umount /twrplib/.vendor || fail "Cannot release the temporary vendor bind."
mounted="${mounted%/twrplib/.vendor }"

# HAL launchers require the marker; publish it only after every bind succeeded.
echo 1 > /twrplib/.staged || fail "Cannot publish the staging marker."
complete=1
/system/bin/setprop twrp.libs.staged 1
/system/bin/setprop twrp.vendor.visible 1
