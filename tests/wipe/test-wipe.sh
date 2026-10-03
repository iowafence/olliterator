#!/bin/sh

# OLLITERATOR wipe primitive synthetic tests.
#
# All destructive operations in this suite target regular files created
# inside a temporary directory. No block device path is accepted by the
# harness.
#
# The test build uses OLLI_ALLOW_REGULAR.
# The production build does not.

set -u

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)"
SRC="$ROOT/src/olli-wipe.c"

TMP="$(mktemp -d)"
TEST_BIN="$TMP/olli-wipe-test"
PROD_BIN="$TMP/olli-wipe-production"

PASS=0
FAIL=0

cleanup() {
    rm -rf "$TMP"
}
trap cleanup EXIT HUP INT TERM

pass() {
    PASS=$((PASS + 1))
    printf 'PASS: %s\n' "$1"
}

fail() {
    FAIL=$((FAIL + 1))
    printf 'FAIL: %s\n' "$1"
}

run_expect_rc() {
    DESC="$1"
    EXPECTED_RC="$2"
    shift 2

    set +e
    "$@" >"$TMP/stdout" 2>"$TMP/stderr"
    RC=$?
    set -e

    if [ "$RC" -eq "$EXPECTED_RC" ]; then
        pass "$DESC (rc=$RC)"
    else
        fail "$DESC (expected rc=$EXPECTED_RC, got rc=$RC)"
        printf '%s\n' "--- stdout ---"
        cat "$TMP/stdout"
        printf '%s\n' "--- stderr ---"
        cat "$TMP/stderr"
    fi
}

set -e

echo "OLLITERATOR synthetic wipe primitive"
echo

echo "=== COMPILE ==="

cc -O2 -Wall -Wextra -Werror \
    -DOLLI_ALLOW_REGULAR \
    "$SRC" \
    -o "$TEST_BIN"

pass "test primitive compiled with OLLI_ALLOW_REGULAR"

cc -O2 -Wall -Wextra -Werror \
    "$SRC" \
    -o "$PROD_BIN"

pass "production primitive compiled without regular-file allowance"

echo
echo "=== SUCCESS CASE ==="

IMAGE="$TMP/success.img"

dd if=/dev/zero bs=1M count=64 status=none |
    tr '\000' '\252' > "$IMAGE"

BEFORE_SIZE="$(stat -c %s "$IMAGE")"

run_expect_rc \
    "64 MiB regular-file wipe succeeds in test build" \
    0 \
    "$TEST_BIN" "$IMAGE" "$BEFORE_SIZE"

if dd if="$IMAGE" bs=1M count=16 status=none |
    cmp -s - <(dd if=/dev/zero bs=1M count=16 status=none)
then
    pass "front 16 MiB zeroed"
else
    fail "front 16 MiB zeroed"
fi

if dd if="$IMAGE" bs=1M skip=48 count=16 status=none |
    cmp -s - <(dd if=/dev/zero bs=1M count=16 status=none)
then
    pass "tail 16 MiB zeroed"
else
    fail "tail 16 MiB zeroed"
fi

if dd if="$IMAGE" bs=1M skip=16 count=32 status=none |
    tr -d '\252' |
    test ! -s /dev/stdin
then
    pass "middle 32 MiB preserved"
else
    fail "middle 32 MiB preserved"
fi

echo
echo "=== SIZE MISMATCH ==="

MISMATCH="$TMP/mismatch.img"
dd if=/dev/zero bs=1M count=64 status=none |
    tr '\000' '\125' > "$MISMATCH"

MISMATCH_BEFORE="$(sha256sum "$MISMATCH" | awk '{print $1}')"

run_expect_rc \
    "expected-size mismatch refuses" \
    22 \
    "$TEST_BIN" "$MISMATCH" 67108863

MISMATCH_AFTER="$(sha256sum "$MISMATCH" | awk '{print $1}')"

if [ "$MISMATCH_BEFORE" = "$MISMATCH_AFTER" ]; then
    pass "size-mismatch refusal leaves file unchanged"
else
    fail "size-mismatch refusal leaves file unchanged"
fi

echo
echo "=== TOO SMALL ==="

SMALL="$TMP/small.img"
dd if=/dev/zero bs=1M count=31 status=none |
    tr '\000' '\173' > "$SMALL"

SMALL_SIZE="$(stat -c %s "$SMALL")"
SMALL_BEFORE="$(sha256sum "$SMALL" | awk '{print $1}')"

run_expect_rc \
    "target below 32 MiB refuses" \
    22 \
    "$TEST_BIN" "$SMALL" "$SMALL_SIZE"

SMALL_AFTER="$(sha256sum "$SMALL" | awk '{print $1}')"

if [ "$SMALL_BEFORE" = "$SMALL_AFTER" ]; then
    pass "too-small refusal leaves file unchanged"
else
    fail "too-small refusal leaves file unchanged"
fi

echo
echo "=== BAD EXPECTED SIZE ==="

run_expect_rc \
    "nonnumeric expected size refuses" \
    10 \
    "$TEST_BIN" "$SMALL" "not-a-number"

echo
echo "=== PRODUCTION TYPE BOUNDARY ==="

PROD_FILE="$TMP/production-refusal.img"
dd if=/dev/zero bs=1M count=64 status=none |
    tr '\000' '\314' > "$PROD_FILE"

PROD_SIZE="$(stat -c %s "$PROD_FILE")"
PROD_BEFORE="$(sha256sum "$PROD_FILE" | awk '{print $1}')"

run_expect_rc \
    "production build refuses regular file" \
    21 \
    "$PROD_BIN" "$PROD_FILE" "$PROD_SIZE"

PROD_AFTER="$(sha256sum "$PROD_FILE" | awk '{print $1}')"

if [ "$PROD_BEFORE" = "$PROD_AFTER" ]; then
    pass "production regular-file refusal leaves file unchanged"
else
    fail "production regular-file refusal leaves file unchanged"
fi

echo
echo "RESULT: $PASS passed / $FAIL failed"

[ "$FAIL" -eq 0 ] || exit 1

echo "WIPE PRIMITIVE: PASS"
