#!/bin/sh

# OLLITERATOR frozen-runtime conformance checks.
#
# This test does not access host block devices and does not invoke
# destructive code. It verifies the identity and safety-relevant
# structure of the frozen selector runtime represented by the
# synthetic selector model.

set -u

RUNTIME="runtime/olliterator-common.sh"
EXPECTED_HASH="7bd74492f1c5368188e67e86ae000d44205666add3bf359e181e69cde58421a3"

PASS=0
FAIL=0

pass() {
    PASS=$((PASS + 1))
    printf 'PASS: %s\n' "$1"
}

fail() {
    FAIL=$((FAIL + 1))
    printf 'FAIL: %s\n' "$1"
}

require_literal() {
    DESC="$1"
    TEXT="$2"

    if grep -Fq -- "$TEXT" "$RUNTIME"; then
        pass "$DESC"
    else
        fail "$DESC"
    fi
}

forbid_literal() {
    DESC="$1"
    TEXT="$2"

    if grep -Fq -- "$TEXT" "$RUNTIME"; then
        fail "$DESC"
    else
        pass "$DESC"
    fi
}

echo "OLLITERATOR frozen-runtime conformance"
echo

ACTUAL_HASH="$(sha256sum "$RUNTIME" | awk '{print $1}')"

if [ "$ACTUAL_HASH" = "$EXPECTED_HASH" ]; then
    pass "frozen runtime SHA-256"
else
    fail "frozen runtime SHA-256"
    printf '  expected: %s\n' "$EXPECTED_HASH"
    printf '  actual:   %s\n' "$ACTUAL_HASH"
fi

if sh -n "$RUNTIME"; then
    pass "runtime sh syntax"
else
    fail "runtime sh syntax"
fi

require_literal \
    "DMI vendor equality predicate" \
    '[ "$OLLI_VENDOR" = "$DMI_VENDOR" ]'

require_literal \
    "DMI product equality predicate" \
    '[ "$OLLI_PRODUCT" = "$DMI_PRODUCT" ]'

require_literal \
    "whole-device partition exclusion" \
    '[ ! -e "$SYS/partition" ] || continue'

require_literal \
    "pseudo-device exclusions" \
    'loop*|ram*|zram*|dm-*|md*)'

require_literal \
    "sector value validation" \
    "''|*[!0-9]*) continue ;;"

require_literal \
    "removable value validation" \
    '0|1) ;;'

require_literal \
    "sector-to-byte conversion" \
    'BYTES=$((SECTORS * 512))'

require_literal \
    "non-removable requirement" \
    '[ "$REMOVABLE" = "0" ] || continue'

require_literal \
    "USB topology exclusion" \
    '*"/usb"*|*"/usb[0-9]"*)'

require_literal \
    "exact byte-size predicate" \
    '[ "$BYTES" -eq "$TARGET_SIZE_BYTES" ] || continue'

require_literal \
    "profile removable predicate" \
    '[ "$REMOVABLE" = "$TARGET_REMOVABLE" ] || continue'

require_literal \
    "candidate increment" \
    'OLLI_CANDIDATES=$((OLLI_CANDIDATES + 1))'

require_literal \
    "zero-candidate refusal" \
    '0) olli_refuse "NO ELIGIBLE TARGET" 20 ;;'

require_literal \
    "ambiguous-candidate refusal" \
    '*) olli_refuse "AMBIGUOUS TARGET SET" 21 ;;'

require_literal \
    "selected block-device existence boundary" \
    '[ -b "/dev/$OLLI_TARGET" ] ||'

require_literal \
    "missing block-device refusal" \
    'olli_refuse "TARGET BLOCK DEVICE MISSING" 22'

# These fields exist in the current profile but are deliberately not
# consumed as authorization predicates by olliterator-common.sh.

forbid_literal \
    "TARGET_NAME is not consumed by frozen runtime" \
    '$TARGET_NAME'

forbid_literal \
    "PROFILE_ID is not consumed by frozen runtime" \
    '$PROFILE_ID'

forbid_literal \
    "OBSERVED_SERIAL is not consumed by frozen runtime" \
    '$OBSERVED_SERIAL'

# Serial is observed independently into OLLI_SERIAL, but not compared.
require_literal \
    "physical serial is observationally read" \
    'OLLI_SERIAL="$(olli_read1 /sys/class/dmi/id/product_serial 2>/dev/null || true)"'

forbid_literal \
    "observed serial is not equality-authorized" \
    '[ "$OLLI_SERIAL" ='

echo
echo "RESULT: $PASS passed / $FAIL failed"

[ "$FAIL" -eq 0 ] || exit 1

echo "RUNTIME CONFORMANCE: PASS"
