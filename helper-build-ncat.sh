#!/usr/bin/env bash

# helper-build-ncat.sh
#
# Helper to build ncat
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

This script will download, build and install ncat.

Your sudo password will be required.
"
echo "$msg"
echo "which ncat"
which ncat
echo #
read -p "Ctrl+C to abort here, or hit return to continue"

#-----------------------------------------------------------------------------
mkdir -p ~/tools
pushd ~/tools

hh_download_verified "https://nmap.org/dist/nmap-7.91.tar.bz2" \
    nmap-7.91.tar.bz2 18cc4b5070511c51eb243cdd2b0b30ff9b2c4dc4544c6312f75ce3a67a593300
hh_extract_tar_gz nmap-7.91.tar.bz2 .
cd nmap-7.91/

./configure
make
sudo make install
hash -r

# cd someplace else so we don't find a cmake in the same directory
cd ..
ncat --version

popd
