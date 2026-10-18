#!/usr/bin/env bash
# Select the tested RAM-image codec on Microsoft Surface hardware.
set -euo pipefail

main() {
    local product kernel parameter=/sys/module/hibernate/parameters/compressor current
    product="$(cat /sys/class/dmi/id/product_name)"
    kernel="$(uname -r)"
    if [[ "$product" != Surface* ]]; then
        printf 'Surface LZ4 selection skipped on %s / %s.\n' "$product" "$kernel"
        return 0
    fi
    if [[ ! -r "$parameter" || ! -w "$parameter" ]]; then
        printf 'Hibernation compressor control unavailable or not writable.\n' >&2
        return 1
    fi
    current="$(< "$parameter")"
    if [[ "$current" != lzo && "$current" != lz4 ]]; then
        printf 'Unexpected compressor %s; preserving it.\n' "$current" >&2
        return 1
    fi

    # Loading the library for zram is not enough: the crypto provider is needed.
    modprobe crypto-lz4
    if ! awk '
        /^name[[:space:]]*:/ {name=$NF}
        /^selftest[[:space:]]*:/ {
            if (name == "lz4") {found++; if ($NF != "passed") failed++}
        }
        /^[[:space:]]*$/ {name=""}
        END {exit !(found && !failed)}
    ' /proc/crypto; then
        printf 'No self-tested LZ4 crypto provider; compressor unchanged.\n' >&2
        return 1
    fi

    if [[ "$(< "$parameter")" != "$current" ]]; then
        printf 'Compressor changed during provider preparation; preserving it.\n' >&2
        return 1
    fi
    if [[ "$current" != lz4 ]]; then
        # The kernel rejects this write with EBUSY during a power transition.
        printf 'lz4\n' > "$parameter"
    fi
    if [[ "$(< "$parameter")" != lz4 ]]; then
        printf 'LZ4 parameter read-back failed; inspect before hibernating.\n' >&2
        return 1
    fi

    local image_size_path=/sys/power/image_size target_image_size=4800000000
    if [[ -r "$image_size_path" && -w "$image_size_path" ]]; then
        if [[ "$(< "$image_size_path")" != "$target_image_size" ]]; then
            printf '%s\n' "$target_image_size" > "$image_size_path"
        fi
        if [[ "$(< "$image_size_path")" != "$target_image_size" ]]; then
            printf 'Hibernation image_size read-back failed (expected %s).\n' "$target_image_size" >&2
            return 1
        fi
    fi

    printf 'Surface hibernation RAM-image compressor verified: lz4 (image_size=%s).\n' "$(cat "$image_size_path" 2>/dev/null || echo unknown)"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main
fi
