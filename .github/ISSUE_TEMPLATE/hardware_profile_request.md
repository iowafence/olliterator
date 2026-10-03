---
name: Hardware profile request
about: Submit evidence for evaluation of a new hardware profile
title: "[PROFILE] "
labels: hardware-profile
assignees: ''
---

# Hardware Profile Request

> **Do not perform a destructive test merely to complete this issue
> template.**

Submitting hardware information does not make the hardware officially
supported.

Project maintainers assign prosecution status.

## Hardware

**Manufacturer:**

**Exact model/product:**

**Architecture:**

## DMI Information

Provide the relevant manufacturer/product identity.

Redact unnecessary unique identifiers.

```text
PASTE RELEVANT DMI INFORMATION HERE
```

## Storage Topology

Provide relevant `lsblk` output including device name, type, exact size,
removable status, and transport where available.

```text
PASTE RELEVANT LSBLK OUTPUT HERE
```

## Candidate Internal Target

**Device name:**

**Exact size in bytes:**

**Storage type (eMMC/NVMe/SATA/etc.):**

**Removable flag:**

## Relevant sysfs Evidence

```text
PASTE RELEVANT SYSFS INFORMATION HERE
```

## Relevant udev Evidence

```text
PASTE RELEVANT UDEV INFORMATION HERE
```

## Other Storage Devices Present

Describe any other internal or external storage visible during boot.

## Observed Boot Environment

Describe how OLLITERATOR or the diagnostic environment was booted.

## Existing OLLITERATOR Testing

Check only what has actually occurred.

- [ ] Evidence collection only
- [ ] Synthetic/non-destructive testing
- [ ] Candidate profile created
- [ ] No destructive testing performed

Do not self-declare PHYSICAL PASS or REPEATABILITY PASS.

## Additional Notes

Include anything unusual about the storage topology or hardware.

Before submitting, remove credentials, personal information, employee
information, customer information, and unnecessary unique identifiers.
