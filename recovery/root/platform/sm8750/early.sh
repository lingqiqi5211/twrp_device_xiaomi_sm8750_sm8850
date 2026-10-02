#!/system/bin/sh
# Runs at early-init, before init starts anything that reads these files.
# The packer gives exec bits only by real path, so files under the layer arrive as 0644.
find /platform/sm8750/overlay -path '*/bin/*' -type f -exec chmod 0755 {} +
cp -alf /platform/sm8750/overlay/. /
ln -sf /sys/class/thermal/thermal_zone1/temp /dev/twrp_cpu_temp
setprop service.adb.tcp.port 5555
