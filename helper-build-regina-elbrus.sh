#!/usr/bin/env bash

    # Helper to build oorexx on Elbrus Linux
    # PATH will need to include ~/tools/bin

    # For Regina Rexx and ooRexx to co-exist, ooRexx must be in a different
    # directory and come first in the PATH.

    helper_dir="$(dirname "$0")"

    # Create our work directory
    mkdir -p ~/tools
    cd ~/tools

    # Download and extract source package
    wget http://www.wrljet.com/ibm360/regina-rexx-3.9.3.tar.gz
    tar xfz regina-rexx-3.9.3.tar.gz 
    cd regina-rexx-3.9.3/

    # Patch/replace config.guess with ones from Hercules-Helper
    cp $helper_dir/patches/config.{guess,sub} .
    cp config.{guess,sub} common/

    # export CC=clang

    # Configure package, and point to a local install directory
    ./configure --enable-64bit  --prefix=$HOME/tools

    make clean
    time make
    make install

    export LD_LIBRARY_PATH=~/tools/lib:$LD_LIBRARY_PATH
    export PATH=~/tools/bin:$PATH
    hash -r

