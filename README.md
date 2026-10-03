# OLLITERATOR

**Deterministic, fail-closed hardware reprovisioning.**

OLLITERATOR is a destructive authorization layer for unattended hardware reprovisioning.

It positively identifies supported hardware and exactly one permitted internal storage target before destructive action is allowed. If identification is ambiguous, authorization fails.

> **OLLITERATOR does not guess.**

If OLLITERATOR isn't certain which disk it's allowed to destroy, it destroys nothing.

## Why This Exists

Unattended provisioning is easy right up until the wrong disk gets selected.

Most installation systems are designed to answer:

> Which disk should I install to?

OLLITERATOR answers a different question first:

> Am I sufficiently certain that this exact physical device is authorized to be destroyed?

Only after that question has been answered does installation begin.

OLLITERATOR is intended to sit in front of an unattended installer, deployment system, PXE environment, or similar provisioning workflow.

**The installer installs. OLLITERATOR decides whether destruction is authorized.**

## Safety Model

OLLITERATOR treats ambiguity as failure.

Authorization currently requires:

1. supported hardware identity;
2. storage enumeration;
3. exactly one permitted candidate;
4. exact target properties;
5. exclusion of removable and USB-backed storage;
6. a second independent authorization immediately before destruction;
7. agreement between both authorization passes;
8. final block-device validation; and
9. independent acceptance by the destructive primitive.

There is no fallback disk. There is no "first disk." There is no "largest disk." There is no "probably the internal one."

Two candidates means:

```text
REFUSE
```
See [`docs/safety-model.md`](docs/safety-model.md) for the normative safety model.

## Current Architecture

The current Ubuntu provisioning path is:

```text
BOOT
  |
  v
initramfs
  |
  v
OLLITERATOR hardware authorization #1
  |
  v
storage target authorization #1
  |
  v
sync / delay / fresh observation
  |
  v
OLLITERATOR hardware authorization #2
  |
  v
storage target authorization #2
  |
  v
compare authorization results
  |
  v
final block-device validation
  |
  v
olli-wipe independently validates target
  |
  v
provisioning metadata destruction
  |
  v
verification / sync
  |
  v
AUTHORIZED INSTALLER HANDOFF
  |
  v
Ubuntu autoinstall
```

Any failed authorization before handoff prevents the installer from continuing.

The current provisioning wipe destroys storage metadata at the beginning and end of the authorized device. It is intended to invalidate the existing provisioning layout.

**It is not a secure sanitization or complete-media erase system.**

## Destructive Primitive

`src/olli-wipe.c` is the minimal destructive primitive.

Before writing, it independently verifies:

- the supplied target exists;
- the target is a block device;
- its exact size matches the authorized value; and
- the requested size is valid.

It then destroys the first and final regions of the authorized target and requires successful synchronization before reporting completion.

The authorization layer cannot simply hand the primitive an arbitrary device and expect it to comply.

**The primitive has its own boundary.**

## Hardware Profiles

Hardware support is explicit.

A profile defines the hardware identity and storage properties OLLITERATOR expects to observe.

The first public profile is:

```text
Microsoft Surface Go 2
64 GB eMMC
x86-64
```

The current authorized storage target for that profile is:

```text
mmcblk0
62537072640 bytes
non-removable
non-USB topology
```

The public profile is located at:

[`profiles/microsoft/surface-go-2/64gb-emmc.conf`](profiles/microsoft/surface-go-2/64gb-emmc.conf)

A profile existing in the repository does not, by itself, prove hardware support.

See [`docs/prosecution/PROCEDURE.md`](docs/prosecution/PROCEDURE.md).

## Hardware Status

OLLITERATOR uses an explicit prosecution lifecycle:

```text
EXPERIMENTAL
    |
    v
CANDIDATE
    |
    v
PHYSICAL PASS
    |
    v
REPEATABILITY PASS
```

Profiles or artifacts may also become `SUSPENDED` or `REVOKED`.

Official prosecution status is assigned by project maintainers from recorded evidence.

Synthetic tests alone do not establish `PHYSICAL PASS`.

## Grandpa

The first physical prosecution target is known as **Grandpa**.

Grandpa is a retired Microsoft Surface Go 2 formerly used by an employee of Iowa Fence Inc.

Grandpa currently runs Ubuntu.

Grandpa has been through enough.

### Rev A

The first v0.2 physical attempt successfully completed both authorization passes but refused before destructive execution because the stage checked the logical target name rather than its `/dev/` block-device path.

The result was:

```text
REFUSED: TARGET IS NO LONGER A BLOCK DEVICE
```

The destructive primitive did not begin.

The installer did not start.

The system remained contained.

That is a failed provisioning attempt and a successful demonstration of fail-closed behavior.

### Rev B

Rev B corrected the final block-device path construction.

On the physical Surface Go 2:

```text
authorization #1        PASS
authorization #2        PASS
authorization agreement PASS
final target check      PASS
destructive primitive   PASS
wipe completion         PASS
installer handoff       PASS
installation            PASS
post-install boot       PASS
USB-independent boot    PASS
```

The complete evidence record is under:

[`docs/prosecution/grandpa/`](docs/prosecution/grandpa/)

### Scope Limitation

Grandpa had already undergone an earlier OLLITERATOR wipe before the v0.2 Rev B prosecution.

Therefore Rev B does **not** establish successful one-boot reprovisioning from every arbitrary populated preexisting disk layout.

That remains a separate test condition.

## Building

The repository contains a public Ubuntu ISO builder:

```text
build/build-ubuntu.sh
```

It starts from a stock Ubuntu ISO, verifies safety-critical source components, injects OLLITERATOR into the initramfs, installs the provisioning hook immediately after `udev`, preserves the upstream boot structure, and constructs a new ISO.

The builder refuses to package a destructive primitive unless it matches the expected prosecuted binary hash.

Example:

```bash
./build/build-ubuntu.sh \
  ubuntu-24.04.1-desktop-amd64.iso \
  olliterator.iso \
  /path/to/olli-wipe
```

The currently exercised base image is Ubuntu 24.04.1 Desktop amd64:

```text
SHA256
c2e6f4dc37ac944e2ed507f87c6188dd4d3179bf4a3f9e110d3c88d1f3294bdc
```

A successful build does **not** inherit the prosecution status of another artifact.

Every newly built ISO has a new artifact identity.

The current public build pipeline has been exercised from the stock Ubuntu ISO through final ISO construction and independent extraction of the finished artifact.

The resulting public test ISO was independently checked for:

- exact embedded safety-critical component hashes;
- exact destructive primitive hash;
- provisioning hook placement immediately after `udev`;
- absence of the old active wipe hook;
- sanitized public hardware profile;
- provisioning boot token;
- autoinstall boot token; and
- preservation of the upstream BIOS and UEFI boot structure.

That build pipeline passed its construction and packaging checks.

The resulting ISO is a **CANDIDATE**.

It does **not** inherit the `PHYSICAL PASS` status of the separately prosecuted Rev B artifact.

See [`docs/building.md`](docs/building.md) for build details and artifact-status rules.

## Installer Configuration

The Ubuntu integration includes:

- [`installer/ubuntu/grub-provision.cfg`](installer/ubuntu/grub-provision.cfg)
- [`installer/ubuntu/autoinstall.example.yaml`](installer/ubuntu/autoinstall.example.yaml)

The included autoinstall file is an example configuration.

It contains no production credentials.

The current example targets `/dev/mmcblk0` because it corresponds to the current Surface Go 2 hardware profile.

OLLITERATOR owns destructive authorization.

The installer receives control only after that authorization succeeds.

## Prosecution

A hardware profile is not proof.

A synthetic test is not a physical test.

A successful boot is not a destructive authorization test.

A newly constructed artifact does not inherit another artifact's prosecution status.

OLLITERATOR records failures as well as successes because a refusal at the correct boundary is evidence about the safety model.

The prosecution procedure is documented in:

[`docs/prosecution/PROCEDURE.md`](docs/prosecution/PROCEDURE.md)

The first prosecution record includes both:

- [`REV-A-FAIL.md`](docs/prosecution/grandpa/REV-A-FAIL.md)
- [`REV-B-PASS.md`](docs/prosecution/grandpa/REV-B-PASS.md)

The associated public evidence manifest is located under:

[`docs/prosecution/grandpa/`](docs/prosecution/grandpa/)

## Contributing Hardware Support

New hardware support requires evidence.

Do not submit a profile containing a model name and disk guess and call it supported.

At minimum, candidate work needs evidence for:

- manufacturer;
- exact model;
- architecture;
- storage enumeration;
- candidate device name;
- exact device size;
- removable state;
- device topology; and
- presence of any additional storage devices.

> **Do not perform a destructive test merely to complete an issue or pull request.**

Maintainers assign official hardware status after the required prosecution work.

That means nobody gets to submit a 12-line `.conf` and announce:

> "Dell OptiPlex 7090 SUPPORTED!!!"

**No motherfucker. Go prosecute it.**

See [`CONTRIBUTING.md`](CONTRIBUTING.md).

## CI Boundary

Automated tests may exercise:

- selector logic;
- ambiguous-target refusal;
- profile validation;
- containment behavior;
- destructive primitive behavior against synthetic files; and
- build and packaging invariants.

CI must not destructively operate arbitrary host block devices.

Physical prosecution remains a separate process.

## What OLLITERATOR Is Not

OLLITERATOR is not:

- a secure disk-erasure product;
- a general-purpose disk selector;
- an installer;
- a hardware inventory system;
- permission to destroy an arbitrary disk;
- proof that unprosecuted hardware is safe; or
- a substitute for backups.

It is a deliberately narrow authorization boundary around destructive reprovisioning.

## Fleet Direction

The current implementation uses Ubuntu autoinstall as the downstream installer.

The architecture is intended to permit other provisioning systems and operating systems to sit behind the same authorization boundary.

A future fleet flow may look like:

```text
controller / deployment system
            |
            v
         PXE boot
            |
            v
      OLLITERATOR
            |
            v
local hardware + target authorization
            |
            v
destructive primitive
            |
            v
authorized installer handoff
            |
            v
OS provisioning
```

Potential downstream environments include Debian, Proxmox, Talos, and TrueNAS.

Support for another installer does not imply support for another hardware platform.

ARM hardware requires its own build, profile, media, and prosecution.

## Why Is This Owned by a Fence Company?

We needed some different field software.

### You're actually a fence company?

Yes.

### No, seriously.

Yes.

[**Iowa Fence Inc.**](https://fencingiowa.com/)

## Security

OLLITERATOR operates at a destructive boundary.

Potential authorization bypasses, target-validation failures, containment failures, and similar findings should be treated as safety-critical.

Do not publish destructive bypass instructions before maintainers have had an opportunity to review them.

See [`SECURITY.md`](SECURITY.md).

## License

Copyright 2026 Iowa Fence Inc.

Licensed under the Apache License, Version 2.0.

See [`LICENSE`](LICENSE) and [`NOTICE`](NOTICE).
