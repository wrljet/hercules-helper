#!/bin/bash

# Prepare system for building SDL-Hercules-390
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
    echo    # move to a new line
    echo "Running this as root is dangerous and can cause misconfiguration issues"
    echo "or damage to your system.  Run as a normal user, and the parts that need"
    echo "it will ask for your sudo password (if required)."
    echo    # move to a new line
    echo "For information, see:"
    echo "https://askubuntu.com/questions/16178/why-is-it-bad-to-log-in-as-root"
    echo "https://wiki.debian.org/sudo/"
    echo "https://phoenixnap.com/kb/how-to-create-add-sudo-user-centos"
    echo    # move to a new line
    read -p "Hit return to exit" -n 1 -r
    echo    # move to a new line
    exit 1
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

	# CENTOS_VERS="centos-release-7-8.2003.0.el7.centos.x86_64"
	# CENTOS_VERS="centos-release-8.2-2.2004.0.2.el8.x86_64"

	CENTOS_VERS=$(rpm --query centos-release) || true
	CENTOS_VERS="${CENTOS_VERS#centos-release-}"
	CENTOS_VERS="${CENTOS_VERS/-/.}"

	VERSION_MAJOR=$(echo ${CENTOS_VERS} | cut -f1 -d.)
	VERSION_MINOR=$(echo ${CENTOS_VERS} | cut -f2 -d.)

	echo "VERSION_MAJOR : $VERSION_MAJOR"
	echo "VERSION_MINOR : $VERSION_MINOR"
    fi
}

verbose_msg "TRACE            : ${TRACE}"
verbose_msg "VERBOSE          : ${VERBOSE}"

# Detect type of system we're running on and display info
detect_system

# Look for Debian/Ubuntu/Mint

if [[ $VERSION_ID == debian* || $VERSION_ID == ubuntu* ]]; then
    # if [[ $(lsb_release -rs) == "18.04" ]]; then

    declare -a debian_packages=( \
        "git" \
        "build-essential" "autoconf" "automake" "cmake" "flex" "gawk" \
	"libbz2-dev" "zlib1g-dev"
    )

    for package in "${debian_packages[@]}"; do
	echo "-----------------------------------------------------------------"
        echo "Checking for package: $package"

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
fi

# CentOS 7

if [[ $VERSION_ID == centos* ]]; then
    if [[ $VERSION_MAJOR -ge 7 ]]; then
	echo "CentOS version 7 or later found"

	declare -a centos_packages=( \
            "git" \
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
    else
	echo "CentOS version 6 or earlier found, and not supported"
        exit 1
    fi
fi

echo "Done!"

# ---- end of script ----
