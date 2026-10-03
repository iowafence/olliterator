# OLLITERATOR v0.2 Rev B — Physical Prosecution Pass

## Result

**PHYSICAL PASS**

OLLITERATOR v0.2 Rev B completed the destructive authorization,
provisioning wipe, installer handoff, unattended installation, and
subsequent boot on physical hardware.

## Hardware

- Manufacturer: Microsoft Corporation
- Product: Surface Go 2
- Storage: 64 GB eMMC
- Target device name: `mmcblk0`
- Expected target size: `62537072640` bytes
- Expected removable state: `0`
- Architecture: x86-64

Unique device identifiers are intentionally omitted from this public
record.

## Rev B Correction

Rev A correctly authenticated the target but tested the logical name
`mmcblk0` as though it were a device path.

Rev B constructs:

`TARGET_DEV="/dev/$SECOND_TARGET"`

It then verifies that target is still a block device before invoking the
destructive primitive.

## Physical Execution

The provision hook activated.

Authentication #1 passed and identified exactly one permitted target:

- target: `mmcblk0`
- bytes: `62537072640`

Authentication #2 performed a fresh hardware read and passed with the
same target and exact byte count.

The two authentication results agreed.

The final block-device check passed.

The destructive primitive was present and executable.

Destructive authorization passed.

## Destructive Primitive

The primitive was invoked against `/dev/mmcblk0` with expected size
`62537072640`.

Physical execution reported:

- front-region write: PASS
- tail-region write: PASS
- synchronization: PASS
- primitive completion: PASS

OLLITERATOR then reported the provisioning wipe complete.

Only after successful destructive completion was installer handoff
authorized.
## Installer Handoff

After OLLITERATOR authorized handoff, execution continued into the
Ubuntu unattended installation path.

The installer proceeded directly into installation without requiring
the normal installation questionnaire.

The installation reached its completion state.

A user action was required to select the installer's final restart
control.

That downstream restart behavior is not part of OLLITERATOR's
destructive authorization decision.

## Installed-System Verification

After restart:

- the machine booted the installed Ubuntu system;
- the installed login was usable;
- the internal eMMC contained the installed system;
- the OLLITERATOR USB remained a separate storage device;
- the USB was removed;
- the installed system remained operational; and
- a subsequent reboot with the USB disconnected succeeded.

This established that the resulting installed system could boot
independently of the provisioning media.

## Artifact Identity

The physically prosecuted Rev B components include:

- `runtime/olliterator-common.sh`
  - SHA-256: `7bd74492f1c5368188e67e86ae000d44205666add3bf359e181e69cde58421a3`
- `runtime/provision-stage.sh`
  - SHA-256: `f438de9dd44dfd4470a48e6bb5c9f2a26ed7841e672999b88690b33b2b7f8f21`
- `runtime/hooks/02olliterator-provision`
  - SHA-256: `4001861e58569308538867bd39723f3e57fea373a8981f16d8eaa587ee3c0096`
- `src/olli-wipe.c`
  - SHA-256: `26ee3ed5b7c2950901de656a5b199f114060d94e80810caf367aa1a6684e9741`
- production `olli-wipe`
  - SHA-256: `9460edea30e00b037d48cd39ebd38e0f9f88f33f18bf001d0ad373bd78adfafe`
- Rev B initrd
  - SHA-256: `6fb41117a2c550f8af4a83bfae70fa849489d8ccf3ebda171e0a16c13cf0292a`
- Rev B final ISO
  - SHA-256: `f609cb7898ab1d2f827c4aea83d03cc3a2c3df536431901088c01d6117038f95`

The private prosecuted hardware profile had SHA-256:

`d16eb4afeafed44712214a4bb3a31466439b461605213cb08b351522634a75e1`

The public profile is a sanitized derivative. Its authorization-relevant
hardware and storage values are preserved, but an observational device
serial has been redacted. It therefore has a different SHA-256 and must
not be represented as byte-identical to the prosecuted profile.

## Scope Limitation

This prosecution does not establish every possible starting-disk state.

The physical Surface Go 2 used for Rev B had already undergone an
earlier OLLITERATOR wipe before this Rev B prosecution.

Therefore this result establishes the Rev B authorization, destructive
execution, containment, installer handoff, installation, and independent
post-install boot chain on physical hardware.

It does **not** independently establish one-boot wipe-to-install behavior
from every arbitrary populated preexisting partition layout.

That case requires separate prosecution.

## Status

- OLLITERATOR v0.2 Rev B: PHYSICAL PASS
- Hardware: Surface Go 2 / 64 GB eMMC
- Dual authentication: PASS
- Destructive primitive: PASS
- Installer handoff: PASS
- Installation: PASS
- Independent post-install boot: PASS
- Arbitrary populated starting layout: NOT YET ESTABLISHED
