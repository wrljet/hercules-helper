#!/usr/bin/env bash

# helper-build-regina-elbrus.sh
#
# Helper to build Regina REXX on Elbrus Linux
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

msg="$(basename "$0"):

This script will build and install Regina REXX on Elbrus Linux.

Your sudo password will be required.
"
echo "$msg"
read -p "Ctrl+C to abort here, or hit return to continue"

#-----------------------------------------------------------------------------
# To use the oorexx built by this script when building Hercules:
#
# PATH and LD_LIBRARY_PATH will need to be set
#
# export LD_LIBRARY_PATH=~/tools/lib:$LD_LIBRARY_PATH
# export PATH=~/tools/bin:$PATH

# For Regina Rexx and ooRexx to co-exist, ooRexx must be in a different
# directory and come first in the PATH.

# Stop on errors and trace everything we do here
set -e
set -x

SCRIPT_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "$SCRIPT_DIR/lib/hercules-helper/common.sh"

# Create our work directory
mkdir -p ~/tools
cd ~/tools

# Download and extract source package
hh_download_verified "https://gist.github.com/wrljet/8581fda46d64392fc6874f0142ad5a80/raw/0f943d464acda87fb34882277a20dde770f77d0c/Regina-REXX-3.9.7.tar.gz" \
    Regina-REXX-3.9.7.tar.gz f13701ebd542e74d0fc83b2a7876a812b07d21e43400275ed65b1ac860204bd4
hh_extract_tar_gz Regina-REXX-3.9.7.tar.gz .
cd regina-rexx-3.9.7/

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
