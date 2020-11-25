#!/bin/bash

# Prepare system for building SDL-Hercules-390
# Updated: 25 NOV 2020
# FIXME update packages for CentOS
#
# Please report errors in this to me so everyone can benefit.
#
# Bill Lewis  wrljet@gmail.com

# Check for installed packages based on system type.
#  git, zlib, bzip2
#  build-essential, autoconf, automake, cmake, flex, gawk, m4

if [[ -n $trace ]]  || \
   [[ -n $TRACE ]]; then
    set -x # For debugging, show all commands as they are being run
fi

if [[ $1 == "trace" ]]; then
    set -x # For debugging, show all commands as they are being run
    shift 1
fi

echo "Memory Total (MB): $(free -m | awk '/^Mem:/{print $2}')"
echo "Memory Free  (MB): $(free -m | awk '/^Mem:/{print $4}')"

machine=$(uname -m) # Display machine type
echo "Machine is $machine"

# awk -F= '$1=="ID" { gsub(/"/, "", $2); print $2 ;}' /etc/os-release
VERSION_ID=$(awk -F= '$1=="ID" { gsub(/"/, "", $2); print $2 ;}' /etc/os-release)
echo "VERSION_ID is $VERSION_ID"

VERSION_STR=$(awk -F= '$1=="VERSION_ID" { gsub(/"/, "", $2); print $2 ;}' /etc/os-release)
echo "VERSION_STR is $VERSION_STR"

# Look for Debian/Ubuntu/Mint

if [[ $VERSION_ID == debian* || $VERSION_ID == ubuntu* ]]; then
    # if [[ $(lsb_release -rs) == "18.04" ]]; then
    VERSION_DISTRO=Debian

    VERSION_MAJOR=$(echo ${VERSION_STR} | cut -f1 -d.)
    VERSION_MINOR=$(echo ${VERSION_STR} | cut -f2 -d.)
    echo "OS is $VERSION_DISTRO variant"
    echo "Version $VERSION_MAJOR"

    declare -a debian_packages=( \
        "git" "libbz2-dev" "zlib1g-dev" \
        "build-essential" "autoconf" "automake" "cmake" "flex" "gawk" \
    )

    for package in "${debian_packages[@]}"; do
	echo "-----------------------------------------------------------------"
        echo "Checking for package: $package"

	is_installed=$(/usr/bin/dpkg-query --show --showformat='${db:Status-Status}\n' $package)
	status=$?

	# install if missing
	if [ $status -eq 0 ] && [ "$is_installed" == "installed" ]; then
	    echo "package $package is already installed"
	else
	    echo "installing package: $package"
	    sudo apt-get -y install $package
	fi
    done
fi

# CentOS 7

if [[ $VERSION_ID == centos* ]]; then
    echo "We have a CentOS system"

    # centos-release-7-8.2003.0.el7.centos.x86_64
    CENTOS_VERS=$(rpm --query centos-release) || true
    VERSION_MAJOR=$(echo ${CENTOS_VERS#centos-release-} | cut -f1 -d-)
    VERSION_MINOR=$(echo ${CENTOS_VERS#centos-release-} | cut -f1 -d. | cut -f2 -d-)
    echo "VERSION_MAJOR = $VERSION_MAJOR"
    if [[ $VERSION_MAJOR -ge 7 ]]; then
	echo "CentOS version 7 or later found"

	declare -a centos_packages=("git" "bzip2-devel" "zlib-devel")

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
    fi
fi
