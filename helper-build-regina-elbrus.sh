#!/usr/bin/env bash

    # Helper to build oorexx on Elbrus Linux

    # PATH and LD_LIBRARY_PATH will need to be set
    #
    # export LD_LIBRARY_PATH=~/tools/lib:$LD_LIBRARY_PATH
    # export PATH=~/tools/bin:$PATH

    # For Regina Rexx and ooRexx to co-exist, ooRexx must be in a different
    # directory and come first in the PATH.

    # Stop on errors and trace everything we do here
    set -e
    set -x

    # FIXME: this doesn't work if this script is running off a symlink
    SCRIPT_PATH=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")
    SCRIPT_DIR="$(dirname $SCRIPT_PATH)"

    # Create our work directory
    mkdir -p ~/tools
    cd ~/tools

    # Download and extract source package
    wget http://www.wrljet.com/ibm360/regina-rexx-3.9.3.tar.gz
    tar xfz regina-rexx-3.9.3.tar.gz 
    cd regina-rexx-3.9.3/

    # Replace config.guess with ones from Hercules-Helper
    cp $SCRIPT_DIR/patches/config.{guess,sub} .
    cp config.{guess,sub} common/

    # Patch configure to understand e2k CPU
    patch -u configure -i "$SCRIPT_DIR/patches/regina-rexx-3.9.3.patch"

    # export CC=clang

    # Configure package, and point to a local install directory
    ./configure --enable-64bit  --prefix=$HOME/tools

    make clean
    time make
    make install

