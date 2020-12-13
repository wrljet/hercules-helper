#!/usr/bin/env bash

# Utility functions for hercules-helper scripts
# Updated: 13 DEC 2020
#
# The most recent version of this script can be obtained with:
#   git clone https://github.com/wrljet/hercules-helper.git
# or
#   wget https://github.com/wrljet/hercules-helper/archive/master.zip
#
# Please report errors in this to me so everyone can benefit.
#
# Bill Lewis  wrljet@gmail.com

# Updated: 13 DEC 2020
# - initial commit to GitHub

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

	if [[ $VERSION_ID == debian* || $VERSION_ID == ubuntu*    || \
	      $VERSION_ID == neon*   || $VERSION_ID == linuxmint* ]]; then
	    # if [[ $(lsb_release -rs) == "18.04" ]]; then
	    VERSION_DISTRO=debian
	    VERSION_MAJOR=$(echo ${VERSION_STR} | cut -f1 -d.)
	    VERSION_MINOR=$(echo ${VERSION_STR} | cut -f2 -d.)

	    verbose_msg "OS               : $VERSION_DISTRO variant"
	    verbose_msg "OS Version       : $VERSION_MAJOR"
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
