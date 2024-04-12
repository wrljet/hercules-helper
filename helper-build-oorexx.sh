#!/usr/bin/env bash

# helper-build-oorexx.sh
#
# Helper to build ooRexx on Linux and macOS
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
# Updated: 11 APR 2024 WRL

#-----------------------------------------------------------------------------
set -e # Stop on errors

#-----------------------------------------------------------------------------
# Configuration

uname_system="$( (uname -s) 2>/dev/null)" || uname_system="unknown"

if [ "$uname_system" == "Linux" ]; then
    opt_rexx_work_dir=${opt_rexx_work_dir:-"./ooRexx"}
    opt_rexx_install_dir=${opt_rexx_install_dir:-"/usr/local/ooRexx"}
fi

# Installation directory:
#  ~/Applications/ooRexx5 (the Applications directory in your home folder)
if [ "$uname_system" == "Darwin" ]; then
    opt_rexx_work_dir=${opt_rexx_work_dir:-"./ooRexx"}
    opt_rexx_install_dir=${opt_rexx_install_dir:-"$HOME/Applications/ooRexx"}
fi

#-----------------------------------------------------------------------------
# Find and read in our helper functions

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

#------------------------------------------------------------------------------
#                              main
#------------------------------------------------------------------------------

msg="$(basename "$0"):

This script will build ooRexx 5 (from SVN trunk) into $opt_rexx_install_dir

Your sudo password will be required.
"
echo "$msg"
read -r -p "Ctrl+C to abort here, or hit return to continue" response

#------------------------------------------------------------------------------
# Some things need to be split between macOS, Linux, etc

if [ "$uname_system" == "Linux" ]; then
    pwd > /dev/null
fi

if [ "$uname_system" == "Darwin" ]; then
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
fi

#-----------------------------------------------------------------------------

# Install required packages

if [ "$uname_system" == "Linux" ]; then
    echo
fi

if [ "$uname_system" == "Darwin" ]; then
    echo "---"
    echo "Step: Updating Homebrew and installing required packages"
    echo "      cmake svn"
    echo
    read -r -p "Hit return to continue..." response

    brew update
    brew install cmake svn
    brew upgrade
fi

#-----------------------------------------------------------------------------

# All this assumes it's running in $opt_rexx_dir directory,

mkdir -p $opt_rexx_work_dir
pushd $opt_rexx_work_dir >/dev/null

# Clone the project repos

echo "---"
echo
echo "Step: Cloning project repos..."
echo
note_msg "This will overwrite any existing oorexx-code directory!"
echo
read -r -p "Hit return to continue..." response

    rm -rf oorexx-code
echo "svn checkout --quiet svn://svn.code.sf.net/p/oorexx/code-0/main/trunk oorexx-code"
    svn checkout --quiet svn://svn.code.sf.net/p/oorexx/code-0/main/trunk oorexx-code

# Building ooRexx

echo
echo "---"
echo
echo "Step: Building ooRexx..."
echo
read -r -p "Hit return to continue..." response

    mkdir -p oorexx-build
    pushd oorexx-build >/dev/null

    cmake ../oorexx-code -DCMAKE_INSTALL_PREFIX=$opt_rexx_install_dir

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

# Create sourceable script to set environment variables

    cat <<FOE >"helper-setvars-oorexx.sh"
#!/usr/bin/env bash
#
# Set up environment variables for ooRexx
#
# This script was created by $0, $(date)
#

# LD_LIBRARY_PATH is often empty, and we don't want to error out on that
set +u

newpath="$opt_rexx_install_dir/bin"
if [ -d "\$newpath" ] && [[ ! \${PATH} =~ "\$newpath" ]]; then
  # export PATH="\${PATH:+"\$PATH:"}\$newpath"
    export PATH="\$newpath\${PATH:+":\$PATH"}"
fi
echo "PATH: \$PATH"

#   export CFLAGS="-I $opt_rexx_install_dir/include/"
#   export LDFLAGS="-Wl,-rpath,$opt_rexx_install_dir/lib"

newpath="$opt_rexx_install_dir/include"
if [ -d "\$newpath" ] && [[ ! \${CFLAGS} =~ "\$newpath" ]]; then
  # export CFLAGS="\${CFLAGS:+"\$CFLAGS:"}\$newpath"
    export CFLAGS="-I \$newpath\${CFLAGS:+" \$CFLAGS"}"
fi
echo "CFLAGS: \$CFLAGS"

# echo "ls /usr/local/ooRexx ="
# echo "\$(ls -l /usr/local/ooRexx)"
# echo "find: \$(find /usr/local/ooRexx -maxdepth 1 -type d -name 'lib*')"

# Find lib path under ooRexx
# newpath="/usr/local/ooRexx/lib"
newpath="/usr/local/ooRexx"
# echo "newpath base = \$newpath"
newpath="\$(find \$newpath -maxdepth 1 -type d -name 'lib*')"
# echo "newpath from find = \$newpath"
# echo "old LDFLAGS = \$LDFLAGS"

if [ -d "\$newpath" ] && [[ ! \${LDFLAGS} =~ "\$newpath" ]]; then
  # export LDFLAGS="\${LDFLAGS:+"\$LDFLAGS:"}\$newpath"
    export LDFLAGS="-Wl,-rpath,\$newpath\${LDFLAGS:+" \$LDFLAGS"}"
fi
echo "LDFLAGS: \$LDFLAGS"

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
    . ./helper-setvars-oorexx.sh
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

