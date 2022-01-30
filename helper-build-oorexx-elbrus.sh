#!/usr/bin/env bash

    # Helper to build oorexx on Elbrus Linux

    # Requires cmake
    # PATH will need to include ~/tools/oorexx/bin

    # For Regina Rexx and ooRexx to co-exist, ooRexx must be in a different
    # directory and come first in the PATH.

    # Create our work directory
    mkdir -p ~/tools
    cd ~/tools

    # Download and extract source package
    svn checkout svn://svn.code.sf.net/p/oorexx/code-0/main/trunk oorexx-code

    mkdir -p oorexx-build && cd oorexx-build

    # Configure package, and point to a local install directory
    cmake ../oorexx-code -DCMAKE_INSTALL_PREFIX=~/tools/oorexx

    time make
    make install

    export PATH=~/tools/oorexx/bin:$PATH
    export CFLAGS="-I$HOME/tools/oorexx/include"
    export LDFLAGS="-L$HOME/tools/oorexx/lib64"
    export LD_LIBRARY_PATH=$HOME/tools/oorexx/lib64
    hash -r
