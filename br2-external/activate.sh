#!/bin/sh
if [ -n "${SDK_ACTIVE:-}" ]; then
    return
else
    _get_sourced_file() {
        if [ -n "${BASH_SOURCE:-}" ]; then
            echo "${BASH_SOURCE}"
            return
        fi

        lsof +p $$ -Fn0 2>/dev/null | tr -dc '[:print:][:space:]' | \
            sed -E 's/^f[0-9]+.?n//g' | grep -v '^/dev' | tail -n1
    }

    _get_scriptdir() {
        (cd "$(dirname "$(_get_sourced_file)")" && pwd)
    }

    _sdk_dir="$(_get_scriptdir)"
    "${_sdk_dir}/relocate-sdk.sh" 1>/dev/null

    SYSROOT="$(find "${_sdk_dir}" -maxdepth 2 -mindepth 2 -type d -name sysroot |\
               tail -n1)"
    SYSROOT="$(cd "${SYSROOT}" && pwd)"

    export SYSROOT
    export QEMU_LD_PREFIX="${SYSROOT}"

    if ! echo "$PATH" | grep -qF "${_sdk_dir}/bin:"; then
        export PATH="${_sdk_dir}/bin:${PATH}"
    fi

    #@cmd_exports@
    #@flag_exports@

    CROSS_COMPILE="$(echo "$CC" | sed 's/-gcc$/-/g')"
    export CROSS_COMPILE

    unset _sdk_dir
    unset _get_scriptdir
    unset _get_sourced_file
    export PS1="(sdk) ${PS1}"
    export SDK_ACTIVE=1
fi
