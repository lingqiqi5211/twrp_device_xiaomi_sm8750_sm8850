#
# Copyright (C) 2025 The Android Open Source Project
#
# SPDX-License-Identifier: Apache-2.0
#

# Building with minimal manifest
ALLOW_MISSING_DEPENDENCIES := true

# Rules
BUILD_BROKEN_DUP_RULES := true
BUILD_BROKEN_ELF_PREBUILT_PRODUCT_COPY_FILES := true

# Architecture
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-a
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_ABI2 :=
TARGET_CPU_VARIANT := generic

# Bootloader
PRODUCT_PLATFORM := sun
TARGET_BOOTLOADER_BOARD_NAME := $(PRODUCT_PLATFORM)
TARGET_NO_BOOTLOADER := true

# Platform
TARGET_BOARD_PLATFORM := xiaomi_sm8750
TARGET_BOARD_PLATFORM_GPU := qcom-adreno830
QCOM_BOARD_PLATFORMS += xiaomi_sm8750

# Kernel
BOARD_KERNEL_IMAGE_NAME       := Image
BOARD_BOOT_HEADER_VERSION     := 4
BOARD_KERNEL_PAGESIZE         := 4096
TARGET_KERNEL_CLANG_COMPILE   := true
TARGET_PREBUILT_KERNEL        := $(DEVICE_PATH)/prebuilt/kernel
BOARD_MKBOOTIMG_ARGS          += --header_version $(BOARD_BOOT_HEADER_VERSION)
BOARD_MKBOOTIMG_ARGS          += --pagesize $(BOARD_KERNEL_PAGESIZE)

# Ramdisk use lz4
BOARD_RAMDISK_USE_LZ4 := true

# A/B
BOARD_EXCLUDE_KERNEL_FROM_RECOVERY_IMAGE := true

AB_OTA_UPDATER := true
AB_OTA_PARTITIONS += \
    boot \
    init_boot \
    vendor_boot \
    dtbo \
    vbmeta \
    vbmeta_system \
    odm \
    product \
    system \
    system_ext \
    system_dlkm \
    vendor \
    vendor_dlkm

# Verified Boot
BOARD_AVB_ENABLE := true

# Partitions
BOARD_PROPERTY_OVERRIDES_SPLIT_ENABLED := true

# Workaround for error copying vendor files to recovery ramdisk
TARGET_COPY_OUT_VENDOR := vendor

TARGET_COPY_OUT_ODM := odm
BOARD_ODMIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_USES_VENDOR_DLKMIMAGE := true
TARGET_COPY_OUT_VENDOR_DLKM := vendor_dlkm
BOARD_VENDOR_DLKMIMAGE_FILE_SYSTEM_TYPE := ext4

BOARD_RECOVERYIMAGE_PARTITION_SIZE := 104857600

# Dynamic Partition
BOARD_SUPER_PARTITION_SIZE := 11811160064
BOARD_SUPER_PARTITION_GROUPS := qti_dynamic_partitions
BOARD_QTI_DYNAMIC_PARTITIONS_SIZE := $(shell echo $$(($(BOARD_SUPER_PARTITION_SIZE) - 10485760)))
BOARD_QTI_DYNAMIC_PARTITIONS_PARTITION_LIST := system system_ext product vendor vendor_dlkm odm system_dlkm

# System as root
BOARD_ROOT_EXTRA_FOLDERS := bluetooth dsp firmware persist soccp

# File systems
TARGET_USERIMAGES_USE_EXT4 := true
TARGET_USERIMAGES_USE_F2FS := true

# Extras
TARGET_SYSTEM_PROP += $(DEVICE_PATH)/system.prop

# Recovery
TARGET_RECOVERY_PIXEL_FORMAT := RGBX_8888
# One platform per image: YARP_PLATFORM=sm8850 builds the SM8850 one.
YARP_PLATFORM ?= sm8750
YARP_DROP_PLATFORM := $(filter-out $(YARP_PLATFORM),sm8750 sm8850)
ifneq ($(words $(YARP_PLATFORM)) $(words $(YARP_DROP_PLATFORM)),1 1)
$(error YARP_PLATFORM must be sm8750 or sm8850, got '$(YARP_PLATFORM)')
endif
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/recovery/root/platform/$(YARP_PLATFORM)/overlay/system/etc/recovery.fstab
# Drop the other platform's layer and SKU entries, move the kept layer's lib/
# into the root (drivers that probe in first stage read /lib/firmware before
# early.sh links the layer), then list the ramdisk again the way
# build/make/core/Makefile does. A define, so it expands late (the root out dir
# is not set yet here) and ends in a newline for vendor/twrp's depmod lines.
YARP_LAYER_LIB := platform/$(YARP_PLATFORM)/overlay/lib
define BOARD_RECOVERY_IMAGE_PREPARE
cd $(TARGET_RECOVERY_ROOT_OUT) && test -d platform/sku && rm -rf platform/$(YARP_DROP_PLATFORM) && grep -l "/platform/$(YARP_DROP_PLATFORM)/" platform/sku/*.rc | xargs -r rm -f && { test ! -d $(YARP_LAYER_LIB) || { mkdir -p lib && cp -a $(YARP_LAYER_LIB)/. lib/ && rm -rf $(YARP_LAYER_LIB); }; } && find . | sed "s/.\///" | sed "/lib\/modules\//d" > ramdisk-files.txt && find -type f | sed "s/.\/ramdisk-files.sha256sum//" | sed "/lib\/modules/d" | sed "/prop.default/d" | sed "/ld\.config\.txt/d" | xargs sha256sum > ramdisk-files.sha256sum

endef

# Crypto
TW_INCLUDE_CRYPTO := true
TW_INCLUDE_CRYPTO_FBE := true
TW_INCLUDE_FBE_METADATA_DECRYPT := true
BOARD_USES_METADATA_PARTITION := true
TW_INCLUDE_OMAPI := true
TW_USE_FSCRYPT_POLICY := 2
PLATFORM_VERSION := 99.87.36
PLATFORM_VERSION_LAST_STABLE := $(PLATFORM_VERSION)
PLATFORM_SECURITY_PATCH := 2099-12-31
VENDOR_SECURITY_PATCH := $(PLATFORM_SECURITY_PATCH)
BOOT_SECURITY_PATCH := $(PLATFORM_SECURITY_PATCH)

# Tool
TW_INCLUDE_7ZA := true
TW_INCLUDE_ZSTD := true
TW_INCLUDE_REPACKTOOLS := true
TW_INCLUDE_RESETPROP := true
TW_INCLUDE_LIBRESETPROP := true
TW_ENABLE_ALL_PARTITION_TOOLS := true

# Debug
TARGET_USES_LOGD := true
TWRP_INCLUDE_LOGCAT := true
TARGET_RECOVERY_DEVICE_MODULES += debuggerd
RECOVERY_BINARY_SOURCE_FILES += $(TARGET_OUT_EXECUTABLES)/debuggerd
TARGET_RECOVERY_DEVICE_MODULES += strace
# Gives the SM8850 vibrator HAL the SM8750 instance name too (vibrator_alias/).
TARGET_RECOVERY_DEVICE_MODULES += libvibrator_alias
RECOVERY_BINARY_SOURCE_FILES += $(TARGET_OUT_EXECUTABLES)/strace
# TW_INCLUDE_WIFI only compiles the WLAN pages in; the daemon the pages talk to
# is this module (external/wpa_supplicant_8, stem wpa_supplicant), and nothing
# pulls it into the ramdisk unless it is named here.
TARGET_RECOVERY_DEVICE_MODULES += wpa_supplicant_recovery wpa_cli_recovery

# Fastbootd
TW_INCLUDE_FASTBOOTD := true

# Wi-Fi
TW_INCLUDE_WIFI := true

# Other TWRP Configurations
TW_THEME := portrait_hdpi
TW_FRAMERATE := 120
RECOVERY_SDCARD_ON_DATA := true
TARGET_RECOVERY_QCOM_RTC_FIX := true
TW_EXCLUDE_DEFAULT_USB_INIT := true
TW_INCLUDE_NTFS_3G := true
TW_USE_DMCTL := true
TW_USE_TOOLBOX := true
TARGET_USES_MKE2FS := true
TW_INPUT_BLACKLIST := "hbtp_vm"
TW_BRIGHTNESS_PATH := "/sys/class/backlight/panel0-backlight/brightness"
TW_MAX_BRIGHTNESS := 2047
TW_EXTRA_LANGUAGES := true
TW_DEFAULT_BRIGHTNESS := 250
TW_EXCLUDE_APEX := true
TW_SUPPORT_INPUT_AIDL_HAPTICS := true
TW_SUPPORT_INPUT_AIDL_HAPTICS_FQNAME := "IVibrator/vibratorfeature"
TW_SUPPORT_INPUT_AIDL_HAPTICS_FIX_OFF := true
TW_USE_SERIALNO_PROPERTY_FOR_DEVICE_ID := true
TW_LOAD_VENDOR_MODULES := "adsp_loader_dlkm.ko rproc_qcom_common.ko q6_dlkm.ko qcom_q6v5.ko qcom_q6v5_pas.ko qcom_sysmon.ko synaptics_tcm2.ko goodix_core.ko nt36532_touch.ko focaltech_touch.ko xiaomi_touch.ko nxp-nci.ko stm_st54se_gpio.ko stm_nfc_i2c.ko qcom-hv-haptics.ko cs40l26-i2c.ko nt38773_touch.ko focaltech_touch_3683.ko focaltech_touch_3685g.ko focaltech_touch_3685g_1.ko cnss_prealloc.ko cnss_nl.ko wlan_firmware_service.ko cnss_plat_ipc_qmi_svc.ko cnss_utils.ko cnss2.ko gsim.ko rmnet_mem.ko ipam.ko"
TW_LOAD_VENDOR_MODULES_EXCLUDE_GKI := true
TW_LOAD_PREBUILT_MODULES_AT_FIRST := true
# Linked to the running platform's CPU-0-0-0 zone by platform/<p>/early.sh.
TW_CUSTOM_CPU_TEMP_PATH := "/dev/twrp_cpu_temp"
TW_BACKUP_EXCLUSIONS := /data/fonts,/data/adb/ap,/data/adb/ksu
