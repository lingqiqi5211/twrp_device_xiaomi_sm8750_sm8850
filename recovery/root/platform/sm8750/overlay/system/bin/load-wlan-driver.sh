#!/system/bin/sh
# The cnss chain is in TW_LOAD_VENDOR_MODULES and TWRP loads it at boot. The
# WLAN driver itself is not: one image serves both chips of the family, kiwi
# (warsaw) and peach (the rest), and loading the wrong one is worse than
# loading none. TWRP's loader only copies the listed modules to a tmpfs and
# unmounts the dlkm partitions when it is done, so the driver has to be fetched
# from the device's own partitions here. That also keeps every module matched
# to the kernel the device actually runs: a copy in the ramdisk cannot be, and
# the kernel refuses a foreign rfkill with "exports protected symbol".
#
# rfkill is a GKI module and lives in system_dlkm (under flatten/ on sm8750);
# cfg80211 and the driver are in vendor_dlkm. Both are searched at any depth.

LOG_TAG="I:load-wlan-driver.sh"
# These run before TWRP creates /tmp/recovery.log, and TWRP truncates it when it
# does, so the lines also go to the kernel log where dmesg keeps them.
log() { echo "$LOG_TAG: $1" >> /tmp/recovery.log; echo "$LOG_TAG: $1" > /dev/kmsg; }

chip="$(getprop ro.twrp.wlan_chip)"
if [ -z "$chip" ]; then
    log "no ro.twrp.wlan_chip, leaving WLAN alone"
    exit 0
fi

mount_partition() {
    tries=0
    while [ ! -d "$1/lib/modules" ] && [ "$tries" -lt 100 ]; do
        mount "$1" 2>/dev/null
        sleep 0.1
        tries=$((tries + 1))
    done
    if [ ! -d "$1/lib/modules" ]; then
        log "$1 did not mount"
        return 1
    fi
    [ "$tries" -gt 0 ] && log "$1 mounted after ${tries} tenths of a second"
    return 0
}

find_module() {
    for part in /system_dlkm /vendor_dlkm; do
        found="$(find "$part" -name "$1.ko" 2>/dev/null | head -1)"
        if [ -n "$found" ]; then
            echo "$found"
            return 0
        fi
    done
    return 1
}

load_module() {
    if grep -q "^$(echo "$1" | tr - _) " /proc/modules; then
        return 0
    fi
    ko="$(find_module "$1")" || { log "$1.ko is on neither dlkm partition"; return 1; }
    mkdir -p /tmp/wlan
    cp -f "$ko" /tmp/wlan/ || { log "copy of $ko failed"; return 1; }
    if insmod "/tmp/wlan/$1.ko"; then
        log "$1 loaded from $ko"
    else
        log "insmod $1 failed (from $ko)"
        return 1
    fi
}

mount_partition /system_dlkm || exit 1
mount_partition /vendor_dlkm || exit 1

for dep in rfkill cfg80211; do
    load_module "$dep" || exit 1
done

for node in /sys/devices/platform/soc/*.qcom,cnss-*/fs_ready; do
    [ -e "$node" ] || continue
    chmod 0222 "$node"
    echo 1 > "$node" && log "fs_ready set on ${node%/fs_ready}"
done

if load_module "qca_cld3_${chip}"; then
    setprop twrp.wifi.driver.loaded true
else
    exit 1
fi
