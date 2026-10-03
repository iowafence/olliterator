# OLLITERATOR Safety Model

This document defines the safety invariants governing OLLITERATOR.

These requirements are normative.

OLLITERATOR is a fail-closed destructive authorization layer for
unattended hardware reprovisioning.

Its job is not to find the most likely storage device.

Its job is to establish that destructive action is authorized against
exactly one permitted target.

> **Olliterator does not guess.**

## 1. Safety Objective

OLLITERATOR must not authorize destructive action unless:

1. the running hardware matches an explicitly supported hardware profile;
2. storage enumeration produces exactly one permitted target;
3. that target satisfies every required profile invariant;
4. the target remains the same through re-authentication;
5. the destructive primitive independently validates its required
   invariants; and
6. destructive execution completes successfully before installer
   handoff is authorized.

Any ambiguity or failed invariant results in refusal.

## 2. Fail-Closed Rule

The default outcome is refusal.

OLLITERATOR must refuse when:

- hardware identity does not match;
- required evidence is unavailable;
- zero storage targets qualify;
- more than one storage target qualifies;
- target properties change between authorization stages;
- the target is no longer a valid block device;
- destructive-boundary validation fails;
- wipe execution fails;
- wipe completion cannot be established; or
- an unexpected runtime condition prevents certainty.

Failure must not silently fall through to destructive action or
installer handoff.

## 3. Hardware Identity

A hardware profile defines the identity OLLITERATOR is permitted to
recognize.

Required identity evidence may include:

- DMI manufacturer;
- DMI product;
- architecture;
- storage topology;
- exact storage size;
- removable state; and
- other deterministic properties required by the profile.

Observational identifiers are not authorization requirements unless the
profile explicitly declares them as such.

Adding evidence to a profile may increase certainty.

Removing uncertainty by selecting the "best" candidate is prohibited.

## 4. Storage Enumeration

OLLITERATOR evaluates whole storage devices.

Pseudo-devices and storage classes outside the supported target model
must not become destructive candidates merely because they resemble a
disk.

The selector must exclude devices that violate the active profile's
requirements.

A valid authorization set contains exactly one candidate.

```text
0 candidates  -> REFUSE
1 candidate   -> CONTINUE
2+ candidates -> REFUSE
```

Candidate ordering must not affect authorization.

## 5. No Selection Heuristics

OLLITERATOR must not resolve ambiguity using fallback heuristics.

Prohibited strategies include selecting:

- the first disk;
- disk zero;
- the smallest disk;
- the largest disk;
- the first non-removable disk;
- the first eMMC device;
- the first NVMe device;
- the first SATA device;
- the apparent boot disk;
- the highest-scoring candidate; or
- the candidate that most closely resembles the expected target.

If two devices satisfy the authorization model, the authorization model
is insufficient.

The correct result is refusal.

## 6. Re-Authentication

Authorization must not rely solely on an earlier observation when the
destructive action occurs later.

Before destructive execution, OLLITERATOR must re-evaluate the
safety-critical target identity required by the active runtime.

The re-authenticated target must agree with the previously authorized
target.

A changed, missing, additional, or ambiguous target causes refusal.

## 7. Destructive Boundary

The destructive primitive is an independent safety boundary.

The primitive must validate the invariants assigned to it rather than
assuming that upstream authorization was correct.

For the current primitive this includes, at minimum:

- valid input;
- expected target type; and
- exact expected target size.

Failure at the destructive boundary must prevent destructive completion
from being reported.

## 8. Provisioning Wipe

The current wipe operation destroys provisioning metadata at the
beginning and end of the authorized target.

It is intended to invalidate existing partition/filesystem metadata
sufficiently for the supported reprovisioning workflow.

It is **not secure sanitization**.

OLLITERATOR must not describe this operation as securely erasing all
recoverable user data.

## 9. Completion and Verification

Successful destructive execution must be positively established.

A partial write, failed synchronization, failed close, or other
incomplete destructive operation must not be reported as successful.

Installer handoff requires successful completion of the authorized
destructive stage.

## 10. Installer Handoff

The installer is downstream of OLLITERATOR's destructive authorization
boundary.

OLLITERATOR may hand execution to an unattended installer only after the
required authorization and destructive stages succeed.

Failure before authorized handoff must terminate or enter a contained
failure state.

Failure must not continue into installation.

## 11. Physical Separation of Artifacts

OLLITERATOR may provide separate boot artifacts for different
operational purposes.

The current design intentionally distinguishes:

- WIPE / RECOVERY; and
- AUTO PROVISION.

A wipe/recovery artifact must not accidentally become an auto-provision
artifact through failure fall-through.

Artifact separation is part of the safety model.

## 12. Hardware Support and Prosecution

A hardware profile alone is not proof of safe destructive operation.

Official support status follows the project's prosecution lifecycle:

- EXPERIMENTAL
- CANDIDATE
- PHYSICAL PASS
- REPEATABILITY PASS
- SUSPENDED
- REVOKED

PHYSICAL PASS applies only to the prosecuted hardware/profile/artifact
combination represented by its evidence.

Changes to safety-critical components may require re-prosecution.

## 13. Safety-Critical Components

Safety-critical components include:

- hardware profiles;
- hardware identity logic;
- storage enumeration;
- candidate filtering;
- target authentication;
- re-authentication;
- destructive authorization;
- destructive primitives;
- failure containment;
- installer handoff; and
- prosecution evidence used to establish support claims.

Changes to these components require safety review.

## 14. CI Boundary

Continuous integration must not perform destructive operations against
arbitrary host block devices.

Automated testing should use controlled synthetic targets or explicitly
isolated fixtures.

Physical prosecution is separate from ordinary CI.

## 15. Governing Principle

When OLLITERATOR cannot prove which target it is permitted to destroy,
it destroys nothing.

More evidence may improve the authorization model.

Guessing may not.
