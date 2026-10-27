#
# Replacement common tree for OnePlus 11 (salami, SM8550 / kalama).
#
# This tree is AUTHORED, not copied from the missing TeamWin tree:
# TeamWin android_device_oneplus_sm85xx-common (branch android-12.1)
# does not exist on GitHub (verified: git ls-remote + API 404).
# Sources used as reference (see README.md for the full map):
#   - LineageOS android_device_oneplus_sm8550-common, lineage-23.2
#     (BoardConfig structure, fstab flag forms, recovery variables)
#   - Stock firmware CPH2447_16.0.5.1301 payload manifest (exact sizes)
#   - Live super metadata parsed from the user's own phone
#     (group name, live logical sizes, byte-exact)
#   - Stock recovery fstab from the unpacked stock recovery ramdisk
#     (my_* mount rows, nofail pattern, no AVB flags on logical rows)
#
# What is DELIBERATELY NOT in this tree:
#   - No Lineage AVB test keys (see the Verified Boot section below).
#   - No Lineage product identity (no CPH2449; the phone is CPH2447,
#     and the variant mapping lives in device/oneplus/salami).
#   - No Lineage vendor blobs and no vendor BoardConfig include.
#   - No ROM-only content (audio/display overlays, SEPolicy, props).
# This tree builds RECOVERY ONLY. It never builds a ROM and never
# compiles a kernel (see the Kernel section below).
#

COMMON_PATH := device/oneplus/sm85xx-common

# A/B
# The 15 slot-suffixed partitions of the stock A/B OTA set, verified
# against the CPH2447_16.0.5.1301 payload manifest (all 15 present)
# and against the live GPT parse (138 entries across 6 UFS LUNs).
AB_OTA_UPDATER := true

AB_OTA_PARTITIONS += \
    boot \
    dtbo \
    init_boot \
    odm \
    product \
    recovery \
    system \
    system_dlkm \
    system_ext \
    vbmeta \
    vbmeta_system \
    vbmeta_vendor \
    vendor \
    vendor_boot \
    vendor_dlkm

# Architecture (Qualcomm SM8550 / kalama platform facts)
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-2a-dotprod
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_VARIANT := generic
TARGET_CPU_VARIANT_RUNTIME := kryo300

# Bootloader
TARGET_BOOTLOADER_BOARD_NAME := kalama

# Boot image (stock header version 4, LZ4 ramdisk — matches the
# shipped stock boot/recovery images, whose ramdisks are LZ4)
BOARD_BOOT_HEADER_VERSION := 4
BOARD_MKBOOTIMG_ARGS += --header_version $(BOARD_BOOT_HEADER_VERSION)
BOARD_RAMDISK_USE_LZ4 := true

# Init Boot
BOARD_INIT_BOOT_HEADER_VERSION := 4
BOARD_MKBOOTIMG_INIT_ARGS += --header_version $(BOARD_INIT_BOOT_HEADER_VERSION)

# Kernel — REFERENCE ONLY. This recovery tree compiles NO kernel.
# The recovery image is ramdisk-only (see the Recovery section) and
# runs on the active slot's boot kernel. The designated kernel base
# for this project is the SHIPPED STOCK kernel 5.15.197, extracted
# from the stock boot image (stock-kernel-Image, 53,189,120 B,
# vermagic 5.15.197-android13-8-o-01214-gbee5b6ef6244) — NOT the
# Dragonw1nd 5.15.211 custom kernel and NOT the OnePlusOSS 5.15.180
# published source baseline. The OnePlusOSS kernel trio
# (android_kernel_oneplus_sm8550, android_kernel_common_oneplus_sm8550,
# android_kernel_modules_and_devicetree_oneplus_sm8550, branch
# oneplus/sm8550_b_16.0.0_oneplus_11) is kept on file as reference
# for kalama GKI config fragments and DTB layout only, and only for
# a possible future second-slot ROM kernel — never for this recovery
# image and never flashed to the OOS slot.
# TARGET_KERNEL_SOURCE is therefore intentionally NOT set here: a
# recovery-only build must not resolve, download, or compile a kernel
# tree. Any build that demands one has misconfigured the target.
BOARD_BOOTCONFIG := \
    androidboot.hardware=qcom \
    androidboot.memcg=1 \
    androidboot.usbcontroller=a600000.dwc3
BOARD_KERNEL_CMDLINE := \
    nosoftlockup
BOARD_USES_GENERIC_KERNEL_IMAGE := true
BOARD_KERNEL_BASE := 0x00000000
BOARD_KERNEL_PAGESIZE := 4096
BOARD_KERNEL_IMAGE_NAME := Image
# Reference config fragments (OnePlusOSS, documentation only):
#   gki_defconfig + vendor/kalama_GKI.config
#   + vendor/oplus/kalama_GKI.config + vendor/debugfs.config
#   with CONFIG_ARCH_KALAMA=y and CONFIG_OPLUS_DEVICE_DTBS=y.

# Platform
BOARD_USES_QCOM_HARDWARE := true
TARGET_BOARD_PLATFORM := kalama

# Metadata
BOARD_USES_METADATA_PARTITION := true

# Partitions — ground truth, cross-checked three ways:
#   (1) CPH2447_16.0.5.1301 payload manifest (47 partitions),
#   (2) live super metadata parsed from the user's phone,
#   (3) live GPT parse (6 LUNs, 138 entries, CRCs verified).
# Any mismatch against (1) or (2) is a build-blocking error, never
# something to adjust silently. See PARTITION-LAYOUT.md.
BOARD_BOOTIMAGE_PARTITION_SIZE := 201326592
BOARD_DTBOIMG_PARTITION_SIZE := 25165824
BOARD_INIT_BOOT_IMAGE_PARTITION_SIZE := 8388608
BOARD_USERDATAIMAGE_PARTITION_SIZE := 233871900672
BOARD_VENDOR_BOOTIMAGE_PARTITION_SIZE := 201326592
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 104857600
BOARD_ODMIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_PRODUCTIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_SYSTEM_EXTIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_SYSTEMIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_SYSTEM_DLKMIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_VENDOR_DLKMIMAGE_FILE_SYSTEM_TYPE := erofs
# NOTE on filesystem types: the values above follow the Lineage
# reference. The stock recovery fstab carries DUAL ext4+erofs rows
# for every logical partition, so mount behavior in recovery does
# not depend on any single value here. The exact live filesystem
# type per logical partition is NOT derivable from super metadata
# alone and is a Phase 0 check (mount + statfs in recovery).
#
# Dynamic partitions. The group name is the LIVE name from the
# user's super metadata: qti_dynamic_partitions_a. The Lineage
# reference uses oneplus_dynamic_partitions; that name does NOT
# appear on the live device and must never be used for a real
# super build. The list below is the FULL live list (17 entries,
# in live parse order), NOT the Lineage 7: the ten my_* logical
# partitions are OnePlus OOS partitions and are required for a
# complete OOS slot. Omitting them is forbidden by design.
BOARD_ONEPLUS_DYNAMIC_PARTITIONS_PARTITION_LIST := \
    system \
    system_ext \
    vendor \
    product \
    my_product \
    odm \
    my_engineering \
    vendor_dlkm \
    system_dlkm \
    my_stock \
    my_heytap \
    my_carrier \
    my_region \
    my_company \
    my_preload \
    my_bigball \
    my_manifest
BOARD_ONEPLUS_DYNAMIC_PARTITIONS_SIZE := 16936005632
BOARD_SUPER_PARTITION_GROUPS := qti_dynamic_partitions_a
BOARD_SUPER_PARTITION_SIZE := 16940199936
BOARD_FLASH_BLOCK_SIZE := 262144 # (BOARD_KERNEL_PAGESIZE * 64)
TARGET_COPY_OUT_ODM := odm
TARGET_COPY_OUT_PRODUCT := product
TARGET_COPY_OUT_SYSTEM_DLKM := system_dlkm
TARGET_COPY_OUT_SYSTEM_EXT := system_ext
TARGET_COPY_OUT_VENDOR := vendor
TARGET_COPY_OUT_VENDOR_DLKM := vendor_dlkm

# Recovery
# Ramdisk-only: the recovery image carries NO kernel and runs on
# the active slot's boot kernel (shipped stock 5.15.197 on the stock
# slot). This is the same arrangement as the shipped OrangeFox V11
# build (FOX_USE_TWRP_RECOVERY_IMAGE_BUILDER=1) and as stock
# recovery itself (stock recovery.img has kernel_size 0).
BOARD_EXCLUDE_KERNEL_FROM_RECOVERY_IMAGE := true
TARGET_RECOVERY_FSTAB := $(COMMON_PATH)/init/fstab.default
TARGET_RECOVERY_PIXEL_FORMAT := RGBX_8888
TARGET_USERIMAGES_USE_EXT4 := true
TARGET_USERIMAGES_USE_F2FS := true
# fastbootd: the only supported path for writing individual logical
# partitions inside super. The shipped V11 ramdisk contains
# fastbootd; this flag keeps it in the rebuilt recovery.
TW_INCLUDE_FASTBOOTD := true

# Security patch (stock firmware SPL, 2026-09-01)
BOOT_SECURITY_PATCH := 2026-09-01
VENDOR_SECURITY_PATCH := $(BOOT_SECURITY_PATCH)

# Verified Boot — READ CAREFULLY.
# This tree builds recovery ONLY. It never generates, signs, or
# flashes any vbmeta image, so it sets NO BOARD_AVB_*_KEY_PATH and
# NO BOARD_AVB_*_ALGORITHM anywhere. In particular it never uses
# Lineage's external/avb/test/data/testkey_rsa4096.pem or any other
# test key: a test-signed vbmeta must never be applied to the OOS
# slot. The OOS slot keeps its STOCK vbmeta, always.
# Stock vbmeta chain (partitions present in the manifest):
#   vbmeta (12,288 B), vbmeta_system (8,192 B),
#   vbmeta_vendor (4,096 B).
# Chain membership (which partitions each vbmeta covers) follows the
# standard Android layout and the Lineage reference (vbmeta_system:
# system, system_dlkm, system_ext, product; vbmeta_vendor: odm,
# vendor, vendor_dlkm). That membership is NOT confirmed by the
# stock recovery fstab (which carries no avb flags on logical rows)
# and is therefore marked UNVERIFIED until Phase 0 (vbmeta dump on
# device). It does not affect the recovery build, which signs
# nothing.
# The vbmeta step for a MODIFIED slot is a MANUAL bootloader-fastboot
# step, never a recovery step and never baked into this tree:
# flash the stock vbmeta with --disable-verity
# --disable-verification BEFORE first booting the modified slot,
# or dm-verity will kill it at first-stage mount. The dual-boot
# flow must warn visibly when this step is skipped.
BOARD_AVB_ENABLE := false
