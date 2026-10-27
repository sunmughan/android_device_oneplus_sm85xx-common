#
# device-common.mk — the operative product file for this common tree.
#
# device/oneplus/salami/device-salami.mk inherits
# $(COMMON_PATH)/device-common.mk (TWRP-tree convention). This file
# is therefore what the OrangeFox build actually includes from the
# common tree. It is intentionally RECOVERY-ONLY and minimal:
#
# Included (recovery needs these):
#   - fastbootd: the only supported path for writing individual
#     logical partitions inside super (with TW_INCLUDE_FASTBOOTD in
#     BoardConfigCommon.mk). Without it, the snapshot engine has no
#     logical-partition write path.
#   - android.hardware.boot-service.qti.recovery: the boot HAL
#     service recovery uses for slot control (bootctl).
#   - android.hardware.health-service.qti_recovery: battery/health
#     reporting inside recovery.
#
# Deliberately EXCLUDED (ROM-only, would bloat or break a recovery
# build, and several would drag in vendor blobs this tree refuses):
#   - Audio/display/camera/sensor HALs and overlays.
#   - Lineage health-service default and any vendor.* packages.
#   - Properties files (odm.prop/product.prop/system_ext.prop/
#     vendor.prop) — ROM properties, not recovery properties.
#   - SEPolicy includes — recovery uses its own policy.
#   - Vendor BoardConfig include — there is no vendor tree here.
#     Any build that demands vendor/oneplus/sm8550-common/
#     BoardConfigVendor.mk is misconfigured for this tree.
#
# Keymaster/decryption note: recovery decryption on this device
# uses keymaster 4.1 (OF_DEFAULT_KEYMASTER_VERSION=4.1, set in
# device/oneplus/salami/vendorsetup.sh, preserved verbatim) with
# FBE metadata-mount-ignore (OF_FBE_METADATA_MOUNT_IGNORE=1).
# The keymaster HAL itself runs from the device's vendor image at
# runtime; no keymaster blob is built or shipped by this tree.
#

PRODUCT_PACKAGES += \
    fastbootd \
    android.hardware.boot-service.qti.recovery \
    android.hardware.health-service.qti_recovery
