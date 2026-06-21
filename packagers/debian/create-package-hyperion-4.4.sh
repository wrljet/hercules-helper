#!/usr/bin/env bash

printf '%s\n' \
    'This legacy Hyperion 4.4 Debian packager is retired.' \
    'Its package template is not present in this repository, and its original workflow used unsafe dynamic command execution and fixed local paths.' \
    'Build Hercules with hercules-buildall.sh and create a package from a maintained Debian packaging tree instead.' >&2
exit 2
