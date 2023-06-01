#!/usr/bin/env bash

echo -ne '\a'; sleep 0.2; echo -ne '\a'

msg="hyperion-buildall.sh is deprecated.  Please use hercules-buildall.sh instead."

printf "\033[1;31m$msg\033[0m\n"

exit 1

