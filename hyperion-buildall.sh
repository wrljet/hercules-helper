#!/bin/bash

# Complete SDL-Hercules build using wrljet github mods
# Updated: 25 NOV 2020
#
# The most recent version of this script can be ontained with:
#   git clone https://github.com/wrljet/hercules-helper.git
# or
#   wget https://github.com/wrljet/hercules-helper/archive/main.zip
#
# Please report errors in this to me so everyone can benefit.
#
# Bill Lewis  wrljet@gmail.com

# To run, create a build directory and cd to it, 
# then run this script.
#
#    mkdir herctest && cd herctest
#    ~/hyperion-buildall.sh 2>&1 | tee ./hyperion-buildall.log

# Show all commands as they are being run
set -x

# Stop on error
set -e

BUILD_DIR=$(pwd)

# Target directory prefix
TARGET_DIR=$(pwd)/herc4x

echo ${BUILD_DIR}
echo ${TARGET_DIR}

#-----------------------------------------------------------------------------
# git may report:
#
# *** Please tell me who you are.
#
# Run
#
#  git config --global user.email "you@example.com"
#  git config --global user.name "Your Name"
#
# to set your account's default identity.
# Omit --global to set the identity only in this repository.
#
# fatal: unable to auto-detect email address (got 'bill@mint20-vm.(none)')
#

# Set up so git knows who we are (for the merges)
# git config --global user.email "wrljet@gmail.com"
# git config --global user.name "Bill Lewis"
git config --global pager.branch false

#-----------------------------------------------------------------------------

# Print current time and machine cpu type
date
uname -m
gcc --version
which g++ || true

if [ -f /etc/debian_version ]; then
    # Older Debian/Ubuntu/etc.
    OS=Debian
    VER=$(cat /etc/debian_version)

    echo "OS is $OS variant"
    echo "Version $VER"
fi

# Build Regina Rexx, which we use to run the Hercules tests
read -p "Hit return to continue (step: build regina rexx)"
wget http://www.wrljet.com/ibm360/regina-rexx-3.9.3.tar.gz
tar xfz regina-rexx-3.9.3.tar.gz 
cd regina-rexx-3.9.3/

if [[ "$(uname -m)" == i686* ]]; then
./configure --prefix=${BUILD_DIR}/rexx --enable-32bit
else
./configure --prefix=${BUILD_DIR}/rexx
fi

time make
time make install

export PATH=${BUILD_DIR}/rexx/bin:$PATH
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${BUILD_DIR}/rexx/lib
export CPPFLAGS=-I${BUILD_DIR}/rexx/include
which rexx

#
read -p "Hit return to continue (step: hercules clone)"
cd ${BUILD_DIR}
mkdir sdl4x
mkdir ${TARGET_DIR}

# Grab unmodified SDL-Hercules Hyperion repo
cd sdl4x
git clone https://github.com/SDL-Hercules-390/hyperion.git
cd hyperion
git branch -va
#git checkout build-mods-reqs

# Check for required packages and minimum versions.
# Inspect the output carefully and do not continue if there are
# any error messages or recommendations unless you know what you're doing.

# On Raspberry Pi Desktop (Buster), the following are often missing:
# autoconf, automake, cmake, flex, gawk, m4

util/bldlvlck 

read -p "Hit return to continue (step: git clone extpkgs)"
cd ${BUILD_DIR}
mkdir extpkgs
cd extpkgs/

git clone -b build-mods-i686 https://github.com/wrljet/gists.git
cp gists/extpkgs.sh .
cp gists/extpkgs.sh.ini .

# Edit extpkgs.sh.ini
# Change 'x86' to 'aarch64' for 64-bit, or 'arm' for 32-bit, etc.

if [[ "$(uname -m)" == x86* ]]; then
    echo "Defaulting to x86 machine type in extpkgs.sh.ini"
else
    mv extpkgs.sh.ini extpkgs.sh.ini-x86
    sed "s/x86/$(uname -m)/g" extpkgs.sh.ini-x86 > extpkgs.sh.ini
fi

mkdir repos && cd repos
rm -rf *

# git clone https://github.com/wrljet/crypto.git crypto-0
# git clone https://github.com/wrljet/decNumber.git decNumber-0
# git clone https://github.com/wrljet/SoftFloat.git SoftFloat-0
# git clone https://github.com/wrljet/telnet.git telnet-0

declare -a pgms=("crypto" "decNumber" "SoftFloat" "telnet")

for pgm in "${pgms[@]}"; do
    echo "-----------------------------------------------------------------"
    echo "$pgm"
    git clone -b build-mods-i686 "https://github.com/wrljet/$pgm.git" "$pgm-0"
#   git clone "https://github.com/wrljet/$pgm.git" "$pgm-0"
#
#   pushd "$pgm-0" > /dev/null;
#   echo "$PWD >"
#
#   git checkout master
#   git checkout build-mods-i686
#   git checkout master
#   git merge build-mods-i686 --no-ff --no-edit
#
#   popd > /dev/null;
done

read -p "Hit return to continue (step: build extpkgs)"
cd ${BUILD_DIR}
cd extpkgs

DEBUG=1 ./extpkgs.sh  c d s t
# ./extpkgs.sh c d s t

cd ${BUILD_DIR}/sdl4x/hyperion

# ./autogen.sh

read -p "Hit return to continue (step: configure)"
./configure \
    --enable-optimization="-O3 -march=native" \
    --enable-extpkgs=${BUILD_DIR}/extpkgs \
    --prefix=${TARGET_DIR} \
    --enable-regina-rexx

# Debian 10 x86_64, gcc 8.3.0
# CBUC test fails without this
#   --enable-optimization="-O3 -march=native" \

# Debian 8.11 i686, gcc 5.4.0
#   --enable-optimization="-O3 -march=native" \

# Debian 9    i686, gcc 6.3
#   --enable-optimization="-O3 -march=native" \
#   --enable-optimization="-O3 -march=native -minline-stringops-dynamically -fomit-frame-pointer" \

# WRL original for Pi 4 64-bit
#   --enable-optimization="-O3 -pipe" \

# Compile and link
read -p "Hit return to continue (step: make)"
make clean
time make -j$(nproc) 2>&1 | tee ${BUILD_DIR}/hyperion-buildall-make.log

read -p "Hit return to continue (step: tests)"
time make check 2>&1 | tee ${BUILD_DIR}/hyperion-buildall-make-check.log
# time ./tests/runtest ./tests

# Failed test "mainsize" on openSUSE 15.1 with 4GB RAM
# HHC01603I mainsize 3g
# HHC01430S Error in function configure_storage( 3G ): Cannot allocate memory
# HHC00007I Previous message from function 'configure_storage' at config.c(337)
# HHC02388E Configure storage error -1
# HHC00007I Previous message from function 'mainsize_cmd' at hsccmd.c(3377)
# HHC01603I archlvl s/370
# HHC00811I Processor CP00: architecture mode S/370
# HHC02204I ARCHLVL        set to S/370
# HHC02204I LPARNUM        set to BASIC
# HHC01603I *Info 1 HHC17006W MAINSIZE decreased to 2G architectural maximim

# Quickie test to see if hercules works at all
# sudo ./hercules

read -p "Hit return to continue (step: install)"
time make install 2>&1 | tee ${BUILD_DIR}/hyperion-buildall-make-install.log

# ---- end of script ----

