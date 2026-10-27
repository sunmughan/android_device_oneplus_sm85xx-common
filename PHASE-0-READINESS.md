# Phase 0 readiness report — plain R12.0 rebuild before any dual-boot code

Phase 0 has exactly one job: prove that a recovery built from
(`ofox_salami` + this authored common tree) behaves identically to
the shipped OrangeFox V11 build. NO dual-boot code is written,
added, or tested in Phase 0. If Phase 0 fails, no dual-boot work
starts; the tree, the branch, or the host is fixed first.

## Public repo (this tree's home)

Proposed (and, per the user's order, actual push target):
**`sunmughan/android_device_oneplus_sm85xx-common`**, PUBLIC.
Public satisfies two requirements at once: OrangeFox GPLv3 (patched
OrangeFox/device-tree code released publicly must have its source
public) and free unlimited GitHub Actions minutes for public repos
(the user's build-host decision, since his PC is damaged).
This repo holds ONLY this common tree's contents at its root.
The `ofox_salami` fork is a separate later step and is NOT part of
this repo.

## CI workflow to use next (Action-OFRP-Builder pattern)

Community GitHub Actions builder for OrangeFox (Action-OFRP-Builder
pattern — the workflow itself is community-maintained, not part of
the OrangeFox wiki; verify its inputs against its own README before
first use). Inputs:

- `SYNC_URL`: OrangeFox GitLab manifest
  (`https://gitlab.com/OrangeFox/sync.git` pattern; confirm the
  exact sync URL from the builder workflow's docs at setup time).
- `MANIFEST_BRANCH`: `12.1` — pinned from the V11 build vars
  (`FOX_MANIFEST_VER="12.1"`, release line R12.0). Validate, don't
  assume: if the 12.1 build fails to decrypt OOS 16 data, the
  branch decision reopens (14.1 is the only documented alternative,
  and only if the device requires a 14.x build system).
- `DEVICE_TREE_URL`: the public fork of `ofox_salami`
  (separate later step; must carry `twrp.dependencies` pointing at
  this common tree repo, remote `sunmughan`, branch `main`).
- `DEVICE_PATH`: `device/oneplus/salami`.
- `MAKEFILE_NAME`: `ofox_salami`.
- `BUILD_TARGET`: `recoveryimage`.
- No secrets are needed for a recovery-only build (no signing keys:
  the recovery image is unsigned ramdisk-only output, and the
  vbmeta disable step stays a manual bootloader-fastboot step).
- Runner disk: OrangeFox sync needs ~45 GB (12.1) plus ccache; the
  builder workflow's disk-management steps must be verified to
  survive a full sync before CI is treated as solved.

Local layout for the build (user's suggested layout, already in
place on the authoring machine):
`~/fox_12.1/device/oneplus/salami` (ofox clone) beside
`~/fox_12.1/device/oneplus/sm85xx-common` (this tree).

## Phase 0 validation checklist (all must pass)

1. The CI build completes and produces `recovery.img`.
2. The image fits the recovery partition: size ≤ 104,857,600 B.
3. The image boots on the phone (flashed to the INACTIVE slot's
   recovery partition first; known-good slot untouched).
4. Variant detection reports CPH2447 (India) — the variant-script
   region mapping (region 21 + 22861 → OP594DL1 / CPH2447)
   preserved verbatim from the salami tree.
5. OOS 16 `/data` decrypts in the rebuilt recovery (keymaster 4.1,
   FBE metadata-mount-ignore). A logo hang here is a keymaster /
   branch problem, not a dual-boot problem: fix the tree/branch
   first.
6. fastbootd enters from the recovery Reboot page and is visible
   to a proper host (fastboot `getvar is-userspace` = yes).
7. Backup/restore of super works from the rebuilt recovery.
8. `TW_INCLUDE_FASTBOOTD` is effective (fastbootd binary present
   in the rebuilt ramdisk; check the ramdisk listing, don't assume).
9. Flag check: the rebuilt ramdisk's effective flags match the V11
   set (see FLAG-DIFF.md); every difference has a reason.

## Unverified items → which Phase 0 test settles each

| Unverified item | Settling test |
|---|---|
| vbmeta chain membership (vbmeta_system / vbmeta_vendor coverage) | vbmeta dump on device (avbctl / vbmeta parse) during Phase 0 |
| Live filesystem type per logical partition (erofs vs ext4) | Mount + statfs in the Phase 0 recovery |
| system_dlkm / vendor_dlkm mount rows (stock fstab omits them) | Mounting both in the Phase 0 recovery |
| Manifest branch 12.1 vs 14.1 for OOS 16 | Phase 0 decryption test (checklist item 5) |
| OOS 16 /data decryption under the rebuilt recovery | Phase 0 decryption test (checklist item 5) |
| Recovery image size headroom for dual-boot additions | Checklist item 2 measurement (plain size vs 104,857,600 B ceiling) |

## What comes after Phase 0 (for orientation only, not this task)

- Phase 1: read-only dual-boot scaffolding (UI pages, registry,
  lpdump display; all writes refused).
- Phase 2: snapshot engine on the inactive slot only (create /
  restore / hash proof / corruption refusal; data strategy decided
  here, including the my_* no-exception rule in SNAPSHOT-DESIGN.md).
- Phase 3: full verified switch flow (snapshot, verify, space
  check, restore, verify, set_active, reboot; abort proofs).
- Phase 4: post-ROM-flash re-application, hardening, publication.
  "Done" means snapshot-restore-on-switch unless measurement proves
  both ROMs fit in super; it never means "both ROMs permanently
  side by side" without that measurement.

## Failsafe (every phase, including Phase 0)

Test on the inactive slot first. Keep the known-good slot untouched.
Abort on first failure. Never leave both slots broken. Stock
restore path (stock images via fastboot/fastbootd, plus stock
recovery to the active slot's recovery partition) verified working
before the first test of each phase.
