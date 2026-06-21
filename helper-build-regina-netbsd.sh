#!/usr/bin/env bash

# helper-build-regina-netbsd.sh
#
# Helper to build Regina REXX on NetBSD
#
# The most recent version of this project can be obtained with:
#   git clone https://github.com/wrljet/hercules-helper.git
# or:
#   wget https://github.com/wrljet/hercules-helper/archive/master.zip
#
# Please report errors in this to me so everyone can benefit.
#
# Bill Lewis  bill@wrljet.com
#
#-----------------------------------------------------------------------------
#
# This works for me, but should be considered just an example

# NOT YET READY FOR USE!

msg="$(basename "$0"):

This script will build and install Regina REXX on NetBSD.

Your sudo password will be required.
"
echo "$msg"
read -p "Ctrl+C to abort here, or hit return to continue"

#-----------------------------------------------------------------------------
# 'realpath' doesn't exist on MacOS or BSDs
# SCRIPT_PATH=$(dirname $(realpath -s $0))

SCRIPT_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
SCRIPT_PATH="$SCRIPT_DIR/$(basename "${BASH_SOURCE[0]}")"
source "$SCRIPT_DIR/lib/hercules-helper/common.sh"
WORK_DIR="$(pwd)"

if test "$WORK_DIR" = "$SCRIPT_DIR"; then
#   echo "Cannot build in the script directory"
    printf "\033[1;31merror: \033[0mCannot build in the script directory\n"
    exit 1
fi

msg="
$(basename "$0"):

This script will download, build and install Regina-REXX 3.9.3 on NetBSD.

Run this from the directory where you want the Regina sources.

It will install locally.
"

    echo "$msg"

    echo "SCRIPT_PATH = $SCRIPT_PATH"
    echo "SCRIPT_DIR  = $SCRIPT_DIR"
    echo "WORK_DIR    = $WORK_DIR"

    echo "which -a regina"
    which -a regina
    echo #

    read -p "Ctrl+C to abort here, or hit return to continue"

# Building Regina REXX

    hh_download_verified "https://gist.github.com/wrljet/8581fda46d64392fc6874f0142ad5a80/raw/0f943d464acda87fb34882277a20dde770f77d0c/Regina-REXX-3.9.7.tar.gz" \
        Regina-REXX-3.9.7.tar.gz f13701ebd542e74d0fc83b2a7876a812b07d21e43400275ed65b1ac860204bd4
    hh_extract_tar_gz Regina-REXX-3.9.7.tar.gz .
    cd regina-rexx-3.9.7

    cp $SCRIPT_DIR/patches/config.* common/

# Patch configure
    patch -u configure -i "$SCRIPT_DIR/patches/regina-rexx-3.9.3.patch"

    CFLAGS="-Wno-error=implicit-function-declaration" ./configure --enable-64bit --prefix=$WORK_DIR/rexx
    gmake clean
    gmake

# install
    gmake install
    cd ..

# these must be added to the bash profile
    export PATH="$WORK_DIR/rexx/bin:$PATH"
    export LD_LIBRARY_PATH="$WORK_DIR/rexx/lib:$LD_LIBRARY_PATH"
    export CPPFLAGS="$CPPFLAGS -I $WORK_DIR/rexx/include"

# test the installation
    which regina
    regina -v
