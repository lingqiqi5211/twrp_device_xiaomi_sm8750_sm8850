#!/system/bin/sh
# The stock vendor partition is first-stage-mounted over the ramdisk's /vendor,
# and TWRP mounts it again for the partition list and leaves it there. While it
# is up, /vendor/bin/hw hands out the stock binary and 56 of the stock Android 15
# libraries sit ahead of ours in the search path -- libbinder.so among them -- so
# a HAL started then dies on a versioned-symbol error and only returns on init's
# five-second retry.
#
# wait-vendor.sh binds the ramdisk's binary and library directories under /twrplib
# while they are still reachable, so take both from there. Exporting the path
# has to come first: every helper below is toybox, and toybox does not link
# either while the stock libraries are in front.
export LD_LIBRARY_PATH=/twrplib/vendor:/twrplib/vendorhw:/twrplib/odm:/system/lib64:/sbin
tries=0
while [ ! -e /twrplib/.staged ] && [ "${tries}" -lt 300 ]; do
    /system/bin/sleep 0.1
    tries=$((tries + 1))
done

[ -e /twrplib/.staged ] || {
    echo "E:hal-launch: Library staging did not complete within 30 seconds." >> /tmp/recovery.log
    exit 1
}

binary="$1"
shift
case "${binary}" in
    /vendor/bin/hw/*) staged="/twrplib/vendorbin/${binary##*/}" ;;
    /odm/bin/hw/*) staged="/twrplib/odmbin/${binary##*/}" ;;
    *) staged="" ;;
esac
if [ -n "${staged}" ]; then
    [ -x "${staged}" ] || {
        echo "E:hal-launch: Staged binary ${staged} is missing or not executable." >> /tmp/recovery.log
        exit 1
    }
    binary="${staged}"
fi

exec "${binary}" "$@"
