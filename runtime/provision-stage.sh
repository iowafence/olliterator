#!/bin/sh
set -u

BASE=/olliterator
PROFILE="$BASE/profiles/surface-go-2-64gb.conf"
COMMON="$BASE/runtime/olliterator-common.sh"
WIPE_BIN="$BASE/bin/olli-wipe"

. "$PROFILE"
. "$COMMON"

echo
echo "=============================================="
echo " OLLITERATOR v0.2 — AUTO PROVISION"
echo "=============================================="
echo

echo "=== AUTH #1 ==="
olli_auth_all
FIRST_TARGET="$OLLI_TARGET"
FIRST_BYTES="$OLLI_TARGET_BYTES"

echo
echo "AUTH #1: PASS"
echo "TARGET : $FIRST_TARGET"
echo "BYTES  : $FIRST_BYTES"

unset OLLI_TARGET OLLI_TARGET_BYTES
sync
sleep 2

echo
echo "=== AUTH #2 — FRESH HARDWARE READ ==="
olli_auth_all
SECOND_TARGET="$OLLI_TARGET"
SECOND_BYTES="$OLLI_TARGET_BYTES"

echo
echo "AUTH #2: PASS"
echo "TARGET : $SECOND_TARGET"
echo "BYTES  : $SECOND_BYTES"

[ "$FIRST_TARGET" = "$SECOND_TARGET" ] || {
    echo "REFUSED: TARGET CHANGED BETWEEN AUTHENTICATIONS"
    exit 30
}

[ "$FIRST_BYTES" = "$SECOND_BYTES" ] || {
    echo "REFUSED: TARGET SIZE CHANGED BETWEEN AUTHENTICATIONS"
    exit 31
}

TARGET_DEV="/dev/$SECOND_TARGET"

[ -b "$TARGET_DEV" ] || {
    echo "REFUSED: TARGET IS NO LONGER A BLOCK DEVICE"
    exit 32
}

[ -x "$WIPE_BIN" ] || {
    echo "REFUSED: OLLI-WIPE PRIMITIVE NOT AVAILABLE"
    exit 33
}

echo
echo "DESTRUCTIVE AUTHORIZATION: PASS"
echo
echo "*** WIPE BEGIN ***"

"$WIPE_BIN" "$TARGET_DEV" "$SECOND_BYTES" || {
    rc=$?
    echo "REFUSED: OLLI-WIPE FAILED rc=$rc"
    exit 40
}

echo
echo "*** WIPE COMPLETE ***"
echo "OLLITERATOR v0.2 WIPE: PASS"
echo
echo "HANDOFF AUTHORIZED: UBUNTU AUTOINSTALL"
echo

sync
exit 0
