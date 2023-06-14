#!/usr/bin/env bash

# This file is part of the Hercules-Helper project.
#
# Display existing Hercules binaries

echo "Looking for existing Hercules binaries ..."

find / -path /System/Volumes -prune -false -o -name hercules -type f \( -perm -u=x -o -perm -g=x -o -perm -o=x \) -exec test -x {} \; -print 2>/dev/null

