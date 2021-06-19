#!/usr/bin/env bash

# The most recent version of this project can be obtained with:
#   git clone https://github.com/wrljet/hercules-helper.git
# or:
#   wget https://github.com/wrljet/hercules-helper/archive/master.zip
#
# Please report errors in this to me so everyone can benefit.
#
# Bill Lewis  bill@wrljet.com

#-----------------------------------------------------------------------------

msg="$(basename "$0"):

This script will download, build and install ncat.

Your sudo password will be required.
"

    echo "$msg"

    echo "which ncat"
    which ncat
    echo #

    read -p "Ctrl+C to abort here, or hit return to continue"

    mkdir -p ~/tools
    pushd ~/tools

    wget "https://nmap.org/dist/nmap-7.91.tar.bz2"
    bzip2 -cd nmap-7.91.tar.bz2 | tar xvf -
    cd nmap-7.91/

    ./configure
    make
    sudo make install
    hash -r

    # cd someplace else so we don't find a cmake in the same directory
    cd ..
    ncat --version

    popd

