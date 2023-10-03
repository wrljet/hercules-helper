#!/usr/bin/env bash

# NOT YET READY FOR USE!

# The most recent version of this project can be obtained with:
#   git clone https://github.com/wrljet/hercules-helper.git
# or:
#   wget https://github.com/wrljet/hercules-helper/archive/master.zip
#
# Please report errors in this to me so everyone can benefit.
#
# Bill Lewis  bill@wrljet.com

#-----------------------------------------------------------------------------

# 'realpath' doesn't exist on MacOS or BSDs
# SCRIPT_PATH=$(dirname $(realpath -s $0))

# FIXME: this doesn't work if this script is running off a symlink
SCRIPT_PATH=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR="$(dirname $SCRIPT_PATH)"
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

    wget "http://www.wrljet.com/ibm360/regina-rexx-3.9.3.tar.gz"
    tar xfz regina-rexx-3.9.3.tar.gz
    cd regina-rexx-3.9.3

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

