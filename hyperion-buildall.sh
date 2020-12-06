#!/bin/bash

# Complete SDL-Hercules-390 build using wrljet GitHub mods
# Updated: 30 NOV 2020
#
# The most recent version of this script can be obtained with:
#   git clone https://github.com/wrljet/hercules-helper.git
# or:
#   wget https://github.com/wrljet/hercules-helper/archive/master.zip
#
# Please report errors in this to me so everyone can benefit.
#
# Bill Lewis  wrljet@gmail.com

# Updated: 30 NOV 2020
# - initial commit to GitHub
#
# Updated:  4 DEC 2020
# - corrected parsing for differing CentOS 7.8 ansd 8.2 version strings
#
# Updated:  5 DEC 2020
# - issue 'setcap' commands so hercules will run without root permissions
# - write out hercules-setvars.sh to create required environment variables
# - show the system language
# - display improvements

#-----------------------------------------------------------------------------
#
# To run, create a build directory and cd to it, then run this script.
#
#  $ mkdir herctest && cd herctest
#  $ ~/hercules-helper/hyperion-buildall.sh -v --prompts --install 2>&1 | tee ./hyperion-buildall.log
#
# Be sure to run hyperion-prepare.sh one time before this build script.
# hyperion-prepare.sh will ensure all required packages are installed.
#

#-----------------------------------------------------------------------------
# Overall working build diretory is the current directory
BUILD_DIR=$(pwd)

# Prefix (target) directory
INSTALL_DIR=$(pwd)/herc4x

usage="usage: $(basename "$0") [-h|--help] [-t|--trace] [-v|--verbose] [--install] [--sudo]

Perform a full build, test, and installation of Hercules Hyperion from GitHub sources

where:
  -h, --help      display this help
  -t, --trace     display every command (set -x)
  -v, --verbose   display lots of messages
  -p, --prompts   display a prompt before each major step
  -i, --install   run \'make install\' after building
  -s, --sudo      use \'sudo\' for installing"

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
INSTALL=false
USESUDO=false

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -h|--help)
    echo "$usage"
    exit
    ;;

    -t|--trace)
    TRACE=true
    shift # past argument
    ;;

    -v|--verbose)
    VERBOSE=true
    shift # past argument
    ;;

    -p|--prompts)
    PROMPTS=true
    shift # past argument
    ;;

    -i|--install)
    INSTALL=true
    shift # past argument
    ;;

    -s|--sudo)
    USESUDO=true
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
#                              push_shopt
#
# helper functions from Fish's extpkgs.sh
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
#
# helper functions from Fish's extpkgs.sh
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
    verbose_msg " "  # move to a new line
    verbose_msg "System stats:"

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

        verbose_msg "OS               : $VERSION_DISTRO variant"
        verbose_msg "OS Version       : $VERSION_MAJOR"
    fi

    if [[ $VERSION_ID == centos* ]]; then
        verbose_msg "We have a CentOS system"

        # CENTOS_VERS="centos-release-7-8.2003.0.el7.centos.x86_64"
        # CENTOS_VERS="centos-release-8.2-2.2004.0.2.el8.x86_64"

        CENTOS_VERS=$(rpm --query centos-release) || true
        CENTOS_VERS="${CENTOS_VERS#centos-release-}"
        CENTOS_VERS="${CENTOS_VERS/-/.}"

        VERSION_MAJOR=$(echo ${CENTOS_VERS} | cut -f1 -d.)
        VERSION_MINOR=$(echo ${CENTOS_VERS} | cut -f2 -d.)

        verbose_msg "VERSION_MAJOR    : $VERSION_MAJOR"
        verbose_msg "VERSION_MINOR    : $VERSION_MINOR"
    fi

    # show the default language
    # i.e. LANG=en_US.UTF-8
    verbose_msg "Language         : $(env | grep LANG)"
}

verbose_msg "Options:"
verbose_msg "TRACE            : ${TRACE}"
verbose_msg "VERBOSE          : ${VERBOSE}"
verbose_msg "PROMPTS          : ${PROMPTS}"
verbose_msg "INSTALL          : ${INSTALL}"
verbose_msg "USESUDO          : ${USESUDO}"

# Detect type of system we're running on and display info
detect_system

echo "BUILD_DIR        : ${BUILD_DIR}"
echo "INSTALL_DIR      : ${INSTALL_DIR}"

#-----------------------------------------------------------------------------

if [ -f /etc/debian_version ]; then
    # Older Debian/Ubuntu/etc.
    OS=Debian
    VER=$(cat /etc/debian_version)

    echo "OS               : $OS variant"
    echo "OS Version       : $VER"
fi

echo "Machine arch     : $(uname -m)"
echo "gcc presence     : $(which gcc || true)"
echo "gcc              : $(gcc --version | head -1)"
echo "g++ presence     : $(which g++ || true)"

which_cc1=$(find / -name cc1 -print 2>&1 | grep cc1)
echo "cc1 presence     : $which_cc1"

which_cc1plus=$(find / -name cc1plus -print 2>&1 | grep cc1plus)
echo "cc1plus presence : $which_cc1plus"

start_seconds="$(TZ=UTC0 printf '%(%s)T\n' '-1')"
start_time=$(date)

echo # move to a new line
echo "Processing started: $start_time"

#-----------------------------------------------------------------------------
# Build Regina Rexx, which we use to run the Hercules tests
echo "-----------------------------------------------------------------
"
if ($PROMPTS); then
    read -p "Hit return to continue (Step: Build Regina Rexx [used for test scripts])"
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
echo "which rexx: $(which rexx)"

#
echo "-----------------------------------------------------------------
"
if ($PROMPTS); then
    read -p "Hit return to continue (Step: Hercules git clone)"
fi

cd ${BUILD_DIR}
mkdir -p sdl4x
mkdir -p ${INSTALL_DIR}

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

echo "-----------------------------------------------------------------
"
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
    echo "-----------------------------------------------------------------
"
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

echo "-----------------------------------------------------------------
"
if ($PROMPTS); then
    read -p "Hit return to continue (Step: Build external packages)"
fi

cd ${BUILD_DIR}
cd extpkgs

DEBUG=1 ./extpkgs.sh  c d s t
# ./extpkgs.sh c d s t

cd ${BUILD_DIR}/sdl4x/hyperion

if [[ "$(uname -m)" == x86* ]]; then
    echo "Skipping autogen step on x86* architecture"
else
    echo "-----------------------------------------------------------------
"
    if ($PROMPTS); then
        read -p "Hit return to continue (Step: autogen.sh)"

        ./autogen.sh
    fi
fi

echo "-----------------------------------------------------------------
"
if ($PROMPTS); then
    read -p "Hit return to continue (Step: configure)"
fi

./configure \
    --enable-optimization="-O3 -march=native" \
    --enable-extpkgs=${BUILD_DIR}/extpkgs \
    --prefix=${INSTALL_DIR} \
    --enable-regina-rexx

echo    # move to a new line
echo "./config.status --config ..."
./config.status --config

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

# Enable cap_sys_nice so Hercules can be run as a normal user
# FIXME this doesn't work with 'make check', so we use 'setcap' instead
#   --enable-capabilities
# which dpkg-query
# dpkg-query --show libcap-dev
# sudo apt-get install libcap-dev
# dpkg-query --show libcap-dev
# find / -name capability.h -print


# Compile and link
echo "-----------------------------------------------------------------
"
if ($PROMPTS); then
    read -p "Hit return to continue (Step: make)"
fi

make clean
time make -j$(nproc) 2>&1 | tee ${BUILD_DIR}/hyperion-buildall-make.log

echo "-----------------------------------------------------------------
"
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

if ($INSTALL); then
  echo "-----------------------------------------------------------------
"
  if ($USESUDO); then
    if ($PROMPTS); then
        read -p "Hit return to continue (step: install [with sudo])"
    fi

    sudo time make install 2>&1 | tee ${BUILD_DIR}/hyperion-buildall-make-install.log
  else
    if ($PROMPTS); then
        read -p "Hit return to continue (step: install [without sudo])"
    fi

    time make install 2>&1 | tee ${BUILD_DIR}/hyperion-buildall-make-install.log
  fi

  echo "-----------------------------------------------------------------
"
  echo "setcap operations so Hercules can run without elevated privileges:"
  sudo setcap 'cap_sys_nice=eip' ${INSTALL_DIR}/bin/hercules
  echo "sudo setcap 'cap_sys_nice=eip' ${INSTALL_DIR}/bin/hercules"
  sudo setcap 'cap_sys_nice=eip' ${INSTALL_DIR}/bin/herclin
  echo "sudo setcap 'cap_sys_nice=eip' ${INSTALL_DIR}/bin/herclin"
  sudo setcap 'cap_net_admin+ep' ${INSTALL_DIR}/bin/hercifc
  echo "sudo setcap 'cap_net_admin+ep' ${INSTALL_DIR}/bin/hercifc"
fi

echo "-----------------------------------------------------------------
"

end_time=$(date)
echo "Overall build processing ended:   $end_time"

elapsed_seconds="$(( $(TZ=UTC0 printf '%(%s)T\n' '-1') - start_seconds ))"
verbose_msg "total elapsed seconds: $elapsed_seconds"
echo "Overall elpased time: $( TZ=UTC0 printf '%(%H:%M:%S)T\n' "$elapsed_seconds" )"
echo    # move to a new line

if true; then
    cat <<FOE > ${BUILD_DIR}/hercules-setvars.sh
#!/bin/bash
#
# Set up environment variables for Hercules
#
# e.g.
#  export PATH=${INSTALL_DIR}/bin:${BUILD_DIR}/rexx/bin:$PATH
#  export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${INSTALL_DIR}/lib:${BUILD_DIR}/rexx/lib
#
# This script was created by $0, $(date)
#

newpath="${INSTALL_DIR}/bin"
if [ -d "\$newpath" ] && [[ ":\$PATH:" != *":\$newpath:"* ]]; then
  # export PATH="\${PATH:+"\$PATH:"}\$newpath"
    export PATH="\$newpath\${PATH:+":\$PATH"}"
fi

newpath="${BUILD_DIR}/rexx/bin"
if [ -d "\$newpath" ] && [[ ":\$PATH:" != *":\$newpath:"* ]]; then
  # export PATH="\${PATH:+"\$PATH:"}\$newpath"
    export PATH="\$newpath\${PATH:+":\$PATH"}"
fi

newpath="${INSTALL_DIR}/lib"
if [ -d "\$newpath" ] && [[ ":\$LD_LIBRARY_PATH:" != *":\$newpath:"* ]]; then
  # export LD_LIBRARY_PATH="\${LD_LIBRARY_PATH:+"\$LD_LIBRARY_PATH:"}\$newpath"
    export LD_LIBRARY_PATH="\$newpath\${LD_LIBRARY_PATH:+":\$LD_LIBRARY_PATH"}"
fi

newpath="${BUILD_DIR}/rexx/lib"
if [ -d "\$newpath" ] && [[ ":\$LD_LIBRARY_PATH:" != *":\$newpath:"* ]]; then
  # export LD_LIBRARY_PATH="\${LD_LIBRARY_PATH:+"\$LD_LIBRARY_PATH:"}\$newpath"
    export LD_LIBRARY_PATH="\$newpath\${LD_LIBRARY_PATH:+":\$LD_LIBRARY_PATH"}"
fi

FOE

    chmod +x ${BUILD_DIR}/hercules-setvars.sh

    echo "To set the required environment variables, run:"
    echo "    source ${BUILD_DIR}/hercules-setvars.sh"
fi

echo "Done!"

#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# This last group of helper functions were taken from Fish's extpkgs.sh

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

