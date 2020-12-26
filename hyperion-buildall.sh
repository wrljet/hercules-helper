#!/usr/bin/env bash

# Complete SDL-Hercules-390 build using wrljet GitHub mods
# Updated: 24 DEC 2020
#
# The most recent version of this script can be obtained with:
#   git clone https://github.com/wrljet/hercules-helper.git
# or:
#   wget https://github.com/wrljet/hercules-helper/archive/master.zip
#
# Please report errors in this to me so everyone can benefit.
#
# Bill Lewis  wrljet@gmail.com

# Changelog:
#
# Updated: 24 DEC 2020
# - use existing installed REXX for configure and 'make check'
# - print the configure before running it
# - correct environment varibles for REXX
#
# Updated: 22 DEC 2020
# - detect existing ooRexx installation
#
# Updated: 21 DEC 2020
# - detect existing Regina REXX installation and skip building (Debian only)
#
# Updated: 20 DEC 2020
# - changes to detect and disallow gcc < 6.3.0 on i686
# - don't follow mount points while searching for files
#
# Updated: 15 DEC 2020
# - changes to detect and disallow Raspberry Pi Desktop for PC
#
# Updated: 13 DEC 2020
# - changes to accomodate Mint (in-progress)
# - changes to accomodate Windows WSL2
# - changes to accomodate Raspberry Pi 32-bit Raspbian
# - break out common functions to utilfns.sh include file
#
# Updated: 12 DEC 2020
# - changes to accomodate KDE Neon (in-progress)
#
# Updated: 11 DEC 2020
# - changes to accomodate NetBSD (in-progress)
#
# Updated:  9 DEC 2020
# - wrljet build-mods-i686 branch is merged to SDL-Hercules-390, 
#   so we git clone from that directly
#
# Updated:  5 DEC 2020
# - issue 'setcap' commands so hercules will run without root permissions
# - write out hercules-setvars.sh to create required environment variables
# - show the system language
# - display improvements
#
# Updated:  4 DEC 2020
# - corrected parsing for differing CentOS 7.8 ansd 8.2 version strings
#
# Updated: 30 NOV 2020
# - initial commit to GitHub

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

# Read in the utility functions
source "$(dirname "$0")/utilfns.sh"

verbose_msg "Options:"
verbose_msg "TRACE            : ${TRACE}"
verbose_msg "VERBOSE          : ${VERBOSE}"
verbose_msg "PROMPTS          : ${PROMPTS}"
verbose_msg "INSTALL          : ${INSTALL}"
verbose_msg "USESUDO          : ${USESUDO}"

# Detect type of system we're running on and display info
detect_system
detect_rexx

echo "BUILD_DIR        : ${BUILD_DIR}"
echo "INSTALL_DIR      : ${INSTALL_DIR}"

#-----------------------------------------------------------------------------

if [[ $VERSION_RPIDESKTOP -eq 1 ]]; then
    verbose_msg "Running on Raspberry Pi Desktop (for PC) is not supported!"
    # exit 1
fi

#if [ -f /etc/debian_version ]; then
#    # Older Debian/Ubuntu/etc.
#    OS=Debian
#    VER=$(cat /etc/debian_version)
#
#    echo "OS               : $OS variant"
#    echo "OS Version       : $VER"
#fi

echo "Machine arch     : $(uname -m)"
echo "CC               : $CC"
echo "CFLAGS           : $CFLAGS"
echo "gcc presence     : $(which gcc || true)"
echo "gcc              : $(gcc --version | head -1)"
echo "g++ presence     : $(which g++ || true)"

# Check for older gcc on i686 systems, that is know to fail CBUC test

as_awk_strverscmp='
  # Use only awk features that work with 7th edition Unix awk (1978).
  # My, what an old awk you have, Mr. Solaris!
  END {
    while (length(v1) && length(v2)) {
      # Set d1 to be the next thing to compare from v1, and likewise for d2.
      # Normally this is a single character, but if v1 and v2 contain digits,
      # compare them as integers and fractions as strverscmp does.
      if (v1 ~ /^[0-9]/ && v2 ~ /^[0-9]/) {
        # Split v1 and v2 into their leading digit string components d1 and d2,
        # and advance v1 and v2 past the leading digit strings.
        for (len1 = 1; substr(v1, len1 + 1) ~ /^[0-9]/; len1++) continue
        for (len2 = 1; substr(v2, len2 + 1) ~ /^[0-9]/; len2++) continue
        d1 = substr(v1, 1, len1); v1 = substr(v1, len1 + 1)
        d2 = substr(v2, 1, len2); v2 = substr(v2, len2 + 1)
        if (d1 ~ /^0/) {
          if (d2 ~ /^0/) {
            # Compare two fractions.
            while (d1 ~ /^0/ && d2 ~ /^0/) {
              d1 = substr(d1, 2); len1--
              d2 = substr(d2, 2); len2--
            }
            if (len1 != len2 && ! (len1 && len2 && substr(d1, 1, 1) == substr(d2, 1, 1))) {
              # The two components differ in length, and the common prefix
              # contains only leading zeros.  Consider the longer to be less.
              d1 = -len1
              d2 = -len2
            } else {
              # Otherwise, compare as strings.
              d1 = "x" d1
              d2 = "x" d2
            }
          } else {
            # A fraction is less than an integer.
            exit 1
          }
        } else {
          if (d2 ~ /^0/) {
            # An integer is greater than a fraction.
            exit 2
          } else {
            # Compare two integers.
            d1 += 0
            d2 += 0
          }
        }
      } else {
        # The normal case, without worrying about digits.
        d1 = substr(v1, 1, 1); v1 = substr(v1, 2)
        d2 = substr(v2, 1, 1); v2 = substr(v2, 2)
      }
      if (d1 < d2) exit 1
      if (d1 > d2) exit 2
    }
    # Beware Solaris /usr/xgp4/bin/awk (at least through Solaris 10),
    # which mishandles some comparisons of empty strings to integers.
    if (length(v2)) exit 1
    if (length(v1)) exit 2
  }
'

hc_gcc_level=$(gcc -dumpversion)

if [[ "$(uname -m)" =~ ^(i686) && $VERSION_DISTRO == debian ]]; then
    echo # move to a new line
    echo "Checking for gcc atomics ..."

    as_arg_v1=$hc_gcc_level
    as_arg_v2="6.3.0"

    set +e
    awk "$as_awk_strverscmp" v1="$as_arg_v1" v2="$as_arg_v2" /dev/null
    awk_rc=$?
    set -e

    case $awk_rc in #(
      1) :
        # echo "... 1 found lesser version $hc_gcc_level < $as_arg_v2"
        hc_cv_gcc_working_atomics=no ;; #(
      0) :
        # echo "... 0 found equal version $hc_gcc_level == $as_arg_v2"
        hc_cv_gcc_working_atomics=yes ;; #(
      2) :
        # echo "... 2 found greater version $hc_gcc_level > $as_arg_v2"
        hc_cv_gcc_working_atomics=yes  ;; #(
      *) :
      ;;
    esac

    if [[ $hc_cv_gcc_working_atomics == no ]]; then
        echo "gcc versions before $as_arg_v2 will not create a fully functional"
        echo "Hercules on this 32-bit system. Certain test are known to fail."

        if ($PROMPTS); then
            if confirm "Continue anyway? [y/N]" ; then
                echo "OK"
            else
                exit 1
            fi
        else
            echo "Giving up"
            exit 1
        fi
    fi
fi

echo "looking for files ... please wait ..."

if [[ $VERSION_WSL -eq 2 ]]; then
    # echo "Windows WSL2 host system found"
    # Don't run a search on /mnt because it takes forever
    which_cc1=$(find / -path /mnt -prune -o -name cc1 -print 2>&1 | grep cc1)
    which_cc1plus=$(find / -path /mnt -prune -o -name cc1plus -print 2>&1 | grep cc1plus)
else
    which_cc1=$(find / -mount -name cc1 -print 2>&1 | grep cc1)
    which_cc1plus=$(find / -mount -name cc1plus -print 2>&1 | grep cc1plus)
fi

echo "cc1 presence     : $which_cc1"
echo "cc1plus presence : $which_cc1plus"

start_seconds="$(TZ=UTC0 printf '%(%s)T\n' '-1')"
start_time=$(date)

echo # move to a new line
echo "Processing started: $start_time"

#-----------------------------------------------------------------------------
# Build Regina Rexx, which we use to run the Hercules tests
echo "-----------------------------------------------------------------
"

built_regina_from_source=0

if [[  $VERSION_REGINA -ge 3 ]]; then
    echo "Regina REXX is present.  Skipping build from source."
elif [[  $VERSION_OOREXX -ge 4 ]]; then
    echo "ooRexx is present.  Skipping build Regina-REXX from source."
else

    if ($PROMPTS); then
        read -p "Hit return to continue (Step: Build Regina Rexx [used for test scripts])"
    fi

    # Remove any existing Regina, download and untar
    rm -f regina-rexx-3.9.3.tar.gz
    rm -rf regina-rexx-3.9.3/

    wget http://www.wrljet.com/ibm360/regina-rexx-3.9.3.tar.gz
    tar xfz regina-rexx-3.9.3.tar.gz 
    cd regina-rexx-3.9.3/


    # Raspberry Pi 4B, Raspbian 32-bit
    # uname -m == armv7l

    #if [[ "$(uname -m)" =~ ^(i686|armv7l) ]]; then
    if [[ "$(uname -m)" =~ ^(i686) ]]; then
        regina_configure_cmd="./configure --prefix=${BUILD_DIR}/rexx --enable-32bit"
    else
        regina_configure_cmd="./configure --prefix=${BUILD_DIR}/rexx"
    fi

    echo $regina_configure_cmd
    echo    # move to a new line
    eval "$regina_configure_cmd"

    time make
    time make install

    export PATH=${BUILD_DIR}/rexx/bin:$PATH
    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${BUILD_DIR}/rexx/lib
    export CPPFLAGS=-I${BUILD_DIR}/rexx/include
    echo "which rexx: $(which rexx)"

    built_regina_from_source=1
fi

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

echo "-----------------------------------------------------------------
"
if ($PROMPTS); then
    read -p "Hit return to continue (Step: util/bldlvlck)"
fi

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

# echo "Cloning extpkgs from https://github.com/wrljet (branch: build-mods-i686)"
# git clone -b build-mods-i686 https://github.com/wrljet/gists.git

echo "Cloning extpkgs from https://github.com/SDL-Hercules-390"
git clone https://github.com/SDL-Hercules-390/gists.git

cp gists/extpkgs.sh .
cp gists/extpkgs.sh.ini .

# Edit extpkgs.sh.ini
# Change 'x86' to 'aarch64' for 64-bit, or 'arm' for 32-bit, etc.

if   [[ "$(uname -m)" == x86* ]]; then
    echo "Defaulting to x86 machine type in extpkgs.sh.ini"
elif [[ "$(uname -m)" == armv7l ]]; then
    mv extpkgs.sh.ini extpkgs.sh.ini-orig
    sed "s/x86/arm/g" extpkgs.sh.ini-orig > extpkgs.sh.ini
else
    mv extpkgs.sh.ini extpkgs.sh.ini-orig
    sed "s/x86/$(uname -m)/g" extpkgs.sh.ini-orig > extpkgs.sh.ini
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
    git clone "https://github.com/SDL-Hercules-390/$pgm.git" "$pgm-0"
#   git clone -b build-mods-i686 "https://github.com/wrljet/$pgm.git" "$pgm-0"
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
    echo    # move to a new line
fi

if [[  $VERSION_REGINA -ge 3 ]]; then
    echo "Regina REXX is present. Using configure option: --enable-regina-rexx"
    enable_rexx_command="--enable-regina-rexx" # enable regina rexx support
elif [[  $VERSION_OOREXX -ge 4 ]]; then
    echo "ooRexx is present. Using configure option: --enable-object-rexx"
    enable_rexx_command="-enable-object-rexx" # enable OORexx support
elif [[ $built_regina_from_source -eq 1 ]]; then
    enable_rexx_command="--enable-regina-rexx" # enable regina rexx support
else
    echo "No REXX support.  Tests will not be run"
    enable_rexx_command=""
fi

configure_cmd=$(cat <<-END-CONFIGURE
./configure \
    --enable-optimization="-O3 -march=native" \
    --enable-extpkgs=${BUILD_DIR}/extpkgs \
    --prefix=${INSTALL_DIR} \
    $enable_rexx_command
END-CONFIGURE
)

echo $configure_cmd
echo    # move to a new line
eval "$configure_cmd"

echo    # move to a new line
echo "./config.status --config ..."
./config.status --config

# Debian 10 x86_64, gcc 8.3.0
# CBUC test fails without this
#   --enable-optimization="-O3 -march=native" \

# Debian 8 & 9, i686, gcc older then 6.3.0 fails CBUC test

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

newpath="${INSTALL_DIR}/lib"
if [ -d "\$newpath" ] && [[ ":\$LD_LIBRARY_PATH:" != *":\$newpath:"* ]]; then
  # export LD_LIBRARY_PATH="\${LD_LIBRARY_PATH:+"\$LD_LIBRARY_PATH:"}\$newpath"
    export LD_LIBRARY_PATH="\$newpath\${LD_LIBRARY_PATH:+":\$LD_LIBRARY_PATH"}"
fi

if [[ $built_regina_from_source -eq 1 ]]; then
    newpath="${BUILD_DIR}/rexx/bin"
    if [ -d "\$newpath" ] && [[ ":\$PATH:" != *":\$newpath:"* ]]; then
      # export PATH="\${PATH:+"\$PATH:"}\$newpath"
	export PATH="\$newpath\${PATH:+":\$PATH"}"
    fi

    newpath="${BUILD_DIR}/rexx/lib"
    if [ -d "\$newpath" ] && [[ ":\$LD_LIBRARY_PATH:" != *":\$newpath:"* ]]; then
      # export LD_LIBRARY_PATH="\${LD_LIBRARY_PATH:+"\$LD_LIBRARY_PATH:"}\$newpath"
	export LD_LIBRARY_PATH="\$newpath\${LD_LIBRARY_PATH:+":\$LD_LIBRARY_PATH"}"
    fi

    newpath="${BUILD_DIR}/rexx/include"
    if [ -d "\$newpath" ] && [[ ":\$CPPFLAGS:" != *":-I\$newpath:"* ]]; then
      # export CPPFLAGS="\${CPPFLAGS:+"\$CPPFLAGS:"}-I\$newpath"
	export CPPFLAGS="-I\$newpath\${CPPFLAGS:+" \$CPPFLAGS"}"
    fi
fi

FOE

    chmod +x ${BUILD_DIR}/hercules-setvars.sh

    echo "To set the required environment variables, run:"
    echo "    source ${BUILD_DIR}/hercules-setvars.sh"
fi

echo "Done!"

# ---- end of script ----

