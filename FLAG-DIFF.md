# Flag diff — authored tree vs shipped OrangeFox V11 build vars

Source of truth for V11: `META-INF/debug/fox_build_vars.txt` from
the shipped installer zip
(`OrangeFox-R12.0-Unofficial-salami-V11_1_d5bk.zip`), 38 variables.
Comparison target: `device/oneplus/salami/vendorsetup.sh` (preserved
verbatim) plus this authored common tree's `BoardConfigCommon.mk`.

Method: parse both files mechanically (quoted and unquoted exports
handled; the non-exported `FOX_ENABLE_KERNELSU_SUPPORT=1` line
counted separately). Result: **zero value mismatches** on every
variable present in both files.

## Variables only in the V11 build-vars file (8)

These are DERIVED BY THE BUILD SYSTEM, not set by any tree file.
No action; they will be regenerated identically by a rebuild:

| Variable | V11 value | Origin |
|---|---|---|
| FOX_BUILD_DEBUG_MESSAGES | 0 | build system default |
| FOX_BUILD_TYPE | Unofficial | build system (unofficial build) |
| FOX_DELETE_INITD_ADDON | 1 | build system default |
| FOX_DEVICE | salami | derived from device path |
| FOX_INTERNAL_RELEASE | R12.0 | OrangeFox release line |
| FOX_MANIFEST_VER | 12.1 | manifest branch (pins Phase 0 to 12.1) |
| FOX_OUT_NAME | OrangeFox-R12.0-Unofficial-salami | derived output name |
| FOX_VARIANT | default | build system default |

## Variables only in vendorsetup.sh (7)

These are build-environment / identity variables that the V11
build-vars dump does not record. They are preserved verbatim in
the salami tree and are NOT discrepancies:

| Variable | Value | Note |
|---|---|---|
| ALLOW_MISSING_DEPENDENCIES | true | build env |
| BUILD_HOSTNAME | android-build | build env identity |
| BUILD_USERNAME | nobody | build env identity |
| FOX_BUILD_DEVICE | OnePlus11 | device alias |
| OF_MAINTAINER | Wishmasterflo | maintainer identity |
| TARGET_ARCH | arm64-v8a | arch string (verbatim from V11 tree) |
| TARGET_DEVICE_ALT | salami, Salami, OnePlus11, OnePlus 11, OP591BL1, OP594DL1 | device aliases incl. variant IDs |

## Value mismatches: NONE

Every variable present in both files has the identical value,
including the load-bearing ones: `FOX_USE_TWRP_RECOVERY_IMAGE_BUILDER=1`,
`OF_AB_DEVICE_WITH_RECOVERY_PARTITION=1`,
`FOX_VIRTUAL_AB_DEVICE=1`, `OF_DEFAULT_KEYMASTER_VERSION=4.1`,
`OF_FBE_METADATA_MOUNT_IGNORE=1`, `OF_QUICK_BACKUP_LIST=
"/boot;/data;/super;"`, `OF_SUPPORT_ALL_PAYLOAD_OTA_UPDATES=1`,
`OF_SUPPORT_ALL_BLOCK_OTA_UPDATES=0`, all screen geometry values
(2400/120/48/48/0), and all tool binaries (zip/tar/busybox/bash/
nano) plus `OF_USE_MAGISKBOOT=1` /
`OF_USE_MAGISKBOOT_FOR_ALL_PATCHES=1`.

## Known quirk, preserved as-is (not a diff to fix)

`FOX_ENABLE_KERNELSU_SUPPORT=1` in `vendorsetup.sh` is NOT
exported (bare assignment, no `export` keyword), so it is not in
the V11 build-vars dump either. Whether that line is what enables
the KernelSU addon in the V11 build is unverified and irrelevant
to dual boot; the line is left exactly as the V11 tree has it.
This tree does not touch it.

## What this common tree ADDS beyond V11's recorded flags

These are common-tree (BoardConfig) decisions, not vendorsetup
variables, so they do not appear in the V11 vars file at all.
Each has a reason documented in `BoardConfigCommon.mk`:

1. `TW_INCLUDE_FASTBOOTD := true` — keeps fastbootd in the
   rebuilt ramdisk (V11 ramdisk contains fastbootd; the flag makes
   that explicit rather than incidental).
2. Dynamic partition list extended from Lineage's 7 to the full
   live 17 (all ten my_* partitions included) — required by the
   no-exception my_* rule.
3. `BOARD_SUPER_PARTITION_GROUPS := qti_dynamic_partitions_a` —
   the LIVE group name, replacing Lineage's
   `oneplus_dynamic_partitions`, which does not exist on device.
4. `BOARD_AVB_ENABLE := false` — this tree signs nothing; no test
   keys anywhere. V11 vars record no AVB variables, so this is a
   new explicit policy, not a change to a V11 value.
5. `BOARD_EXCLUDE_KERNEL_FROM_RECOVERY_IMAGE := true` (ramdisk-only,
   same arrangement as V11) and `TARGET_RECOVERY_FSTAB` pointing at
   this tree's authored `init/fstab.default` (stock-pattern fstab,
   see its header).

## What this tree does NOT change

No vendorsetup.sh variable, no salami BoardConfig.mk flag
(TW_FRAMERATE 120, TW_MAX_BRIGHTNESS 550, AIDL haptics), no
variant-script mapping, no vibrator overlay file, and no
`PRODUCT_MODEL` / `PRODUCT_SYSTEM_DEVICE` value was altered. The
only salami-tree file changed is `twrp.dependencies`, whose
dependency pointer now targets this authored common tree
(remote `sunmughan`, branch `main`) instead of the nonexistent
TeamWin remote — that change lives in the local salami clone and
is part of the separate ofox-fork step, not of this common-tree
repo.
