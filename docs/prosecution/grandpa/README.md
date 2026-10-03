# Grandpa — Surface Go 2 Physical Prosecution

This directory contains the public physical prosecution record for the
first OLLITERATOR v0.2 hardware target.

"Grandpa" is a retired Microsoft Surface Go 2 formerly used by an
employee of Iowa Fence Inc.

Grandpa currently runs Ubuntu.

Grandpa has been through enough.

## Hardware

- Manufacturer: Microsoft Corporation
- Product: Surface Go 2
- Architecture: x86-64
- Internal storage: 64 GB eMMC
- Target device: `mmcblk0`
- Exact target size: `62537072640` bytes
- Target removable state: `0`

Unique device identifiers are intentionally omitted from the public
record.

## Results

### Rev A

**PHYSICAL PROSECUTION FAIL — FAIL-CLOSED**

Rev A successfully completed both hardware authentication passes but
presented the logical target name as a block-device path during the
final pre-destruction check.

OLLITERATOR refused execution.

The wipe did not begin.

The Ubuntu installer did not start.

The containment hook remained in its permanent failure state.

See [REV-A-FAIL.md](REV-A-FAIL.md).

### Rev B

**PHYSICAL PASS**

Rev B corrected the target-path construction and was prosecuted again
on physical hardware.

The observed chain was:

1. provision hook activation;
2. authentication #1 PASS;
3. fresh authentication #2 PASS;
4. identical target and exact byte count confirmed;
5. final destructive authorization PASS;
6. front-region wipe PASS;
7. tail-region wipe PASS;
8. synchronization PASS;
9. destructive primitive PASS;
10. installer handoff authorized;
11. unattended Ubuntu installation;
12. installed-system boot;
13. provisioning USB removed; and
14. independent reboot with the USB disconnected.

See [REV-B-PASS.md](REV-B-PASS.md).

## Important Scope Limitation

Grandpa had already undergone an earlier OLLITERATOR provisioning wipe
before the Rev B prosecution.

Rev B therefore proves the documented Rev B chain on this physical
hardware, but it does not independently establish one-boot
wipe-to-install behavior from every arbitrary populated preexisting
partition layout.

That case requires separate prosecution.

## Public Profile and Prosecuted Profile

The physically prosecuted hardware profile contained an observed device
serial that was not used as an authorization requirement.

The public profile removes that unique identifier.

Because of that sanitization, the public profile is not byte-identical
to the physically prosecuted profile and has a different SHA-256.

The authorization-relevant hardware and storage values are preserved.

## Verification

`MANIFEST.sha256` contains hashes for the prosecution documents and
source files that are present in the public repository.

Verify them from the repository root with:

    sha256sum -c docs/prosecution/grandpa/MANIFEST.sha256

Hashes for physically prosecuted release artifacts that are not stored
in the source tree are recorded in `REV-B-PASS.md`.

## Rule

A physical prosecution result applies only to the identified hardware,
software, configuration, and artifacts actually tested.

A modified artifact does not inherit the status of the artifact from
which it was derived.

OLLITERATOR does not guess.
