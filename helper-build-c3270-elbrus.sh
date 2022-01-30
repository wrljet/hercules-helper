#!/usr/bin/env bash

    # Helper to build suite3270 (c3270, x3270, etc) on Elbrus Linux

    # PATH and LD_LIBRARY_PATH will need to be set
    #

    # Stop on errors and trace everything we do here
    set -e
    set -x

    # FIXME: this doesn't work if this script is running off a symlink
    SCRIPT_PATH=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")
    SCRIPT_DIR="$(dirname $SCRIPT_PATH)"

    # Create our work directory
    mkdir -p ~/tools
    cd ~/tools

    wget http://x3270.bgp.nu/download/04.00/suite3270-4.0ga13-src.tgz
    tar xfz suite3270-4.0ga13-src.tgz 
    cd suite3270-4.0/

    # Patch/replace config.guess with ones from Hercules-Helper
    cp $SCRIPT_DIR/patches/config.{guess,sub} .

    # Test config.guess
    ./config.guess 

    # Configure package, enabling c3270, and point to a local install directory
    ./configure -C --enable-unix --enable-c3270 \
        --prefix=$HOME/tools \
        --bindir=$HOME/tools/bin \
        --sysconfdir=$HOME/tools/etc \
        --with-fontdir=$HOME/tools/fonts/3270

    make clean && make -j 2
    make install

