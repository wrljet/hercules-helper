#!/usr/bin/env bash

# Complete SDL-Hercules-390 build using wrljet GitHub mods
# Updated: 19 JAN 2021
#
# The most recent version of this project can be obtained with:
#   git clone https://github.com/wrljet/hercules-helper.git
# or:
#   wget https://github.com/wrljet/hercules-helper/archive/master.zip
#
# Please report errors in this to me so everyone can benefit.
#
# Bill Lewis  bill@wrljet.com

#-----------------------------------------------------------------------------
#
# To run, create a build directory and cd to it, then run this script.
#
#  $ mkdir herctest && cd herctest
#  $
#  $ ~/hercules-helper/hyperion-buildall.sh --auto
#     or
#  $ ~/hercules-helper/hyperion-buildall.sh --verbose --prompts 2>&1 | tee ./hyperion-buildall.log
#
#-----------------------------------------------------------------------------

# Changelog:
#
# Updated: 19 JAN 2021
# - add detection and support for Manjaro Linux
#
# Updated: 14 JAN 2021
# - correct CentOS detection to take CentOS Stream into account
#
# Updated: 10 JAN 2021
# - merge utilfns.sh into main script
# - add --auto option to just do it all, with full logging
# - remove separate logs for sub-steps
#
# Updated: 09 JAN 2021
# - do all git clones in one place
# - fix bug when creating /etc/profile.d/hyperion.sh
# - in ~/.bashrc, test for /etc/profile.d/hyperion.sh before calling it
#
# Updated: 07 JAN 2021
# - merge package preparation functionality into hyperion-buildall.sh
# - add --no-packages option
# - default to always install, and reverse sense of option to --no-install
# - fix package detection for CMAKE on CentOS 7.8
# - added openSUSE package support
#
# Updated: 05 JAN 2021
# - initial support for NetBSD
# - correct 'make -j' argument and CPU count for NetBSD
# - show an error for unknown command line options
# - display a version number for this script
#
# Updated: 04 JAN 2021
# - create feature of external .conf file (not yet advertised)
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
# - auto install libregina3-dev (on Debian)
#
# Updated: 20 DEC 2020
# - changes to detect and disallow gcc < 6.3.0 on i686
# - don't follow mount points while searching for files
# - comment known issue looking for installed state on Ubuntu 12.04
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
# Updated:  6 DEC 2020
# - another fix for CentOS 7.x detection
# - improve system status info for debugging
# - fix configure C pre-processor detection on CentOS
#
# Updated:  5 DEC 2020
# - issue 'setcap' commands so hercules will run without root permissions
# - write out hercules-setvars.sh to create required environment variables
# - added m4 as a required package for Debian
# - show the system language
# - display improvements
#
# Updated:  4 DEC 2020
# - disallow running as the root user
# - corrected parsing for differing CentOS 7.8 ansd 8.2 version strings
# - update package list for CentOS
# - on CentOS 7, CMAKE 3.x is built from source
# - added wget as a required package for CentOS
#
# Updated: 30 NOV 2020
# - initial commit to GitHub

#
# Default Configuration Parameters:
#
# Overall working build diretory is the current directory
OPT_BUILD_DIR=${OPT_BUILD_DIR:-$(pwd)}

# Prefix (target) directory
OPT_INSTALL_DIR=${OPT_INSTALL_DIR:-$(pwd)/herc4x}

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
OPT_VERBOSE=${OPT_VERBOSE:-false}

# Prompt the user before each major step is started
OPT_PROMPTS=${OPT_PROMPTS:-false}

# Do not install missing packages if true
OPT_NO_PACKAGES=${OPT_NO_PACKAGES:-false}

# Skip 'make install' after building
OPT_NO_INSTALL=${OPT_NO_INSTALL:-false}

# Use 'sudo' for 'make install'
OPT_USESUDO=${OPT_USESUDO:-false}

#-----------------------------------------------------------------------------

pushd "$(dirname "$0")" >/dev/null;
version_info="$0: $(git describe --long --tags --dirty --always)"
popd > /dev/null;

usage="Hercules-Helper $version_info
Usage: $(basename "$0") [OPTIONS]

Perform a full build, test, and installation of SDL-Hercules-390 Hyperion from GitHub sources

Options:
  -h,  --help         print this help
  -t,  --trace        print every command (set -x)
  -v,  --verbose      print lots of messages
  -p,  --prompts      print a prompt before each major step
  -c,  --config=FILE  specify config file containing options
  -a,  --auto         run everything, with --verbose and --prompts,
                      and creating a full log file

Sub-functions:
       --no-install   run \'make install\' after building
  -s,  --sudo         use \'sudo\' for installing
       --no-packages  skip installing required packages

Email bug reports, questions, etc. to <bill@wrljet.com>
"

#-----------------------------------------------------------------------------
# Stop on error
# FIXME set -e

#------------------------------------------------------------------------------
#                               trace
#------------------------------------------------------------------------------
trace_msg()
{
  if [[ -n $debug ]]  || \
     [[ -n $DEBUG ]]; then
    echo  "++ $1"
  fi
}

#------------------------------------------------------------------------------
#                               verbose_msg
#------------------------------------------------------------------------------
verbose_msg()
{
    if ($OPT_VERBOSE); then
        echo "$@"
    fi
}

#------------------------------------------------------------------------------
#                               error_msg
#------------------------------------------------------------------------------
error_msg()
{
    printf "\033[1;37m[[ \033[1;31merror: \033[1;37m]] \033[0m$1\n"
}

#------------------------------------------------------------------------------
#                              confirm
#------------------------------------------------------------------------------
confirm() {
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
#                               status_prompter
#------------------------------------------------------------------------------

# called with:
#   status_prompter "Step: Create shell profile."

status_prompter()
{
    if ($OPT_PROMPTS); then
        read -p "$1  Hit return to continue"
    else
        echo "$1"
    fi

    echo   # move to a new line
}

#------------------------------------------------------------------------------
#                               detect_pi
#------------------------------------------------------------------------------

# Table source:
# https://www.raspberrypi.org/documentation/hardware/raspberrypi/revision-codes/README.md

function get_pi_version()
{
    verbose_msg -n "Checking for Raspberry Pi... "

    RPI_MODEL=$(awk '/Model/ {print $3}' /proc/cpuinfo)
    # echo "$RPI_MODEL"
    if [[ $RPI_MODEL =~ "Raspberry" ]]; then
        verbose_msg "found"
    else
        verbose_msg "nope"
    fi

    RPI_REVCODE=$(awk '/Revision/ {print $3}' /proc/cpuinfo)
    verbose_msg "Raspberry Pi revision: $RPI_REVCODE"
}

function check_pi_version()
{
  local -rA RPI_REVISIONS=(
    [900021]="A+        1.1     512MB   Sony UK"
    [900032]="B+        1.2     512MB   Sony UK"
    [900092]="Zero      1.2     512MB   Sony UK"
    [900093]="Zero      1.3     512MB   Sony UK"
    [9000c1]="Zero W    1.1     512MB   Sony UK"
    [9020e0]="3A+       1.0     512MB   Sony UK"
    [920092]="Zero      1.2     512MB   Embest"
    [920093]="Zero      1.3     512MB   Embest"
    [900061]="CM        1.1     512MB   Sony UK"
    [a01040]="2B        1.0     1GB     Sony UK"
    [a01041]="2B        1.1     1GB     Sony UK"
    [a02082]="3B        1.2     1GB     Sony UK"
    [a020a0]="CM3       1.0     1GB     Sony UK"
    [a020d3]="3B+       1.3     1GB     Sony UK"
    [a02042]="2B (with BCM2837)         1.2     1GB     Sony UK"
    [a21041]="2B        1.1     1GB     Embest"
    [a22042]="2B (with BCM2837)         1.2     1GB     Embest"
    [a22082]="3B        1.2     1GB     Embest"
    [a220a0]="CM3       1.0     1GB     Embest"
    [a32082]="3B        1.2     1GB     Sony Japan"
    [a52082]="3B        1.2     1GB     Stadium"
    [a22083]="3B        1.3     1GB     Embest"
    [a02100]="CM3+      1.0     1GB     Sony UK"
    [a03111]="4B        1.1     1GB     Sony UK"
    [b03111]="4B        1.1     2GB     Sony UK"
    [b03112]="4B        1.2     2GB     Sony UK"
    [c03111]="4B        1.1     4GB     Sony UK"
    [c03112]="4B        1.2     4GB     Sony UK"
    [d03114]="4B        1.4     8GB     Sony UK"
    [c03130]="Pi 4004   1.0     4GB     Sony UK"
  )

    verbose_msg "Raspberry Pi ${RPI_REVISIONS[${RPI_REVCODE}]} (${RPI_REVCODE})"
}

function detect_pi()
{
    verbose_msg " "  # move to a new line

# Raspberry Pi 4B,   Ubuntu 20 64-bit,  uname -m == aarch64
# Raspberry Pi 4B,   RPiOS     32-bit,  uname -m == armv7l
# Raspberry Pi Zero, RPiOS     32-bit,  uname -m == armv6l

    get_pi_version
    check_pi_version
}

#------------------------------------------------------------------------------
#                               detect_darwin
#------------------------------------------------------------------------------
detect_darwin()
{
    # from config.guess:
    # https://git.savannah.gnu.org/git/config.git

    # uname -a
    # Darwin Sunils-Air 20.2.0 Darwin Kernel Version 20.2.0: Wed Dec  2 20:40:21 PST 2020; root:xnu-7195.60.75~1/RELEASE_ARM64_T8101 x86_64

#   UNAME_MACHINE=$( (uname -m) 2>/dev/null) || UNAME_MACHINE=unknown
#   UNAME_RELEASE=$( (uname -r) 2>/dev/null) || UNAME_RELEASE=unknown
#   UNAME_SYSTEM=$( (uname -s) 2>/dev/null) || UNAME_SYSTEM=unknown
#   UNAME_VERSION=$( (uname -v) 2>/dev/null) || UNAME_VERSION=unknown

#   case "$UNAME_MACHINE:$UNAME_SYSTEM:$UNAME_RELEASE:$UNAME_VERSION" in
#       arm64:Darwin:*:*)
#           echo aarch64-apple-darwin"$UNAME_RELEASE"
#           ;;
#       *:Darwin:*:*)
#           UNAME_PROCESSOR=$(uname -p)
#           case $UNAME_PROCESSOR in
#               unknown) UNAME_PROCESSOR=powerpc ;;
#           esac
#   esac

    if [[ $UNAME_SYSTEM == Darwin ]]; then
        VERSION_DISTRO=darwin
    fi
}

#------------------------------------------------------------------------------
#                               detect_system
#------------------------------------------------------------------------------
detect_system()
{

# $ cat /boot/issue.txt | head -1
#  Raspberry Pi reference 2020-05-27

# 19 JAN 2021
# $ cat /etc/os-release 
# NAME="Manjaro Linux"
# ID=manjaro
# ID_LIKE=arch
# BUILD_ID=rolling
# PRETTY_NAME="Manjaro Linux"
# ANSI_COLOR="32;1;24;144;200"
# HOME_URL="https://manjaro.org/"
# DOCUMENTATION_URL="https://wiki.manjaro.org/"
# SUPPORT_URL="https://manjaro.org/"
# BUG_REPORT_URL="https://bugs.manjaro.org/"
# LOGO=manjarolinux

# /etc/os-release
#
#  NAME="Linux Mint"
#  VERSION="20 (Ulyana)"
#  ID=linuxmint
#  ID_LIKE=ubuntu
#  PRETTY_NAME="Linux Mint 20"
#  VERSION_ID="20"
#  HOME_URL="https://www.linuxmint.com/"
#  SUPPORT_URL="https://forums.linuxmint.com/"
#  BUG_REPORT_URL="http://linuxmint-troubleshooting-guide.readthedocs.io/en/latest/"
#  PRIVACY_POLICY_URL="https://www.linuxmint.com/"
#  VERSION_CODENAME=ulyana
#  UBUNTU_CODENAME=focal

    verbose_msg " "  # move to a new line
    verbose_msg "System stats:"

    OS_NAME=$(uname -s)
    verbose_msg "OS Type          : $OS_NAME"

    machine=$(uname -m)
    verbose_msg "Machine Arch     : $machine"

    if [ "${OS_NAME}" = "Linux" ]; then
        # awk -F= '$1=="ID" { gsub(/"/, "", $2); print $2 ;}' /etc/os-release
        VERSION_ID=$(awk -F= '$1=="ID" { gsub(/"/, "", $2); print $2 ;}' /etc/os-release)
        # echo "VERSION_ID is $VERSION_ID"

        VERSION_ID_LIKE=$(awk -F= '$1=="ID_LIKE" { gsub(/"/, "", $2); print $2 ;}' /etc/os-release)
        # echo "VERSION_ID_LIKE is $VERSION_ID_LIKE"

        VERSION_PRETTY_NAME=$(awk -F= '$1=="PRETTY_NAME" { gsub(/"/, "", $2); print $2 ;}' /etc/os-release)
        # echo "VERSION_STR is $VERSION_STR"

        VERSION_STR=$(awk -F= '$1=="VERSION_ID" { gsub(/"/, "", $2); print $2 ;}' /etc/os-release)
        # echo "VERSION_STR is $VERSION_STR"

        verbose_msg "Memory Total (MB): $(free -m | awk '/^Mem:/{print $2}')"
        verbose_msg "Memory Free  (MB): $(free -m | awk '/^Mem:/{print $4}')"

        verbose_msg "VERSION_ID       : $VERSION_ID"
        verbose_msg "VERSION_ID_LIKE  : $VERSION_ID_LIKE"
        verbose_msg "VERSION_PRETTY   : $VERSION_PRETTY_NAME"
        verbose_msg "VERSION_STR      : $VERSION_STR"

        # Look for Manjaro

        if [[ $VERSION_ID == arch* || $VERSION_ID == manjaro* ]];
        then
            VERSION_DISTRO=arch
            VERSION_STR=$(awk -F= '$1=="DISTRIB_RELEASE" { gsub(/"/, "", $2); print $2 ;}' /etc/lsb-release)
            VERSION_MAJOR=$(echo ${VERSION_STR} | cut -f1 -d.)
            VERSION_MINOR=$(echo ${VERSION_STR} | cut -f2 -d.)

            verbose_msg "OS               : $VERSION_DISTRO variant"
            verbose_msg "OS Version       : $VERSION_MAJOR"
        fi

        # Look for Debian/Ubuntu/Mint

        if [[ $VERSION_ID == debian*  || $VERSION_ID == ubuntu*    || \
              $VERSION_ID == neon*    || $VERSION_ID == linuxmint* || \
              $VERSION_ID == raspbian*                             ]];
        then
            # if [[ $(lsb_release -rs) == "18.04" ]]; then
            VERSION_DISTRO=debian
            VERSION_MAJOR=$(echo ${VERSION_STR} | cut -f1 -d.)
            VERSION_MINOR=$(echo ${VERSION_STR} | cut -f2 -d.)

            verbose_msg "OS               : $VERSION_DISTRO variant"
            verbose_msg "OS Version       : $VERSION_MAJOR"
        fi

        if [[ $VERSION_ID == raspbian* ]]; then
            echo "$(cat /boot/issue.txt | head -1)"
        fi

        if [[ $VERSION_ID == centos* ]]; then
            verbose_msg "We have a CentOS system"

            # CENTOS_VERS="centos-release-7-8.2003.0.el7.centos.x86_64"
            # CENTOS_VERS="centos-release-7.9.2009.1.el7.centos.x86_64"
            # CENTOS_VERS="centos-release-8.2-2.2004.0.2.el8.x86_64"

            # Centos Stream 8:
            # $ rpm --query centos-release
            # package centos-release is not installed
            # $ cat /etc/redhat-release 
            # CentOS Linux release 8.2.2004
            # CentOS Stream release 8

          # CENTOS_VERS=$(rpm --query centos-release) || true
            CENTOS_VERS=$(cat /etc/redhat-release) || true
            CENTOS_VERS="${CENTOS_VERS#*release }"
            CENTOS_VERS="${CENTOS_VERS/-/.}"

            VERSION_DISTRO=redhat
            VERSION_MAJOR=$(echo ${CENTOS_VERS} | cut -f1 -d.)
            VERSION_MINOR=$(echo "${CENTOS_VERS}.0" | cut -f2 -d.)

            verbose_msg "VERSION_MAJOR    : $VERSION_MAJOR"
            verbose_msg "VERSION_MINOR    : $VERSION_MINOR"
        fi

        # Look for openSUSE

        if [[ ${VERSION_ID,,} == opensuse* ]];
        then
            VERSION_DISTRO=openSUSE
            VERSION_MAJOR=$(echo ${VERSION_STR} | cut -f1 -d.)
            VERSION_MINOR=$(echo ${VERSION_STR} | cut -f2 -d.)

            verbose_msg "OS               : $VERSION_DISTRO variant"
            verbose_msg "OS Version       : $VERSION_MAJOR"
        fi

        # show the default language
        # i.e. LANG=en_US.UTF-8
        verbose_msg "Language         : $(env | grep LANG)"

        # Check if running under Windows WSL
        verbose_msg " "  # move to a new line
        VERSION_WSL=0

        verbose_msg -n "Checking for Windows WSL1... "
        if [[ "$(< /proc/version)" == *@(Microsoft|WSL)* ]]; then
            verbose_msg "running on WSL1"
            VERSION_WSL=1
        else
            verbose_msg "nope"
        fi

        verbose_msg -n "Checking for Windows WSL2... "
        if [ $(uname -r | sed -n 's/.*\( *Microsoft *\).*/\1/ip') ]; then
            verbose_msg "running on WSL2"
            VERSION_WSL=2
        else
            verbose_msg "nope"
        fi

        # Check if running under Raspberry Pi Desktop (for PC)
        #
        # Raspberry Pi, native and x86_64 Desktop
        # $ cat /etc/rpi-issue
        # Raspberry Pi reference 2020-02-12
        # Generated using pi-gen, https://github.com/RPi-Distro/pi-gen, f3b8a04dc10054b328a56fa7570afe6c6d1b856e, stage5

        VERSION_RPIDESKTOP=0

        if [ -f /etc/rpi-issue ]; then
            if [[ "$(< /etc/rpi-issue)" == *@(Raspberry Pi reference)* &&
                  "$machine" == "x86_64" ]];
            then
                verbose_msg "Running on Raspberry Pi Desktop (for PC)"
                VERSION_RPIDESKTOP=1
            fi
        fi

        if [[ "$machine" != "x86_64" ]]; then
            # Check for real Raspberry Pi hardware
            detect_pi
        fi

    elif [ "${OS_NAME}" = "NetBSD" ]; then

        VERSION_DISTRO=netbsd
        VERSION_ID="netbsd"

# for NetBSD:
# [bill@daisy:~/herctest] $ cat /proc/meminfo
#         total:    used:    free:  shared: buffers: cached:
# Mem:  66666078208 59402612736 7263465472        0 41681768448 43967352832
# Swap: 68718448640        0 68718448640
# MemTotal:  65103592 kB
# MemFree:    7093228 kB
# MemShared:        0 kB
# Buffers:   40704852 kB
# Cached:    42936868 kB
# SwapTotal: 67107860 kB
# SwapFree:  67107860 kB

        NETBSD_MEMINFO=$(cat /proc/meminfo)
        verbose_msg "Memory Total (MB): $(cat /proc/meminfo | awk '/^Mem:/{mb = $2/1024/1024; printf "%.0f", mb}')"
        verbose_msg "Memory Free  (MB): $(cat /proc/meminfo | awk '/^Mem:/{mb = $4/1024/1024; printf "%.0f", mb}')"

        # 9.0_STABLE
        VERSION_STR=$(uname -r)

        verbose_msg "VERSION_ID       : $VERSION_ID"
        verbose_msg "VERSION_STR      : $VERSION_STR"

        VERSION_SUBSTR=$(echo ${VERSION_STR} | cut -f1 -d_)
        verbose_msg "VERSION_SUBSTR   : $VERSION_SUBSTR"
        VERSION_MAJOR=$(echo ${VERSION_SUBSTR} | cut -f1 -d.)
        verbose_msg "VERSION_MAJOR    : $VERSION_MAJOR"
        VERSION_MINOR=$(echo ${VERSION_SUBSTR} | cut -f2 -d.)
        verbose_msg "VERSION_MINOR    : $VERSION_MINOR"

        # show the default language

        # i.e. LANG=en_US.UTF-8
        verbose_msg "Language         : <unknown>"

    elif [ "${OS_NAME}" = "OpenBSD" ]; then
        error_msg "OpenBSD is not yet supported!"
    fi
}

#------------------------------------------------------------------------------
#                              detect_regina
#------------------------------------------------------------------------------

detect_regina()
{
    verbose_msg -n "Checking for Regina-REXX... " # no newline!

    VERSION_REGINA=0

    which_rexx=$(which rexx) || true
    which_status=$?

    # echo "(which rexx) status: $which_status"

    if [ -z $which_rexx ]; then
        verbose_msg "nope"  # move to a new line
        # verbose_msg "Regina-REXX      : is not installed"
    else
        # rexx -v
        # REXX-Regina_3.6 5.00 31 Dec 2011
        # rexx: REXX-Regina_3.9.3 5.00 5 Oct 2019 (32 bit)

        regina_v=$(rexx -v 2>&1 | grep "Regina" | sed "s#^rexx: ##")
        if [ -z "$regina_v" ]; then
            verbose_msg "nope"  # move to a new line
            verbose_msg "Found REXX, but not Regina-REXX"
        else
            verbose_msg " "  # move to a new line
            verbose_msg "Found REXX       : $regina_v"

            regina_name=$(echo ${regina_v} | cut -f1 -d_)

            if [[ $regina_name == "REXX-Regina" ]]; then
                # echo "we have Regina REXX"

                regina_verstr=$(echo ${regina_v} | cut -f2 -d_)
                # echo "regina ver string: $regina_verstr"
                VERSION_REGINA=$(echo ${regina_verstr} | cut -f1 -d.)
                # echo "regina version major: $VERSION_REGINA"
                regina_verminor=$(echo ${regina_verstr} | cut -f2 -d. | cut -f1 -d' ')
                # echo "regina version minor: $regina_verminor"
                verbose_msg "Regina version   : $VERSION_REGINA.$regina_verminor"
            else
                error_msg "ERROR: Found an unknown Regina-REXX"
            fi
        fi
    fi
}

#------------------------------------------------------------------------------
#                              detect_oorexx
#------------------------------------------------------------------------------

detect_oorexx()
{
    verbose_msg -n "Checking for ooRexx... " # no newline!

    VERSION_OOREXX=0

    which_rexx=$(which rexx) || true
    which_status=$?

    # echo "(which rexx) status: $which_status"

    if [ -z $which_rexx ]; then
        verbose_msg "nope"  # move to a new line
        # verbose_msg "ooRexx           : is not installed"
    else
        # rexx -v
        # Open Object Rexx Version 5.0.0 r12142

        oorexx_v=$(rexx -v 2>&1 | grep "Open Object Rexx" | sed "s#^rexx: ##")

        if [ -z "$oorexx_v" ]; then
            verbose_msg "nope"  # move to a new line
            verbose_msg "Found REXX, but not ooRexx"
        else
            verbose_msg " "  # move to a new line
            verbose_msg "Found REXX       : $oorexx_v"

            if [[ $oorexx_v =~ "Open Object Rexx" ]]; then
                # echo "we have ooRexx"

                oorexx_verstr=$(echo ${oorexx_v} | sed "s#^Open Object Rexx Version ##")
                # echo "oorexx ver string: $oorexx_verstr"
                VERSION_OOREXX=$(echo ${oorexx_verstr} | cut -f1 -d.)
                # echo "oorexx version major: $VERSION_OOREXX"
                oorexx_verminor=$(echo ${oorexx_verstr} | cut -f2 -d.)
                # echo "oorexx version minor: $oorexx_verminor"
                verbose_msg "ooRexx version   : $VERSION_OOREXX.$oorexx_verminor"
            else
                verbose_msg "Found an unknown ooRexx"
            fi
        fi
    fi
}

#------------------------------------------------------------------------------
#                              detect_rexx
#------------------------------------------------------------------------------

detect_rexx()
{
    which_rexx=$(which rexx) || true
    which_status=$?

    verbose_msg "REXX presence    : $which_rexx"
    # echo "(which rexx) status: $which_status"

    detect_regina

    # See if the compiler can find the Regina-REXX include file(s)
    if [[ $VERSION_REGINA -ge 3 ]]; then
        echo "#include \"rexxsaa.h\"" | gcc $CPPFLAGS $CFLAGS -dI -E -x c - >/dev/null 2>&1
        gcc_status=$?

        # #include "rexx.h"
        # # 1 "/usr/include/rexx.h" 1 3 4

        # gcc returns exit code 1 if this fails
        # <stdin>:1:10: fatal error: rexx.h: No such file or directory
        # compilation terminated.
        # #include "rexx.h"

        gcc_find_h=$(echo "#include \"rexxsaa.h\"" | gcc $CPPFLAGS $CFLAGS -dI -E -x c - 2>&1 | grep "rexxsaa.h" )
        if [[ $gcc_status -eq 0 ]]; then
            verbose_msg "gcc_status = $gcc_status"
            verbose_msg "rexxsaa.h is found in gcc search path"
            trace_msg "$gcc_find_h"
        else
            verbose_msg "gcc_status = $gcc_status"
            error_msg "rexxsaa.h is not found in gcc search path"
            trace_msg "$gcc_find_h"
        fi
    fi

    detect_oorexx

    # See if the compiler can find the ooRexx include file(s)
    if [[ $VERSION_OOREXX -ge 4 ]]; then
        echo "#include \"rexx.h\"" | gcc $CPPFLAGS $CFLAGS -dI -E -x c - >/dev/null 2>&1
        gcc_status=$?

        # #include "rexx.h"
        # # 1 "/usr/include/rexx.h" 1 3 4

        # gcc returns exit code 1 if this fails
        # <stdin>:1:10: fatal error: rexx.h: No such file or directory
        # compilation terminated.
        # #include "rexx.h"

        gcc_find_h=$(echo "#include \"rexx.h\"" | gcc $CPPFLAGS $CFLAGS -dI -E -x c - 2>&1 | grep "rexx.h" )

        if [[ $gcc_status -eq 0 ]]; then
            verbose_msg "gcc_status = $gcc_status"
            verbose_msg "rexx.h is found in gcc search path"
            trace_msg "$gcc_find_h"
        else
            verbose_msg "gcc_status = $gcc_status"
            error_msg "rexx.h is not found in gcc search path"
            trace_msg "$gcc_find_h"
        fi
    fi
}

#------------------------------------------------------------------------------
# Process command line

if [[ ${TRACE} == true ]]; then
    set -x # For debugging, show all commands as they are being run
fi

opt_override_trace=false
opt_override_verbose=false
opt_override_prompts=false
opt_override_no_install=false
opt_override_usersudo=false
opt_override_no_packages=false
opt_override_auto=false

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
    OPT_VERBOSE=true
    shift # past argument
    ;;

  -p|--prompts)
    opt_override_prompts=true
    shift # past argument
    ;;

  -a|--auto)  # run everything using all defaults, prompts, and logging
    opt_override_auto=true
    opt_override_verbose=true
    opt_override_prompts=true
    shift # past argument
    ;;

  --install)
    opt_override_no_install=false
    shift # past argument
    ;;

  --no-install)
    opt_override_no_install=true
    shift # past argument
    ;;

  -s|--sudo)
    opt_override_usersudo=true
    shift # past argument
    ;;

  --no-packages) # skip installing required packages
    opt_override_no_packages=true
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

function the_works {  # Put everthing in an I/O redirection

echo "Using logfile $logfile.log"

pushd "$(dirname "$0")" >/dev/null;
echo "$0: $(git describe --long --tags --dirty --always)"
popd > /dev/null;
echo    # print a new line

# Find and read in the configuration

config_dir="$(dirname "$0")"
config_file="${config_dir}/hercules-helper.conf"
echo "Using config file: ${config_file}"

if test -f "${config_file}" ; then
    source "${config_file}"
else
    echo "Config file not found.  Using defaults."
fi

if [ $opt_override_trace       == true ]; then TRACE=true;   fi
if [ $opt_override_verbose     == true ]; then OPT_VERBOSE=true; fi
if [ $opt_override_prompts     == true ]; then OPT_PROMPTS=true; fi
if [ $opt_override_no_install  == true ]; then OPT_NO_INSTALL=true; fi
if [ $opt_override_usersudo    == true ]; then OPT_USESUDO=true; fi
if [ $opt_override_no_packages == true ]; then OPT_NO_PACKAGES=true; fi

if [[ ${TRACE} == true ]]; then
    set -x # For debugging, show all commands as they are being run
fi

#------------------------------------------------------------------------------
#                              prepare_packages
#------------------------------------------------------------------------------
prepare_packages()
{
  # Look for Debian/Ubuntu/Mint

  if [[ $VERSION_DISTRO == debian  ]]; then
      # if [[ $(lsb_release -rs) == "18.04" ]]; then

      declare -a debian_packages=( \
          "git" \
          "build-essential" "autoconf" "automake" "cmake" "flex" "gawk" "m4" \
          "libbz2-dev" "zlib1g-dev"
      )

      for package in "${debian_packages[@]}"; do
          echo -n "Checking for package: $package ... "

          # the following only works on Ubuntu newer than 12.04
          # another method is:
          # /usr/bin/dpkg-query -s <packagename> 2>/dev/null | grep -q ^"Status: install ok installed"$

          is_installed=$(/usr/bin/dpkg-query --show --showformat='${db:Status-Status}\n' $package)
          status=$?

          # install if missing
          if [ $status -eq 0 ] && [ "$is_installed" == "installed" ]; then
              echo "is already installed"
          else
              echo "is missing, installing"
              sudo apt-get -y install $package
              echo "-----------------------------------------------------------------"
          fi
      done

      if [[ $VERSION_REGINA -ge 3 ]]; then
          echo "-----------------------------------------------------------------"
          echo "Found an existing Regina REXX"

          package="libregina3-dev"

          echo "Checking for package: $package"
          is_installed=$(/usr/bin/dpkg-query --show --showformat='${db:Status-Status}\n' $package)
          status=$?

          if [ $status -eq 0 ] && [ "$is_installed" == "installed" ]; then
              echo "package: $package is already installed"
          else
              echo "installing package: $package"
              sudo apt-get -y install $package
          fi
      fi

    return
  fi

#-----------------------------------------------------------------------------
  # Look for Arch/Manjaro

  if [[ $VERSION_DISTRO == arch  ]]; then
      declare -a arch_packages=( \
          "git" \
          "base-devel" "make" "gcc" "autoconf" "automake" "cmake" "flex" "gawk" "m4" \
          "bzip2" "zlib"
      )

      for package in "${arch_packages[@]}"; do
          echo -n "Checking for package: $package ... "

          is_installed=$(pacman -Q $package 2>&1)
          status=$?

          # install if missing
          if [ $status -eq 0 ]; then
              echo "is already installed"
          else
              echo "is missing, installing"
              sudo pacman -S --noconfirm $package
              echo "-----------------------------------------------------------------"
          fi
      done

      if [[ $VERSION_REGINA -ge 3 ]]; then
          echo "-----------------------------------------------------------------"
          echo "Found an existing Regina REXX"

          package="libregina3-dev"

          echo "Checking for package: $package"
          is_installed=$(/usr/bin/dpkg-query --show --showformat='${db:Status-Status}\n' $package)
          status=$?

          if [ $status -eq 0 ] && [ "$is_installed" == "installed" ]; then
              echo "package: $package is already installed"
          else
              echo "installing package: $package"
              sudo apt-get -y install $package
          fi
      fi

    return
  fi


#-----------------------------------------------------------------------------
  # CentOS 7

  if [[ $VERSION_ID == centos* ]]; then
      if [[ $VERSION_MAJOR -ge 7 ]]; then
          echo "CentOS version 7 or later found"

          if [[ $VERSION_MAJOR -eq 7 ]]; then
              declare -a centos_packages=( \
                  "git" "wget" \
                  "gcc" "make" "autoconf" "automake" "flex" "gawk" "m4"
                  "bzip2-devel" "zlib-devel"
              )
          fi

          if [[ $VERSION_MAJOR -eq 8 ]]; then
              declare -a centos_packages=( \
                  "git" "wget" \
                  "gcc" "make" "autoconf" "automake" "flex" "gawk" "m4"
                  "cmake"
                  "bzip2-devel" "zlib-devel"
              )
          fi

          for package in "${centos_packages[@]}"; do
              echo "-----------------------------------------------------------------"

              #yum list installed bzip2-devel  > /dev/null 2>&1 ; echo $?
              yum list installed $package
              status=$?

              # install if missing
              if [ $status -eq 0 ]; then
                  echo "package $package is already installed"
              else
                  echo "installing package: $package"
                  sudo yum -y install $package
              fi
          done

          if [[ $VERSION_MAJOR -eq 7 ]]; then

              echo "-----------------------------------------------------------------"
  # cmake presence: /usr/local/bin/cmake
  # /usr/local/bin/cmake status: 0
              which_cmake=$(which cmake)
              which_status=$?

              echo "CMAKE presence: $which_cmake"
              echo "(which cmake) status: $which_status"

              if [ $which_status -eq 1 ]; then
                  echo "On CentOS 7, there is no package for CMAKE 3.x"
                  echo "Building from source..."

                  mkdir -p ~/tools
                  pushd ~/tools > /dev/null;

                  if [ ! -f cmake-3.12.3.tar.gz ]; then
                      wget https://cmake.org/files/v3.12/cmake-3.12.3.tar.gz
                  fi

                  tar xfz cmake-3.12.3.tar.gz
                  cd cmake-3.12.3/
                  ./bootstrap --prefix=/usr/local
                  make -j$(nproc)
                  sudo make install
                  cmake --version
                  popd > /dev/null;
              fi

          fi

          # run on all CentOS, after CMAKE
          echo "-----------------------------------------------------------------"

          which_cc1=$(find / -name cc1 -print 2>&1 | grep cc1)
          echo "cc1 presence:       $which_cc1"

          which_cc1plus=$(find / -name cc1plus -print 2>&1 | grep cc1plus)
          which_status=$?
          echo "cc1plus presence:   $which_cc1plus"

          if [ -z $which_cc1plus ]; then
              echo "On CentOS and there is no cc1plus"

              if [ ! -z $which_cc1 ]; then
                  echo "We do have cc1; linking cc1plus to cc1"
                  sudo ln -s "$which_cc1" /usr/bin/cc1plus
              else
                  error_msg "We do not have cc1 either; full gcc-c++ package is required"
              fi
          fi

          echo    # print a new line
      else
          error_msg "CentOS version 6 or earlier found, and not supported"
          exit 1
      fi
    return
  fi

#-----------------------------------------------------------------------------
  # openSUSE (15.1)

  if [[ ${VERSION_ID,,} == opensuse* ]]; then
      declare -a opensuse_packages=( \
          "git" \
          "devel_basis" "autoconf" "automake" "cmake" "flex" "gawk" "m4" \
          "bzip2" \
          "libz1" "zlib-devel"
      )

      for package in "${opensuse_packages[@]}"; do
          echo "-----------------------------------------------------------------"
          echo "Checking for package: $package"

          is_installed=$(zypper search --installed-only --match-exact "$package")
          status=$?

          # install if missing
          if [ $status -eq 0 ] ; then
              echo "package: $package is already installed"
          else
              echo "installing package: $package"
              echo "sudo zypper install -y -t pattern $package"
              sudo zypper install -y -t pattern $package
          fi
      done

    return
  fi

#-----------------------------------------------------------------------------
  # NetBSD

  if [[ $VERSION_ID == netbsd* ]]; then
      declare -a netbsd_packages=( \
          "git" \
          "build-essential" "autoconf" "automake" "cmake" "flex" "gawk" "m4" \
          "bzip2" "zlib1g-dev"
      )

      for package in "${netbsd_packages[@]}"; do
          echo "-----------------------------------------------------------------"
          echo "Checking for package: $package"

          is_installed=$(pkg_info -E $package)
          status=$?

          # install if missing
          if [ $status -eq 0 ] ; then
              echo "package: $package is already installed"
          else
              echo "$package : must be installed"
              # echo "installing package: $package"
          fi
      done

    return
  fi
}

detect_darwin
if [[ $VERSION_DISTRO == darwin ]]; then
    error_msg "Not yet supported under Apple Darwin OS!"
    exit 1
fi

verbose_msg    # print a new line
verbose_msg "General Options:"
verbose_msg "TRACE                : ${TRACE}"
verbose_msg "OPT_VERBOSE          : ${OPT_VERBOSE}"
verbose_msg "OPT_PROMPTS          : ${OPT_PROMPTS}"
verbose_msg "OPT_NO_INSTALL       : ${OPT_NO_INSTALL}"
verbose_msg "OPT_USESUDO          : ${OPT_USESUDO}"

verbose_msg # move to a new line
verbose_msg "Configuration:"
verbose_msg "OPT_BUILD_DIR        : ${OPT_BUILD_DIR}"
verbose_msg "OPT_INSTALL_DIR      : ${OPT_INSTALL_DIR}"

if [ -z "$GIT_BRANCH_HYPERION" ] ; then
    verbose_msg "GIT_REPO_HYPERION    : ${GIT_REPO_HYPERION}"
else
    verbose_msg "GIT_REPO_HYPERION    : ${GIT_REPO_HYPERION} [checkout $GIT_BRANCH_HYPERION]"
fi

if [ -z "$GIT_BRANCH_GISTS" ] ; then
    verbose_msg "GIT_REPO_GISTS       : ${GIT_REPO_GISTS}"
else
    verbose_msg "GIT_REPO_GISTS       : ${GIT_REPO_GISTS} [checkout $GIT_BRANCH_GISTS]"
fi

if [ -z "$GIT_BRANCH_EXTPKGS" ] ; then
    verbose_msg "GIT_REPO_EXTPKGS     : ${GIT_REPO_EXTPKGS}"
else
    verbose_msg "GIT_REPO_EXTPKGS     : ${GIT_REPO_EXTPKGS} [checkout $GIT_BRANCH_EXTPKGS]"
fi

# Detect type of system we're running on and display info
detect_system

#-----------------------------------------------------------------------------

if [[ $VERSION_RPIDESKTOP -eq 1 ]]; then
    error_msg "Running on Raspberry Pi Desktop (for PC) is not supported!"
    exit 1
fi

if [[ $VERSION_WSL -eq 1 ]]; then
    error_msg "Not supported under Windows WSL1!"
    exit 1
fi

#-----------------------------------------------------------------------------
verbose_msg # move to a new line
if ($OPT_NO_PACKAGES); then
    verbose_msg "Step: Check for required packages: (skipped)"
else
    status_prompter "Step: Check for required packages:"
    prepare_packages
fi

#-----------------------------------------------------------------------------
verbose_msg # move to a new line
status_prompter "Step: continuing..."
detect_rexx

#-----------------------------------------------------------------------------
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

        if ($OPT_PROMPTS); then
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
        regina_configure_cmd="./configure --prefix=${OPT_BUILD_DIR}/rexx --enable-32bit"
    else
        regina_configure_cmd="./configure --prefix=${OPT_BUILD_DIR}/rexx"
    fi

    verbose_msg $regina_configure_cmd
    verbose_msg    # move to a new line
    eval "$regina_configure_cmd"

    time make
    time make install

    export PATH=${OPT_BUILD_DIR}/rexx/bin:$PATH
    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${OPT_BUILD_DIR}/rexx/lib
    export CPPFLAGS=-I${OPT_BUILD_DIR}/rexx/include
    verbose_msg "which rexx: $(which rexx)"

    built_regina_from_source=1
fi

#
verbose_msg "-----------------------------------------------------------------
"
status_prompter "Step: git clone all required repos:"

cd ${OPT_BUILD_DIR}
mkdir -p sdl4x
mkdir -p ${OPT_INSTALL_DIR}

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

#-------

verbose_msg    # move to a new line
cd ${OPT_BUILD_DIR}
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
    git clone -b "$GIT_BRANCH_GISTS" "$GIT_REPO_GISTS"
fi

#-------

verbose_msg    # move to a new line
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
status_prompter "Step: util/bldlvlck:"

cd ${OPT_BUILD_DIR}/sdl4x/hyperion

# Check for required packages and minimum versions.
# Inspect the output carefully and do not continue if there are
# any error messages or recommendations unless you know what you're doing.

# On Raspberry Pi Desktop (Buster), the following are often missing:
# autoconf, automake, cmake, flex, gawk, m4

util/bldlvlck 

verbose_msg "-----------------------------------------------------------------
"
status_prompter "Step: Prepare and build extpkgs:"

cd ${OPT_BUILD_DIR}/extpkgs
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

cd ${OPT_BUILD_DIR}/extpkgs

DEBUG=1 ./extpkgs.sh  c d s t
# ./extpkgs.sh c d s t

cd ${OPT_BUILD_DIR}/sdl4x/hyperion

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
    --enable-extpkgs=${OPT_BUILD_DIR}/extpkgs \
    --prefix=${OPT_INSTALL_DIR} \
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

if [[ $VERSION_ID == netbsd* ]]; then
    NPROCS="$(sysctl -n hw.ncpu 2>/dev/null || echo 1)"
else
    NPROCS="$(nproc 2>/dev/null || echo 1)"
fi

verbose_msg    # move to a new line
verbose_msg "time make -j $NPROCS 2>&1"
time make -j "$NPROCS" 2>&1

if [ ${PIPESTATUS[0]} -ne 0 ]; then
    error_msg "Make failed!"
fi

verbose_msg "-----------------------------------------------------------------
"
status_prompter "Step: tests:"

time make check 2>&1
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

  verbose_msg "-----------------------------------------------------------------
"
if ($OPT_NO_INSTALL); then
    verbose_msg "Step: install: (skipped)"
else
  if ($OPT_USESUDO); then
    status_prompter "Step: install [with sudo]:"

    sudo time make install 2>&1
  else
    status_prompter "Step: install [without sudo]:"

    time make install 2>&1
  fi

  verbose_msg "-----------------------------------------------------------------
"
  verbose_msg "Step: setcap operations so Hercules can run without elevated privileges:"
  verbose_msg    # move to a new line
  verbose_msg "sudo setcap 'cap_sys_nice=eip' ${OPT_INSTALL_DIR}/bin/hercules"
  sudo setcap 'cap_sys_nice=eip' ${OPT_INSTALL_DIR}/bin/hercules
  verbose_msg "sudo setcap 'cap_sys_nice=eip' ${OPT_INSTALL_DIR}/bin/herclin"
  sudo setcap 'cap_sys_nice=eip' ${OPT_INSTALL_DIR}/bin/herclin
  verbose_msg "sudo setcap 'cap_net_admin+ep' ${OPT_INSTALL_DIR}/bin/hercifc"
  sudo setcap 'cap_net_admin+ep' ${OPT_INSTALL_DIR}/bin/hercifc
fi

verbose_msg "-----------------------------------------------------------------
"

end_time=$(date)
verbose_msg "Overall build processing ended:   $end_time"

elapsed_seconds="$(( $(TZ=UTC0 printf '%(%s)T\n' '-1') - start_seconds ))"
verbose_msg "total elapsed seconds: $elapsed_seconds"
verbose_msg "Overall elpased time: $( TZ=UTC0 printf '%(%H:%M:%S)T\n' "$elapsed_seconds" )"
verbose_msg    # move to a new line

if ($OPT_INSTALL); then
    shell=$(/usr/bin/basename $(/bin/ps -p $$ -ocomm=))
    cat <<FOE >"${OPT_INSTALL_DIR}/hyperion-init-$shell.sh"
#!/bin/bash
#
# Set up environment variables for Hercules
#
# e.g.
#  export PATH=${OPT_INSTALL_DIR}/bin:${OPT_BUILD_DIR}/rexx/bin:$PATH
#  export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${OPT_INSTALL_DIR}/lib:${OPT_BUILD_DIR}/rexx/lib
#
# This script was created by $0, $(date)
#

newpath="${OPT_INSTALL_DIR}/bin"
if [ -d "\$newpath" ] && [[ ":\$PATH:" != *":\$newpath:"* ]]; then
  # export PATH="\${PATH:+"\$PATH:"}\$newpath"
    export PATH="\$newpath\${PATH:+":\$PATH"}"
fi

newpath="${OPT_INSTALL_DIR}/lib"
if [ -d "\$newpath" ] && [[ ":\$LD_LIBRARY_PATH:" != *":\$newpath:"* ]]; then
  # export LD_LIBRARY_PATH="\${LD_LIBRARY_PATH:+"\$LD_LIBRARY_PATH:"}\$newpath"
    export LD_LIBRARY_PATH="\$newpath\${LD_LIBRARY_PATH:+":\$LD_LIBRARY_PATH"}"
fi

if [[ $built_regina_from_source -eq 1 ]]; then
    newpath="${OPT_BUILD_DIR}/rexx/bin"
    if [ -d "\$newpath" ] && [[ ":\$PATH:" != *":\$newpath:"* ]]; then
      # export PATH="\${PATH:+"\$PATH:"}\$newpath"
        export PATH="\$newpath\${PATH:+":\$PATH"}"
    fi

    newpath="${OPT_BUILD_DIR}/rexx/lib"
    if [ -d "\$newpath" ] && [[ ":\$LD_LIBRARY_PATH:" != *":\$newpath:"* ]]; then
      # export LD_LIBRARY_PATH="\${LD_LIBRARY_PATH:+"\$LD_LIBRARY_PATH:"}\$newpath"
        export LD_LIBRARY_PATH="\$newpath\${LD_LIBRARY_PATH:+":\$LD_LIBRARY_PATH"}"
    fi

    newpath="${OPT_BUILD_DIR}/rexx/include"
    if [ -d "\$newpath" ] && [[ ":\$CPPFLAGS:" != *":-I\$newpath:"* ]]; then
      # export CPPFLAGS="\${CPPFLAGS:+"\$CPPFLAGS:"}-I\$newpath"
        export CPPFLAGS="-I\$newpath\${CPPFLAGS:+" \$CPPFLAGS"}"
    fi
fi

FOE
# end in inline "here" file

    chmod +x "${OPT_INSTALL_DIR}/hyperion-init-$shell.sh"
    source "${OPT_INSTALL_DIR}/hyperion-init-$shell.sh"

#   echo "To set the required environment variables, run:"
#   echo "    source ${OPT_BUILD_DIR}/hercules-setvars.sh"
fi

if (! $OPT_NO_INSTALL); then
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
            if ($OPT_PROMPTS); then
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

# location of script: ${OPT_INSTALL_DIR}
if [ -f "${OPT_INSTALL_DIR}/hyperion-init-\$shell.sh" ]; then
   . "${OPT_INSTALL_DIR}/hyperion-init-\$shell.sh"
else
   echo "Cannot create Hyperion profile variables on \$shell, script is missing."
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
if [ -f /etc/profile.d/hyperion.sh ]; then
    . /etc/profile.d/hyperion.sh
fi

BASHRC
# end in inline "here" file
            fi

        fi # if bash

    fi

fi # if (! $OPT_NO_INSTALL)
     
verbose_msg "Done!"

} # End of I/O redirection function

current_time=$(date "+%Y-%m-%d")
logfile="$(basename "$0")"
logfile="${logfile%.*}-$current_time"

if [[ -e $logfile.log || -L $logfile.log ]] ; then
    i=1
    while [[ -e $logfile-$i.log || -L $logfile-$i.log ]] ; do
        let i++
    done
    logfile=$logfile-$i
fi

the_works 2>&1 | tee "$logfile.log"

# ---- end of script ----

