#!/usr/bin/env bash

# helper-build-suite3270-debian.sh
#
# Helper to build Suite3270 (c3270, x3270, etc) on Debian based Linux
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
# This works for me, but should be considered just an example

msg="$(basename "$0"):

This script will build and install Suite3270 on Debian.

Your sudo password will be required.
"
echo "$msg"
read -p "Ctrl+C to abort here, or hit return to continue"

#-----------------------------------------------------------------------------
# Stop on errors and trace everything we do here
set -e
set -x

# FIXME: this doesn't work if this script is running off a symlink
SCRIPT_PATH=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR="$(dirname $SCRIPT_PATH)"

sudo apt install libssl-dev libreadline-dev libxaw7-dev xfonts-100dpi libncurses5-dev
sudo apt install libexpat-dev tcl-dev m4

# Create our work directory
mkdir -p $HOME/tools
pushd $HOME/tools

wget http://x3270.bgp.nu/download/04.02/suite3270-4.2ga7-src.tgz
tar xfz suite3270-4.2ga7-src.tgz 
cd suite3270-4.2/

# Configure package, enabling c3270 x3270, etc
./configure -C --enable-unix
#       --sysconfdir=$HOME/tools/etc \
#       --with-fontdir=$HOME/tools/fonts/3270
#       --prefix=$HOME/tools \
#       --bindir=$HOME/tools/bin \

make clean && make -j 2
sudo make install

popd
