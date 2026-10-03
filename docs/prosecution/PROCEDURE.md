# OLLITERATOR Hardware Prosecution Procedure

This document defines the minimum evidence required to assign an
official OLLITERATOR hardware prosecution status.

A hardware profile is not proof.

A synthetic test is not a physical prosecution.

A successful boot is not a destructive authorization prosecution.

OLLITERATOR support claims must follow the evidence.

## Status Lifecycle

OLLITERATOR uses the following hardware-profile statuses:

- **EXPERIMENTAL** — profile or implementation exists but has not
  completed the required synthetic prosecution.
- **CANDIDATE** — synthetic prosecution has passed and the target is
  eligible for controlled physical prosecution.
- **PHYSICAL PASS** — the identified artifact completed the required
  physical prosecution on the identified hardware.
- **REPEATABILITY PASS** — the prosecuted behavior was reproduced on
  additional hardware covered by the same profile.
- **SUSPENDED** — previous status is temporarily withdrawn pending
  investigation or re-prosecution.
- **REVOKED** — previous status is withdrawn because its assumptions,
  evidence, or safety properties are no longer accepted.

Official status is assigned by project maintainers.

Submitting a profile does not assign PHYSICAL PASS.

## Core Requirement

OLLITERATOR must positively establish both:

1. supported hardware identity; and
2. exactly one permitted internal destructive target.

Any ambiguity is failure.

Two plausible targets do not produce a preference.

They produce refusal.

## Phase 1 — Profile Evidence

Before destructive testing, collect enough evidence to define the
hardware profile.

At minimum record:

- manufacturer;
- exact product/model identity;
- architecture;
- observed or intended internal target name;
- exact target size in bytes;
- removable state;
- relevant device topology; and
- all other visible storage devices.

Unique identifiers should not be published unless they are technically
required for authorization.

If a unique identifier is observational only, omit or redact it from
public evidence.

## Phase 2 — Synthetic Prosecution

The selector must be tested without destructive access to physical
hardware.

At minimum exercise:

- zero valid candidates;
- exactly one valid candidate;
- removable-device impostor;
- USB-topology device whose removable flag is misleading;
- wrong-size candidate;
- two otherwise valid candidates;
- valid internal target plus USB storage; and
- pseudo/block-device classes excluded by policy.

The expected result is refusal for every ambiguous or invalid case and
authorization only for the single exact valid case.

Synthetic prosecution must not destructively operate arbitrary host
block devices.

A passing synthetic prosecution may advance a profile to CANDIDATE.
## Phase 3 — Physical Prosecution

Physical prosecution must use hardware that may safely be destroyed and
reprovisioned.

Back up anything that matters before beginning.

The prosecution record must identify the exact software artifacts being
tested by cryptographic hash.

The physical run must establish, where applicable:

1. the intended boot artifact starts;
2. the expected hardware profile is loaded;
3. hardware identity passes;
4. storage enumeration produces exactly one permitted target;
5. the target has the exact required properties;
6. fresh re-authentication produces the same result;
7. the target remains a valid block device immediately before
   destruction;
8. the destructive primitive independently accepts the target;
9. destructive execution completes successfully;
10. failure at any authorization boundary prevents downstream
    destructive or installer execution;
11. installer handoff occurs only after successful destructive
    completion; and
12. the resulting installed system is independently verified where the
    prosecution includes provisioning.

Observed failures must be recorded.

A fail-closed failure is useful prosecution evidence, but it is not a
PHYSICAL PASS.

## Phase 4 — Repeatability

A PHYSICAL PASS applies only to the hardware and artifacts actually
prosecuted.

Testing additional physical units covered by the same profile provides
repeatability evidence.

REPEATABILITY PASS requires successful prosecution on additional
representative hardware under the same authorization assumptions.

A maintainer must review the evidence before assigning the status.

## Artifact Changes

Safety status follows artifacts, not filenames.

Changing safety-critical runtime code, hardware authorization logic,
containment behavior, destructive primitive behavior, or relevant build
artifacts invalidates assumptions attached to the previous artifact.

The modified artifact must be tested at the level appropriate to the
change.

A modified artifact does not inherit PHYSICAL PASS merely because it was
derived from one that passed.

## Evidence Record

A physical prosecution record should contain:

- hardware identity;
- profile identity;
- source revision;
- relevant SHA-256 hashes;
- test objective;
- observed execution;
- failures and corrections;
- final result;
- known limitations; and
- explicit status.

Public evidence must pass the project's publication gates for secrets,
personal information, repository hygiene, and unsupported release
claims.

## Destructive Testing Rule

**Do not perform a destructive test merely to complete documentation,
an issue template, or a pull request.**

Physical prosecution is deliberate destructive testing conducted on
hardware designated for that purpose.

## Governing Principle

OLLITERATOR does not guess.

If OLLITERATOR cannot prove which storage device it is authorized to
destroy, it destroys nothing.
