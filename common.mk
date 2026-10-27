#
# common.mk — compatibility wrapper.
#
# In LineageOS trees the ROM device makefile inherits
# $(COMMON_PATH)/common.mk. In this recovery-only tree the operative
# file is device-common.mk (inherited by
# device/oneplus/salami/device-salami.mk, TWRP-tree convention).
# This file exists so that either include path resolves to the same
# recovery-only package set, and so that a reader coming from the
# Lineage reference can see where the ROM content went: nowhere —
# it was deliberately left out (see device-common.mk).
#
$(call inherit-product, $(COMMON_PATH)/device-common.mk)
