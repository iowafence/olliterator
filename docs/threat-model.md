# OLLITERATOR Threat Model

This document defines the current threat model for OLLITERATOR.

OLLITERATOR is a destructive authorization layer for unattended hardware
reprovisioning. Its primary safety concern is preventing destructive
action against the wrong storage device or unsupported hardware.

This threat model does not claim protection against every attacker or
every failure mode.

## 1. Assets at Risk

The primary assets protected by OLLITERATOR are:

- storage devices that are not authorized destruction targets;
- data on unintended storage devices;
- unsupported hardware;
- the integrity of the destructive authorization decision; and
- the integrity of the transition from authorization to installer
  handoff.

## 2. Primary Safety Threat

The primary threat is incorrect destructive authorization.

Examples include:

- selecting the wrong disk;
- selecting one disk from multiple plausible disks;
- accepting unsupported hardware;
- treating removable media as the internal target;
- accepting a device based on an incomplete hardware match;
- acting on stale target information;
- continuing after an authorization failure; or
- handing control to an installer after destructive authorization has
  failed.

OLLITERATOR addresses these threats through deterministic hardware
profiles, exact candidate requirements, re-authentication, independent
validation at the destructive boundary, and fail-closed containment.

## 3. Ambiguous Storage Topology

An ambiguous storage topology is treated as unsafe.

OLLITERATOR does not attempt to determine which candidate is probably
correct.

If the authorization model produces more than one valid candidate,
destructive authorization must fail.

Additional disks, unusual firmware exposure, changed enumeration, or
unexpected storage topology may therefore cause a supported machine to
refuse operation.

That refusal is expected behavior.

## 4. Removable and Boot Media

Boot media must not become a destructive target merely because it
resembles expected storage.

The active hardware profile and runtime must distinguish permitted
internal storage from removable or otherwise excluded storage.

A removable-state inconsistency or unexpected topology must not be
resolved through a fallback selection heuristic.

## 5. Time-of-Check / Time-of-Use

Storage observations can change between initial discovery and
destructive execution.

OLLITERATOR therefore treats stale authorization as a threat.

Safety-critical target properties must be re-authenticated before the
destructive boundary according to the active runtime's requirements.

If the target disappears, changes, becomes ambiguous, or no longer
satisfies the required invariants, operation must fail closed.

## 6. Destructive Primitive Boundary

Upstream authorization may contain defects.

OLLITERATOR therefore treats the destructive primitive as an additional
validation boundary rather than a passive write utility.

The primitive must independently reject targets that fail the
invariants assigned to it.

A caller claiming that a target is valid is not sufficient evidence.

## 7. Failure Fall-Through

A failed authorization path that continues execution is a safety threat.

OLLITERATOR must contain failures so that refusal cannot accidentally
continue into:

- destructive execution;
- another destructive path; or
- unattended installer handoff.

A visible error message without execution containment is insufficient.

## 8. Modified or Unprosecuted Artifacts

Physical prosecution applies to identified artifacts.

Modified source, rebuilt binaries, changed profiles, altered initrds, or
different final media do not automatically inherit the prosecution
status of the artifact from which they were derived.

Artifact identity and hashes are therefore part of release provenance.

## 9. Unsupported Hardware

Unknown hardware is not an opportunity for best-effort matching.

Unsupported hardware must fail closed.

Similarity to supported hardware is not authorization.

A new hardware family or storage configuration requires evidence,
profile development, testing, and the applicable prosecution process.

## 10. Secure Erasure Is Not a Security Claim

The current provisioning wipe destroys metadata regions required by the
supported reprovisioning workflow.

OLLITERATOR does not currently claim complete-media secure sanitization.

Recovery of residual raw data outside the provisioning metadata regions
is therefore outside the current wipe guarantee.

## 11. Physical Attackers

OLLITERATOR currently assumes the boot environment and prosecuted
artifact have not been maliciously replaced by an unrestricted attacker
with physical control of the machine.

Protection against an attacker capable of arbitrarily modifying the
boot media, runtime, kernel, firmware, or executing privileged code is
outside the current threat model.

Future authenticated-boot or artifact-verification mechanisms may
change this boundary.

## 12. Malicious Kernel or Firmware

OLLITERATOR relies on information exposed by the running operating
environment.

A malicious kernel or compromised firmware capable of deliberately
fabricating storage or hardware identity information is outside the
current threat model.

## 13. Hardware Failure

OLLITERATOR can detect some inconsistent observations but cannot
guarantee correct behavior from physically failing storage,
controllers, memory, firmware, or other hardware.

Unexpected or inconsistent evidence should result in refusal where
detectable.

OLLITERATOR does not claim to make defective hardware trustworthy.

## 14. Denial of Service

Fail-closed behavior intentionally makes denial of service easier than
unsafe continuation.

An unexpected device, missing property, changed topology, or failed
validation may prevent reprovisioning.

This is preferable to destroying an uncertain target.

Availability does not outrank destructive safety.

## 15. Installer Boundary

After authorized destructive execution succeeds, OLLITERATOR may hand
control to an installer.

OLLITERATOR does not claim to provide a general security boundary around
all downstream installer behavior.

However, OLLITERATOR must not authorize that handoff when its own
required destructive stage has failed.

## 16. Development and CI

Ordinary CI is not a physical prosecution environment.

Tests should use synthetic or explicitly isolated fixtures and must not
destructively operate arbitrary host block devices.

Passing CI demonstrates the properties covered by those tests.

It does not independently establish physical hardware support.

## 17. Reporting Boundary Failures

A finding should be treated as safety-critical when it could permit:

- unsupported hardware to pass authorization;
- an unintended target to become uniquely authorized;
- ambiguity to be silently resolved;
- re-authentication to be bypassed;
- destructive-boundary validation to be bypassed; or
- failure to fall through into destructive action or installer handoff.

See `SECURITY.md` for reporting guidance.

## 18. Governing Tradeoff

OLLITERATOR intentionally prefers refusal over uncertain availability.

A false refusal can stop a reprovisioning job.

A false authorization can destroy the wrong data.

Those outcomes are not equivalent.
