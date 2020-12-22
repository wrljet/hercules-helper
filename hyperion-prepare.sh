#!/usr/bin/env bash

# Prepare system for building SDL-Hercules-390
# Updated: 21 DEC 2020
#
# The most recent version of this script can be obtained with:
#   git clone https://github.com/wrljet/hercules-helper.git
# or
#   wget https://github.com/wrljet/hercules-helper/archive/main.zip
#
# Please report errors in this to me so everyone can benefit.
#
# Bill Lewis  wrljet@gmail.com

# Updated: 30 NOV 2020
# - initial commit to GitHub
#
# Updated:  4 DEC 2020
# - disallow running as the root user
# - corrected parsing for differing CentOS 7.8 ansd 8.2 version strings
# - update package list for CentOS
# - on CentOS 7, CMAKE 3.x is built from source
# - added wget as a required package for CentOS
#
# Updated:  5 DEC 2020
# - added m4 as a required package for Debian
# - show the system language
# - display improvements
#
# Updated:  6 DEC 2020
# - another fix for CentOS 7.x detection
# - improve system status info for debugging
# - fix configure C pre-processor detection on CentOS
#
# Updated: 11 DEC 2020
# - changes to accomodate NetBSD (in-progress)
#
# Updated: 12 DEC 2020
# - changes to accomodate KDE Neon (in-progress)
#
# Updated: 13 DEC 2020
# - changes to accomodate Mint (in-progress)
# - changes to accomodate Windows WSL2
# - changes to accomodate Raspberry Pi 32-bit Raspbian
# - break out common functions to utilfns.sh include file
#
# Updated: 15 DEC 2020
# - changes to detect and disallow Raspberry Pi Desktop for PC
#
# Updated: 20 DEC 2020
# - comment known issue looking for installed state on Ubuntu 12.04
#
# Updated: 21 DEC 2020
# - detect existing Regina REXX installation
# - auto install libregina3-dev (on Debian)

# Checks for, and installs, required packages based on system type.
#   git
#   build-essential, autoconf, automake, cmake, flex, gawk, m4
#   zlib, bzip2

# Process command line

if [[ -n $trace ]]  || \
   [[ -n $TRACE ]]; then
    set -x # For debugging, show all commands as they are being run
fi

usage="usage: $(basename "$0") [-h|--help] [-t|--trace] [-v|--verbose]

Checks for, and installs, packages required to build Hercules Hyperion

where:
  -h, --help      display this help
  -t, --trace     display every command (set -x)
  -v, --verbose   display lots of messages"

TRACE=false
VERBOSE=false

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

    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

if ($TRACE); then
    set -x # For debugging, show all commands as they are being run
fi

if [ "$EUID" -eq 0 ]; then
    echo    # print a new line
    echo "Running this as root is dangerous and can cause misconfiguration issues"
    echo "or damage to your system.  Run as a normal user, and the parts that need"
    echo "it will ask for your sudo password (if required)."
    echo    # print a new line
    echo "For information, see:"
    echo "https://askubuntu.com/questions/16178/why-is-it-bad-to-log-in-as-root"
    echo "https://wiki.debian.org/sudo/"
    echo "https://phoenixnap.com/kb/how-to-create-add-sudo-user-centos"
    echo    # print a new line
    read -p "Hit return to exit" -n 1 -r
    echo    # print a new line
    exit 1
fi

# Read in the utility functions
source "$(dirname "$0")/utilfns.sh"

verbose_msg "Options:"
verbose_msg "TRACE            : ${TRACE}"
verbose_msg "VERBOSE          : ${VERBOSE}"

# Detect type of system we're running on and display info
detect_system
detect_regina

echo    # print a new line

if [[ $VERSION_WSL -eq 1 ]]; then
    echo "Not supported under Windows WSL1!"
    exit 1
fi

if [[ $VERSION_WSL -eq 2 ]]; then
    echo "Windows WSL2 host system found"
fi

if [[ $VERSION_RPIDESKTOP -eq 1 ]]; then
    verbose_msg "Running on Raspberry Pi Desktop (for PC) is not supported!"
    # exit 1
fi

case $VERSION_DISTRO in
  debian)
    echo "$VERSION_DISTRO based system found"
    ;;

  redhat)
    echo "$VERSION_DISTRO based system found"
    ;;

  netbsd*)
    echo "$VERSION_DISTRO based system found"
    echo "Not yet supported!"
    exit 1
    ;;

  *)
    ;;
esac

echo    # print a new line

# Look for Debian/Ubuntu/Mint

if [[ $VERSION_DISTRO == debian  ]]; then
    # if [[ $(lsb_release -rs) == "18.04" ]]; then

    declare -a debian_packages=( \
        "git" \
        "build-essential" "autoconf" "automake" "cmake" "flex" "gawk" "m4" \
        "libbz2-dev" "zlib1g-dev"
    )

    for package in "${debian_packages[@]}"; do
        echo "-----------------------------------------------------------------"
        echo "Checking for package: $package"

        # the following only works on Ubuntu newer than 12.04
        # another method is:
        # /usr/bin/dpkg-query -s <packagename> 2>/dev/null | grep -q ^"Status: install ok installed"$

        is_installed=$(/usr/bin/dpkg-query --show --showformat='${db:Status-Status}\n' $package)
        status=$?

        # install if missing
        if [ $status -eq 0 ] && [ "$is_installed" == "installed" ]; then
            echo "package: $package is already installed"
        else
            echo "installing package: $package"
            sudo apt-get -y install $package
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

fi

# CentOS 7

if [[ $VERSION_ID == centos* ]]; then
    if [[ $VERSION_MAJOR -ge 7 ]]; then
        echo "CentOS version 7 or later found"

        declare -a centos_packages=( \
            "git" "wget" \
            "gcc" "make" "autoconf" "automake" "flex" "gawk" "m4"
            "cmake3"
            "bzip2-devel" "zlib-devel"
        )

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
                echo "We do not have cc1 either; full gcc-c++ package is required"
            fi
        fi

        echo    # print a new line
    else
        echo "CentOS version 6 or earlier found, and not supported"
        exit 1
    fi
fi

# NetBSD

if [[ $VERSION_ID == netbsd* ]]; then
    echo "NetBSD found.  Not yet supported!"
fi

echo "Done!"

# ---- end of script ----
