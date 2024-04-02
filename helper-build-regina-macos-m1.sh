#!/usr/bin/env bash

# helper-build-regina-macos-m1.sh
#
# Helper to build Regina REXX on macOS (Apple Silicon)
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

This script will download, build and install Regina-REXX 3.6 on macOS.

Your sudo password will be required.
"
echo "$msg"
echo "which -a regina"
which -a regina
echo #
read -p "Ctrl+C to abort here, or hit return to continue"

#-----------------------------------------------------------------------------
# Stop on errors
set -e

#-----------------------------------------------------------------------------
# Find and read in the helper functions

fns_dir="$(dirname "$0")"
fns_file="$fns_dir/helper-fns.sh"

if test -f "$fns_file" ; then
    source "$fns_file"
else
    echo "Helper functions script file $fns_file not found!"
    exit 1
fi

# FIXME: this doesn't work if this script is running off a symlink
SCRIPT_PATH=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR="$(dirname $SCRIPT_PATH)"

#-----------------------------------------------------------------------------
# Building Regina REXX

# Regina download
# opt_regina_dir=${opt_regina_dir:-"Regina-REXX-3.6"}
# opt_regina_tarfile=${opt_regina_tarfile:-"Regina-REXX-3.6.tar.gz"}
# opt_regina_url=${opt_regina_url:-"https://gist.github.com/wrljet/053c3bab74910d42f8775841fcc6fd3f/raw/fe7d723509356ebb77d1eb4593f15dda941949da/Regina-REXX-3.6.tar.gz"}
opt_regina_dir="Regina-REXX-3.9.3"
opt_regina_tarfile="Regina-REXX-3.9.3.tar.gz"
opt_regina_url="https://gist.github.com/wrljet/dd19076064da7c3dea1aa9614fc37511/raw/e842479d63fae7af79d4aec467b8fdb148ca196a/Regina-REXX-3.9.3.tar.gz"

echo
echo "---"
echo "Step: Download and unpack Regina source..."
echo
read -r -p "Hit return to continue..." response

    curl -LJO "$opt_regina_url"
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        error_msg "curl -LJO $opt_regina_url failed!"
        exit 1
    fi

    tar xfz "$opt_regina_tarfile"
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        error_msg "tar failed!"
        exit 1
    fi

# wget "http://www.wrljet.com/ibm360/Regina-REXX-3.6.tar.gz"
# tar xfz Regina-REXX-3.6.tar.gz

cd "$opt_regina_dir"

echo
echo "---"
echo "Step: Patching Regina configure scripts..."
echo
read -r -p "Hit return to continue..." response

# patch -u configure -i "$(dirname "$0")/patches/regina-rexx-3.6.patch"
patch -u configure -i "$SCRIPT_DIR/patches/regina-rexx-3.9.3.patch"

echo "Replacing config.{guess,sub}"
cp "$(dirname "$0")/patches/config.guess" ./common/
cp "$(dirname "$0")/patches/config.sub" ./common/

echo
echo "---"
echo "Step: Configure and make..."
echo
read -r -p "Hit return to continue..." response

CFLAGS="-Wno-error=implicit-function-declaration" ./configure
make clean
make

# quickie test
./regina -v

# install
sudo make install
cd ..

# test the installation
which regina
regina -v

