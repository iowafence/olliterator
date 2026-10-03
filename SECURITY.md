# Security Policy

OLLITERATOR operates at a destructive boundary.

A safety or security vulnerability includes any defect, race,
validation bypass, or containment failure that could cause OLLITERATOR
to authorize destructive action against:

- an unintended storage target;
- unsupported hardware;
- an ambiguous multi-disk environment;
- a target whose authenticated properties changed before destruction;
- a target not independently accepted by the destructive primitive; or
- a system after destructive authorization has failed.

## Reporting a Vulnerability

**Do not open a public GitHub issue for a safety-critical validation
bypass or destructive-target authorization flaw.**

Document, where possible:

- OLLITERATOR version;
- release artifact and SHA-256;
- hardware manufacturer and exact model;
- storage topology;
- hardware profile;
- exact observed behavior;
- expected behavior;
- whether the source or artifact was modified.

Do not casually reproduce destructive behavior against valuable
hardware, production machines, or data you need.

Private reporting instructions will be published with the first public
release after the project's monitored security-reporting channel is
confirmed.

## Expected / Out-of-Scope Behavior

### Data recovery after the provisioning wipe

The current OLLITERATOR provisioning wipe destroys storage metadata at
the beginning and end of the target device.

It is not a complete-media overwrite or secure sanitization system.

The possibility that raw data remains recoverable after the current
provisioning wipe is therefore not, by itself, a vulnerability.

### Arbitrarily modified builds

The project's prosecution results apply to the identified artifacts and
hardware profiles.

A locally modified build does not inherit the prosecution status of an
official release artifact.

### Physical attackers

OLLITERATOR currently boots into a privileged transient environment.
Protection against an unrestricted malicious actor with physical
console access is outside the current threat model.

## Safety First

If you are uncertain whether a finding could cause OLLITERATOR to
destroy the wrong storage device, treat it as safety-critical and do
not publish reproduction instructions until maintainers have reviewed
it.
