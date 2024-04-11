#!/usr/bin/env bash

# helper-build-regina.sh
#
# Helper to build Regina REXX on Linux and macOS
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

# SVN Regina 3.9.5
opt_regina_dir="Regina-REXX-3.9.5"
opt_regina_svn_url="https://svn.code.sf.net/p/regina-rexx/code/"
opt_regina_svn_revision="113"
opt_regina_install_dir="/usr/local/regina"

# Regina download
# opt_regina_dir=${opt_regina_dir:-"Regina-REXX-3.6"}
# opt_regina_tarfile=${opt_regina_tarfile:-"Regina-REXX-3.6.tar.gz"}
# opt_regina_url=${opt_regina_url:-"https://gist.github.com/wrljet/053c3bab74910d42f8775841fcc6fd3f/raw/fe7d723509356ebb77d1eb4593f15dda941949da/Regina-REXX-3.6.tar.gz"}
# opt_regina_dir="Regina-REXX-3.9.3"
# opt_regina_tarfile="Regina-REXX-3.9.3.tar.gz"
# opt_regina_url="https://gist.github.com/wrljet/dd19076064da7c3dea1aa9614fc37511/raw/e842479d63fae7af79d4aec467b8fdb148ca196a/Regina-REXX-3.9.3.tar.gz"

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

This script will download, build and install Regina-REXX 3.9.5
into $opt_regina_install_dir

Your sudo password will be required.
"
echo "$msg"
echo "which -a regina: $(which -a regina)"
echo #
read -p "Ctrl+C to abort here, or hit return to continue"

#-----------------------------------------------------------------------------
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
    brew install curl
    brew upgrade
fi

#-----------------------------------------------------------------------------
# Building Regina REXX

echo
echo "---"
echo "Step: Download and unpack Regina source..."
echo
note_msg "This will overwrite any existing $opt_regina_dir directory!"
echo
read -r -p "Hit return to continue..." response
echo

#   curl -LJO "$opt_regina_url"
#   if [ ${PIPESTATUS[0]} -ne 0 ]; then
#       error_msg "curl -LJO $opt_regina_url failed!"
#       exit 1
#   fi
#
#   tar xfz "$opt_regina_tarfile"
#   if [ ${PIPESTATUS[0]} -ne 0 ]; then
#       error_msg "tar failed!"
#       exit 1
#   fi

rm -rf $opt_regina_dir
echo "svn checkout --quiet $opt_regina_svn_url $opt_regina_dir"
svn checkout --quiet $opt_regina_svn_url $opt_regina_dir

if [ ${PIPESTATUS[0]} -ne 0 ]; then
    error_msg "svn checkout $opt_regina_svn_url failed!"
    exit 1
fi

pushd $opt_regina_dir/interpreter/trunk >/dev/null

svn up -r $opt_regina_svn_revision

if [ ${PIPESTATUS[0]} -ne 0 ]; then
    error_msg "svn up -r  $opt_regina_svn_revision failed!"
    exit 1
fi

# wget "http://www.wrljet.com/ibm360/Regina-REXX-3.6.tar.gz"
# tar xfz Regina-REXX-3.6.tar.gz

# cd "$opt_regina_dir"

echo
echo "---"
echo "Step: Patching Regina configure scripts..."
echo
read -r -p "Hit return to continue..." response

# patch -u configure -i "$(dirname "$0")/patches/regina-rexx-3.6.patch"
# patch -u configure -i "$SCRIPT_DIR/patches/regina-rexx-3.9.3.patch"

echo
echo "Replacing config.{guess,sub}"
cp "$(dirname "$0")/patches/config.guess" ./common/
cp "$(dirname "$0")/patches/config.sub" ./common/

echo "Fix missing rxstack.conf.etc"
cp rxstack.conf rxstack.conf.etc

echo
echo "---"
echo "Step: Configure..."
echo
read -r -p "Hit return to continue..." response

CFLAGS="-Wno-error=implicit-function-declaration" ./configure --prefix=$opt_regina_install_dir

echo "Configuration:"
./config.status --config

echo
echo "---"
echo "Step: Make..."
echo
read -r -p "Hit return to continue..." response

make clean
make

# Install
echo
echo "---"
echo "Step: Installation to system directories..."
echo
read -r -p "Hit return to continue..." response

sudo make install

#   popd >/dev/null # back to $opt_regina_work_dir

    popd >/dev/null # back to script run dir

echo
echo "Files required for Hercules integration:"
echo
find /usr/local -name 'rexxsaa.h'
find /usr/local -name 'libregina*'

# Set up for environment variables
echo
echo "---"
echo "Step: Set up environment variables..."
echo
read -r -p "Hit return to continue..." response

# Create sourceable script to set environment variables

echo
echo "Creating sourceable script to set environment variables"

    cat <<FOE >"helper-setvars-regina.sh"
#!/usr/bin/env bash
#
# Set up environment variables for Regina REXX
#
# This script was created by $0, $(date)
#

# LD_LIBRARY_PATH is often empty, and we don't want to error out on that
set +u

newpath="$opt_regina_install_dir/bin"
if [ -d "\$newpath" ] && [[ ":\$PATH:" != *":\$newpath:"* ]]; then
  # export PATH="\${PATH:+"\$PATH:"}\$newpath"
    export PATH="\$newpath\${PATH:+":\$PATH"}"
fi
echo "PATH: \$PATH"

#   export CFLAGS="-I $opt_regina_install_dir/include/"
#   export LDFLAGS="-Wl,-rpath,$opt_regina_install_dir/lib"

newpath="$opt_regina_install_dir/include"
if [ -d "\$newpath" ] && [[ ! \${CFLAGS} =~ "\$newpath" ]]; then
  # export CFLAGS="\${CFLAGS:+"\$CFLAGS:"}\$newpath"
    export CFLAGS="-I \$newpath\${CFLAGS:+" \$CFLAGS"}"
fi
echo "CFLAGS: \$CFLAGS"

newpath="$opt_regina_install_dir/lib"
if [ -d "\$newpath" ] && [[ ! \${LDFLAGS} =~ "\$newpath" ]]; then
  # export LDFLAGS="\${LDFLAGS:+"\$LDFLAGS:"}\$newpath"
    export LDFLAGS="-Wl,-rpath,\$newpath\${LDFLAGS:+" \$LDFLAGS"}"
fi
echo "LDFLAGS: \$LDFLAGS"

# If we're on macOS, DYLD_* environment variables are purged when
# launching protected processes.  So we'll just set it up here to
# the usual suspects.

uname_system="\$( (uname -s) 2>/dev/null)" || uname_system="unknown"

if [[ "\$uname_system" == "Linux" ]]; then
    newpath="$opt_regina_install_dir/lib"
    if [ -d "\$newpath" ] && [[ ":\$LD_LIBRARY_PATH:" != *":\$newpath:"* ]]; then
      # export LD_LIBRARY_PATH="\${LD_LIBRARY_PATH:+"\$LD_LIBRARY_PATH:"}\$newpath"
        export LD_LIBRARY_PATH="\$newpath\${LD_LIBRARY_PATH:+":\$LD_LIBRARY_PATH"}"
    fi
    echo "LD_LIBRARY_PATH: \$LD_LIBRARY_PATH"
fi

if [[ "\$uname_system" == "Darwin" ]]; then
    newpath="$opt_regina_install_dir/lib"
    if [ -d "\$newpath" ] && [[ ":\$DYLD_LIBRARY_PATH:" != *":\$newpath:"* ]]; then
      # export DYLD_LIBRARY_PATH="\${DYLD_LIBRARY_PATH:+"\$DYLD_LIBRARY_PATH:"}\$newpath"
        export DYLD_LIBRARY_PATH="\$newpath\${DYLD_LIBRARY_PATH:+":\$DYLD_LIBRARY_PATH"}"
    fi
    echo "DYLD_LIBRARY_PATH: \$DYLD_LIBRARY_PATH"
fi

FOE
# end of inline "here" file

chmod +x helper-setvars-regina.sh

echo
. ./helper-setvars-regina.sh

echo
echo "Required environment variables:"
echo
echo "PATH: $PATH"
echo "CFLAGS: $CFLAGS"
echo "LDFLAGS: $LDFLAGS"
uname_system="$( (uname -s) 2>/dev/null)" || uname_system="unknown"
if [ "$uname_system" == "Linux" ]; then
    echo "LD_LIBRARY_PATH: $LD_LIBRARY_PATH"
fi

if [ "$uname_system" == "Darwin" ]; then
    echo "DYLD_LIBRARY_PATH: $DYLD_LIBRARY_PATH"
fi

# Test the installation
echo
echo "---"
echo "Step: Test the installation..."
echo
read -r -p "Hit return to continue..." response

echo
hash -r
echo "which -a regina: $(which -a regina)"
regina -v

echo
    echo "To set up the required environment variables to build Hercules"
    echo "with this new ooRexx, without restarting your terminal session, run:"
    echo   # output a newline
    echo "(note the '.', which will \"source\" the script)"
    echo   # output a newline
    echo "  . $(pwd)/helper-setvars-regina.sh"
echo
echo "Done!"

