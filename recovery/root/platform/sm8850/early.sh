#!/system/bin/sh
# Runs at early-init, before init starts anything that reads these files.
# The packer gives exec bits only by real path, so files under the layer arrive as 0644.
find /platform/sm8850/overlay -path '*/bin/*' -type f -exec chmod 0755 {} +
cp -alf /platform/sm8850/overlay/. /
ln -sf /sys/class/thermal/thermal_zone25/temp /dev/twrp_cpu_temp
# The image is built as sm8750; give the vendor stack the values it shipped with.
resetprop ro.board.platform xiaomi_sm8850
resetprop ro.product.board canoe
resetprop ro.board.first_api_level 202504
resetprop ro.product.first_api_level 36
setprop ro.dynamic.full_size 13421772800
