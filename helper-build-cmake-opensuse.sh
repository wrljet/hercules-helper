#!/usr/bin/env bash

# helper-build-cmake-opensuse.sh
#
# Helper to build CMake on OpenSUSE
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

This script will build and install CMake on OpenSUSE.

Your sudo password will be required.
"
echo "$msg"
read -p "Ctrl+C to abort here, or hit return to continue"

#-----------------------------------------------------------------------------
sudo zypper update
zypper search cmake

sudo zypper -n install wget git
sudo zypper -n install openssl libopenssl-devel

mkdir -p ./tools
pushd ./tools

wget https://cmake.org/files/v3.20/cmake-3.20.3.tar.gz
tar xfz cmake-3.20.3.tar.gz 
cd cmake-3.20.3/

./bootstrap --prefix=/usr/local
gmake -j$(nproc)
sudo make install
hash -r

# cd someplace else so we don't find a cmake in the same directory
cd ..
cmake --version

popd

