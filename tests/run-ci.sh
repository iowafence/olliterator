#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

EXPECTED_COMMON="7bd74492f1c5368188e67e86ae000d44205666add3bf359e181e69cde58421a3"
EXPECTED_STAGE="f438de9dd44dfd4470a48e6bb5c9f2a26ed7841e672999b88690b33b2b7f8f21"
EXPECTED_HOOK="4001861e58569308538867bd39723f3e57fea373a8981f16d8eaa587ee3c0096"
EXPECTED_SOURCE="26ee3ed5b7c2950901de656a5b199f114060d94e80810caf367aa1a6684e9741"
EXPECTED_PROFILE="9ab4509cbef124d3abad0e6a17d72211a536e155b8e400bc429c0e5d5bc879d1"
EXPECTED_GRUB="1a1f5ed28bc9808288cfc8f7379389d415bbcdff82e1c986003e7e8ccc09fe31"

check_hash() {
    local expected="$1"
    local file="$2"
    local actual

    actual="$(sha256sum "$file" | awk '{print $1}')"

    if [[ "$actual" != "$expected" ]]; then
        echo "FAIL: hash mismatch: $file"
        echo "expected: $expected"
        echo "actual:   $actual"
        exit 1
    fi

    echo "PASS: frozen identity: $file"
}

echo "=== FROZEN / CONTROLLED IDENTITIES ==="
check_hash "$EXPECTED_COMMON" runtime/olliterator-common.sh
check_hash "$EXPECTED_STAGE" runtime/provision-stage.sh
check_hash "$EXPECTED_HOOK" runtime/hooks/02olliterator-provision
check_hash "$EXPECTED_SOURCE" src/olli-wipe.c
check_hash "$EXPECTED_PROFILE" profiles/microsoft/surface-go-2/64gb-emmc.conf
check_hash "$EXPECTED_GRUB" installer/ubuntu/grub-provision.cfg

echo
echo "=== SHELL SYNTAX ==="
sh -n runtime/olliterator-common.sh
sh -n runtime/provision-stage.sh
sh -n runtime/hooks/02olliterator-provision
sh -n tests/selector/test-selector-model.sh
sh -n tests/selector/test-runtime-conformance.sh
bash -n tests/wipe/test-wipe.sh
bash -n build/build-ubuntu.sh
echo "PASS: shell syntax"

echo
echo "=== SELECTOR MODEL ==="
./tests/selector/test-selector-model.sh

echo
echo "=== RUNTIME CONFORMANCE ==="
./tests/selector/test-runtime-conformance.sh

echo
echo "=== WIPE PRIMITIVE ==="
bash tests/wipe/test-wipe.sh

echo
echo "=== STATIC PRODUCTION COMPILE ==="
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

gcc -O2 -Wall -Wextra -Werror -static \
    src/olli-wipe.c \
    -o "$TMP/olli-wipe"

file "$TMP/olli-wipe"

if file "$TMP/olli-wipe" | grep -q 'statically linked'; then
    echo "PASS: production primitive is statically linked"
else
    echo "FAIL: production primitive is not statically linked"
    exit 1
fi

echo
echo "=== CI DESTRUCTIVE-PATH GUARD ==="

if grep -RniE \
    '(^|[[:space:]])(sudo[[:space:]]+)?(wipefs|blkdiscard|mkfs(\.[A-Za-z0-9_-]+)?|fdisk|sfdisk|parted)[[:space:]]|/dev/(sd[a-z]|nvme[0-9]|mmcblk[0-9])' \
    tests .github/workflows
then
    echo "FAIL: CI/test tree contains a host block-device or destructive command reference"
    exit 1
fi

echo "PASS: no host block-device/destructive command path in CI/test tree"

echo
echo "CI: PASS"
