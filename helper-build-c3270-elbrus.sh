#!/usr/bin/env bash

    # Helper to build suite3270 (c3270, x3270, etc) on Elbrus Linux

    # PATH will need to include ~/tools/bin

    helper_dir="$(dirname "$0")"

    # Create our work directory
    mkdir -p ~/tools
    cd ~/tools

    wget http://x3270.bgp.nu/download/04.00/suite3270-4.0ga13-src.tgz
    tar xfz suite3270-4.0ga13-src.tgz 
    cd suite3270-4.0/

    # Patch/replace config.guess with ones from Hercules-Helper
    cp $helper_dir/patches/config.{guess,sub} .

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

