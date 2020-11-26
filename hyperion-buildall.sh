#!/bin/bash

# Complete SDL-Hercules-390 build using wrljet github mods
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

#-----------------------------------------------------------------------------
# To run, create a build directory and cd to it, then run this script.
#
#  $ mkdir herctest && cd herctest
#  $ ~/hercules-helper/hyperion-buildall.sh -v --prompts 2>&1 | tee ./hyperion-buildall.log

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
# Stop on error
set -e

# Process command line

if [[ -n $trace ]]  || \
   [[ -n $TRACE ]]; then
    set -x # For debugging, show all commands as they are being run
fi

TRACE=false
VERBOSE=false
PROMPTS=false

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -t|--trace)
    TRACE=true
    shift # past argument
    ;;

    -p|--prompts)
    PROMPTS=true
    shift # past argument
    ;;

    -v|--verbose)
    VERBOSE=true
    shift # past argument
    ;;

    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

if [[ "${TRACE}" == true ]]; then
    # Show all commands as they are being run
    set -x
fi

#------------------------------------------------------------------------------
#                               verbose_msg
#------------------------------------------------------------------------------
verbose_msg()
{
    if ($VERBOSE); then
	echo "$1"
    fi
}

#------------------------------------------------------------------------------
#                               detect_system
#------------------------------------------------------------------------------
detect_system()
{
    echo "System stats:"

    machine=$(uname -m)
    # echo "Machine is $machine"

    # awk -F= '$1=="ID" { gsub(/"/, "", $2); print $2 ;}' /etc/os-release
    VERSION_ID=$(awk -F= '$1=="ID" { gsub(/"/, "", $2); print $2 ;}' /etc/os-release)
    # echo "VERSION_ID is $VERSION_ID"

    VERSION_STR=$(awk -F= '$1=="VERSION_ID" { gsub(/"/, "", $2); print $2 ;}' /etc/os-release)
    # echo "VERSION_STR is $VERSION_STR"

    verbose_msg "Machine arch     : $machine"

    verbose_msg "Memory Total (MB): $(free -m | awk '/^Mem:/{print $2}')"
    verbose_msg "Memory Free  (MB): $(free -m | awk '/^Mem:/{print $4}')"

    verbose_msg "VERSION_ID       : $VERSION_ID"
    verbose_msg "VERSION_STR      : $VERSION_STR"

    # Look for Debian/Ubuntu/Mint

    if [[ $VERSION_ID == debian* || $VERSION_ID == ubuntu* ]]; then
	# if [[ $(lsb_release -rs) == "18.04" ]]; then
	VERSION_DISTRO=Debian
	VERSION_MAJOR=$(echo ${VERSION_STR} | cut -f1 -d.)
	VERSION_MINOR=$(echo ${VERSION_STR} | cut -f2 -d.)

	echo "OS               : $VERSION_DISTRO variant"
	echo "OS Version       : $VERSION_MAJOR"
    fi

    if [[ $VERSION_ID == centos* ]]; then
	echo "We have a CentOS system"

	# centos-release-7-8.2003.0.el7.centos.x86_64
	CENTOS_VERS=$(rpm --query centos-release) || true
	VERSION_MAJOR=$(echo ${CENTOS_VERS#centos-release-} | cut -f1 -d-)
	VERSION_MINOR=$(echo ${CENTOS_VERS#centos-release-} | cut -f1 -d. | cut -f2 -d-)

	echo "VERSION_MAJOR : $VERSION_MAJOR"
	if [[ $VERSION_MAJOR -ge 7 ]]; then
	    echo "CentOS version 7 or later found"
        fi
    fi
}

verbose_msg "Options:"
verbose_msg "TRACE            : ${TRACE}"
verbose_msg "VERBOSE          : ${VERBOSE}"
verbose_msg "PROMPTS          : ${PROMPTS}"

# Detect type of system we're running on and display info
detect_system

#-----------------------------------------------------------------------------
# Overall working build diretory is the current director
BUILD_DIR=$(pwd)

# Prefix (target) directory
PREFIX_DIR=$(pwd)/herc4x

echo "BUILD_DIR        : ${BUILD_DIR}"
echo "PREFIX_DIR       : ${PREFIX_DIR}"

#-----------------------------------------------------------------------------

if [ -f /etc/debian_version ]; then
    # Older Debian/Ubuntu/etc.
    OS=Debian
    VER=$(cat /etc/debian_version)

    echo "OS               : $OS variant"
    echo "OS Version       : $VER"
fi

echo "Machine arch     : $(uname -m)"
echo "gcc              : $(gcc --version | head -1)"
echo "g++ presence     : $(which g++ || true)"

start_seconds="$(TZ=UTC0 printf '%(%s)T\n' '-1')"
start_time=$(date)
echo "Processing started: $start_time"

#-----------------------------------------------------------------------------
# Build Regina Rexx, which we use to run the Hercules tests
if ($PROMPTS); then
    read -p "Hit return to continue (Step: Build regina rexx)"
fi

# Remove any existing Regina, download and untar
rm -f regina-rexx-3.9.3.tar.gz
rm -rf regina-rexx-3.9.3/

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
if ($PROMPTS); then
    read -p "Hit return to continue (Step: Hercules clone)"
fi

cd ${BUILD_DIR}
mkdir -p sdl4x
mkdir -p ${PREFIX_DIR}

# Grab unmodified SDL-Hercules Hyperion repo
cd sdl4x
rm -rf hyperion
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

if ($PROMPTS); then
    read -p "Hit return to continue (Step: git clone extpkgs)"
fi

cd ${BUILD_DIR}
rm -rf extpkgs
mkdir extpkgs
cd extpkgs/

echo "Cloning extpkgs from https://github.com/wrljet (branch: build-mods-i686)"

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

if ($PROMPTS); then
    read -p "Hit return to continue (Step: Build extpkgs)"
fi

cd ${BUILD_DIR}
cd extpkgs

DEBUG=1 ./extpkgs.sh  c d s t
# ./extpkgs.sh c d s t

cd ${BUILD_DIR}/sdl4x/hyperion

# ./autogen.sh

if ($PROMPTS); then
    read -p "Hit return to continue (Step: configure)"
fi

./configure \
    --enable-optimization="-O3 -march=native" \
    --enable-extpkgs=${BUILD_DIR}/extpkgs \
    --prefix=${PREFIX_DIR} \
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
if ($PROMPTS); then
    read -p "Hit return to continue (Step: make)"
fi

make clean
time make -j$(nproc) 2>&1 | tee ${BUILD_DIR}/hyperion-buildall-make.log

if ($PROMPTS); then
    read -p "Hit return to continue (Step: tests)"
fi 

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

if ($PROMPTS); then
    read -p "Hit return to continue (step: install)"
fi

time make install 2>&1 | tee ${BUILD_DIR}/hyperion-buildall-make-install.log

echo "-----------------------------------------------------------------"
echo "Done!"

end_time=$(date)
echo "Processing ended:   $end_time"

elapsed_seconds="$(( $(TZ=UTC0 printf '%(%s)T\n' '-1') - start_seconds ))"
verbose_msg "total elapsed seconds: $elapsed_seconds"
echo "Overall elpased time: $( TZ=UTC0 printf '%(%H:%M:%S)T\n' "$elapsed_seconds" )"

#------------------------------------------------------------------------------
# This last group of helper functions were taken from Fish's extpkgs.sh

#------------------------------------------------------------------------------
#                              push_shopt
#------------------------------------------------------------------------------
push_shopt()
{
  if [[ -z $shopt_idx ]]; then shopt_idx="-1"; fi
  shopt_idx=$(( $shopt_idx + 1 ))
  shopt_opt[ $shopt_idx ]=$2
  shopt -q $2
  shopt_val[ $shopt_idx ]=$?
  eval shopt $1 $2
}

#------------------------------------------------------------------------------
#                              pop_shopt
#------------------------------------------------------------------------------
pop_shopt()
{
  if [[ -n $shopt_idx ]] && (( $shopt_idx >= 0 )); then
    if (( ${shopt_val[ $shopt_idx ]} == 0 )); then
      eval shopt -s ${shopt_opt[ $shopt_idx ]}
    else
      eval shopt -u ${shopt_opt[ $shopt_idx ]}
    fi
    shopt_idx=$(( $shopt_idx - 1 ))
  fi
}

#------------------------------------------------------------------------------
#                               trace
#------------------------------------------------------------------------------
trace()
{
  if [[ -n $debug ]]  || \
     [[ -n $DEBUG ]]; then
    logmsg  "++ $1"
  fi
}

#------------------------------------------------------------------------------
#                               logmsg
#------------------------------------------------------------------------------
logmsg()
{
  stdmsg  "stdout"  "$1"
}

#------------------------------------------------------------------------------
#                               errmsg
#------------------------------------------------------------------------------
errmsg()
{
  stdmsg  "stderr"  "$1"
  set_rc1
}

#------------------------------------------------------------------------------
#                               stdmsg
#------------------------------------------------------------------------------
stdmsg()
{
  local  _stdxxx="$1"
  local  _msg="$2"

  push_shopt -s nocasematch

  if [[ $_stdxxx != "stdout" ]]  && \
     [[ $_stdxxx != "stderr" ]]; then
    _stdxxx=stdout
  fi

  if [[ $_stdxxx == "stdout" ]]; then
    echo "$_msg"
  else
    echo "$_msg" 1>&2
  fi

  pop_shopt
}

# ---- end of script ----

