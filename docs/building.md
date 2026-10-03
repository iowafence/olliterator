# Building OLLITERATOR

This document describes the current public Ubuntu build path and the provenance rules that apply to generated artifacts.

The most important rule is:

> **Building an artifact does not prosecute an artifact.**

A successful build demonstrates that the build pipeline completed its defined checks.

It does not automatically grant the resulting ISO `PHYSICAL PASS`.

## Current Build Target

The current public build path targets:

```text
Ubuntu 24.04.1 Desktop amd64
Microsoft Surface Go 2
64 GB eMMC
x86-64
```

The exercised upstream Ubuntu ISO is:

```text
ubuntu-24.04.1-desktop-amd64.iso
```

Expected SHA-256:

```text
c2e6f4dc37ac944e2ed507f87c6188dd4d3179bf4a3f9e110d3c88d1f3294bdc
```

Verify the base ISO before relying on it as the same upstream artifact used by the current build record.

## Builder

The public builder is:

```text
build/build-ubuntu.sh
```

Usage:

```bash
./build/build-ubuntu.sh \
  BASE_ISO \
  OUTPUT_ISO \
  OLLI_WIPE_BINARY
```

Example:

```bash
./build/build-ubuntu.sh \
  ~/Downloads/ubuntu-24.04.1-desktop-amd64.iso \
  ~/Downloads/olliterator.iso \
  /path/to/olli-wipe
```

The builder does not flash the resulting ISO to removable media.

## Required Tools

The current builder checks for the tools it requires.

These include:

```text
xorriso
unmkinitramfs
cpio
sha256sum
grep
find
cmp
install
sed
awk
readlink
mktemp
```

The exact package names used to provide these commands vary by distribution.

The builder refuses to continue when a required command is unavailable.

## Build Inputs

The builder consumes three external or repository inputs:

1. a base Ubuntu ISO;
2. the public OLLITERATOR source tree; and
3. an `olli-wipe` production binary.

The output is a newly generated bootable ISO.

## Safety-Critical Source Verification

Before constructing the ISO, the builder verifies the expected hashes of the current safety-critical repository components.

These include:

```text
runtime/olliterator-common.sh
runtime/provision-stage.sh
runtime/hooks/02olliterator-provision
src/olli-wipe.c
profiles/microsoft/surface-go-2/64gb-emmc.conf
installer/ubuntu/grub-provision.cfg
```

A mismatch causes refusal.

This prevents the current builder from silently packaging modified safety-critical source while presenting the result as the known build configuration.

## The Destructive Primitive

The repository contains the source for the destructive primitive:

```text
src/olli-wipe.c
```

The public source tree does not commit the generated production binary.

The current production builder instead accepts the binary as an explicit input and requires its exact expected SHA-256.

Current expected production binary SHA-256:

```text
9460edea30e00b037d48cd39ebd38e0f9f88f33f18bf001d0ad373bd78adfafe
```

If the supplied binary does not match, the builder refuses to package it.

## Why the Binary Is an Explicit Input

The physically prosecuted Rev B artifact used a specific production `olli-wipe` binary.

Its identity is known by hash.

Recompiling the same source in a different compiler, libc, linker, or build environment may produce a functionally equivalent binary with different bytes.

OLLITERATOR does not pretend that such a binary is byte-identical to the prosecuted primitive.

Therefore the current production builder makes the distinction explicit:

```text
same source != necessarily same binary
same behavior != same artifact identity
```

A separately compiled primitive may be useful for development and testing.

It is a new artifact until its identity and evidence are established.

## Static Production Primitive

The current prosecuted production primitive is a static x86-64 Linux executable.

The source implements the production block-device checks directly.

Development or test builds may use different compilation modes to exercise the primitive against synthetic files, but those builds must not be represented as the prosecuted production binary.

## Initramfs Construction

The builder extracts the stock Ubuntu initramfs and adds the current OLLITERATOR runtime.

The packaged paths include:

```text
/olliterator/runtime/olliterator-common.sh
/olliterator/provision-stage.sh
/olliterator/profiles/surface-go-2-64gb.conf
/olliterator/bin/olli-wipe
/scripts/init-top/02olliterator-provision
```

The public repository profile:

```text
profiles/microsoft/surface-go-2/64gb-emmc.conf
```

is mapped into the initramfs at:

```text
/olliterator/profiles/surface-go-2-64gb.conf
```

This internal path is the path consumed by the current frozen provision stage.

## Hook Placement

The current public build places:

```text
/scripts/init-top/02olliterator-provision "$@"
```

immediately after:

```text
/scripts/init-top/udev "$@"
```

in the initramfs `scripts/init-top/ORDER` file.

The builder verifies that the provisioning hook occurs exactly once in the active order and verifies its required placement.

The current public builder does not install the earlier probe hook used during development.

## Repack Verification

After repacking the initramfs, the builder unpacks the newly generated initramfs again.

It then compares the embedded OLLITERATOR components against the intended inputs.

This verifies the packaged contents rather than relying only on the pre-packaging source tree.

## ISO Construction

The builder uses the stock Ubuntu ISO as the boot-layout source.

It uses `xorriso` boot replay while replacing the required files.

The generated ISO receives:

```text
/boot/grub/grub.cfg
/casper/initrd
/autoinstall.yaml
```

from the current OLLITERATOR build inputs.

The upstream boot structure is preserved rather than manually recreating the BIOS and UEFI boot layout from scratch.

## Boot Configuration

The current provisioning GRUB configuration supplies:

```text
olliterator=provision
autoinstall
```

The provisioning token activates the OLLITERATOR containment hook.

The `autoinstall` token activates the downstream Ubuntu unattended installer behavior.

The current public provisioning artifact must not activate the historical wipe-only boot path.

## Public Autoinstall Configuration

The repository contains:

```text
installer/ubuntu/autoinstall.example.yaml
```

This is a sanitized example.

It does not contain production credentials.

The example currently uses:

```text
/dev/mmcblk0
```

because it corresponds to the current Surface Go 2 / 64 GB eMMC profile.

The installer target configuration is downstream of OLLITERATOR authorization.

It is not a replacement for OLLITERATOR target authorization.

## Workspace

The builder uses:

```text
build/work/
```

for temporary build state.

This directory is ignored by Git.

The workspace is intentionally disk-backed rather than assuming `/tmp` has enough capacity for a full Ubuntu ISO and unpacked initramfs.

Temporary build state is removed by the builder cleanup path.

## Refusal Behavior

The builder is intended to fail before output construction when required inputs or invariants are not satisfied.

Current refusal cases include:

```text
missing base ISO
missing destructive primitive
missing required command
missing required repository file
safety-critical source hash mismatch
destructive primitive hash mismatch
invalid hook placement
packaged component mismatch
```

A refusal is preferable to silently producing an artifact with uncertain provenance.

## Public Pipeline Exercise

The current public builder has been exercised using the expected Ubuntu 24.04.1 Desktop amd64 base ISO and the exact prosecuted production primitive.

That build completed successfully.

The resulting public test ISO SHA-256 was:

```text
dcf7b8becccdfd4cbc84e8ad611c0dc102ef0147d2e29f65c7cb7ee6fc95c82b
```

This hash identifies that particular generated test artifact.

It is not a permanent expected hash for every future build.

## Independent Finished-ISO Inspection

The generated public test ISO was independently re-extracted after construction.

The outer artifact checks confirmed:

```text
GRUB configuration
SHA-256:
1a1f5ed28bc9808288cfc8f7379389d415bbcdff82e1c986003e7e8ccc09fe31

generated initrd
SHA-256:
9e9987fd892dbd7bb6881a88b279a3decf107e706e60521f4df4e182e85b3271

public autoinstall example
SHA-256:
5b726477c1df5555c23dd0ce44fd3b7a98c2bab4b58aec2019385213ff4a660d
```

The boot configuration contained the provisioning and autoinstall tokens and did not contain the historical wipe boot token.

## Independent Initramfs Inspection

The initramfs extracted from the finished public test ISO was independently unpacked.

The embedded components matched:

```text
olliterator-common.sh
7bd74492f1c5368188e67e86ae000d44205666add3bf359e181e69cde58421a3

provision-stage.sh
f438de9dd44dfd4470a48e6bb5c9f2a26ed7841e672999b88690b33b2b7f8f21

02olliterator-provision
4001861e58569308538867bd39723f3e57fea373a8981f16d8eaa587ee3c0096

public Surface Go 2 profile
9ab4509cbef124d3abad0e6a17d72211a536e155b8e400bc429c0e5d5bc879d1

olli-wipe production binary
9460edea30e00b037d48cd39ebd38e0f9f88f33f18bf001d0ad373bd78adfafe
```

Inspection also confirmed:

- the provisioning hook was immediately after `udev`;
- the historical wipe hook was not active; and
- the private observed Surface serial was absent from the public profile.

## Build Pipeline Status

The public build pipeline passed its current construction and packaging checks.

That statement applies to the build process and inspected generated artifact.

It does not mean the generated public test ISO has completed physical prosecution.

Its status is:

```text
CANDIDATE
```

## Historical Rev B Versus Public Build

The historical Rev B artifact and the newly generated public test artifact are different artifacts.

Historical Rev B completed physical prosecution on the Surface Go 2.

The public builder was reconstructed from the established build procedure and current frozen components, then independently exercised and inspected.

Therefore:

```text
Historical Rev B:
PHYSICAL PASS for the documented prosecution scope.

Public generated test ISO:
CANDIDATE after successful construction and packaging verification.
```

Do not transfer the historical `PHYSICAL PASS` label to a newly generated ISO without the required evidence.

## Rebuilding the Primitive

The source for `olli-wipe` is public so it can be inspected, compiled, tested, and modified.

A future build workflow may provide a documented compiler toolchain for generating a production primitive directly from source.

Until a reproducible toolchain and corresponding evidence are established, an independently compiled binary must be treated as a new binary artifact.

Do not change the builder's exact production-binary hash check merely to make an arbitrary local compilation pass.

## Development Builds

Development builds are expected to exist.

They may include:

- modified runtime logic;
- modified profiles;
- alternate primitives;
- alternate installer configuration;
- additional diagnostics; or
- experimental hardware support.

They must be labeled according to what they are.

A development artifact does not become physically prosecuted because it descended from prosecuted source.

## Generated Files

Do not commit generated build products into the source tree by default.

Examples include:

```text
*.iso
*.img
initrd
*.cpio
generated binaries
unpacked ISO trees
unpacked initramfs trees
temporary build workspaces
```

Release artifacts may be distributed separately with explicit hashes and provenance metadata.

## Before Physical Testing

Before using a newly generated artifact for destructive physical testing:

1. verify the base ISO identity;
2. verify the repository revision;
3. verify safety-critical source hashes;
4. verify the destructive primitive identity;
5. verify the generated ISO hash;
6. inspect the finished ISO;
7. inspect the embedded initramfs;
8. verify active hook order;
9. verify the intended hardware profile;
10. verify no private data or credentials were accidentally embedded; and
11. follow the prosecution procedure.

Do not skip artifact inspection merely because the builder exited successfully.

## Physical Testing

Physical testing is destructive.

Use hardware that is explicitly available for destructive prosecution.

Do not perform destructive testing on a machine merely because it appears to match a profile.

Do not perform destructive testing merely to complete an issue or pull request.

The prosecution procedure, not this build document, governs assignment of physical status.

See:

```text
docs/prosecution/PROCEDURE.md
```

## Release Builds

Release artifacts should publish enough provenance to identify what was actually built.

At minimum, record:

```text
OLLITERATOR version
source revision
base ISO identity and SHA-256
hardware profile identity and SHA-256
runtime component hashes
destructive primitive SHA-256
generated initramfs SHA-256
final ISO SHA-256
prosecution status
```

See [`releases.md`](releases.md) for the release model.

## Final Rule

A green build is evidence about construction.

A successful synthetic test is evidence about logic.

A physical prosecution is evidence about the tested physical artifact and hardware.

They are related.

They are not interchangeable.
