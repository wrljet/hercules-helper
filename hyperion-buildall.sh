#!/usr/bin/env bash

# Complete SDL-Hercules-390 build using wrljet GitHub mods
# Updated: 05 JAN 2021
#
# The most recent version of this project can be obtained with:
#   git clone https://github.com/wrljet/hercules-helper.git
# or:
#   wget https://github.com/wrljet/hercules-helper/archive/master.zip
#
# Please report errors in this to me so everyone can benefit.
#
# Bill Lewis  wrljet@gmail.com

# Changelog:
#
# Updated: 05 JAN 2021
# - initial support for NetBSD
# - show an error for unknown command line options
# - display a version number for this script
#
# Updated: 04 JAN 2021
# - create feature of external .conf file
# - configurable URLs to GitHub for cloning repos *and* branch checkout
# - don't use 'find -mount' on NetBSD
# - when modifying extpkgs.sh.ini, don't override x86 with amd64 (NetBSD)
# - when modifying extpkgs.sh.ini, don't use sed/g
# - change a bunch of 'echo' to 'verbose_msg' calls
#
# Updated: 29 DEC 2020
# - create shell profile.d script to set PATH, etc. (currently for Bash only)
# - fix bug skipping autogen if not displaying prompts
# - add custom title to ./configure
# - correct non-functional typo in ./configure options
# - use new status_prompter() function
#
# Updated: 28 DEC 2020
# - detect and disallow running on Apple Darwin OS
#
# Updated: 25 DEC 2020
# - check for armv6l CPU on Raspberry Pi Zero
#
# Updated: 24 DEC 2020
# - use existing installed REXX for configure and 'make check'
# - print the configure before running it
# - correct environment varibles for REXX
# - add colored error messages
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

#
# Default Configuration Parameters:
#
# Overall working build diretory is the current directory
BUILD_DIR=${BUILD_DIR:-$(pwd)}

# Prefix (target) directory
INSTALL_DIR=${INSTALL_DIR:-$(pwd)/herc4x}

# Git repo for SDL-Hercules Hyperion
GIT_REPO_HYPERION=${GIT_REPO_HYPERION:-https://github.com/SDL-Hercules-390/hyperion.git}
# GIT_REPO_HYPERION=https://github.com/wrljet/hyperion.git

# Git checkout branch for Hyperion
# GIT_BRANCH_HYPERION=build-netbsd

# Git repo for Hyperion Gists
GIT_REPO_GISTS=${GIT_REPO_GISTS:-https://github.com/SDL-Hercules-390/gists.git}
# GIT_REPO_GISTS=https://github.com/wrljet/gists.git

# Git checkout branch for Hyperion Gists
# GIT_BRANCH_GISTS=build-mods-i686

# Git repo for Hyperion External Packages
GIT_REPO_EXTPKGS=${GIT_REPO_EXTPKGS:-https://github.com/SDL-Hercules-390}
# GIT_REPO_EXTPKGS=https://github.com/wrljet

# Git checkout branch for Hyperion External Packages
# GIT_BRANCH_EXTPKGS=build-mods-i686

# Show/trace every Bash command
TRACE=${TRACE:-false}  # If TRACE variable not set or null, default to FALSE

# Print verbose progress information
VERBOSE=${VERBOSE:-false}

# Prompt the user before each major step is started
PROMPTS=${PROMPTS:-false}

# 'make install' after building
INSTALL=${INSTALL:-false}

# Use 'sudo' for 'make install'
USESUDO=${USESUDO:-false}

#-----------------------------------------------------------------------------

#-----------------------------------------------------------------------------
usage="usage: $(basename "$0") [-h|--help] [-t|--trace] [-v|--verbose] [--install] [--sudo]

Perform a full build, test, and installation of SDL-Hercules-390 Hyperion from GitHub sources

where:
  -h, --help      display this help
  -t, --trace     display every command (set -x)
  -v, --verbose   display lots of messages
  -p, --prompts   display a prompt before each major step
  -i, --install   run \'make install\' after building
  -s, --sudo      use \'sudo\' for installing
  -c, --config <filename> "

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

# Read in the utility functions
source "$(dirname "$0")/utilfns.sh"

# Process command line

if [[ ${TRACE} == true ]]; then
    set -x # For debugging, show all commands as they are being run
fi

opt_override_trace=false
opt_override_verbose=false
opt_override_prompts=false
opt_override_install=false
opt_override_usersudo=false

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
#  -c|--config)  # FIXME pick up filename
#    shift # past argument
#    CONFIGFILE="$1"
#    shift # past argument
#    ;;

  -h|--help)
    echo "$usage"
    exit
    ;;

  -t|--trace)
    opt_override_trace=true
    shift # past argument
    ;;

  -v|--verbose)
    opt_override_verbose=true
    VERBOSE=true
    shift # past argument
    ;;

  -p|--prompts)
    opt_override_prompts=true
    shift # past argument
    ;;

  -i|--install)
    opt_override_install=true
    shift # past argument
    ;;

  -s|--sudo)
    opt_override_usersudo=true
    shift # past argument
    ;;

  -*|--*)  # unknown option
    error_msg "$0: unknown option: $1"
    exit 1
    ;;

  *)    # unknown parameter
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

#-----------------------------------------------------------------------------

pushd "$(dirname "$0")" >/dev/null;
verbose_msg "$0: $(git describe --long --tags --dirty --always)"
popd > /dev/null;
verbose_msg    # print a new line

# Read in the configuration
config_dir="$(dirname "$0")"
echo "dirname: $config_dir"

nx0="$(basename "$0")"
echo "basename: $nx0"

n0="${nx0%.*}"
echo "filename: $n0"

# config_file="${config_dir}/${n0}.conf"
config_file="${config_dir}/hercules-helper.conf"
echo "config file: ${config_file}"

if test -f "${config_file}" ; then
    source "${config_file}"
else
    echo "No config file"
fi

if [ $opt_override_trace    == true ]; then TRACE=true;   fi
if [ $opt_override_verbose  == true ]; then VERBOSE=true; fi
if [ $opt_override_prompts  == true ]; then PROMPTS=true; fi
if [ $opt_override_install  == true ]; then INSTALL=true; fi
if [ $opt_override_usersudo == true ]; then USESUDO=true; fi

if [[ ${TRACE} == true ]]; then
    set -x # For debugging, show all commands as they are being run
fi

detect_darwin
if [[ $VERSION_DISTRO == darwin ]]; then
    error_msg "Not yet supported under Apple Darwin OS!"
    exit 1
fi

verbose_msg "General Options:"
verbose_msg "TRACE            : ${TRACE}"
verbose_msg "VERBOSE          : ${VERBOSE}"
verbose_msg "PROMPTS          : ${PROMPTS}"
verbose_msg "INSTALL          : ${INSTALL}"
verbose_msg "USESUDO          : ${USESUDO}"

verbose_msg # move to a new line
verbose_msg "Configuration:"
verbose_msg "BUILD_DIR        : ${BUILD_DIR}"
verbose_msg "INSTALL_DIR      : ${INSTALL_DIR}"

if [ -z "$GIT_BRANCH_HYPERION" ] ; then
    verbose_msg "clone GIT_REPO_HYPERION: ${GIT_REPO_HYPERION}"
else
    verbose_msg "clone GIT_REPO_HYPERION: ${GIT_REPO_HYPERION} [checkout $GIT_BRANCH_HYPERION]"
fi

if [ -z "$GIT_BRANCH_GISTS" ] ; then
    verbose_msg "clone GIT_REPO_GISTS   : ${GIT_REPO_GISTS}"
else
    verbose_msg "clone GIT_REPO_GISTS   : ${GIT_REPO_GISTS} [checkout $GIT_BRANCH_GISTS]"
fi

if [ -z "$GIT_BRANCH_EXTPKGS" ] ; then
    verbose_msg "clone GIT_REPO_EXTPKGS : ${GIT_REPO_EXTPKGS}"
else
    verbose_msg "clone GIT_REPO_EXTPKGS : ${GIT_REPO_EXTPKGS} [checkout $GIT_BRANCH_EXTPKGS]"
fi

# Detect type of system we're running on and display info
detect_system
detect_rexx

#-----------------------------------------------------------------------------

if [[ $VERSION_RPIDESKTOP -eq 1 ]]; then
    error_msg "Running on Raspberry Pi Desktop (for PC) is not supported!"
    exit 1
fi

#if [ -f /etc/debian_version ]; then
#    # Older Debian/Ubuntu/etc.
#    OS=Debian
#    VER=$(cat /etc/debian_version)
#
#    echo "OS               : $OS variant"
#    echo "OS Version       : $VER"
#fi

verbose_msg "CC               : $CC"
verbose_msg "CFLAGS           : $CFLAGS"
verbose_msg "gcc presence     : $(which gcc || true)"
verbose_msg "gcc              : $(gcc --version | head -1)"
verbose_msg "g++ presence     : $(which g++ || true)"

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
    verbose_msg # move to a new line
    verbose_msg "Checking for gcc atomics ..."

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
        error_msg "gcc versions before $as_arg_v2 will not create a fully functional"
        error_msg "Hercules on this 32-bit system. Certain test are known to fail."

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

#-----------------------------------------------------------------------------

verbose_msg "looking for files ... please wait ..."

if [[ $VERSION_WSL -eq 2 ]]; then
    # echo "Windows WSL2 host system found"
    # Don't run a search on /mnt because it takes forever
    which_cc1=$(find / -path /mnt -prune -o -name cc1 -print 2>&1 | grep cc1 | head -5)
    which_cc1plus=$(find / -path /mnt -prune -o -name cc1plus -print 2>&1 | grep cc1plus | head -5)
elif [[ $VERSION_ID == netbsd* ]]; then
    which_cc1=$(find / -xdev -name cc1 -print 2>&1 | grep cc1 | head -5)
    which_cc1plus=$(find / -xdev -name cc1plus -print 2>&1 | grep cc1plus | head -5)
else
    which_cc1=$(find / -mount -name cc1 -print 2>&1 | grep cc1 | head -5)
    which_cc1plus=$(find / -mount -name cc1plus -print 2>&1 | grep cc1plus | head -5)
fi

verbose_msg "cc1 presence     : $which_cc1"
verbose_msg "cc1plus presence : $which_cc1plus"

start_seconds="$(TZ=UTC0 printf '%(%s)T\n' '-1')"
start_time=$(date)

verbose_msg # move to a new line
verbose_msg "Processing started: $start_time"

#-----------------------------------------------------------------------------
# Build Regina Rexx, which we use to run the Hercules tests
verbose_msg "-----------------------------------------------------------------
"

built_regina_from_source=0

if [[  $VERSION_REGINA -ge 3 ]]; then
    verbose_msg "Regina REXX is present.  Skipping build from source."
elif [[  $VERSION_OOREXX -ge 4 ]]; then
    verbose_msg "ooRexx is present.  Skipping build Regina-REXX from source."
else

    status_prompter "Step: Build Regina Rexx [used for test scripts]:"

    # Remove any existing Regina, download and untar
    rm -f regina-rexx-3.9.3.tar.gz
    rm -rf regina-rexx-3.9.3/

    wget http://www.wrljet.com/ibm360/regina-rexx-3.9.3.tar.gz
    tar xfz regina-rexx-3.9.3.tar.gz 
    cd regina-rexx-3.9.3/

    if [[ "$(uname -m)" =~ ^(i686) ]]; then
        regina_configure_cmd="./configure --prefix=${BUILD_DIR}/rexx --enable-32bit"
    else
        regina_configure_cmd="./configure --prefix=${BUILD_DIR}/rexx"
    fi

    verbose_msg $regina_configure_cmd
    verbose_msg    # move to a new line
    eval "$regina_configure_cmd"

    time make
    time make install

    export PATH=${BUILD_DIR}/rexx/bin:$PATH
    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${BUILD_DIR}/rexx/lib
    export CPPFLAGS=-I${BUILD_DIR}/rexx/include
    verbose_msg "which rexx: $(which rexx)"

    built_regina_from_source=1
fi

#
verbose_msg "-----------------------------------------------------------------
"
status_prompter "Step: Hercules git clone:"

cd ${BUILD_DIR}
mkdir -p sdl4x
mkdir -p ${INSTALL_DIR}

# Grab unmodified SDL-Hercules Hyperion repo
cd sdl4x
rm -rf hyperion

if [ -z "$GIT_REPO_HYPERION" ] ; then
    error_msg "GIT_REPO_HYPERION variable is not set!"
    exit 1
fi

if [ -z "$GIT_BRANCH_HYPERION" ] ; then
    verbose_msg "git clone $GIT_REPO_HYPERION"
    git clone $GIT_REPO_HYPERION
else
    verbose_msg "git clone -b $GIT_BRANCH_HYPERION $GIT_REPO_HYPERION"
    git clone -b "$GIT_BRANCH_HYPERION" "$GIT_REPO_HYPERION"
fi

cd hyperion

verbose_msg "-----------------------------------------------------------------
"
status_prompter "Step: util/bldlvlck:"

# Check for required packages and minimum versions.
# Inspect the output carefully and do not continue if there are
# any error messages or recommendations unless you know what you're doing.

# On Raspberry Pi Desktop (Buster), the following are often missing:
# autoconf, automake, cmake, flex, gawk, m4

util/bldlvlck 

verbose_msg "-----------------------------------------------------------------
"
status_prompter "Step: git clone extpkgs:"

cd ${BUILD_DIR}
rm -rf extpkgs
mkdir extpkgs
cd extpkgs/

if [ -z "$GIT_REPO_GISTS" ] ; then
    error_msg "GIT_REPO_GISTS variable is not set!"
    exit 1
fi

verbose_msg "Cloning gists / extpkgs from $GIT_REPO_GISTS"
if [ -z "$GIT_BRANCH_GISTS" ] ; then
    verbose_msg "git clone $GIT_REPO_GISTS"
    git clone "$GIT_REPO_GISTS"
else
    verbose_msg "git clone -b $GIT_BRANCH_GISTS $GIT_REPO_GISTS"
  # git clone -b build-mods-i686 https://github.com/wrljet/gists.git
    git clone -b "$GIT_BRANCH_GISTS" "$GIT_REPO_GISTS"
fi

cp gists/extpkgs.sh .
cp gists/extpkgs.sh.ini .

# Edit extpkgs.sh.ini
# Change 'x86' to 'aarch64' for 64-bit, or 'arm' for 32-bit, etc.

if   [[ "$(uname -m)" == x86* || "$(uname -m)" == amd64* ]]; then
    verbose_msg "Defaulting to x86 machine type in extpkgs.sh.ini"
elif [[ "$(uname -m)" =~ (armv6l|armv7l) ]]; then
    mv extpkgs.sh.ini extpkgs.sh.ini-orig
    sed "s/x86/arm/g" extpkgs.sh.ini-orig > extpkgs.sh.ini
else
    mv extpkgs.sh.ini extpkgs.sh.ini-orig
    sed "s/x86/$(uname -m)/" extpkgs.sh.ini-orig > extpkgs.sh.ini
fi

mkdir repos && cd repos
rm -rf *

if [ -z "$GIT_REPO_EXTPKGS" ] ; then
    error_msg "GIT_REPO_EXTPKGS variable is not set!"
    exit 1
fi

declare -a pgms=("crypto" "decNumber" "SoftFloat" "telnet")

for pgm in "${pgms[@]}"; do
    verbose_msg "-----------------------------------------------------------------
"
    if [ -z "$GIT_BRANCH_EXTPKGS" ] ; then
        verbose_msg "git clone $GIT_REPO_EXTPKGS/$pgm $pgm-0"
        git clone "$GIT_REPO_EXTPKGS/$pgm.git" "$pgm-0"
    else
        verbose_msg "git clone -b $GIT_BRANCH_EXTPKGS $GIT_REPO_EXTPKGS/$pgm $pgm-0"
        git clone -b "$GIT_BRANCH_EXTPKGS" "$GIT_REPO_EXTPKGS/$pgm.git" "$pgm-0"
    fi
done

verbose_msg "-----------------------------------------------------------------
"
status_prompter "Step: Build external packages:"

cd ${BUILD_DIR}
cd extpkgs

DEBUG=1 ./extpkgs.sh  c d s t
# ./extpkgs.sh c d s t

cd ${BUILD_DIR}/sdl4x/hyperion

# I understand some people don't, but I like to run autogen.
# We will skip it, though, on x86_64 machines.

if [[ "$(uname -m)" == x86* ]]; then
    verbose_msg "Skipping autogen step on x86* architecture"
else
    verbose_msg "-----------------------------------------------------------------
"
    status_prompter "Step: autogen.sh:"
    ./autogen.sh
fi

verbose_msg "-----------------------------------------------------------------
"
status_prompter "Step: configure:"

if [[  $VERSION_REGINA -ge 3 ]]; then
    verbose_msg "Regina REXX is present. Using configure option: --enable-regina-rexx"
    enable_rexx_command="--enable-regina-rexx" # enable regina rexx support
elif [[  $VERSION_OOREXX -ge 4 ]]; then
    verbose_msg "ooRexx is present. Using configure option: --enable-object-rexx"
    enable_rexx_command="--enable-object-rexx" # enable OORexx support
elif [[ $built_regina_from_source -eq 1 ]]; then
    enable_rexx_command="--enable-regina-rexx" # enable regina rexx support
else
    error_msg "No REXX support.  Tests will not be run"
    enable_rexx_command=""
fi

configure_cmd=$(cat <<-END-CONFIGURE
./configure \
    --enable-optimization="-O3 -march=native" \
    --enable-extpkgs=${BUILD_DIR}/extpkgs \
    --prefix=${INSTALL_DIR} \
    --enable-custom="Built using hercules-helper" \
    $enable_rexx_command
END-CONFIGURE
)

verbose_msg $configure_cmd
verbose_msg    # move to a new line
eval "$configure_cmd"

verbose_msg    # move to a new line
verbose_msg "./config.status --config ..."
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
verbose_msg "-----------------------------------------------------------------
"
status_prompter "Step: make:"

make clean
time make -j$(nproc) 2>&1 | tee ${BUILD_DIR}/hyperion-buildall-make.log

verbose_msg "-----------------------------------------------------------------
"
status_prompter "Step: tests:"

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
  verbose_msg "-----------------------------------------------------------------
"
  if ($USESUDO); then
    status_prompter "Step: install [with sudo]:"

    sudo time make install 2>&1 | tee ${BUILD_DIR}/hyperion-buildall-make-install.log
  else
    status_prompter "Step: install [without sudo]:"

    time make install 2>&1 | tee ${BUILD_DIR}/hyperion-buildall-make-install.log
  fi

  verbose_msg "-----------------------------------------------------------------
"
  verbose_msg "Step: setcap operations so Hercules can run without elevated privileges:"
  verbose_msg    # move to a new line
  verbose_msg "sudo setcap 'cap_sys_nice=eip' ${INSTALL_DIR}/bin/hercules"
  sudo setcap 'cap_sys_nice=eip' ${INSTALL_DIR}/bin/hercules
  verbose_msg "sudo setcap 'cap_sys_nice=eip' ${INSTALL_DIR}/bin/herclin"
  sudo setcap 'cap_sys_nice=eip' ${INSTALL_DIR}/bin/herclin
  verbose_msg "sudo setcap 'cap_net_admin+ep' ${INSTALL_DIR}/bin/hercifc"
  sudo setcap 'cap_net_admin+ep' ${INSTALL_DIR}/bin/hercifc
fi

verbose_msg "-----------------------------------------------------------------
"

end_time=$(date)
verbose_msg "Overall build processing ended:   $end_time"

elapsed_seconds="$(( $(TZ=UTC0 printf '%(%s)T\n' '-1') - start_seconds ))"
verbose_msg "total elapsed seconds: $elapsed_seconds"
verbose_msg "Overall elpased time: $( TZ=UTC0 printf '%(%H:%M:%S)T\n' "$elapsed_seconds" )"
verbose_msg    # move to a new line

if true; then
    shell=$(/usr/bin/basename $(/bin/ps -p $$ -ocomm=))
    cat <<FOE >"${INSTALL_DIR}/hyperion-init-$shell.sh"
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
# end in inline "here" file

    chmod +x "${INSTALL_DIR}/hyperion-init-$shell.sh"
    source "${INSTALL_DIR}/hyperion-init-$shell.sh"

#   echo "To set the required environment variables, run:"
#   echo "    source ${BUILD_DIR}/hercules-setvars.sh"
fi

if ($INSTALL); then
  verbose_msg "-----------------------------------------------------------------
"
    status_prompter "Step: create shell profile [requires sudo]:"

# Create /etc/profile.d/hyperion.sh
# Requires sudo

    add_profile=0

    # Make sure we have the profile directory on this system
    if [ -d /etc/profile.d ]; then

        # Check if the profile already exists
        if [ -f /etc/profile.d/hyperion.sh ]; then
            if ($PROMPTS); then
                if confirm "/etc/profile.d/hyperion.sh already exists.  Overwrite? [y/N]" ; then
                    echo "OK"
                    add_profile=1
                else
                    verbose_msg # move to a new line
                fi
            else
                verbose_msg "Overwriting existing /etc/profile.d/hyperion.sh"
                add_profile=1
            fi
        else
            verbose_msg "Creating /etc/profile.d/hyperion.sh"
            add_profile=1
        fi
    else
        error_msg "/etc/profile.d directory not found.  Cannot add paths to profile."
    fi

    if [[ $add_profile -eq 1 ]]; then
        cat <<FOE2 | sudo tee /etc/profile.d/hyperion.sh >/dev/null
#!/bin/bash
#
shell=\$(/usr/bin/basename \$(/bin/ps -p \$\$ -ocomm=))

# location of script: ${INSTALL_DIR}
if [ -f "${INSTALL_DIR}/hyperion-init-\$shell.sh" ]; then
   . "${INSTALL_DIR}/hyperion-init-\$shell.sh"
else
   error_msg "Cannot create Hyperion profile variables on \$shell, script is missing."
fi  

FOE2
# end in inline "here" file
    fi

    if true; then
        shell=$(/usr/bin/basename $(/bin/ps -p $$ -ocomm=))
        # echo $shell

        # Only do this for Bash
        if [[ $shell != bash ]]; then
            error_msg "Login shell is not Bash.  Unable to create profile commands."
        else
            # Add /etc/profile.d/hyperion.sh to ~/.bashrc if not already present
            if grep -Fqe "/etc/profile.d/hyperion.sh" ~/.bashrc ; then
                verbose_msg "Hyperion profile commands are already present in  ~/.bashrc"
            else
                verbose_msg "Adding profile commands to ~/.bashrc"
                cat <<-"BASHRC" >> ~/.bashrc

# For SDL-Hyperion
. /etc/profile.d/hyperion.sh

BASHRC
# end in inline "here" file
            fi

        fi # if bash

    fi

fi # if ($INSTALL)
     
verbose_msg "Done!"

# ---- end of script ----

