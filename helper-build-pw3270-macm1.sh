#!/usr/bin/env bash

# helper-build-pw3270-macm1.sh
#
# Helper to build PW3270 on macOS (Apple Silicon)
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
# WRL 05 MAR 2024

msg="$(basename "$0"):

This script will build and install PW3270 on macOS (Apple Silicon).

Your sudo password will be required.
"
echo "$msg"
read -p "Ctrl+C to abort here, or hit return to continue"

#-----------------------------------------------------------------------------
# Stop on errors
set -e

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

echo
echo "This script will build PW3270 on macOS (for Apple Silicon)"
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

# All this assumes it's running in a ~/tools directory,
# so we make one in case it's not there already.

mkdir -p ~/tools
cd ~/tools

# Install required packages

echo
echo "---"
echo "Step: Updating Brew and installing required packages"
echo
read -r -p "Hit return to continue..." response

brew update
brew install xz automake binutils coreutils curl gettext libtool openssl pkgconfig
brew upgrade

brew unlink gettext && brew link --force gettext

brew install adwaita-icon-theme imagemagick
brew install gtk+3

newpath="/usr/local/opt/libtool/libexec/gnubin"
if [ -d "\$newpath" ] && [[ ":\$PATH:" != *":\$newpath:"* ]]; then
  export PATH="\${PATH:+"\$PATH:"}\$newpath"
fi

echo
echo "---"
echo
export PKG_CONFIG_PATH="$(brew --prefix curl)/lib/pkgconfig:$(brew --prefix openssl)/lib/pkgconfig"
echo "PKG_CONFIG_PATH=$PKG_CONFIG_PATH"

#export CFLAGS="$CFLAGS -I$(find $(brew --cellar libtool) -type d -name "include" | sort -n | tail -n 1)"
#export LDFLAGS="$LDFLAGS -L$(find $(brew --cellar libtool) -type d -name "lib" | sort -n | tail -n 1)"

# Clone the project repos

echo
echo "---"
echo
echo "Step: Cloning project repos..."
echo

if [ -d ./libv3270 ]; then
  if confirm "libv3270 directory already exists.  overwrite? [y/N]" ; then
    rm -rf libv3270/
    git clone https://github.com/PerryWerneck/libv3270.git
  else
    echo "Using existing libv3270 directory"
#   echo "Quitting"
#   exit 1
  fi
else
    git clone https://github.com/PerryWerneck/libv3270.git
fi

if [ -d ./lib3270 ]; then
  if confirm "lib3270 directory already exists.  overwrite? [y/N]" ; then
    rm -rf lib3270/
    git clone https://github.com/PerryWerneck/lib3270.git
  else
    echo "Using existing lib3270 directory"
#   echo "Quitting"
#   exit 1
  fi
else
    git clone https://github.com/PerryWerneck/lib3270.git
fi

if [ -d ./pw3270 ]; then
  if confirm "pw3270 directory already exists.  overwrite? [y/N]" ; then
    rm -rf pw3270
    git clone https://github.com/PerryWerneck/pw3270.git
  else
    echo "Using existing pw3270 directory"
#   echo "Quitting"
#   exit 1
  fi
else
    git clone https://github.com/PerryWerneck/pw3270.git
fi

# Build the lib3270 project

echo
echo "---"
echo "Step: Build the lib3270 project"
echo
read -r -p "Hit return to continue..." response

rm -rf /opt/homebrew/Cellar/lib3270
cd lib3270

# FIXME Uncomment these if the compiler/linker fails to find them
# FIXME echo "find /opt -name 'libintl*'"
# FIXME find /opt -name 'libintl*'

export CFLAGS="-I /opt/homebrew/include" LDFLAGS="-L /opt/homebrew/lib"
echo
echo "CFLAGS=$CFLAGS"
echo
echo "./autogen --prefix=$(brew --cellar)/lib3270/5.4 --with-libiconv-prefix=$(brew --prefix gettext)"
echo
./autogen.sh --prefix="$(brew --cellar)/lib3270/5.4" --with-libiconv-prefix=$(brew --prefix gettext)

make all
make install

echo "brew unlink && brew link lib3270"
brew unlink lib3270
brew link lib3270

cd ..

# Build libv3270 project

echo
echo "---"
echo "Step: Build the libv3270 project"
echo
read -r -p "Hit return to continue..." response

rm -rf /opt/homebrew/Cellar/libv3270
cd libv3270
CFLAGS="-I /opt/homebrew/include" LDFLAGS="-L /opt/homebrew/lib" ./autogen.sh --prefix="$(brew --cellar)/libv3270/5.4"
make all
make install

echo
echo "brew link libv3270 && brew link libv3270"
brew unlink libv3270
brew link libv3270
cd ..

# Build the main pw3270 project

echo
echo "Step: Build the main pw3270 project"
echo
read -r -p "Hit return to continue..." response

cd pw3270

# Used to be branch macos which conflicted with the directory of the same name
git checkout develop

# FIXME use my updated autogen.sh, which will use glibtoolize
# FIXME no longer needed with commit 3d70bc0
# cp ../pw3270-autogen.sh ./autogen.sh

# Fix possibly missing executable bit on 'bundle'
ls -l mac/bundle
chmod +x mac/bundle

CFLAGS="-I /opt/homebrew/include" LDFLAGS="-L /opt/homebrew/lib" ./autogen.sh
make all

echo
echo "---"
echo "Step: Bundle the project"
echo
read -r -p "Hit return to continue..." response

# Create macOS app bundle
# FIXME directory name changed with commit b5df356
cd mac

# This no longer needed -- has been added to upstream repo
# Copy in fixed 'bundle' from AndreBreves
# mv bundle bundle-orig
# cp ../../pw3270-andrebreves/macos/bundle .

# Reset Stop on errors
set +e

ls -ltrh
./bundle

echo "---"
echo "Resulting bundle: $(pwd)/bundle"
du -sh pw3270.app

cp -r pw3270.app ..

# cd up to pw3270
cd ..

echo "---"
echo "Step: Zipping the bundled app..."
echo "pwd: $(pwd)"
zip -r ../pw3270-macos-m1.zip pw3270.app

echo
echo "Done!"

pushd "$(pwd)/../" >/dev/null
zipdir=$(pwd)
popd >/dev/null
echo
echo "The bundled and zipped app is in: $zipdir/pw3270-macos-m1.zip"
echo

# end
