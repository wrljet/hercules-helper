#!/usr/bin/env bash

# The most recent version of this project can be obtained with:
#   git clone https://github.com/wrljet/hercules-helper.git
# or:
#   wget https://github.com/wrljet/hercules-helper/archive/master.zip
#
# Please report errors in this to me so everyone can benefit.
#
# Bill Lewis  bill@wrljet.com

#-----------------------------------------------------------------------------

msg="$(basename "$0"):

This script will download, build and install Regina-REXX 3.6.

Your sudo password will be required.
"

    echo "$msg"

    echo "which -a regina"
    which -a regina
    echo #

    read -p "Ctrl+C to abort here, or hit return to continue"

# Building Regina REXX

  499  wget "http://www.wrljet.com/ibm360/Regina-REXX-3.6.tar.gz"
  500  tar xfz Regina-REXX-3.6.tar.gz
  501  cd Regina-REXX-3.6

  512  CFLAGS="-Wno-error=implicit-function-declaration" ./configure
  514  make clean
  515  make

# quickie test
  518  ./regina -v

# install
  531  sudo make install
  532  cd ..

# test the installation
  533  which regina
  534  regina -v

