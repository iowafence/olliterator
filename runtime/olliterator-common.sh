#!/bin/sh

olli_refuse() {
    echo
    echo "OLLITERATOR: REFUSED"
    echo "REASON: $1"
    exit "${2:-1}"
}

olli_read1() {
    [ -r "$1" ] || return 1
    cat "$1"
}

olli_auth_dmi() {
    OLLI_VENDOR="$(olli_read1 /sys/class/dmi/id/sys_vendor 2>/dev/null || true)"
    OLLI_PRODUCT="$(olli_read1 /sys/class/dmi/id/product_name 2>/dev/null || true)"
    OLLI_SERIAL="$(olli_read1 /sys/class/dmi/id/product_serial 2>/dev/null || true)"

    [ "$OLLI_VENDOR" = "$DMI_VENDOR" ] ||
        olli_refuse "UNSUPPORTED VENDOR" 10

    [ "$OLLI_PRODUCT" = "$DMI_PRODUCT" ] ||
        olli_refuse "UNSUPPORTED PRODUCT" 11
}

olli_select_target() {
    OLLI_CANDIDATES=0
    OLLI_TARGET=""
    OLLI_TARGET_BYTES=""

    for SYS in /sys/class/block/*; do
        [ -e "$SYS" ] || continue

        NAME="${SYS##*/}"

        # Whole block devices only.
        [ ! -e "$SYS/partition" ] || continue

        case "$NAME" in
            loop*|ram*|zram*|dm-*|md*)
                continue
                ;;
        esac

        SECTORS="$(olli_read1 "$SYS/size" 2>/dev/null || true)"
        REMOVABLE="$(olli_read1 "$SYS/removable" 2>/dev/null || true)"
        REAL="$(readlink -f "$SYS" 2>/dev/null || true)"

        case "$SECTORS" in
            ''|*[!0-9]*) continue ;;
        esac

        case "$REMOVABLE" in
            0|1) ;;
            *) continue ;;
        esac

        BYTES=$((SECTORS * 512))

        # Never target removable media.
        [ "$REMOVABLE" = "0" ] || continue

        # Never target anything under USB topology, even if RM lies.
        case "$REAL" in
            *"/usb"*|*"/usb[0-9]"*)
                continue
                ;;
        esac

        [ "$BYTES" -eq "$TARGET_SIZE_BYTES" ] || continue
        [ "$REMOVABLE" = "$TARGET_REMOVABLE" ] || continue

        OLLI_CANDIDATES=$((OLLI_CANDIDATES + 1))
        OLLI_TARGET="$NAME"
        OLLI_TARGET_BYTES="$BYTES"
    done

    case "$OLLI_CANDIDATES" in
        0) olli_refuse "NO ELIGIBLE TARGET" 20 ;;
        1) ;;
        *) olli_refuse "AMBIGUOUS TARGET SET" 21 ;;
    esac

    [ -b "/dev/$OLLI_TARGET" ] ||
        olli_refuse "TARGET BLOCK DEVICE MISSING" 22
}

olli_auth_all() {
    olli_auth_dmi
    olli_select_target
}
