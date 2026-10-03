# Contributing to OLLITERATOR

OLLITERATOR sits directly in front of destructive storage operations.

Contributions are welcome, but convenience does not outrank certainty.

> **If a patch makes Olliterator guess, it is a regression and will be closed.**

## Core Rule

OLLITERATOR must positively identify both:

1. supported hardware; and
2. exactly one permitted destructive target.

Ambiguity is failure.

Examples:

- zero matching targets -> REFUSE
- exactly one matching target -> MAY AUTHORIZE
- two matching targets -> REFUSE
- changed target identity between authorization stages -> REFUSE
- unsupported hardware -> REFUSE
- incomplete evidence -> REFUSE

Do not introduce fallback selection such as:

- first disk;
- smallest disk;
- largest disk;
- first non-removable disk;
- first NVMe/eMMC/SATA disk;
- disk zero;
- likely boot disk;
- best match;
- closest match.

More evidence belongs in the authorization model.

It does not justify guessing.

## Hardware Support Is Evidence-Based

A configuration file does not make hardware supported.

Hardware profiles move through the following project states:

- EXPERIMENTAL
- CANDIDATE
- PHYSICAL PASS
- REPEATABILITY PASS
- SUSPENDED
- REVOKED

Only project maintainers assign official prosecution status.

### EXPERIMENTAL

Initial profile or hardware evidence exists.

No destructive-support claim is permitted.

### CANDIDATE

The profile and selector have passed the project's required
non-destructive and synthetic checks.

Physical destructive behavior has not yet received PHYSICAL PASS.

### PHYSICAL PASS

The identified artifact/profile combination has completed the project's
physical prosecution procedure on the specified hardware.

A PHYSICAL PASS applies only to the prosecuted configuration and
identified artifacts.

### REPEATABILITY PASS

Required physical prosecution has been successfully repeated according
to the project's current prosecution procedure.

### SUSPENDED

Previously accepted support has been temporarily withdrawn pending
investigation or re-prosecution.

### REVOKED

Previously accepted support has been withdrawn.

## Hardware Profile Contributions

A new hardware profile should include evidence sufficient to understand
the hardware identity and storage topology.

Useful evidence can include:

- manufacturer;
- exact product/model;
- DMI identity;
- storage device names;
- exact device sizes in bytes;
- removable flags;
- bus/topology information;
- relevant sysfs information;
- relevant `lsblk` output;
- relevant `udevadm` output.

Do not publish credentials, private keys, customer information, employee
information, or unnecessary unique device identifiers.

A profile submission does not authorize the submitter to label hardware
PHYSICAL PASS or REPEATABILITY PASS.

## Do Not Destroy Hardware for a Pull Request

**Do not perform a destructive test merely to complete an issue or pull
request.**

Physical prosecution is a controlled project activity.

If maintainers need additional physical evidence, that requirement
should be identified explicitly before destructive testing occurs.

## Destructive Primitive

Changes to the destructive primitive receive additional scrutiny.

The primitive must independently reject a target that does not satisfy
its own required invariants.

Authorization in a shell script is not a substitute for validation at
the destructive boundary.

## Runtime and Containment

Failure must not fall through into an installer or another destructive
path.

Changes affecting:

- target selection;
- target authentication;
- re-authentication;
- destructive authorization;
- wipe execution;
- failure containment; or
- installer handoff

must preserve fail-closed behavior.

## Shell Code

Use the interpreter declared by the script.

Do not assume that every runtime environment supports Bash features.

Critical operations should have explicit failure handling. Avoid
uncontrolled fall-through at destructive boundaries.

## Tests

Tests should be non-destructive by default.

CI must never destructively operate arbitrary host block devices.

Synthetic selector tests and wipe tests should use controlled fixtures,
regular files, loop-safe test mechanisms, or other explicitly isolated
test targets as appropriate.

## Publication Hygiene

Public contributions must pass four publication gates.

### Gate 1 — Secrets

Do not commit:

- passwords;
- password hashes used by real systems;
- API credentials;
- access tokens;
- private keys;
- `.env` files;
- authentication cookies;
- production credentials.

### Gate 2 — Personal and Internal Information

Remove unnecessary:

- employee names;
- customer information;
- device serial numbers;
- UUIDs;
- MAC addresses;
- WWNs;
- internal usernames;
- workstation paths;
- private infrastructure names;
- unrelated company infrastructure details.

Information required as technical evidence should be minimized to what
the evidence actually requires.

### Gate 3 — Repository Hygiene

The public repository should contain only information relevant to
OLLITERATOR, its implementation, its evidence, and its operation.

Do not include unrelated development history, transient working notes,
local-environment details, or other unnecessary provenance metadata.

Comments should explain the code and its safety properties rather than
narrate its development history.

### Gate 4 — Release Claims

Do not claim:

- support for hardware that has not reached the stated prosecution
  status;
- PHYSICAL PASS without the corresponding prosecution record;
- REPEATABILITY PASS without the corresponding evidence;
- secure sanitization when only provisioning metadata destruction was
  performed;
- provenance for an artifact whose hashes do not match the documented
  record.

## Commit Hygiene

Keep commits reviewable.

Do not mix unrelated infrastructure, credentials, internal notes, or
development artifacts into a contribution.

Generated ISOs, unpacked operating-system trees, transient build output,
and local logs should not be committed unless a project release process
explicitly requires a reviewed artifact.

## Safety-Critical Findings

Do not publicly disclose a target-selection bypass, destructive
authorization bypass, or containment failure before maintainers have
had an opportunity to review it privately.

See `SECURITY.md`.

## License

By contributing to OLLITERATOR, you agree that your contribution is
licensed under the Apache License, Version 2.0.
