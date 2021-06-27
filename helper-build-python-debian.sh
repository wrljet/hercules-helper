#!/usr/bin/env bash

# helper-build-python-debian.sh

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

This script will install prerequisite packages, and download, build
and install Python 3.9.5.

Your sudo password will be required.
"

    echo "$msg"

    echo "which -a python3"
    which -a python3
    echo #
    echo "python3 -V"
    python3 -V

    read -p "Ctrl+C to abort here, or hit return to continue"

  # sudo apt-get install openssl openssl-dev libssl-dev
    sudo apt-get install openssl libssl-dev

    mkdir -p ~/tools
    pushd ~/tools

    wget "https://www.python.org/ftp/python/3.9.5/Python-3.9.5.tgz"
    tar xfz Python-3.9.5.tgz 
    cd Python-3.9.5/

    ./configure
    make
    sudo make install
    hash -r

    # cd someplace else so we don't find a cmake in the same directory
    cd ..
    which -a python3
    python3 -V

    popd

