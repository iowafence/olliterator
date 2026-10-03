# OLLITERATOR Pull Request

## What Changed?

Describe the change and why it is needed.

## Safety Impact

Does this change affect any of the following?

- [ ] hardware identification
- [ ] target selection
- [ ] target authentication
- [ ] re-authentication
- [ ] destructive authorization
- [ ] destructive primitive
- [ ] failure containment
- [ ] installer handoff
- [ ] hardware profiles
- [ ] prosecution evidence
- [ ] none of the above

If any safety-sensitive item is checked, explain the effect:

## Testing

Describe exactly what was tested.

Do not claim destructive or physical testing that did not occur.

## Fail-Closed Review

- [ ] zero valid targets refuse
- [ ] multiple valid targets refuse
- [ ] unsupported hardware refuses
- [ ] changed target identity refuses
- [ ] failure cannot fall through into destructive action
- [ ] failure cannot fall through into installer handoff

Mark items not applicable only when the change cannot affect that
invariant.

## Publication Gates

I reviewed this contribution for:

- [ ] secrets and credentials
- [ ] personal/customer/employee/internal information
- [ ] unnecessary development history or provenance metadata
- [ ] unsupported or overstated release claims

## Generated Artifacts

- [ ] This PR does not add generated destructive media or build output
- [ ] Any intentionally included artifact is documented and hashed

## Hardware Status

If this PR changes a hardware profile:

**Current status:**

**Requested status:**

**Supporting prosecution record:**

A pull request does not independently establish PHYSICAL PASS or
REPEATABILITY PASS.

## Final Check

- [ ] This change does not make OLLITERATOR guess.
