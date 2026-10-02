#!/system/bin/sh
#=================================================
# Auto-set device properties based on hardware SKU
#=================================================
set -e

variant=$(getprop ro.boot.hardware.sku)
base_name="Xiaomi 15"
log_file="/tmp/recovery.log"

log() {
    echo "variant-props-override.sh: $1" | tee -a "$log_file"
}

#-------------------------------------------------
# Helper: set multiple vibrator-related properties
#-------------------------------------------------
# $1 resonant frequency, $2 slide effect protect time, $3 sysfs path
detect_wlan_chip() {
    for node in /sys/devices/platform/soc/*.qcom,cnss-*; do
        [ -d "${node}" ] || continue
        case "${node#*cnss-}" in
        kiwi*) echo "kiwi_v2"; return 0 ;;
        peach*) echo "peach_v2"; return 0 ;;
        esac
    done
    return 1
}

set_vibrator_props() {
    # Off in recovery: audio-coupled haptics needs a sound card, and waiting on
    # one costs another three seconds before IVibrator registers. Measured on
    # warsaw with device_type ff: 4s with it on, 1s with it off.
    resetprop ro.odm.mm.vibrator.audio_haptic_support "false"
    resetprop ro.odm.mm.vibrator.resonant_frequency "$1"
    resetprop ro.odm.mm.vibrator.slide_effect_protect_time "$2"
    resetprop ro.odm.mm.vibrator.sys_path "$3"
    # Always FF here. AGM wants /sys/kernel/snd_card/card_state, which no recovery
    # has, and the HAL retries it twenty times before falling back to FF anyway.
    # Measured on warsaw: agm 24s to register IVibrator, ff 1s, same deviceType 0.
    resetprop ro.odm.mm.vibrator.device_type "ff"
    resetprop ro.vendor.mm.vibrator.sys_path "/sys/class/qcom-haptics"
}

#-------------------------------------------------
# Variant-specific configuration
#-------------------------------------------------
case "$variant" in
"dada")
    resetprop ro.twrp.wlan_chip "peach_v2"
    model="$base_name"
    resetprop ro.twrp.device_version "Xiaomi_15"
    resetprop ro.twrp.y_offset "111"
    resetprop ro.twrp.h_offset "-111"
    resetprop vendor.display.enable_spr "1"
    set_vibrator_props "170" "35" "/sys/class/qcom-haptics"
    ;;

"haotian")
    resetprop ro.twrp.wlan_chip "peach_v2"
    model="$base_name Pro"
    resetprop ro.twrp.device_version "Xiaomi_15_Pro"
    resetprop ro.twrp.y_offset "116"
    resetprop ro.twrp.h_offset "-116"
    resetprop vendor.display.enable_spr "1"
    resetprop ro.odm.mm.vibrator.cirrus "true"
    resetprop ro.odm.mm.vibrator.lowPowerMode "true"
    set_vibrator_props "130" "20" "/sys/bus/i2c/drivers/cs40l26/0-0043"
    ;;

"xuanyuan")
    resetprop ro.twrp.wlan_chip "peach_v2"
    model="$base_name Ultra"
    resetprop ro.twrp.device_version "Xiaomi_15_Ultra"
    resetprop ro.twrp.y_offset "116"
    resetprop ro.twrp.h_offset "-116"
    resetprop ro.odm.mm.vibrator.he1.0 "mihaptic"
    set_vibrator_props "170" "20" "/sys/class/qcom-haptics"
    ;;

"warsaw")
    resetprop ro.twrp.wlan_chip "kiwi_v2"
    model="REDMI K90 Ultra"
    resetprop ro.twrp.device_version "REDMI_K90_Ultra"
    resetprop vendor.display.enable_spr "1"
    resetprop vendor.display.enable_spr_bypass "1"
    resetprop ro.odm.mm.vibrator.lowPowerMode "true"
    set_vibrator_props "170" "35" "/sys/class/qcom-haptics"
    ;;

"annibale")
    resetprop ro.twrp.wlan_chip "kiwi_v2"
    model="REDMI K90"
    resetprop ro.twrp.device_version "REDMI_K90"
    resetprop ro.odm.mm.vibrator.lowPowerMode "true"
    set_vibrator_props "170" "35" "/sys/class/qcom-haptics"
    ;;

"miro")
    model="REDMI K80 Pro"
    resetprop ro.twrp.device_version "REDMI_K80_Pro"
    resetprop ro.odm.mm.vibrator.lowPowerMode "true"
    set_vibrator_props "170" "20" "/sys/class/qcom-haptics"
    ;;

"piano")
    resetprop ro.twrp.wlan_chip "peach_v2"
    model="Xiaomi Pad 8 Pro"
    resetprop ro.twrp.device_version "Xiaomi_Pad_8_Pro"
    set_vibrator_props "170" "35" "/sys/class/qcom-haptics"
    ;;

*)
    #-----------------------------------------
    # Default configuration
    #-----------------------------------------
    log "Unknown variant: $variant, applying default configuration (SM8750)"
    variant="SM8750"
    model="SM8750"
    set_vibrator_props "170" "35" "/sys/class/qcom-haptics"
    ;;
esac

chip="$(detect_wlan_chip)" || chip=""
if [ -n "$chip" ]; then
    resetprop ro.twrp.wlan_chip "$chip"
fi
log "WLAN chip: $(getprop ro.twrp.wlan_chip) (detected: ${chip:-none})"

#-------------------------------------------------
# Common configuration
#-------------------------------------------------
echo "$model" >/config/usb_gadget/g1/strings/0x409/product
resetprop vendor.usb.product_string "$model"
mkdir -p /usbotg

#-------------------------------------------------
# Set product & model properties
#-------------------------------------------------
device_props=(
    ro.build.product
    ro.product.device
    ro.product.odm.device
    ro.product.vendor.device
    ro.product.product.device
    ro.product.system_ext.device
    ro.product.system.device
    ro.product.bootimage.device
    ro.product.name
    ro.product.odm.name
    ro.product.vendor.name
    ro.product.product.name
    ro.product.system_ext.name
    ro.product.system.name
)

model_props=(
    ro.product.model
    ro.product.odm.model
    ro.product.vendor.model
    ro.product.product.model
    ro.product.system_ext.model
    ro.product.system.model
)

for prop in "${device_props[@]}"; do
    resetprop "$prop" "$variant"
done

for prop in "${model_props[@]}"; do
    resetprop "$prop" "$model"
done

#-------------------------------------------------
# Copy variant-specific files
#-------------------------------------------------
# set -e is on, so an unknown SKU with no overlay would abort the script here
# and never raise files_copied, leaving weaver, haptics and touch unstarted.
if [ -d "/odm/variant/$variant/odm" ]; then
    cp -rf /odm/variant/$variant/odm/* /odm
    chmod -R 755 /odm/bin/*
else
    log "No overlay for $variant, keeping the base odm"
fi
setprop twrp.variant.files_copied "1"

#-------------------------------------------------
# Done
#-------------------------------------------------
log "Applied variant props for: $model ($variant)"
exit 0
