# android_device_oneplus_sm85xx-common (replacement common tree)

Replacement common tree for the OnePlus 11 (salami, SM8550 / kalama,
CPH2447 India), written for the dual-boot OrangeFox recovery project.

## Why this tree exists

`device/oneplus/salami` (Wishmasterflo `ofox_salami`) is a thin tree:
it declares `COMMON_PATH := device/oneplus/sm85xx-common` and expects
a common tree at that exact path. The original TeamWin tree
(`TeamWin/android_device_oneplus_sm85xx-common`, branch `android-12.1`)
does **not** exist on GitHub (verified: `git ls-remote` +
GitHub API 404, three times). Searching for it is over. This tree is
authored from sources in hand to fill that exact path, so no path
rename is needed anywhere in the salami tree.

## What this tree is, and is not

- It builds **recovery only**. It is not a ROM tree. It contains no
  ROM product definition, no audio/display/camera HALs, no overlays,
  no SEPolicy, no properties files, and no vendor blobs.
- It compiles **no kernel**. The recovery image is ramdisk-only
  (`BOARD_EXCLUDE_KERNEL_FROM_RECOVERY_IMAGE := true`) and runs on
  the active slot's boot kernel. The designated kernel base is the
  **shipped stock kernel 5.15.197** (extracted from the stock boot
  image: `stock-kernel-Image`, 53,189,120 B, vermagic
  `5.15.197-android13-8-o-01214-gbee5b6ef6244`) — not Dragonw1nd
  5.15.211 and not the OnePlusOSS 5.15.180 published source.
- It signs **no vbmeta**. `BOARD_AVB_ENABLE := false` is deliberate:
  this tree never generates or signs vbmeta, and never uses any test
  key. The OOS slot keeps its stock vbmeta, always. See
  `BoardConfigCommon.mk` (Verified Boot section) for the manual
  bootloader-fastboot vbmeta step for modified slots.

## Sources: translated vs copied

| Content | Source | How used |
|---|---|---|
| BoardConfig structure, arch/platform values, fstab flag forms, recovery variables, fastbootd/boot-service package names | LineageOS `android_device_oneplus_sm8550-common`, lineage-23.2 | Structure and flag FORMS only; values re-checked against stock/live truth below |
| Partition sizes, A/B OTA list (15), super size | Stock firmware CPH2447_16.0.5.1301 payload manifest (47 partitions) | Ground truth; any mismatch is a build-blocking error |
| Dynamic group name `qti_dynamic_partitions_a`, live logical sizes, live group max | Live super metadata parsed from the user's own phone (`lpdump_real_only.json`) | Ground truth; overrides the Lineage group name `oneplus_dynamic_partitions`, which does NOT appear on the live device |
| my_* mount rows, nofail pattern, no-AVB-flag pattern on logical rows, /data row | Stock recovery fstab, unpacked from the shipped stock recovery ramdisk | Copied pattern (mount behavior verified on-device); see `init/fstab.default` header |
| OrangeFox flags (ramdisk-only builder, recovery-partition flag, virtual A/B, keymaster 4.1, FBE metadata-mount-ignore, OTA flags, quick backup list) | `device/oneplus/salami/vendorsetup.sh` (preserved verbatim in the salami tree, NOT duplicated here) | Compatibility requirement; this tree must not contradict them |
| Kernel config fragments, DTB layout | OnePlusOSS kernel trio (branch `oneplus/sm8550_b_16.0.0_oneplus_11`) | Reference only; nothing compiled from them for recovery |
| GPT layout (6 LUNs, 138 entries, CRCs verified) | Live GPT dumps parsed from the user's phone (`gpt_parsed.json`) | Cross-check for the layout doc; recovery does not consume GPT directly |

## What was deliberately NOT copied

- Lineage AVB test keys (`external/avb/test/data/testkey_rsa4096.pem`)
  — absent from every file in this tree.
- Lineage product identity (CPH2449) — the phone is CPH2447; the
  variant mapping lives in the salami tree's `variant-script.sh`
  (region 21 + 22861 → OP594DL1 / CPH2447) and is preserved verbatim.
- Lineage vendor blobs and the `vendor/oneplus/sm8550-common/
  BoardConfigVendor.mk` include — there is no vendor tree here.
- Lineage ROM content: audio/display configs, overlays, properties,
  SEPolicy, `extract-files.py` / `setup-makefiles.py` blob tooling.
- The Lineage dynamic-partition list of 7 — replaced by the full
  live list of 17 (see `PARTITION-LAYOUT.md`). The ten my_*
  partitions are not optional.

## Files in this tree

- `BoardConfigCommon.mk` — platform, arch, partitions, recovery,
  security patch, verified-boot policy.
- `device-common.mk` — the operative product file (inherited by
  salami's `device-salami.mk`); recovery-only package set.
- `common.mk` — compatibility wrapper (includes `device-common.mk`).
- `init/fstab.default` — recovery fstab (see its header for the
  three deliberate deviations from Lineage, each with a reason).
- `PARTITION-LAYOUT.md` — full layout documentation with exact sizes.
- `SNAPSHOT-DESIGN.md` — dual-boot snapshot engine design note,
  including the no-exception my_* rules and who flashes my_*
  partitions in normal use vs in the dual-boot design.
- `PHASE-0-READINESS.md` — CI workflow, validation checklist,
  unverified items and which Phase 0 test settles each.
- `FLAG-DIFF.md` — flag-by-flag diff vs the shipped V11 build vars.

## Unverified items (honest list — Phase 0 settles each)

1. vbmeta chain membership (which partitions vbmeta_system /
   vbmeta_vendor cover). Stock recovery fstab carries no avb flags,
   so it cannot confirm this. Settled by: vbmeta dump on device
   during Phase 0. Does not block the recovery build (it signs
   nothing).
2. Exact live filesystem type per logical partition (erofs vs ext4).
   Super metadata does not record it; the fstab carries dual rows
   so mounts do not depend on it. Settled by: mount + statfs in
   the Phase 0 recovery.
3. system_dlkm / vendor_dlkm mount rows: kept from Lineage although
   the stock recovery fstab omits them. Settled by: mounting both
   in the Phase 0 recovery.
4. The 12.1 vs 14.1 OrangeFox manifest branch for OOS 16. The V11
   build vars say manifest 12.1; the fork pins 12.1 first and
   validates by booting. Settled by: Phase 0 decryption test.
5. Whether the rebuilt recovery decrypts OOS 16 /data. Nothing in
   any tree proves this; only a boot test does. Settled by:
   Phase 0 decryption test on the OOS slot.
6. Super group free space for two ROMs side by side. Live metadata
   gives group max and current usage, but whether a second ROM fits
   depends on that ROM's sizes. Settled by: `lpdump` + the second
   ROM's manifest in Phase 2, not Phase 0. Until then the design
   is snapshot-restore-on-switch, not assumed side-by-side.

## License

Apache-2.0, following the LineageOS reference tree's license for the
translated structure. The OnePlus/Qualcomm platform facts (partition
sizes, group names, fstab patterns) are device facts, not creative
expression. If this tree is published with patched OrangeFox code,
the OrangeFox GPLv3 obligations for the combined work apply to the
fork as a whole (see PHASE-0-READINESS.md).
