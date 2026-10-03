#!/bin/sh

# OLLITERATOR synthetic selector model tests.
#
# This suite models the selection predicates implemented by the frozen
# runtime without accessing host /sys, host /dev, or destructive code.
#
# It does NOT replace physical prosecution and does NOT claim to execute
# the frozen runtime's real sysfs enumeration path.

set -u

PASS=0
FAIL=0

TARGET_SIZE_BYTES=62537072640
TARGET_REMOVABLE=0

pass() {
    PASS=$((PASS + 1))
    printf 'PASS: %s\n' "$1"
}

fail() {
    FAIL=$((FAIL + 1))
    printf 'FAIL: %s\n' "$1"
}

# Arguments:
#   name
#   sectors
#   removable
#   topology
#   whole
#
# Return:
#   0 = eligible
#   1 = excluded
eligible() {
    NAME="$1"
    SECTORS="$2"
    REMOVABLE="$3"
    TOPOLOGY="$4"
    WHOLE="$5"

    [ "$WHOLE" = "1" ] || return 1

    case "$NAME" in
        loop*|ram*|zram*|dm-*|md*)
            return 1
            ;;
    esac

    case "$SECTORS" in
        ''|*[!0-9]*)
            return 1
            ;;
    esac

    case "$REMOVABLE" in
        0|1)
            ;;
        *)
            return 1
            ;;
    esac

    BYTES=$((SECTORS * 512))

    [ "$REMOVABLE" = "0" ] || return 1

    case "$TOPOLOGY" in
        *"/usb"*|*"/usb"[0-9]*)
            return 1
            ;;
    esac

    [ "$BYTES" -eq "$TARGET_SIZE_BYTES" ] || return 1
    [ "$REMOVABLE" = "$TARGET_REMOVABLE" ] || return 1

    return 0
}

# Candidate records:
#
# name|sectors|removable|topology|whole
#
# Output:
#   REFUSE:NO_ELIGIBLE_TARGET
#   SELECT:<name>
#   REFUSE:AMBIGUOUS_TARGET_SET
select_from_records() {
    COUNT=0
    SELECTED=""

    while IFS='|' read -r NAME SECTORS REMOVABLE TOPOLOGY WHOLE; do
        [ -n "$NAME" ] || continue

        if eligible \
            "$NAME" \
            "$SECTORS" \
            "$REMOVABLE" \
            "$TOPOLOGY" \
            "$WHOLE"
        then
            COUNT=$((COUNT + 1))
            SELECTED="$NAME"
        fi
    done

    case "$COUNT" in
        0)
            printf '%s\n' "REFUSE:NO_ELIGIBLE_TARGET"
            ;;
        1)
            printf '%s\n' "SELECT:$SELECTED"
            ;;
        *)
            printf '%s\n' "REFUSE:AMBIGUOUS_TARGET_SET"
            ;;
    esac
}

run_case() {
    NAME="$1"
    EXPECTED="$2"
    DATA="$3"

    ACTUAL="$(
        printf '%s\n' "$DATA" |
            select_from_records
    )"

    if [ "$ACTUAL" = "$EXPECTED" ]; then
        pass "$NAME -> $ACTUAL"
    else
        fail "$NAME -> expected $EXPECTED, got $ACTUAL"
    fi
}

VALID_SECTORS=122142720
WRONG_SECTORS=122142719

INTERNAL_TOPOLOGY="/devices/platform/soc/mmc_host/mmc0/mmc0:0001/block/mmcblk0"
USB_TOPOLOGY="/devices/pci0000:00/usb1/1-1/1-1:1.0/host0/target0/block/sda"

echo "OLLITERATOR synthetic selector model"
echo

run_case \
    "zero candidates" \
    "REFUSE:NO_ELIGIBLE_TARGET" \
    ""

run_case \
    "one valid candidate" \
    "SELECT:mmcblk0" \
    "mmcblk0|$VALID_SECTORS|0|$INTERNAL_TOPOLOGY|1"

run_case \
    "removable impostor" \
    "REFUSE:NO_ELIGIBLE_TARGET" \
    "sda|$VALID_SECTORS|1|/devices/platform/internal/block/sda|1"

run_case \
    "USB device with removable flag lying" \
    "REFUSE:NO_ELIGIBLE_TARGET" \
    "sda|$VALID_SECTORS|0|$USB_TOPOLOGY|1"

run_case \
    "wrong size" \
    "REFUSE:NO_ELIGIBLE_TARGET" \
    "mmcblk0|$WRONG_SECTORS|0|$INTERNAL_TOPOLOGY|1"

run_case \
    "two valid candidates" \
    "REFUSE:AMBIGUOUS_TARGET_SET" \
    "mmcblk0|$VALID_SECTORS|0|$INTERNAL_TOPOLOGY|1
nvme0n1|$VALID_SECTORS|0|/devices/pci0000:00/nvme/nvme0/block/nvme0n1|1"

run_case \
    "valid candidate plus USB device" \
    "SELECT:mmcblk0" \
    "mmcblk0|$VALID_SECTORS|0|$INTERNAL_TOPOLOGY|1
sda|$VALID_SECTORS|0|$USB_TOPOLOGY|1"

run_case \
    "pseudo device" \
    "REFUSE:NO_ELIGIBLE_TARGET" \
    "loop0|$VALID_SECTORS|0|/devices/virtual/block/loop0|1"

echo
echo "RESULT: $PASS passed / $FAIL failed"

[ "$PASS" -eq 8 ] || exit 1
[ "$FAIL" -eq 0 ] || exit 1

echo "SELECTOR MODEL: PASS"
