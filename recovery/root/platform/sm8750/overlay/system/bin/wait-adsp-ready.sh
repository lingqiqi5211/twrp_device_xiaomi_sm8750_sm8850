#!/system/bin/sh
#
# The health HAL reads the gauge off the PMIC and the eSE HAL asks the element
# for its vendor id; both of those paths run through the ADSP, so nothing that
# uses them can start until it is running. Its remoteproc index is not the same
# on every SKU in this family, so find the node by name rather than by number.

adsp=""
for node in /sys/class/remoteproc/remoteproc*; do
    case "$(cat "$node/name" 2>/dev/null)" in
    *adsp*)
        adsp="$node"
        break
        ;;
    esac
done

if [ -z "$adsp" ]; then
    setprop twrp.adsp.ready false
    exit 1
fi

tries=0
while [ "$tries" -lt 60 ]; do
    if [ "$(cat "$adsp/state" 2>/dev/null)" = "running" ]; then
        setprop twrp.adsp.ready true
        exit 0
    fi

    sleep 1
    tries=$((tries + 1))
done

setprop twrp.adsp.ready false
exit 1
