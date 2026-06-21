#!/usr/bin/env bash

# helper-build-c3270-elbrus.sh
#
# Helper to build suite3270 (c3270, x3270, etc) on Elbrus Linux
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
#
# PATH and LD_LIBRARY_PATH will need to be set

msg="$(basename "$0"):

This script will build and install Suite3270 on Elbrus Linux.

Your sudo password will be required.
"
echo "$msg"
read -p "Ctrl+C to abort here, or hit return to continue"

#-----------------------------------------------------------------------------
# Stop on errors and trace everything we do here
set -e
set -x

SCRIPT_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "$SCRIPT_DIR/lib/hercules-helper/common.sh"

# Create our work directory
mkdir -p ~/tools
cd ~/tools

hh_download_verified "https://x3270.bgp.nu/download/04.00/suite3270-4.0ga13-src.tgz" \
    suite3270-4.0ga13-src.tgz eb39f1b65dfdc9b912301d7a7f269f4d92043223a5196bcfd7e8d7bdf2c95fcf
hh_extract_tar_gz suite3270-4.0ga13-src.tgz .
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
