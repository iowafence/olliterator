#!/usr/bin/env bash
set -euo pipefail

# OLLITERATOR Ubuntu ISO builder
#
# This script implements the documented public build procedure derived
# from the build sequence used for OLLITERATOR v0.2.
#
# IMPORTANT:
# A newly built ISO is a new artifact. It does not inherit the
# prosecution status or artifact hashes of a physically prosecuted ISO.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
    cat <<USAGE
Usage:
  $0 BASE_ISO OUTPUT_ISO OLLI_WIPE_BINARY

Example:
  $0 \
    ~/Downloads/ubuntu-24.04.1-desktop-amd64.iso \
    ~/Downloads/olliterator.iso \
    /path/to/olli-wipe
USAGE
}

[ "$#" -eq 3 ] || {
    usage
    exit 2
}

BASE_ISO_INPUT="$1"
OUTPUT_ISO="$2"
WIPE_BIN_INPUT="$3"

[ -f "$BASE_ISO_INPUT" ] || {
    echo "REFUSED: base ISO not found: $BASE_ISO_INPUT"
    exit 10
}

[ -x "$WIPE_BIN_INPUT" ] || {
    echo "REFUSED: olli-wipe binary missing or not executable: $WIPE_BIN_INPUT"
    exit 11
}

BASE_ISO="$(readlink -f "$BASE_ISO_INPUT")"
WIPE_BIN="$(readlink -f "$WIPE_BIN_INPUT")"

for cmd in xorriso unmkinitramfs cpio sha256sum grep find cmp install sed awk readlink mktemp; do
    command -v "$cmd" >/dev/null 2>&1 || {
        echo "REFUSED: required command not found: $cmd"
        exit 12
    }
done

COMMON="$ROOT/runtime/olliterator-common.sh"
STAGE="$ROOT/runtime/provision-stage.sh"
HOOK="$ROOT/runtime/hooks/02olliterator-provision"
PROFILE="$ROOT/profiles/microsoft/surface-go-2/64gb-emmc.conf"
GRUB="$ROOT/installer/ubuntu/grub-provision.cfg"
AUTOINSTALL="$ROOT/installer/ubuntu/autoinstall.example.yaml"

for f in "$COMMON" "$STAGE" "$HOOK" "$PROFILE" "$GRUB" "$AUTOINSTALL"; do
    [ -f "$f" ] || {
        echo "REFUSED: required source file missing: $f"
        exit 13
    }
done

echo "=== VERIFYING FROZEN SOURCE COMPONENTS ==="

check_hash() {
    expected="$1"
    file="$2"

    actual="$(sha256sum "$file" | awk '{print $1}')"

    [ "$actual" = "$expected" ] || {
        echo "REFUSED: hash mismatch"
        echo "File:     $file"
        echo "Expected: $expected"
        echo "Actual:   $actual"
        exit 20
    }

    echo "PASS: $file"
}

check_hash \
    7bd74492f1c5368188e67e86ae000d44205666add3bf359e181e69cde58421a3 \
    "$COMMON"

check_hash \
    f438de9dd44dfd4470a48e6bb5c9f2a26ed7841e672999b88690b33b2b7f8f21 \
    "$STAGE"

check_hash \
    4001861e58569308538867bd39723f3e57fea373a8981f16d8eaa587ee3c0096 \
    "$HOOK"

check_hash \
    26ee3ed5b7c2950901de656a5b199f114060d94e80810caf367aa1a6684e9741 \
    "$ROOT/src/olli-wipe.c"

check_hash \
    9ab4509cbef124d3abad0e6a17d72211a536e155b8e400bc429c0e5d5bc879d1 \
    "$PROFILE"

check_hash \
    1a1f5ed28bc9808288cfc8f7379389d415bbcdff82e1c986003e7e8ccc09fe31 \
    "$GRUB"

echo
echo "=== VERIFYING DESTRUCTIVE PRIMITIVE ==="

WIPE_HASH="$(sha256sum "$WIPE_BIN" | awk '{print $1}')"

[ "$WIPE_HASH" = \
  "9460edea30e00b037d48cd39ebd38e0f9f88f33f18bf001d0ad373bd78adfafe" ] || {
    echo "REFUSED: olli-wipe binary does not match prosecuted primitive"
    echo "Actual: $WIPE_HASH"
    exit 21
}

echo "PASS: prosecuted olli-wipe binary"

WORK_ROOT="$ROOT/build/work"
mkdir -p "$WORK_ROOT"

WORK="$(mktemp -d "$WORK_ROOT/olliterator-build.XXXXXX")"

cleanup() {
    rm -rf "$WORK"
}
trap cleanup EXIT

INITRD="$WORK/initrd"
mkdir -p "$INITRD"

echo
echo "=== EXTRACTING STOCK INITRD ==="

xorriso \
    -osirrox on \
    -indev "$BASE_ISO" \
    -extract /casper/initrd "$WORK/stock-initrd" \
    >/dev/null 2>&1

unmkinitramfs "$WORK/stock-initrd" "$INITRD"

echo
echo "=== INSTALLING OLLITERATOR ==="

mkdir -p \
    "$INITRD/olliterator/runtime" \
    "$INITRD/olliterator/profiles" \
    "$INITRD/olliterator/bin"

install -m 0755 \
    "$COMMON" \
    "$INITRD/olliterator/runtime/olliterator-common.sh"

install -m 0755 \
    "$STAGE" \
    "$INITRD/olliterator/provision-stage.sh"

install -m 0644 \
    "$PROFILE" \
    "$INITRD/olliterator/profiles/surface-go-2-64gb.conf"

install -m 0755 \
    "$WIPE_BIN" \
    "$INITRD/olliterator/bin/olli-wipe"

install -m 0755 \
    "$HOOK" \
    "$INITRD/scripts/init-top/02olliterator-provision"

ORDER="$INITRD/scripts/init-top/ORDER"

[ -f "$ORDER" ] || {
    echo "REFUSED: init-top ORDER not found"
    exit 30
}

# Remove historical OLLITERATOR execution entries before inserting the
# provision hook immediately after udev.
sed -i \
    '\#/scripts/init-top/0[0-9]olliterator-#d' \
    "$ORDER"

sed -i \
    '\#/scripts/init-top/udev "\$@"#a /scripts/init-top/02olliterator-provision "$@"' \
    "$ORDER"

COUNT="$(grep -Fc \
    '/scripts/init-top/02olliterator-provision "$@"' \
    "$ORDER")"

[ "$COUNT" -eq 1 ] || {
    echo "REFUSED: provision hook ORDER is not unique"
    exit 31
}

awk '
    $0 == "/scripts/init-top/udev \"$@\"" {
        if (getline nextline) {
            if (nextline == "/scripts/init-top/02olliterator-provision \"$@\"" ) {
                found = 1
            }
        }
    }
    END { exit(found ? 0 : 1) }
' "$ORDER" || {
    echo "REFUSED: provision hook is not immediately after udev"
    exit 32
}

echo "PASS: provision hook uniquely ordered immediately after udev"

echo
echo "=== REPACKING INITRD ==="

(
    cd "$INITRD"
    find . -print0 |
        cpio --null -o --format=newc > "$WORK/initrd.olliterator"
)

echo
echo "=== VERIFYING REPACKED INITRD ==="

VERIFY="$WORK/verify-initrd"
mkdir -p "$VERIFY"

unmkinitramfs "$WORK/initrd.olliterator" "$VERIFY"

cmp -s \
    "$COMMON" \
    "$VERIFY/olliterator/runtime/olliterator-common.sh" ||
    {
        echo "REFUSED: packaged common runtime differs"
        exit 40
    }

cmp -s \
    "$STAGE" \
    "$VERIFY/olliterator/provision-stage.sh" ||
    {
        echo "REFUSED: packaged provision stage differs"
        exit 41
    }

cmp -s \
    "$HOOK" \
    "$VERIFY/scripts/init-top/02olliterator-provision" ||
    {
        echo "REFUSED: packaged provision hook differs"
        exit 42
    }

cmp -s \
    "$PROFILE" \
    "$VERIFY/olliterator/profiles/surface-go-2-64gb.conf" ||
    {
        echo "REFUSED: packaged hardware profile differs"
        exit 43
    }

cmp -s \
    "$WIPE_BIN" \
    "$VERIFY/olliterator/bin/olli-wipe" ||
    {
        echo "REFUSED: packaged destructive primitive differs"
        exit 44
    }

echo "PASS: packaged OLLITERATOR components verified"

echo
echo "=== BUILDING ISO ==="

rm -f "$OUTPUT_ISO"

xorriso \
    -indev "$BASE_ISO" \
    -outdev "$OUTPUT_ISO" \
    -boot_image any replay \
    -map "$GRUB" /boot/grub/grub.cfg \
    -map "$WORK/initrd.olliterator" /casper/initrd \
    -map "$AUTOINSTALL" /autoinstall.yaml \
    -commit

echo
echo "=== RESULT ==="
sha256sum "$OUTPUT_ISO"

echo
echo "IMPORTANT:"
echo "This ISO is a newly built artifact."
echo "It does not inherit PHYSICAL PASS from another artifact."
