#!/usr/bin/env bash

# helper-build-oorexx-macos.sh
#
# Helper to build ooRexx on macOS
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
# WRL 02 APR 2024

msg="$(basename "$0"):

This script will build and install ooRexx on macOS.

Your sudo password will be required.
"
echo "$msg"
read -p "Ctrl+C to abort here, or hit return to continue"

#-----------------------------------------------------------------------------
# Stop on errors
set -e

opt_rexx_work_dir=${opt_rexx_work_dir:-"./ooRexx"}
opt_rexx_install_dir=${opt_rexx_install_dir:-"$HOME/Applications/ooRexx"}

#------------------------------------------------------------------------------
#                              confirm
#------------------------------------------------------------------------------
confirm() {
    echo -ne '\a'

    # call with a prompt string or use a default
    read -r -p "${1:-Are you sure? [y/N]} " response
    case "$response" in 
        [yY][eE][sS]|[yY])
            true
            ;; 
        *)     
            false
            ;; 
    esac
}

#------------------------------------------------------------------------------
#                              main
#------------------------------------------------------------------------------

echo "This script will build ooRexx 5 (SVN trunk) on macOS"
echo
read -r -p "Hit return to continue, or Ctrl+C to quit..." response

echo
echo "Checking for Xcode command line tools ..."
xcode-select -p 1>/dev/null 2>/dev/null
if [[ $? == 2 ]] ; then
    darwin_need_prereqs=true
else
    echo "    Xcode command line tools appear to be installed"

    if (cc --version 2>&1 | head -n 1 | grep -Fiqe "xcrun: error: invalid active developer path"); then
        error_msg "    But the C compiler does not work"
        echo "$(cc --version 2>&1)"
        exit 1
    fi
fi

echo "Checking for Homebrew package manager ..."
which -s brew
if [[ $? != 0 ]] ; then
    darwin_need_prereqs=true
    echo "    Homebrew is not installed"
else
    darwin_need_prereqs=false
    echo "    Homebrew is already installed"
fi

if ( $darwin_need_prereqs == true ) ; then
    echo   # output a newline
    echo "Please run prerequisites-macOS.sh from Hercules-Helper first"
    echo   # output a newline
    exit 1
fi

# All this assumes it's running in $opt_rexx_dir directory,

mkdir -p $opt_rexx_work_dir
pushd $opt_rexx_work_dir >/dev/null

#-----------------------------------------------------------------------------
#-----------------------------------------------------------------------------

# Install required packages

echo
echo "---"
echo "Step: Updating Brew and installing required packages"
echo
read -r -p "Hit return to continue..." response

brew update
brew install cmake svn
brew upgrade

#-----------------------------------------------------------------------------


# Installation directory:
#  ~/Applications/ooRexx5 (the Applications directory in your home folder)

# Clone the project repos

echo
echo "---"
echo
echo "Step: Cloning project repos..."
echo
echo "This will overwrite any existing oorexx-code directory!"
echo
read -r -p "Hit return to continue..." response

    rm -rf oorexx-code
echo "svn checkout svn://svn.code.sf.net/p/oorexx/code-0/main/trunk oorexx-code"
    svn checkout svn://svn.code.sf.net/p/oorexx/code-0/main/trunk oorexx-code

# Building ooRexx

echo
echo "---"
echo
echo "Step: Building ooRexx..."
echo
read -r -p "Hit return to continue..." response

    mkdir -p oorexx-build
    pushd oorexx-build >/dev/null

    cmake ../oorexx-code
    make clean
    make

echo
echo "---"
echo
echo "Step: Installing ooRexx..."
echo
read -r -p "Hit return to continue..." response

    sudo make install

    popd >/dev/null # back to $opt_rexx_work_dir

    popd >/dev/null # back to script run dir

echo
echo "---"
echo
echo "Step: Creating script to set up ooRexx environment variables..."
echo
read -r -p "Hit return to continue..." response

    export PATH=$opt_rexx_install_dir/bin:$PATH
    export CFLAGS="-I$opt_rexx_install_dir/include/"
    export LDFLAGS="-Wl,-rpath,$opt_rexx_install_dir/lib"

# Create sourceable script to set environment variables

    cat <<FOE >"helper-setvars-oorexx.sh"
#
# Set up environment variables for ooRexx
#
# This script was created by $0, $(date)
#

# LD_LIBRARY_PATH is often empty, and we don't want to error out on that
set +u

newpath="$opt_rexx_install_dir/bin"
if [ -d "\$newpath" ] && [[ ":\$PATH:" != *":\$newpath:"* ]]; then
  # export PATH="\${PATH:+"\$PATH:"}\$newpath"
    export PATH="\$newpath\${PATH:+":\$PATH"}"
fi

#   export CFLAGS="-I$opt_rexx_install_dir/include/"
#   export LDFLAGS="-Wl,-rpath,$opt_rexx_install_dir/lib"

newpath="$opt_rexx_install_dir/include"
if [ -d "\$newpath" ] && [[ ":\$CFLAGS:" != *":\$newpath:"* ]]; then
  # export CFLAGS="\${CFLAGS:+"\$CFLAGS:"}\$newpath"
    export CFLAGS="-I\$newpath\${CFLAGS:+":\$CFLAGS"}"
fi

newpath="$opt_rexx_install_dir/lib"
if [ -d "\$newpath" ] && [[ ":\$LDFLAGS:" != *":\$newpath:"* ]]; then
  # export LDFLAGS="\${LDFLAGS:+"\$LDFLAGS:"}\$newpath"
    export LDFLAGS="-Wl,-rpath,\$newpath\${LDFLAGS:+":\$LDFLAGS"}"
fi

FOE
# end of inline "here" file

chmod +x helper-setvars-oorexx.sh

# Quickie test

echo
echo "---"
echo
echo "Step: Quickie test for ooRexx..."
echo
read -r -p "Hit return to continue..." response

    echo
    hash -r
    echo "which rexx"
    which rexx

    rexx -v

echo
echo "Done!"
echo
    echo "To set up the required environment variables to build Hercules"
    echo "with this new ooRexx, without restarting your terminal session, run:"
    echo   # output a newline
    echo "(note the '.', which will \"source\" the script)"
    echo   # output a newline
    echo "  . $(pwd)/helper-setvars-oorexx.sh"
echo
echo "Uninstallation instructions are at the of this script"
echo

# To uninstall:
#
# $ cat install_manifest.txt | sudo xargs rm
# $ xargs rm < install_manifest.txt

# $ cat install_manifest.txt | xargs -L1 dirname | sudo xargs rmdir -p
#
# The second command will print a bunch of errors because it recursively
# deletes folders until it finds one that is not empty. I like seeing
# those errors to know which folders are left. If you want to hide these
# errors you can add --ignore-fail-on-non-empty to rmdir.
#
# AFAIK using xargs -I "{}" -- rm -- '{}' should solve the whitespace problem
#
# anyway, you should be able to fix this by using \0 as a delimiter for xargs,
# but before you have to convert the file names of install_manifest to use \0.
# 
# $ cat install_manifest.txt | tr '\n' '\0' | xargs -0 rm
#
# should work (have not tested)

