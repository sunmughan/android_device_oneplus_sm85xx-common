# Dual-boot snapshot engine — design note

This note defines the snapshot engine that the dual-boot recovery
will implement in Phase 2 (after the Phase 0 plain recovery is
validated). It is a DESIGN note, not code: no snapshot code ships
in Phase 0, and Phase 0 must not flash any my_* partition.

## The problem the engine solves

FBE-encrypted userdata is a single physical partition shared by both
slots, and super is a single physical partition whose metadata maps
both slots' logical partitions. There is no per-slot userdata split
on this phone (the old OP6 mod's GPT `sgdisk` split cannot apply:
super/logical volumes are not GPT partitions). A second ROM therefore
cannot simply boot on the first ROM's data, and a slot switch is not
an instant flip unless both ROMs already live, fully populated, in
super — which must be MEASURED, never assumed (see the super
question below). The snapshot engine is what makes switching safe
regardless of that measurement's outcome.

## Who flashes my_stock / my_product — honest answer

In NORMAL use (no dual-boot engine involved), exactly two actors
flash my_stock / my_product, and neither is the recovery UI:

1. **Stock OTA (update_engine).** A stock OxygenOS OTA writes the
   inactive slot: it updates that slot's logical partitions,
   including my_product and my_stock, as part of the OTA payload,
   then marks the slot bootable. This is the only routine writer
   of my_* partitions on a stock phone.
2. **fastbootd manual full restore.** A human (or a tool driving
   fastbootd) restoring a full firmware set writes the inactive
   slot's logical partitions through fastbootd, including my_*.
   Bootloader fastboot cannot do this: it must refuse dynamic
   partitions. OrangeFox "Install image" to a dlkm target cannot
   do it either: it writes raw bytes without creating or committing
   logical-partition metadata.

What does NOT flash them: the recovery UI never flashes my_*
partitions individually; custom ROMs (LineageOS and others) do not
ship my_* partitions at all, so a Lineage slot simply has no my_*
content; and the stock recovery never writes them outside an OTA.

In the DUAL-BOOT design, the flasher is a third actor: **the
snapshot engine, on restore**. When the user switches to a slot
whose snapshot is stored externally, the engine restores that
slot's partitions — including its my_* partitions — through
fastbootd logical flash (the metadata-aware path). The fallback
`dd` to an already-mapped device-mapper node is allowed ONLY when
the image fits the existing mapped node's size exactly; there is
no resize path in the shipped recovery ramdisk (no lpmake/lpadd),
so an image larger than its node is a hard refusal, never a forced
write. Raw `dd` to super itself is forbidden absolutely: super
metadata is shared by both slots, and corrupting it breaks both
slots at once.

## What a snapshot contains (no exceptions)

A per-slot snapshot is the complete slot, not a subset:

- Boot chain (physical GPT partitions): boot, vendor_boot,
  init_boot, dtbo, vbmeta (stock vbmeta for that slot, with its
  disable flags recorded, never re-signed).
- All 17 live logical partitions of that slot, INCLUDING all ten
  my_* partitions (my_product, my_stock, my_region, my_heytap,
  my_bigball, my_carrier, my_engineering, my_manifest, my_company,
  my_preload) with exact live sizes (see PARTITION-LAYOUT.md).
- The slot's build fingerprint (build.prop values read read-only
  from that slot's system partition, or "Unknown" if unreadable —
  never guessed).
- Per-partition SHA-256 hashes, taken at snapshot time and stored
  in the snapshot registry.

Phase 0 plain recovery does NOT need to flash my_* partitions and
must not try. my_* handling lands in the Phase 2 snapshot engine.
That sequencing is deliberate: the recovery must first prove it
boots, decrypts, and mounts before it is trusted to move 6 GB of
OOS content.

## Registry

One registry entry per snapshot, stored alongside the snapshots
(never inside the repo): slot, build fingerprint, per-partition
size + SHA-256, timestamps, free-space accounting, and the source
slot the snapshot was taken from. The registry is the ONLY source
for per-slot build display when the inactive slot's logical
partitions are not mapped (Virtual A/B: inactive logical nodes
typically do not exist until mounted). Display reads the registry;
if a slot has no registry entry, display shows "Unknown", never a
guessed value.

## Switch order (verify-before-set_active — mandatory)

1. Snapshot the CURRENT slot (or verify its existing snapshot is
   current and hash-valid).
2. Verify the TARGET snapshot: every partition present, every hash
   matching the registry. ANY missing image or hash mismatch =
   REFUSE the switch, before anything is written.
3. Check free space: on the snapshot destination and in super,
   before any write begins. Insufficient space = REFUSE.
4. Restore the target snapshot (fastbootd logical flash; dd to a
   mapped node only when the image fits that node).
5. Verify the RESTORED partitions: read back and hash-check every
   restored partition. Any mismatch = ABORT, and restore the
   previous slot's snapshot before any slot switch.
6. ONLY after steps 1–5 pass: `bootctl set-active-boot-slot`,
   then reboot.

Abort on first failure, before the slot switch, so the known-good
slot is never lost. A switch that has already written a partial
target must restore the previous slot before returning control.

## The no-exception my_* rule (user order, hard)

- If ANY my_* image is missing from a snapshot, or fails hash
  verification at switch time, the switch MUST REFUSE.
- Silently skipping a my_* partition is FORBIDDEN BY DESIGN.
  A restored OOS slot without my_product/my_stock/my_region/
  my_heytap content looks broken (missing OOS apps, region
  content, HeyTap content) and must never be presented as a
  successful switch.
- There is no exception for "the recovery boots without my_*":
  recovery booting does not need my_* mounts (recovery needs
  system/vendor/data, not my_*), but a RESTORED SLOT is not a
  recovery boot — it is a full slot, and full means my_* included.
- Phase 0 does not flash my_*; Phase 2 refuses without them.
  Both halves of that sentence are required.

## Storage

- Snapshots live on SSD Vault storage (external storage), never in
  a git repo. GitHub's 2 GB per-file cap makes repo storage
  impossible for my_product (2,897,543,168 B) and my_stock
  (3,079,491,584 B) alone, before any other partition is counted.
- my_* alone is ≈ 6 GB per slot (5,984,890,880 B); a full slot
  snapshot is ~10.25 GB of logical content plus the boot chain.
  The pre-switch space check must account for the FULL snapshot,
  not just my_*.
- Snapshot images are ordinary partition images (the same bytes
  the stock firmware ships, or the same bytes read back from the
  live mapped nodes for live-only my_company/my_preload). They are
  not repo artifacts and must never be committed anywhere.

## Failsafe (applies at every phase)

Test on the inactive slot first. Keep the known-good slot untouched.
Abort on first failure. Never leave both slots broken. The stock
restore path (stock images via fastboot/fastbootd, plus stock
recovery to the active slot's recovery partition if stuck in the
bootloader) must be verified working before each phase's first
test.

## Open questions this design does NOT answer (measurement only)

- Whether super holds two full ROMs side by side (group free space
  vs the second ROM's sizes). Until measured, the design is
  snapshot-restore-on-switch.
- Whether userdata snapshots taken under OOS decrypt under
  LineageOS (FBE cross-ROM compatibility). Until tested, the data
  strategy (snapshot userdata vs fresh data per ROM) is undecided,
  and seamless switching must not be promised.
- Whether the LineageOS installer reworks super groups on this
  phone. Until tested on the inactive slot, no design assumption
  is made about it.
