#!/usr/bin/env bash

# Utility functions for hercules-helper scripts
# Updated: 24 DEC 2020
#
# The most recent version of this script can be obtained with:
#   git clone https://github.com/wrljet/hercules-helper.git
# or
#   wget https://github.com/wrljet/hercules-helper/archive/master.zip
#
# Please report errors in this to me so everyone can benefit.
#
# Bill Lewis  wrljet@gmail.com

# Changelog:
#
# Updated: 24 DEC 2020
# - detect existing ooRexx
# - use existing installed REXX for 'make check'
#
# Updated: 22 DEC 2020
# - correct Regina REXX detection for different version string formats
#
# Updated: 21 DEC 2020
# - detect existing Regina REXX installation
#
# Updated: 15 DEC 2020
# - changes to detect and disallow Raspberry Pi Desktop for PC
#
# Updated: 13 DEC 2020
# - initial commit to GitHub
# - changes to accomodate Mint (in-progress)
# - changes to accomodate Windows WSL2
# - changes to accomodate Raspberry Pi 32-bit Raspbian
# - break out common functions to utilfns.sh include file
#

#------------------------------------------------------------------------------
#                               verbose_msg
#------------------------------------------------------------------------------
verbose_msg()
{
    if ($VERBOSE); then
        echo "$@"
    fi
}

#------------------------------------------------------------------------------
#                               detect_system
#------------------------------------------------------------------------------
detect_system()
{

# $ cat /boot/issue.txt | head -1
#  Raspberry Pi reference 2020-05-27

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

            CENTOS_VERS=$(rpm --query centos-release) || true
            CENTOS_VERS="${CENTOS_VERS#centos-release-}"
            CENTOS_VERS="${CENTOS_VERS/-/.}"

            VERSION_DISTRO=redhat
            VERSION_MAJOR=$(echo ${CENTOS_VERS} | cut -f1 -d.)
            VERSION_MINOR=$(echo ${CENTOS_VERS} | cut -f2 -d.)

            verbose_msg "VERSION_MAJOR    : $VERSION_MAJOR"
            verbose_msg "VERSION_MINOR    : $VERSION_MINOR"
        fi

        # show the default language
        # i.e. LANG=en_US.UTF-8
        verbose_msg "Language         : $(env | grep LANG)"

        # Check if running under Windows WSL
        VERSION_WSL=0

        verbose_msg -n "Checking for Windows WSL1... "
        if [[ "$(< /proc/version)" == *@(Microsoft|WSL)* ]]; then
            verbose_msg "running on WSL1"
            VERSION_WSL=1
        else
            echo "nope"
        fi

        verbose_msg -n "Checking for Windows WSL2... "
        if [ $(uname -r | sed -n 's/.*\( *Microsoft *\).*/\1/ip') ]; then
            verbose_msg "running on WSL2"
            VERSION_WSL=2
        else
            echo "nope"
        fi

        # Check if running under Raspberry Pi Desktop (for PC)

# Raspberry Pi, native and x86_64 Desktop
# $ cat /etc/rpi-issue 
# Raspberry Pi reference 2020-02-12
# Generated using pi-gen, https://github.com/RPi-Distro/pi-gen, f3b8a04dc10054b328a56fa7570afe6c6d1b856e, stage5

        VERSION_RPIDESKTOP=0

        if [ -f /etc/rpi-issue ]; then
            if [[ "$(< /etc/rpi-issue)" == *@(Raspberry Pi reference)* &&
                  "$machine" == "x86_64"                               ]];
            then
                verbose_msg "Running on Raspberry Pi Desktop (for PC)"
                VERSION_RPIDESKTOP=1
            fi
        fi

    elif [ "${OS_NAME}" = "OpenBSD" -o "${OS_NAME}" = "NetBSD" ]; then

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

        # show the default language

        # i.e. LANG=en_US.UTF-8
        verbose_msg "Language         : <unknown>"
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
    verbose_msg " "  # move to a new line

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
            echo "gcc_status = $gcc_status"
            echo "rexxsaa.h is found in gcc search path"
            trace "$gcc_find_h"
        else
            echo "gcc_status = $gcc_status"
            error_msg "rexxsaa.h is not found in gcc search path"
            echo "$gcc_find_h"
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
            echo "gcc_status = $gcc_status"
            echo "rexx.h is found in gcc search path"
            trace "$gcc_find_h"
        else
            echo "gcc_status = $gcc_status"
            echo "rexx.h is not found in gcc search path"
            echo "$gcc_find_h"
        fi
    fi
}

#------------------------------------------------------------------------------
# This last group of helper functions were taken from Fish's extpkgs.sh

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
