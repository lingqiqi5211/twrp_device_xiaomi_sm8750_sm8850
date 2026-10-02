#!/system/bin/sh
# init's wait command stops its whole command queue, and wlan0 needs about ten
# seconds to appear: the firmware download has to finish first. Measured on
# piano, init stood still for 10234 ms. The ctl.start that prepdecrypt sends for
# KeyMint sat in that queue for all of them, so KeyMint registered ten seconds
# late. keystore2 gives up on IKeyMintDevice/default after its own timeout, and
# a device whose KeyMint arrives after that decrypts nothing. Poll here instead,
# so init keeps working while WLAN comes up.

LOG_TAG="I:wait-wlan0.sh"
tries=0
while [ ! -e /sys/class/net/wlan0 ] && [ "$tries" -lt 300 ]; do
    sleep 0.1
    tries=$((tries + 1))
done

if [ -e /sys/class/net/wlan0 ]; then
    echo "$LOG_TAG: wlan0 appeared after ${tries} tenths of a second" >> /tmp/recovery.log
    echo "$LOG_TAG: wlan0 appeared after ${tries} tenths of a second" > /dev/kmsg
    echo "[wifi][interface] Interface wlan0 found" > /dev/kmsg
    setprop twrp.wifi.driver.ready true
else
    echo "$LOG_TAG: wlan0 never appeared, leaving wpa_supplicant down" >> /tmp/recovery.log
    echo "$LOG_TAG: wlan0 never appeared" > /dev/kmsg
    echo "[wifi][interface] wlan0 never appeared" > /dev/kmsg
fi
