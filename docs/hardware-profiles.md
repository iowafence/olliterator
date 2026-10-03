# OLLITERATOR Hardware Profiles

Hardware profiles define the observations OLLITERATOR requires before destructive authorization may proceed on a particular hardware configuration.

A profile is not a guess.

A profile is not a generic compatibility declaration.

A profile is not proof that a machine is safe to reprovision.

> **A profile describes required evidence. Prosecution establishes support.**

## Current Profile Model

The current profile format is a shell-compatible configuration containing hardware, storage, and observational properties. Not every field is consumed by the current authorization runtime.

The first public profile is:

```text
profiles/microsoft/surface-go-2/64gb-emmc.conf
```

Its fields include:

```text
PROFILE_ID
DMI_VENDOR
DMI_PRODUCT
TARGET_NAME
TARGET_SIZE_BYTES
TARGET_REMOVABLE
OBSERVED_SERIAL
```

The current `olliterator-common.sh` authorization runtime consumes `DMI_VENDOR`, `DMI_PRODUCT`, `TARGET_SIZE_BYTES`, and `TARGET_REMOVABLE`. `PROFILE_ID`, `TARGET_NAME`, and `OBSERVED_SERIAL` are not authorization predicates in that runtime.

The current public Surface Go 2 profile describes:

```text
DMI vendor:        Microsoft Corporation
DMI product:       Surface Go 2
target name:       mmcblk0
target size:       62537072640 bytes
target removable:  0
```

These values correspond to the physically prosecuted Surface Go 2 / 64 GB eMMC configuration.

## Observational Fields

A profile may also contain information recorded for evidence or investigation that is not currently an authorization predicate.

The Surface Go 2 profile contains:

```text
OBSERVED_SERIAL
```

The physical prosecution artifact recorded the observed device serial.

The public profile redacts that value.

The current runtime does not use `OBSERVED_SERIAL` as an authorization requirement.

Changing or removing an observational value that is not consumed by authorization logic does not automatically change the authorization predicates.

It may still change artifact identity and therefore must be documented honestly.

## Exactness

OLLITERATOR profiles should use exact values where the safety model depends on exactness.

Examples include:

- exact DMI vendor;
- exact DMI product;
- exact target byte count; and
- exact removable state.

Do not replace an exact value with a broad approximation merely to make more devices match.

Examples of unacceptable substitutions include:

```text
"about 64 GB"
"first internal disk"
"largest disk"
"any Microsoft tablet"
"anything named mmcblk*"
```

Those are heuristics.

They are not equivalent to the prosecuted profile.

## Candidate Cardinality

A matching profile does not authorize OLLITERATOR to choose among multiple acceptable-looking disks.

The runtime must establish exactly one permitted candidate.

```text
0 candidates  -> REFUSE
1 candidate   -> continue authorization
2+ candidates -> REFUSE
```

A hardware profile must not introduce ranking logic to resolve ambiguity.

If multiple devices satisfy the profile, the profile or authorization model is insufficient.

## USB Exclusion

The current runtime does not rely solely on the removable flag.

A device may report unexpected or misleading removable state.

OLLITERATOR therefore also evaluates device topology and excludes USB-backed storage from the current internal-target model.

A future profile must not weaken this property merely because a particular test machine happens to enumerate storage differently.

If the hardware requires a different storage model, that difference must be explicitly designed and prosecuted.

## Device Classes

The current authorization model is intended for a whole physical target device matching the prosecuted profile.

Pseudo, virtual, or aggregate storage devices are not silently treated as equivalent.

Examples include:

- loop devices;
- RAM-backed devices;
- zram;
- device-mapper devices; and
- software RAID devices.

Supporting a different device class requires an explicit authorization model.

## Creating a Candidate Profile

Before proposing a candidate hardware profile, collect evidence from the physical machine.

At minimum, record:

1. manufacturer;
2. exact model;
3. architecture;
4. DMI identity used by the runtime;
5. all visible storage devices;
6. observed or intended target device name;
7. exact target byte count;
8. removable state;
9. target topology;
10. whether the target is USB-backed;
11. presence of additional internal storage; and
12. any boot-time enumeration behavior relevant to authorization.

Do not perform destructive testing merely to gather this information.

Discovery comes before destruction.

## Profile Naming

Profiles should be organized by manufacturer, product family, and storage configuration where necessary.

Example:

```text
profiles/
└── microsoft/
    └── surface-go-2/
        └── 64gb-emmc.conf
```

A materially different storage configuration should receive its own profile when its authorization evidence differs.

For example, a 128 GB configuration must not inherit the 64 GB exact-size predicate merely because the chassis looks identical.

## Profile IDs

`PROFILE_ID` should be stable, descriptive, and specific enough to distinguish materially different authorization profiles.

Current example:

```text
surface-go-2-64gb
```

Do not silently reuse an existing profile ID for materially different authorization semantics.

## Profile Status

The existence of a profile in the repository does not imply `PHYSICAL PASS`.

Profile and artifact status follow the prosecution model described in:

```text
docs/prosecution/PROCEDURE.md
```

Relevant lifecycle states include:

```text
EXPERIMENTAL
CANDIDATE
PHYSICAL PASS
REPEATABILITY PASS
SUSPENDED
REVOKED
```

Maintainers assign official status from evidence.

## Synthetic Validation

Candidate profiles should be exercised against synthetic selector cases before physical destructive prosecution.

At minimum, selector testing should cover:

```text
zero candidates
one valid candidate
removable impostor
USB-backed candidate
wrong-size candidate
two valid candidates
valid candidate plus USB device
pseudo or virtual device
```

The expected result for every ambiguous or invalid case is refusal.

Synthetic tests establish logic behavior.

They do not establish physical support.

## Physical Prosecution

A candidate profile becomes physically meaningful only when tested against the actual hardware and the required prosecution procedure.

Physical prosecution should establish, as applicable:

- observed hardware identity;
- observed storage topology;
- expected authorization result;
- refusal behavior where intentionally tested;
- destructive primitive behavior;
- containment behavior;
- installer handoff behavior; and
- post-install boot behavior.

Evidence should include both failures and passes.

A correct refusal is valuable evidence.

## Repeatability

One successful physical run establishes only what that run demonstrates.

`REPEATABILITY PASS` requires additional evidence beyond a single successful target.

Where multiple nominally identical devices are available, repeatability testing should determine whether the profile's supposedly stable predicates are actually stable across those devices.

Unexpected variation is not a reason to weaken the profile automatically.

It is evidence that the authorization model needs review.

## Changing a Profile

Treat authorization-relevant profile changes as safety-critical.

Examples include changing:

- vendor;
- product;
- any field that the active authorization runtime consumes;
- target size;
- removable requirement; or
- storage topology assumptions.

A changed authorization predicate can invalidate prior evidence.

Do not claim that a modified profile inherits prosecution merely because it was derived from a prosecuted profile.

## Public Redaction

Public evidence may redact information that is not required for authorization and would unnecessarily identify a particular physical device or person.

Redaction must not conceal a predicate that materially contributed to authorization.

The public Surface Go 2 profile redacts its observed serial because the current runtime does not use that value as an authorization requirement.

Authorization-relevant values remain visible.

## Unsupported Hardware

Unsupported hardware should fail closed.

The correct behavior on an unknown machine is not:

```text
try the most likely disk
```

It is:

```text
REFUSE
```

The path to supporting new hardware is to gather evidence, define the required predicates, validate the selector, and prosecute the hardware.

The path is not to weaken the existing profile until the machine happens to boot.

## Contribution Rule

A pull request adding a profile is a request to evaluate candidate hardware support.

It is not permission to label the hardware supported.

Maintainers may require additional evidence, synthetic cases, physical testing, or changes to the authorization model before assigning official status.

And, for clarity:

> Nobody gets to add a `.conf`, point at a successful boot, and declare victory.

OLLITERATOR does not guess.

Neither should its hardware profiles.
