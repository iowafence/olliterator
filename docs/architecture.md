# OLLITERATOR Architecture

OLLITERATOR is a deterministic, fail-closed destructive authorization layer for unattended hardware reprovisioning.

Its job is deliberately narrow:

> Establish sufficient evidence that the running machine is supported and that exactly one storage device is authorized for destructive action.

OLLITERATOR does not choose the most likely disk.

OLLITERATOR does not repair ambiguity.

OLLITERATOR does not continue when an invariant fails.

## System Boundary

The current Ubuntu implementation sits between early boot and the downstream installer.

```text
firmware
   |
   v
boot media
   |
   v
Linux kernel
   |
   v
initramfs
   |
   v
OLLITERATOR
   |
   +--> hardware identity
   |
   +--> storage discovery
   |
   +--> target authorization
   |
   +--> second authorization
   |
   +--> destructive primitive
   |
   v
authorized handoff
   |
   v
Ubuntu installer
```

The downstream installer is outside the OLLITERATOR authorization boundary.

OLLITERATOR determines whether destructive reprovisioning may begin.

The installer determines how the new operating system is installed after authorization succeeds.

## Core Components

### Hardware Profile

A hardware profile describes the expected identity and storage properties of a specifically supported hardware configuration.

The current Surface Go 2 profile contains:

- expected DMI vendor;
- expected DMI product;
- expected storage device name;
- exact storage size; and
- expected removable state.

Observed serial information may be recorded as evidence, but the current runtime does not use the observed serial as an authorization requirement.

Profiles are evidence inputs, not proof of support by themselves.

### Runtime Authorization

`runtime/olliterator-common.sh` contains the current authorization logic.

The runtime:

1. reads hardware identity;
2. compares it against the active profile;
3. enumerates storage;
4. excludes prohibited device classes;
5. rejects removable devices;
6. rejects USB-backed storage;
7. requires exact target size;
8. requires exactly one candidate satisfying the storage predicates; and
9. requires exactly one authorized candidate.

Zero candidates is refusal.

Two candidates is refusal.

Any ambiguous result is refusal.

### Provision Stage

`runtime/provision-stage.sh` owns the destructive authorization sequence.

The stage performs an authorization pass, obtains a fresh observation, performs a second authorization pass, and requires both results to agree.

Only after agreement does it construct the final `/dev/` target path and perform final block-device validation.

The stage then invokes the destructive primitive.

A successful primitive return authorizes handoff to the installer.

A failure does not authorize handoff.

### Initramfs Containment Hook

`runtime/hooks/02olliterator-provision` is the early-boot containment boundary for provisioning mode.

The hook activates only for the provisioning boot token.

When active:

- successful authorization and wipe allow boot to continue toward the installer;
- failure prevents installer continuation.

This is intentionally different from a selector that merely returns a preferred disk.

The hook controls whether destructive provisioning is allowed to proceed at all.

### Destructive Primitive

`src/olli-wipe.c` is a deliberately small destructive primitive.

The primitive independently requires:

- a valid expected byte count;
- an openable target;
- a block device in production mode;
- exact device size agreement;
- successful front-region write;
- successful tail-region write; and
- successful synchronization and close.

The current production primitive destroys the first 16 MiB and final 16 MiB of the authorized device.

This is provisioning metadata destruction.

It is not secure sanitization.

## Authorization Sequence

The current provisioning sequence is:

```text
BOOT TOKEN
    |
    v
PROFILE LOAD
    |
    v
AUTHORIZATION #1
    |
    +---- failure ----> REFUSE
    |
    v
FRESH OBSERVATION
    |
    v
AUTHORIZATION #2
    |
    +---- failure ----> REFUSE
    |
    v
COMPARE RESULTS
    |
    +---- disagreement -> REFUSE
    |
    v
FINAL BLOCK DEVICE CHECK
    |
    +---- failure ----> REFUSE
    |
    v
DESTRUCTIVE PRIMITIVE
    |
    +---- failure ----> REFUSE / HALT
    |
    v
WIPE COMPLETE
    |
    v
AUTHORIZED INSTALLER HANDOFF
```

No downstream installer action is authorized before this sequence succeeds.

## Candidate Selection

Candidate selection is intentionally strict.

The runtime does not rank candidates.

It establishes a set of devices satisfying all required predicates.

The cardinality of that set is then evaluated.

```text
0 candidates -> REFUSE
1 candidate  -> continue authorization
2+ candidates -> REFUSE
```

This property is fundamental.

A future implementation that selects the first, largest, fastest, most common, or most likely device from an ambiguous candidate set would violate the OLLITERATOR safety model.

## Device Exclusions

The current runtime excludes storage classes that are not valid whole-device targets for the prosecuted profile.

These include pseudo or virtual device classes such as:

- loop;
- ram;
- zram;
- device mapper;
- software RAID; and
- other non-profile storage.

The runtime also checks sysfs topology and excludes USB-backed candidates even if a removable flag is incorrect.

A removable flag alone is not treated as sufficient evidence that a device is internal.

## Double Authorization

Storage state can change during boot.

OLLITERATOR therefore does not treat one early observation as permanent truth.

The provisioning stage performs authorization twice and requires agreement between the resulting selected device name and size.

This does not eliminate every possible local mutation or hostile in-process condition.

It establishes a deliberate re-observation boundary before destructive execution.

See [`threat-model.md`](threat-model.md) for scope and trust assumptions.

## Independent Primitive Boundary

Authorization success does not bypass validation inside `olli-wipe`.

The destructive primitive receives:

```text
TARGET
EXPECTED_BYTES
```

It independently checks the target type and exact size before writing.

This creates another refusal boundary between higher-level authorization and actual destructive I/O.

## Installer Handoff

OLLITERATOR does not install Ubuntu.

After successful destructive authorization and wipe completion, the initramfs hook returns control to the normal boot sequence.

Ubuntu autoinstall then performs installation using the supplied installer configuration.

This separation is intentional:

```text
OLLITERATOR = may destructive provisioning proceed?
INSTALLER   = how should the operating system be installed?
```

A downstream installer failure does not retroactively change the authorization result.

Likewise, installer capability does not grant destructive authorization.

## Boot Artifacts

The project intentionally distinguishes destructive boot purposes.

Historical development included separate wipe/recovery and automatic provisioning artifacts.

The current public builder constructs the automatic provisioning path.

Physical separation between different destructive purposes is preferable to silently overloading one boot artifact with multiple behaviors.

## Artifact Identity

A build artifact is identified by its actual bytes.

Changing:

- runtime code;
- profile data;
- hook behavior;
- destructive primitive;
- initramfs;
- installer configuration;
- boot configuration; or
- build process

can produce a new artifact requiring new verification.

A newly generated ISO does not inherit `PHYSICAL PASS` merely because some of its components were previously prosecuted.

Prosecution status belongs to the evidence record for the artifact and hardware combination actually tested.

## Current Public Build

The public Ubuntu builder:

```text
build/build-ubuntu.sh
```

verifies expected safety-critical component hashes, injects the required runtime into the stock initramfs, places the provisioning hook immediately after `udev`, repacks the initramfs, preserves the upstream boot structure, and creates a new ISO.

The builder currently requires the known production `olli-wipe` binary as an external input and verifies its exact hash before packaging it.

This preserves the identity of the prosecuted destructive primitive while keeping generated binaries out of the source tree.

A successful public build creates a new artifact.

It does not automatically create a physically prosecuted artifact.

## Safety Versus Availability

OLLITERATOR intentionally favors refusal over destructive availability.

A machine that cannot be identified with sufficient certainty may require:

- a new hardware profile;
- additional evidence;
- a changed authorization model; or
- manual provisioning.

It must not be made "supported" by weakening an invariant merely to make the machine proceed.

> **If OLLITERATOR cannot establish authorization, destruction is unavailable.**

That is the architecture.
