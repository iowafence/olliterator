# OLLITERATOR v0.2 Rev A — Physical Prosecution Failure

## Result

**FAIL — FAIL-CLOSED**

Rev A did not complete destructive provisioning.

The failure occurred before destructive execution and the containment
boundary prevented the Ubuntu installer from starting.

No PHYSICAL PASS was assigned to Rev A.

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

## Test Objective

Exercise the OLLITERATOR v0.2 auto-provision path on physical hardware:

1. activate the provision boot path;
2. authenticate the hardware and target;
3. re-authenticate from fresh hardware state;
4. authorize destructive execution only if both observations agree;
5. execute the destructive primitive;
6. authorize installer handoff only after successful destructive completion.

## Observed Execution

The provision hook activated.

Authentication #1 succeeded.

Authentication #2 succeeded.

Both authentication stages identified `mmcblk0` at exactly
`62537072640` bytes.

The stage then refused:

`REFUSED: TARGET IS NO LONGER A BLOCK DEVICE`

The destructive primitive did not begin.

The Ubuntu installer did not start.

The outer provision hook entered its permanent failure-containment state.
## Root Cause

`olli_auth_all` returns the logical device name `mmcblk0`.

Rev A subsequently tested that value directly as a block-device path.
The required device path was `/dev/mmcblk0`.

The authorization result was correct. The path presented to the final
block-device check was not.

## Safety Result

This failure provided physical evidence for the containment behavior.

The system:

- did not reinterpret the failed check;
- did not select another storage device;
- did not begin the wipe;
- did not continue into the installer; and
- remained in the failure state.

The failure was therefore operationally unsuccessful but fail-closed.

## Correction

Rev B explicitly constructs `/dev/$SECOND_TARGET`, verifies that path is
still a block device, and passes that device path to the destructive
primitive.

Rev B was subjected to a new physical prosecution rather than inheriting
a pass from Rev A.

## Status

- Rev A: PHYSICAL PROSECUTION FAIL
- Fail-closed containment: OBSERVED
- Destructive execution: NOT STARTED
- Installer handoff: NOT AUTHORIZED
