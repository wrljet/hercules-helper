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

SCRIPT_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/hercules-helper/common.sh"

msg="$(basename "$0"):

This script will build and install CMake on OpenSUSE.

Your sudo password will be required.
"
echo "$msg"
read -p "Ctrl+C to abort here, or hit return to continue"

#-----------------------------------------------------------------------------
zypper search cmake

sudo zypper -n install wget git
sudo zypper -n install openssl libopenssl-devel

mkdir -p ./tools
pushd ./tools

hh_download_verified "https://cmake.org/files/v3.20/cmake-3.20.3.tar.gz" \
    cmake-3.20.3.tar.gz 4d008ac3461e271fcfac26a05936f77fc7ab64402156fb371d41284851a651b8
hh_extract_tar_gz cmake-3.20.3.tar.gz .
cd cmake-3.20.3/

./bootstrap --prefix=/usr/local
gmake -j$(nproc)
sudo make install
hash -r

# cd someplace else so we don't find a cmake in the same directory
cd ..
cmake --version

popd
