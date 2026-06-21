#!/usr/bin/env bash

# helper-build-oorexx-elbrus.sh
#
# Helper to build ooRexx on Elbrus Linux

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

msg="$(basename "$0"):

This script will build and install ooRexx on Elbrus Linux.

Your sudo password will be required.
"
echo "$msg"
read -p "Ctrl+C to abort here, or hit return to continue"

#-----------------------------------------------------------------------------
# Requires cmake

# To use the oorexx built by this script when building Hercules:
#
# PATH and LD_LIBRARY_PATH will need to be set
#
# export PATH=~/tools/oorexx/bin:$PATH
# export CFLAGS="-I$HOME/tools/oorexx/include"
# export LDFLAGS="-L$HOME/tools/oorexx/lib64"
# export LD_LIBRARY_PATH=$HOME/tools/oorexx/lib64

# For Regina Rexx and ooRexx to co-exist and for Hercules to
# configure and build correctly, ooRexx must be in a different
# directory and must come first in the PATH.

# Stop on errors and trace everything we do here
set -e
set -x

SCRIPT_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "$SCRIPT_DIR/lib/hercules-helper/common.sh"

# Create our work directory
mkdir -p ~/tools
cd ~/tools

# Download and extract source package
hh_safe_rm_rf "$HOME/tools" oorexx-code
svn checkout -r 13169 https://svn.code.sf.net/p/oorexx/code-0/main/trunk oorexx-code

mkdir -p oorexx-build && cd oorexx-build

# Configure package, and point to a local install directory
cmake ../oorexx-code -DCMAKE_INSTALL_PREFIX=~/tools/oorexx

time make
make install
