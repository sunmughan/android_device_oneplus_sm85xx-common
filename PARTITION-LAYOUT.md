# Partition layout — OnePlus 11 (salami, CPH2447, OOS 16)

Ground truth for this tree, cross-checked three ways:
(1) stock firmware CPH2447_16.0.5.1301 payload manifest (47 partitions),
(2) live super metadata parsed from the user's phone,
(3) live GPT parse (6 UFS LUNs, 138 entries, header + entry CRCs verified).
A size that disagrees with (1) or (2) is a build-blocking error, never
something to adjust silently.

## Super and dynamic partitions (live truth)

- Super partition (GPT `super`, sda6): **16,940,199,936 B** exactly.
- Live dynamic group: **`qti_dynamic_partitions_a`**,
  max **16,936,005,632 B** (= super minus 4 MiB).
  The Lineage reference name `oneplus_dynamic_partitions` does NOT
  appear on the live device and must never be used for a real build.
- Live logical partitions (slot A, from `lpdump_real_only.json`):
  all `readonly`, all in `qti_dynamic_partitions_a`.

| Logical partition (slot A) | Size (bytes) | Manifest match |
|---|---|---|
| system_a | 925,081,600 | exact |
| system_ext_a | 934,920,192 | exact |
| vendor_a | 710,836,224 | exact |
| product_a | 9,383,936 | exact |
| my_product_a | 2,897,543,168 | exact |
| odm_a | 1,511,489,536 | exact |
| my_engineering_a | 335,872 | exact |
| vendor_dlkm_a | 173,043,712 | exact |
| system_dlkm_a | 425,984 | exact |
| my_stock_a | 3,079,491,584 | exact |
| my_heytap_a | 335,872 | exact |
| my_carrier_a | 335,872 | exact |
| my_region_a | 3,166,208 | exact |
| my_company_a | 335,872 | live-only (no firmware image) |
| my_preload_a | 2,494,464 | live-only (no firmware image) |
| my_bigball_a | 335,872 | exact |
| my_manifest_a | 516,096 | exact |

Live total (17 partitions): **10,250,072,064 B** (~10.25 GB).
Group headroom: 16,936,005,632 − 10,250,072,064 =
**6,685,933,568 B** (~6.69 GB) free in the group on slot A.

## my_* partitions — full list, no exceptions

Every OnePlus `my_*` logical partition is listed here with its exact
live size. There is no "Lineage doesn't ship them" exemption: a
restored OOS slot without its my_* content is a broken OOS slot
(missing OOS apps, region content, and HeyTap content).

| my_* partition | Size (bytes) | Source |
|---|---|---|
| my_product | 2,897,543,168 | firmware manifest |
| my_stock | 3,079,491,584 | firmware manifest |
| my_region | 3,166,208 | firmware manifest |
| my_heytap | 335,872 | firmware manifest |
| my_bigball | 335,872 | firmware manifest |
| my_carrier | 335,872 | firmware manifest |
| my_engineering | 335,872 | firmware manifest |
| my_manifest | 516,096 | firmware manifest |
| my_company | 335,872 | live device only |
| my_preload | 2,494,464 | live device only |

my_* subtotal per slot: **5,984,890,880 B** (~5.98 GB, ≈ 6 GB).
A per-slot snapshot that includes my_* therefore needs ≈ 6 GB for
my_* alone, on top of the system-side partitions. Snapshots live on
SSD Vault storage, never in a git repo (GitHub's 2 GB per-file cap
makes repo storage impossible for my_product / my_stock alone).

fstab mount behavior (stock recovery fstab, verified): every my_*
partition mounts at `/<name>` as a logical, slotselect,
first_stage_mount partition with dual ext4+erofs rows. `nofail` is
set on my_company, my_carrier, my_region, my_bigball, my_heytap,
my_stock, my_preload, my_manifest — and NOT on my_product and
my_engineering (stock treats those two as required). No my_* row
carries an avb flag in stock recovery fstab (see `init/fstab.default`
header for why the authored fstab follows that pattern).

Live-only notes: my_company and my_preload exist only on the device
(OOS-created). They have no firmware image, so a snapshot engine
must capture them from the live mapped nodes
(`/dev/block/mapper/my_company_a`, `/dev/block/mapper/my_preload_a`)
before any restore can reproduce them. A restore that cannot
reproduce them must refuse (see SNAPSHOT-DESIGN.md).

## Fixed (GPT) partitions — stock firmware manifest (47 total)

Slot-suffixed (`_a`/`_b` in GPT) for the 15 A/B OTA partitions:
boot, dtbo, init_boot, odm, product, recovery, system, system_dlkm,
system_ext, vbmeta, vbmeta_system, vbmeta_vendor, vendor, vendor_boot,
vendor_dlkm. (odm/product/system/system_dlkm/system_ext/vendor/
vendor_dlkm are logical, inside super; the rest are GPT partitions.)
Other GPT entries are slot-suffixed where the live GPT says so
(e.g. abl_a/abl_b, xbl_a/xbl_b, modem_a/modem_b, dsp_a/dsp_b); the
full 138-entry GPT table lives in the live GPT parse, not here.

| Manifest partition | Size (bytes) | Manifest partition | Size (bytes) |
|---|---|---|---|
| system | 925,081,600 | shrm | 65,536 |
| system_ext | 934,920,192 | splash | 331,776 |
| product | 9,383,936 | tz | 3,973,120 |
| vbmeta_system | 8,192 | uefi | 3,153,920 |
| init_boot | 8,388,608 | uefisecapp | 180,224 |
| xbl_ramdump | 872,448 | vbmeta | 12,288 |
| abl | 270,336 | vbmeta_vendor | 4,096 |
| aop | 282,624 | vendor_boot | 201,326,592 |
| aop_config | 16,384 | xbl | 1,208,320 |
| bluetooth | 1,224,704 | xbl_config | 192,512 |
| boot | 201,326,592 | vendor | 710,836,224 |
| cpucp | 192,512 | vendor_dlkm | 173,043,712 |
| devcfg | 57,344 | odm | 1,511,489,536 |
| dsp | 67,108,864 | system_dlkm | 425,984 |
| dtbo | 25,165,824 | my_product | 2,897,543,168 |
| engineering_cdt | 1,048,576 | my_engineering | 335,872 |
| featenabler | 98,304 | my_stock | 3,079,491,584 |
| hyp | 1,654,784 | my_carrier | 335,872 |
| imagefv | 77,824 | my_region | 3,166,208 |
| keymaster | 413,696 | my_bigball | 335,872 |
| modem | 310,325,248 | my_heytap | 335,872 |
| oplus_sec | 851,968 | my_manifest | 516,096 |
| oplusstanvbk | 2,236,416 | recovery | 104,857,600 |
| qupfw | 57,344 | | |

Recovery partition ceiling: **104,857,600 B**. Any recovery image
(including dual-boot additions) must fit inside it. The Phase 0
plain rebuild is measured against this ceiling before any feature
work is added.

## UFS LUN map (live GPT parse, CRC-verified)

sda = LUN 0, sdb = LUN 1, sdc = LUN 2, sdd = LUN 3, sde = LUN 4,
sdf = LUN 5. 4096-byte sectors throughout. Main firmware partitions
live on sde; sda holds super (sda6), userdata (sda14), persist,
misc, metadata, vbmeta_system/vendor; sdb/sdc hold xbl_a/xbl_b +
xbl_config; sdf holds modemst1/2, fsg, fsc. Four GPT entries have
no by-name symlink and are filler (`last_parti`): sdc6, sdd8,
sde84, sdf20 — GPT-only entries, no firmware image, not flashable.

## What this tree does NOT claim

- It does not claim the live filesystem type (erofs vs ext4) per
  logical partition; super metadata does not record it.
- It does not claim vbmeta chain membership; stock recovery fstab
  carries no avb flags to confirm it (see README.md unverified list).
- It does not claim slot B is bootable: slot B metadata exists in
  super (32 partitions, different sizes, e.g. system_b
  910,364,672 B vs system_a 925,081,600 B), but metadata presence
  alone does not prove a populated, bootable slot B. That question
  is answered by measurement (Phase 2), never assumed.
