#!/usr/bin/env bash

hh_regina_prepare_environment()
{
    local config prefix bin_dir include_dir lib_dir
    config="$(command -v regina-config 2>/dev/null || true)"
    if [ -z "$config" ] && [ -n "${HERCULES_REGINA_PREFIX:-}" ] && [ -x "$HERCULES_REGINA_PREFIX/bin/regina-config" ]; then
        config="$HERCULES_REGINA_PREFIX/bin/regina-config"
    fi
    [ -n "$config" ] || return 1

    prefix="$("$config" --prefix 2>/dev/null)" || return 1
    bin_dir="$prefix/bin"
    include_dir="$prefix/include"
    if [ -d "$prefix/lib64" ]; then lib_dir="$prefix/lib64"; else lib_dir="$prefix/lib"; fi
    [ -x "$bin_dir/regina" ] && [ -d "$include_dir" ] && [ -d "$lib_dir" ] || return 1

    PATH="$bin_dir:$PATH"
    CPPFLAGS="-I$include_dir${CPPFLAGS:+ $CPPFLAGS}"
    LDFLAGS="-L$lib_dir${LDFLAGS:+ $LDFLAGS}"
    export PATH CPPFLAGS LDFLAGS
    if [ "$(uname -s)" = Darwin ]; then
        DYLD_LIBRARY_PATH="$lib_dir${DYLD_LIBRARY_PATH:+:$DYLD_LIBRARY_PATH}"
        export DYLD_LIBRARY_PATH
    else
        LD_LIBRARY_PATH="$lib_dir${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
        export LD_LIBRARY_PATH
    fi
    HERCULES_REGINA_PREFIX="$prefix"
    HERCULES_REGINA_LIBDIR="$lib_dir"
    export HERCULES_REGINA_PREFIX HERCULES_REGINA_LIBDIR
}

hh_regina_version()
{
    local output status
    output="$(regina -v 2>&1)"
    status=$?
    if [ "$status" -ne 0 ]; then
        printf 'Regina executable failed (status %s):\n%s\n' "$status" "$output" >&2
        return "$status"
    fi
    printf '%s\n' "$output"
}

hh_regina_stage_macos_tests()
{
    local build_dir="$1" link_path
    [ "$(uname -s)" = Darwin ] || return 0
    [ -n "${HERCULES_REGINA_LIBDIR:-}" ] || return 0
    [ -f "$HERCULES_REGINA_LIBDIR/libregina.dylib" ] || return 0
    mkdir -p "$build_dir/.libs" || return 1
    link_path="$build_dir/.libs/libregina.dylib"
    rm -f "$link_path"
    ln -s "$HERCULES_REGINA_LIBDIR/libregina.dylib" "$link_path" || return 1
    HH_REGINA_TEST_LINK="$link_path"
    export HH_REGINA_TEST_LINK
    printf 'Staging Regina for macOS tests: %s\n' "$HERCULES_REGINA_LIBDIR/libregina.dylib"
}

hh_regina_unstage_macos_tests()
{
    [ -n "${HH_REGINA_TEST_LINK:-}" ] || return 0
    rm -f "$HH_REGINA_TEST_LINK"
    HH_REGINA_TEST_LINK=
}
