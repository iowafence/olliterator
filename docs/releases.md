# OLLITERATOR Releases

OLLITERATOR releases distinguish source versions, generated artifacts, hardware profiles, and prosecution status.

These are related identities.

They are not interchangeable.

> **A release label does not create evidence.**

## Release Principles

Every distributed destructive artifact should be identifiable by its actual bytes and the source and inputs used to construct it.

A release should answer:

1. What source revision produced this artifact?
2. What upstream operating-system image was used?
3. What hardware profile was packaged?
4. What runtime components were packaged?
5. What destructive primitive was packaged?
6. What are the resulting artifact hashes?
7. What prosecution status has actually been established?
8. On what hardware was that status established?

If those questions cannot be answered, the artifact should not be represented as a prosecuted OLLITERATOR release.

## Version Versus Artifact Identity

A human-readable version identifies a project release.

A cryptographic hash identifies a particular artifact.

For example:

```text
OLLITERATOR v0.2
```

may describe a software generation, while:

```text
SHA-256: <artifact hash>
```

identifies one exact file.

Two files carrying the same human-readable version are not necessarily the same artifact.

## Source Revision

Every release should identify the exact source revision used to construct it.

For Git-based releases, record the commit identity.

Example:

```text
source revision:
<git commit>
```

A dirty working tree should not be used for an official release without explicitly recording that condition and the complete delta.

The preferred release condition is a clean source tree at a known commit.

## Upstream Base Identity

When a release incorporates an upstream operating-system artifact, record its exact identity.

For the current Ubuntu build path, this includes:

```text
upstream:
Ubuntu 24.04.1 Desktop amd64

base image:
ubuntu-24.04.1-desktop-amd64.iso

SHA-256:
c2e6f4dc37ac944e2ed507f87c6188dd4d3179bf4a3f9e110d3c88d1f3294bdc
```

A different upstream ISO is a different build input even if its filename or product branding appears similar.

## Hardware Profile Identity

Record the exact profile included in the artifact.

At minimum:

```text
profile ID
profile repository path
profile SHA-256
profile status
```

For the current public Surface Go 2 profile:

```text
profile ID:
surface-go-2-64gb

path:
profiles/microsoft/surface-go-2/64gb-emmc.conf

SHA-256:
9ab4509cbef124d3abad0e6a17d72211a536e155b8e400bc429c0e5d5bc879d1
```

A changed profile hash means the profile artifact changed.

Do not assume prior prosecution automatically applies.

## Runtime Identity

Release provenance should identify the safety-critical runtime components.

The current prosecuted lineage includes:

```text
runtime/olliterator-common.sh
7bd74492f1c5368188e67e86ae000d44205666add3bf359e181e69cde58421a3

runtime/provision-stage.sh
f438de9dd44dfd4470a48e6bb5c9f2a26ed7841e672999b88690b33b2b7f8f21

runtime/hooks/02olliterator-provision
4001861e58569308538867bd39723f3e57fea373a8981f16d8eaa587ee3c0096
```

A change to safety-critical runtime code creates a new evidence question.

## Destructive Primitive Identity

The production destructive primitive must be identified separately.

Current prosecuted production binary:

```text
SHA-256:
9460edea30e00b037d48cd39ebd38e0f9f88f33f18bf001d0ad373bd78adfafe
```

The source identity should also be recorded:

```text
src/olli-wipe.c

SHA-256:
26ee3ed5b7c2950901de656a5b199f114060d94e80810caf367aa1a6684e9741
```

Source identity and binary identity are separate provenance facts.

## Generated Initramfs Identity

When the release contains a generated initramfs, publish its SHA-256.

The initramfs hash identifies the packaged early-boot environment, including the embedded OLLITERATOR runtime.

A changed initramfs is a changed artifact even when the visible ISO version string remains unchanged.

## Final ISO Identity

Every distributed ISO should have an accompanying SHA-256.

Example:

```text
OLLITERATOR ISO
SHA-256:
<exact final ISO hash>
```

Users should verify the ISO before writing it to boot media.

## Prosecution Status

Release status must describe evidence that actually exists.

Defined project states include:

```text
EXPERIMENTAL
CANDIDATE
PHYSICAL PASS
REPEATABILITY PASS
SUSPENDED
REVOKED
```

### EXPERIMENTAL

Development work without sufficient evidence for candidate status.

### CANDIDATE

An artifact or profile that has completed the required pre-physical checks but has not established the required physical prosecution evidence.

### PHYSICAL PASS

The documented artifact and hardware combination completed the defined physical prosecution procedure for the stated scope.

### REPEATABILITY PASS

Additional evidence demonstrates the required behavior across the defined repeatability scope.

### SUSPENDED

Prior status is temporarily withdrawn pending investigation or additional evidence.

### REVOKED

Prior status is withdrawn because evidence or later findings invalidate the claim.

## Status Scope

Status must always be read together with scope.

For example:

```text
PHYSICAL PASS
```

does not mean:

```text
safe on every computer
safe with every disk layout
safe with every installer
safe with every future build
```

It means the documented artifact and hardware combination passed the documented prosecution conditions.

## Historical Rev B

The historical OLLITERATOR v0.2 Rev B artifact completed physical prosecution on the documented Microsoft Surface Go 2 / 64 GB eMMC target.

Its status is:

```text
PHYSICAL PASS
```

within the scope recorded under:

```text
docs/prosecution/grandpa/
```

That evidence does not automatically transfer to another ISO.

## Public Builder Artifact

The public Ubuntu builder has successfully produced and independently packaged-verified a new ISO from the documented inputs.

That generated public test ISO had SHA-256:

```text
dcf7b8becccdfd4cbc84e8ad611c0dc102ef0147d2e29f65c7cb7ee6fc95c82b
```

Its current status is:

```text
CANDIDATE
```

It has not inherited the historical Rev B `PHYSICAL PASS`.

## Release Manifest

A release should include machine-readable provenance in addition to human-readable notes.

The release manifest should record, at minimum:

```text
schema version
OLLITERATOR version
source revision
build timestamp if used
base ISO name
base ISO SHA-256
profile ID
profile path
profile SHA-256
runtime component hashes
destructive primitive source SHA-256
destructive primitive binary SHA-256
GRUB configuration SHA-256
autoinstall configuration SHA-256
generated initramfs SHA-256
final ISO SHA-256
prosecution status
prosecution evidence reference
```

Do not include secrets, credentials, private keys, or unnecessary device identifiers in the public manifest.

## SHA256SUMS

Binary release assets should be accompanied by a `SHA256SUMS` file or equivalent release checksum record.

Example:

```text
<sha256>  olliterator-<version>-<target>.iso
```

Checksums establish artifact identity.

They do not establish safety status by themselves.

## Signing

Cryptographic release signing may be added independently of prosecution status.

Signing answers:

> Who published or approved this artifact?

Prosecution answers:

> What evidence exists for this artifact's behavior on the stated hardware and scope?

A valid signature does not replace prosecution.

A prosecution record does not replace release authenticity.

Both may be useful.

## Release Notes

Release notes should clearly separate:

```text
new features
safety-critical changes
profile changes
build-system changes
installer changes
known limitations
prosecution status
```

Safety-critical changes should never be buried inside general cleanup notes.

## Safety-Critical Changes

Changes to the following should trigger explicit review of existing evidence:

```text
hardware authorization
storage discovery
candidate filtering
candidate cardinality
USB exclusion
profile predicates
double authorization
containment behavior
final target validation
destructive primitive
hook ordering
installer handoff boundary
```

A release containing such changes must not casually inherit prior physical status.

## Documentation-Only Changes

Documentation-only changes do not necessarily alter executable artifact identity.

They may still require a new source revision.

Release notes should distinguish documentation changes from executable changes rather than implying a new physical prosecution occurred.

## Profile-Only Changes

A profile-only change can materially alter destructive authorization.

Therefore "only a config change" is not a reason to preserve prosecution status automatically.

Profile predicates are part of the safety boundary.

## Build-System Changes

Build-system changes can alter the generated artifact even when safety-critical source files are unchanged.

A modified builder must be evaluated for:

```text
wrong-file injection
hook-order changes
stale artifacts
incorrect profile mapping
boot configuration changes
initramfs packaging changes
upstream boot-layout changes
```

The output is a new artifact and should be verified accordingly.

## Release Assets

A typical binary release may eventually contain:

```text
olliterator-<version>-<target>.iso
SHA256SUMS
manifest.json
release notes
```

Source remains available through the repository and source archive.

Generated intermediate trees should not be distributed unless they serve a specific evidentiary or debugging purpose.

## Secrets and Private Data

Before publication, release contents must be checked for:

```text
password hashes
plaintext passwords
API credentials
private keys
tokens
employee data
customer data
private device serials
MAC addresses
WWNs
UUIDs not required for public evidence
internal infrastructure details
```

A release should contain only the information necessary for operation, verification, and public evidence.

## Revocation

If a safety defect invalidates a prior release claim:

1. mark the affected status `SUSPENDED` or `REVOKED`;
2. identify affected artifact hashes;
3. publish the reason at an appropriate level of detail;
4. prevent new distribution of the affected artifact where practical;
5. preserve the historical evidence record; and
6. prosecute any replacement artifact before assigning new physical status.

Do not erase a failed history to make the project look cleaner.

Failures are part of the evidence.

## Release Rule

The release process must never turn:

```text
we built it
```

into:

```text
we proved it
```

without the evidence between those statements.

OLLITERATOR does not guess about disks.

Its release process should not guess about provenance either.
