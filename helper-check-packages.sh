#!/usr/bin/env bash

# helper-check-packages.sh
# Updated: 16 NOV 2022

# The most recent version of this project can be obtained with:
#   git clone https://github.com/wrljet/hercules-helper.git
# or:
#   wget https://github.com/wrljet/hercules-helper/archive/master.zip
#
# Please report errors in this to me so everyone can benefit.
#
# Bill Lewis  bill@wrljet.com

#-----------------------------------------------------------------------------

if test "$BASH" == "" || "$BASH" -uc "a=();true \"${a[@]}\"" 2>/dev/null; then
    # Bash 4.4+, Zsh
    # Treat unset variables as an error when substituting
    set -uo pipefail
else
    # Bash 4.3 and older chokes on empty arrays with set -u
    set -o pipefail
fi

# Stop on error
# set -e

# Instructions on updating Bash on macOS Mojave 10.14
# https://itnext.io/upgrading-bash-on-macos-7138bd1066ba

if ((BASH_VERSINFO[0] == 4)); then
#   echo "Bash version < v4"
#lse
    shopt -s globstar
fi

shopt -s nullglob
shopt -s extglob # Required for MacOS

require(){ hash "$@" || exit 127; }

#-----------------------------------------------------------------------------

# Check for Apple macOS and prerequisites

darwin_have_homebrew=false
darwin_have_macports=false

uname_system="$( (uname -s) 2>/dev/null)" || uname_system="unknown"

if [ "$uname_system" == "Darwin" ]; then
    darwin_need_prereqs=false

  # echo "Checking for Xcode command line tools ..."
    xcode-select -p 1>/dev/null 2>/dev/null
    if [[ $? == 2 ]] ; then
        darwin_need_prereqs=true
    else
        echo "Xcode command line tools appear to be installed"

        if (cc --version 2>&1 | head -n 1 | grep -Fiqe "xcrun: error: invalid active developer path"); then
            error_msg "But the C compiler does not work"
            echo "$(cc --version 2>&1)"
            exit 1
        fi
    fi

  # echo "Checking for Homebrew package manager ..."
    which -s brew
    if [[ $? != 0 ]] ; then
        echo "    Homebrew is not installed"
    else
        darwin_need_prereqs=false
        darwin_have_homebrew=true
        echo "    Homebrew is already installed"
    fi

  # echo "Checking for MacPorts package manager ..."
    which -s port
    if [[ $? != 0 ]] ; then
        echo "    MacPorts is not installed"
    else
        darwin_need_prereqs=false
        darwin_have_macports=true
        echo "    MacPorts is already installed"
    fi

#   if ( $darwin_need_prereqs == true ) ; then
#       echo   # output a newline
#       echo "Please run macOS_prerequisites.sh first"
#       echo   # output a newline
#       exit 1
#   fi

    echo   # output a newline
fi

#------------------------------------------------------------------------------
#                               error_msg
#------------------------------------------------------------------------------
error_msg()
{
#   printf "\033[1;37m[[ \033[1;31merror: \033[1;37m]] \033[0m$1\n"
    printf "\033[1;31m[[ error: ]] \033[0m$1\n"
}

#------------------------------------------------------------------------------
#                               detect_pi
#------------------------------------------------------------------------------

# Table source:
# https://www.raspberrypi.org/documentation/hardware/raspberrypi/revision-codes/README.md

function get_pi_version()
{
#   echo -n "Checking for Raspberry Pi... "

    RPI_MODEL=$(awk '/Model/ {print $3}' /proc/cpuinfo)
    # echo "$RPI_MODEL"
    if [[ $RPI_MODEL =~ "Raspberry" ]]; then
#       echo "found"
        os_is_supported=true

        RPI_REVCODE=$(awk '/Revision/ {print $3}' /proc/cpuinfo)
#       echo "Raspberry Pi rev : $RPI_REVCODE"

        RPI_CPUS=$(awk '/^processor/{n+=1}END{print n}' /proc/cpuinfo)
#       echo "CPU count        : $RPI_CPUS"
#   else
#       echo "nope"
    fi
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

    echo "Raspberry Pi ${RPI_REVISIONS[$RPI_REVCODE]} ($RPI_REVCODE)"
}

function detect_pi()
{
#   echo " "  # output a newline

# Raspberry Pi 4B,   Ubuntu 20 64-bit,  uname -m == aarch64
# Raspberry Pi 4B,   RPiOS     32-bit,  uname -m == armv7l
# Raspberry Pi Zero, RPiOS     32-bit,  uname -m == armv6l

    grep -iqe  "Raspberry Pi" /proc/cpuinfo 2>&1
    status=$?
    if [ $status -eq 0 ]; then
#       echo "Running on Raspberry Pi hardware"

        get_pi_version
        check_pi_version
    fi
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
    # Darwin xxxx.cyberlynk.net 20.5.0 Darwin Kernel Version 20.5.0: Sat May  8 05:10:31 PDT 2021; root:xnu-7195.121.3~9/RELEASE_ARM64_T8101 arm64

    if [ "$uname_system" == "Darwin" ]; then
        version_distro="darwin"
    fi
}

#------------------------------------------------------------------------------
#                               detect_system
#------------------------------------------------------------------------------
detect_system()
{
    os_name="$( (uname -s) 2>/dev/null)" || os_name="unknown"
#   echo "OS Type          : $os_name"

    machine=$(uname -m)
#   echo "Machine Arch     : $machine"

    if [ "$os_name" = "Linux" ]; then
        version_id="??? unknown ???"
        version_id_like="??? unknown ???"
        version_pretty_name="??? unknown ???"
        version_str="??? unknown ???"

        if [ -f /etc/os-release ]; then
            # awk -F= '$1=="ID" { gsub(/"/, "", $2); print $2 ;}' /etc/os-release
            version_id=$(awk -F= '$1=="ID" { gsub(/"/, "", $2); print $2 ;}' /etc/os-release)
            # echo "VERSION_ID is $version_id"

            version_id_like=$(awk -F= '$1=="ID_LIKE" { gsub(/"/, "", $2); print $2 ;}' /etc/os-release)
            # echo "VERSION_ID_LIKE is $version_id_like"

            version_pretty_name=$(awk -F= '$1=="PRETTY_NAME" { gsub(/"/, "", $2); print $2 ;}' /etc/os-release)
            # echo "VERSION_STR is $version_str"

            version_str=$(awk -F= '$1=="VERSION_ID" { gsub(/"/, "", $2); print $2 ;}' /etc/os-release)
            # echo "VERSION_STR is $version_str"
        fi

#       echo "VERSION_ID       : $version_id"
#       echo "VERSION_PRETTY   : $version_pretty_name"
#       echo "VERSION_STR      : $version_str"

        # Look for Alpine Linux

        if [[ $version_id == alpine* ]];
        then
            echo "We have an Alpine system"

            version_distro="alpine"
            version_major=$(echo $version_str | cut -f1 -d.)
            version_minor=$(echo $version_str | cut -f2 -d.)

            os_is_supported=false
            error_msg "Alpine Linux is not yet supported!"
            exit 1
        fi

        # Look for Manjaro

        if [[ $version_id == arch* || $version_id == manjaro* ]];
        then
            echo "We have an Arch based system"

            version_distro="arch"
            version_str=$(awk -F= '$1=="DISTRIB_RELEASE" { gsub(/"/, "", $2); print $2 ;}' /etc/lsb-release)
            version_major=$(echo $version_str | cut -f1 -d.)
            version_minor=$(echo $version_str | cut -f2 -d.)

            os_is_supported=true
        fi

        # Look for Debian/Ubuntu/Mint

        if [[ $version_id == debian*   || $version_id == ubuntu*    || \
              $version_id == neon*     || $version_id == linuxmint* || \
              $version_id == raspbian* || $version_id == zorin*     || \
              $version_id == pop*      ]];
        then
            echo "We have a Debian based system"

            version_distro="debian"
            version_major=$(echo $version_str | cut -f1 -d.)
            version_minor=$(echo $version_str | cut -f2 -d.)

            os_is_supported=true
        fi

        if [[ $version_id == raspbian* ]]; then
            echo "$(cat /boot/issue.txt | head -1)"
        fi

        # Look for AlmaLinux
        if [[ $version_id == almalinux* ]]; then
            echo "We have an AlmaLinux system"

            # AlmaLinux 8.4
            # $ rpm --query centos-release
            # package centos-release is not installed
            # $ cat /etc/redhat-release 
            # AlmaLinux release 8.4 (Electric Cheetah)

          # almalinux_vers=$(rpm --query centos-release) || true
            almalinux_vers=$(cat /etc/redhat-release) || true
            almalinux_vers="${almalinux_vers#*release }"
            almalinux_vers="${almalinux_vers/ */}"

            version_distro="almalinux"
            version_major=$(echo $almalinux_vers | cut -f1 -d.)
            version_minor=$(echo "$almalinux_vers.0" | cut -f2 -d.)

            echo "VERSION_MAJOR    : $version_major"
            echo "VERSION_MINOR    : $version_minor"
            os_is_supported=true
        fi

        # Look for CentOS
        if [[ $version_id == centos* ]]; then
            echo "We have a CentOS system"

            # CENTOS_VERS="centos-release-7-8.2003.0.el7.centos.x86_64"
            # CENTOS_VERS="centos-release-7.9.2009.1.el7.centos.x86_64"
            # CENTOS_VERS="centos-release-8.2-2.2004.0.2.el8.x86_64"

            # Centos Stream 8:
            # $ rpm --query centos-release
            # package centos-release is not installed
            # $ cat /etc/redhat-release 
            # CentOS Linux release 8.2.2004
            # CentOS Stream release 8

          # centos_vers=$(rpm --query centos-release) || true
            centos_vers=$(cat /etc/redhat-release) || true
            centos_vers="${centos_vers#*release }"
            centos_vers="${centos_vers/-/.}"

            version_distro="redhat"
            version_major=$(echo $centos_vers | cut -f1 -d.)
            version_minor=$(echo "$centos_vers.0" | cut -f2 -d.)

            echo "VERSION_MAJOR    : $version_major"
            echo "VERSION_MINOR    : $version_minor"

            if [[ $version_major -ge 7 ]]; then
              os_is_supported=true
            fi
        fi

        # Look for Fedora
# NAME=Fedora
# VERSION="34 (Workstation Edition)"
# ID=fedora
# VERSION_ID=34
# PRETTY_NAME="Fedora 34 (Workstation Edition)"

        if [[ $version_id == fedora* ]]; then
            echo "We have a Fedora system"

            # cat /etc/redhat-release
            # Fedora release 34 (Thirty Four)
            fedora_vers=$(cat /etc/redhat-release) || true

            fedora_vers="${fedora_vers#*release }"
            fedora_vers="${fedora_vers/-/.}"

            version_distro="redhat"
            version_major=$(echo $fedora_vers | cut -f1 -d' ')
            echo "VERSION_MAJOR    : $version_major"

            if [[ $version_major -ge 34 ]]; then
              os_is_supported=true
            fi
        fi

        if [[ $version_id == clear-linux-os* ]]; then
            echo "We have a Intel Clear Linux system"

            version_distro="clear-linux"
            version_major=$(echo $version_str | cut -f1 -d.)
            version_minor=$(echo $version_str | cut -f2 -d.)

            echo "OS Version       : $version_major"
            os_is_supported=true
        fi

        # Look for openSUSE
        if [[ $version_id == opensuse* ]];
        then
            echo "We have an openSUSE based system"

            version_distro="openSUSE"
            version_major=$(echo $version_str | cut -f1 -d.)
            version_minor=$(echo $version_str | cut -f2 -d.)

            os_is_supported=true
        fi

        # Check if running under Raspberry Pi Desktop (for PC)
        #
        # Raspberry Pi, native and x86_64 Desktop
        # $ cat /etc/rpi-issue
        # Raspberry Pi reference 2020-02-12
        # Generated using pi-gen, https://github.com/RPi-Distro/pi-gen, f3b8a04dc10054b328a56fa7570afe6c6d1b856e, stage5

        version_rpidesktop=0
        RPI_CPUS=0

        if [ -f /etc/rpi-issue ]; then
            if [[ "$(< /etc/rpi-issue)" == *@(Raspberry Pi reference)* &&
                  "$machine" == "x86_64" ]];
            then
                echo "Running on Raspberry Pi Desktop (for PC)"
                version_rpidesktop=1
                os_is_supported=false
            else
                if [[ "$machine" != "x86_64" ]]; then
                    os_is_supported=true
                fi
            fi
        fi

        # Check for real Raspberry Pi hardware
        detect_pi

#------------------------------------------------------------------------------
    elif [ "$os_name" = "NetBSD" ]; then
        echo "We have a NetBSD system"

        version_distro="netbsd"
        version_id="netbsd"

        # 9.0_STABLE
        version_str=$(uname -r)

        echo "VERSION_ID       : $version_id"
        echo "VERSION_STR      : $version_str"

        version_substr=$(echo $version_str | cut -f1 -d_)
        echo "VERSION_SUBSTR   : $version_substr"
        version_major=$(echo $version_substr | cut -f1 -d.)
        echo "VERSION_MAJOR    : $version_major"
        version_minor=$(echo $version_substr | cut -f2 -d.)
        echo "VERSION_MINOR    : $version_minor"

#------------------------------------------------------------------------------
    elif [ "$os_name" = "OpenBSD" ]; then
        echo "We have an OpenBSD system"
        error_msg "OpenBSD is not yet supported!"

#------------------------------------------------------------------------------
    elif [ "$os_name" = "FreeBSD" ]; then

        echo "We have a FreeBSD system"

        version_distro="freebsd"
        version_id="freebsd"

        # FREEBSD_MEMINFO="$(sysctl hw | grep hw.phys)"
        version_freebsd_memory="$(sysctl hw.physmem | awk '/^hw.physmem:/{mb = $2/1024/1024; printf "%.0f", mb}')"
#       echo "Memory Total (MB): $(sysctl hw.physmem | awk '/^hw.physmem:/{mb = $2/1024/1024; printf "%.0f", mb}')"

        # sysctl hw.model
        # hw.model: ARM Cortex-A53 r0p4
        version_freebsd_model="$(sysctl hw.model | cut -f2 -d: | awk '{$1=$1};1')"
#       echo "CPU Model        : $(sysctl hw.model | cut -f2 -d: | awk '{$1=$1};1')"

        # Try to detect FreeBSD on a Raspberry Pi
        # bcm2835_cpufreq0: <CPU Frequency Control> on cpu0
        version_freebsd_cpu="$(dmesg | grep CPU | grep bcm2)"

        # Raspberry Pi BCM chipset?
        if (dmesg | grep CPU | grep -Fqe "bcm2"); then
            echo "                 : $version_freebsd_cpu"
            echo "                 : assuming Raspberry Pi"

            if [ $version_freebsd_memory -lt 2000 ]; then
                echo "                 : FreeBSD Raspberry Pi with low memory"
            fi
        fi

        # 12.2-RELEASE
        version_str=$(uname -r)

        echo "VERSION_ID       : $version_id"
        echo "VERSION_STR      : $version_str"

        version_substr=$(echo $version_str | cut -f1 -d-)
        # echo "VERSION_SUBSTR   : $version_substr"
        version_major=$(echo $version_substr | cut -f1 -d.)
        # echo "VERSION_MAJOR    : $version_major"
        version_minor=$(echo $version_substr | cut -f2 -d.)
        # echo "VERSION_MINOR    : $version_minor"

        if [[ $version_major -ge 12 ]]; then
          os_is_supported=true
        fi

#------------------------------------------------------------------------------
    elif [ "$os_name" = "Darwin" ]; then

# uname -a        : Darwin Bills-Mac.local 18.0.0 Darwin Kernel Version 18.0.0: Wed Aug 22 20:13:40 PDT 2018; root:xnu-4903.201.2~1/RELEASE_X86_64 x86_64
# uname -m        : x86_64
# uname -p        : i386
# uname -s        : Darwin
# uname -r        : 18.0.0

# uname -a        : Darwin xxx.cyberlynk.net 20.5.0 Darwin Kernel Version 20.5.0: Sat May  8 05:10:31 PDT 2021; root:xnu-7195.121.3~9/RELEASE_ARM64_T8101 arm64
# uname -m        : arm64
# uname -p        : arm
# uname -s        : Darwin
# config.guess    :aarch64-apple-darwin20.5.0

# uname -a        : Darwin Sunils-Air 20.2.0 Darwin Kernel Version 20.2.0: Wed Dec  2 20:40:21 PST 2020; root:xnu-7195.60.75~1/RELEASE_ARM64_T8101 x86_64

# 18.0.0 = macOS v10.14 (Mojave)

        echo "We have a MacOS Darwin system"

        version_id="darwin"
        version_str=$(sw_vers -productVersion)

        echo "VERSION_ID       : $version_id"
        echo "VERSION_STR      : $version_str"

        version_major=$(echo $version_str | cut -f1 -d.)
#       echo "VERSION_MAJOR    : $version_major"
        version_minor=$(echo $version_str | cut -f2 -d.)
#       echo "VERSION_MINOR    : $version_minor"
        version_build=$(echo $version_str | cut -f3 -d.)
#       echo "VERSION_BUILD    : $version_build"

        if [[ $version_major -eq 10 && $version_minor -eq 13 ]]; then
            os_is_supported=true
            echo "Apple macOS version $version_str (High Sierra) found"
        elif [[ $version_major -eq 10 && $version_minor -eq 14 ]]; then
            os_is_supported=true
            echo "Apple macOS version $version_str (Mojave) found"
        elif [[ $version_major -eq 10 && $version_minor -eq 15 ]]; then
            os_is_supported=true
            echo "Apple macOS version $version_str (Catalina) found"
        elif [[ $version_major -eq 11 ]]; then
            os_is_supported=true

            if [[ "$(uname -m)" =~ ^arm64 ]]; then
                echo "Apple macOS version $version_str (Big Sur) on ARM CPU found"
            else
                echo "Apple macOS version $version_str (Big Sur) found"
            fi
        else
            os_is_supported=false
            echo "Apple macOS version $version_major.$version_minor found, is not automatically checked"
            exit 1
        fi
    fi
}

#------------------------------------------------------------------------------
#                              check_packages
#------------------------------------------------------------------------------
check_packages()
{
  # Look for Debian/Ubuntu/Mint

  if [ "$version_distro" == "debian"  ]; then
      declare -a packages=( \
          "git" "wget" "time" \
          "build-essential" "cmake" \
          "autoconf" "automake" "flex" "gawk" "m4" "libltdl-dev" "libtool-bin" \
          "libcap2-bin" \
          "libbz2-dev" "zlib1g-dev"
      )

      # package="libregina3-dev"

      echo    # print a newline
      echo "Required packages: "
      echo "${packages[*]}"
      echo    # print a newline

      for package in "${packages[@]}"; do
          echo -n "Checking for package: $package ... "

          # the following only works on Ubuntu newer than 12.04
          # another method is:
          # /usr/bin/dpkg-query -s <packagename> 2>/dev/null | grep -q ^"Status: install ok installed"$

          is_installed=$(/usr/bin/dpkg-query --show --showformat='${db:Status-Status}\n' $package 2>&1)
          status=$?

          if [ $status -eq 0 ] && [ "$is_installed" == "installed" ]; then
              echo "is already installed"
          else
              echo "is missing"
          fi
      done
    return
  fi

#-----------------------------------------------------------------------------
  # Look for Arch/Manjaro

  if [ "$version_distro" == "arch"  ]; then
      declare -a packages=( \
          "base-devel" "make" "autoconf" "automake" "cmake" "flex" "gawk" "m4" \
          "bzip2" "zlib"
      )

      # package="libregina3-dev"

      echo    # print a newline
      echo "Required packages: "
      echo "${packages[*]}"
      echo    # print a newline

      for package in "${packages[@]}"; do
          echo -n "Checking for package: $package ... "

          is_installed=$(pacman -Q $package 2>&1)
          status=$?

          if [ $status -eq 0 ]; then
              echo "is already installed"
          else
              echo "is missing"
          fi
      done
    return
  fi

#-----------------------------------------------------------------------------
  # Fedora

  if [[ $version_id == fedora* ]]; then
      if [[ $version_major -ge 34 ]]; then
          echo "Fedora version 34 or later found"

          declare -a packages=( \
              "gcc" "make" "flex" "gawk" "m4" \
              "autoconf" "automake" "libtool-ltdl-devel" "libtool" \
              "cmake"
              "bzip2-devel" "zlib-devel"
              )

          echo    # print a newline
          echo "Required packages: "
          echo "${packages[*]}"
          echo    # print a newline

          for package in "${packages[@]}"; do
              echo -n "Checking for package: $package ... "

              is_installed=$(dnf list installed $package 2>&1)
              status=$?

              if [ $status -eq 0 ]; then
                  echo "is already installed"
              else
                  echo "is missing"
              fi
          done
      else
          error_msg "Fedora version 33 or earlier found, and not automatically checked"
          exit 1
      fi
    return
  fi

#-----------------------------------------------------------------------------
  # AlmaLinux

  if [[ $version_id == almalinux* ]]; then
      if [[ $version_major -ge 8 ]]; then
          echo "AlmaLinux version 8 or later found"

          declare -a packages=( \
              "gcc" "make" "flex" "gawk" "m4" \
              "autoconf" "automake" "libtool-ltdl-devel" "libtool" \
              "cmake"
              "bzip2-devel" "zlib-devel"
              )

          echo    # print a newline
          echo "Required packages: "
          echo "${packages[*]}"
          echo    # print a newline

          for package in "${packages[@]}"; do
              echo -n "Checking for package: $package ... "

              #yum list installed bzip2-devel  > /dev/null 2>&1 ; echo $?
              is_installed=$(yum list installed $package 2>&1)
              status=$?

              if [ $status -eq 0 ]; then
                  echo "is already installed"
              else
                  echo "is missing"
              fi
          done
      else
          error_msg "AlmaLinux version 7 or earlier found, and not automatically checked"
          exit 1
      fi
    return
  fi

#-----------------------------------------------------------------------------
  # CentOS 7

  if [[ $version_id == centos* ]]; then
      if [[ $version_major -ge 7 ]]; then
          echo "CentOS version 7 or later found"

          if [[ $version_major -eq 7 ]]; then
              declare -a packages=( \
                  "gcc" "make" "flex" "gawk" "m4" \
                  "autoconf" "automake" "libtool-ltdl-devel" \
                  "bzip2-devel" "zlib-devel"
              )
          fi

          if [[ $version_major -ge 8 ]]; then
              declare -a packages=( \
                  "gcc" "make" "flex" "gawk" "m4" \
                  "autoconf" "automake" "libtool-ltdl-devel" \
                  "cmake" "time" \
                  "bzip2-devel" "zlib-devel"
              )
          fi

          echo    # print a newline
          echo "Required packages: "
          echo "${packages[*]}"
          echo    # print a newline

          for package in "${packages[@]}"; do
              echo "-----------------------------------------------------------------"

              #yum list installed bzip2-devel  > /dev/null 2>&1 ; echo $?
              yum list installed $package
              status=$?

              if [ $status -eq 0 ]; then
                  echo "package $package is already installed"
              else
                  echo "package $package: is missing"
              fi
          done

          if [[ $version_major -eq 7 ]]; then

              echo "-----------------------------------------------------------------"
  # cmake presence: /usr/local/bin/cmake
  # /usr/local/bin/cmake status: 0
              which_cmake=$(which cmake)
              which_status=$?

              echo "CMAKE presence: $which_cmake"
              echo "(which cmake) status: $which_status"

              if [ $which_status -eq 1 ]; then
                  echo "On CentOS 7, there is no package for CMAKE 3.x"
                  echo "Must be built from source."
              fi
          fi
      else
          error_msg "CentOS version 6 or earlier found, and not automatically checked"
          exit 1
      fi
    return
  fi

#-----------------------------------------------------------------------------
  # openSUSE (15.1)

  if [[ $version_id == opensuse* ]]; then

# devel_basis is a "pattern"
# libcap-progs is not, and won't install it -t pattern

      declare -a opensuse_patterns=( \
          "devel_basis" "autoconf" "automake" "cmake" "flex" "gawk" "m4" \
          "libtool" \
          "bzip2" \
          "libz1" "zlib-devel"
      )

      declare -a packages=( \
          "git" "libbz2-devel" \
          "libcap-progs"
      )

      echo    # print a newline
      echo "Required patterns: "
      echo "${opensuse_patterns[*]}"
      echo "Required packages: "
      echo "${packages[*]}"
      echo    # print a newline

      for package in "${opensuse_patterns[@]}"; do
          echo "-----------------------------------------------------------------"
          echo "Checking for pattern: $package"

          is_installed=$(zypper search --installed-only --match-exact "$package")
          status=$?

          if [ $status -eq 0 ] ; then
              echo "package: $package is already installed"
          else
              echo "package $package: is missing"
          fi
      done

      for package in "${packages[@]}"; do
          echo "-----------------------------------------------------------------"
          echo "Checking for package: $package"

          is_installed=$(zypper search --installed-only --match-exact "$package")
          status=$?

          if [ $status -eq 0 ] ; then
              echo "package: $package is already installed"
          else
              echo "package $package: is missing"
          fi
      done

    return
  fi

#-----------------------------------------------------------------------------
  # Intel Clear Linux (supported from 35130 onward)

  if [[ $version_id == clear-linux-os* ]]; then
      declare -a packages=( \
          "git" "wget" \
          "dev-utils" "perl-basic" \
          "c-basic" "flex" "os-core" \
          "devpkg-bzip2" \
          "devpkg-zlib" "zlib"
      )

      for package in "${packages[@]}"; do
          echo -n "Checking for package: $package ... "

          is_installed=$(sudo swupd bundle-list | grep -Fie "$package" 2>&1)
          status=$?

          # install if missing
          if [ $status -eq 0 ]; then
              echo "is already installed"
          else
              echo "is missing, installing"
              sudo swupd bundle-add $package 2>&1
          fi
          echo "-----------------------------------------------------------------"
      done
  fi

#-----------------------------------------------------------------------------
#   # Alpine Linux 3.x
# 
#   if [[ $version_id == alpine* ]]; then
#       declare -a packages=( \
#           "git" "wget" "bash" \
#           "build-base" "autoconf" "automake" "cmake" "flex" "gawk" "m4" \
#           "bzip2" "libbz2" \
#           "zlib" "zlib-dev"
#       )
# 
#       for package in "${packages[@]}"; do
#           echo "Checking for package: $package"
# 
#           is_installed=$(apk list --installed | grep "$package")
#           status=$?
# 
#           # install if missing
#           if [ $status -eq 0 ] ; then
#               echo "package: $package is already installed"
#           else
#               echo "$package: is missing"
#           fi
#       done
# 
#     return
#   fi

#-----------------------------------------------------------------------------
  # Apple Darwin (macOS)

  if [[ $version_id == darwin* ]]; then
      declare -a packages=( \
          "autoconf" "automake" "libtool" \
          "cmake"   \
          "gsed"
        # "flex" "gawk" "m4" \
        # "bzip2" "zlib"
      )

      echo    # print a newline
      echo "Required packages: "
      echo "${packages[*]}"
      echo    # print a newline

      # split cases between Homebrew and MacPorts
      if ( $darwin_have_macports == true ) ; then

          for package in "${packages[@]}"; do
              echo -n "Checking for package: $package ... "

              is_installed=$(port installed 2>&1 | grep -Fiqe "$package")
              status=$?

              if [[ $status -eq 1 || $is_installed == *"Not installed"* ]] ; then
                  echo "is missing"
              else
                  echo "is already installed"
              fi
          done

      elif ( $darwin_have_homebrew == true ) ; then

          for package in "${packages[@]}"; do
              echo -n "Checking for package: $package ... "

              is_installed=$(brew info $package 2>&1)
              status=$?

              if [[ $status -eq 1 || $is_installed == *"Not installed"* ]] ; then
                  echo "is missing"
              else
                  echo "is already installed"
              fi
          done
      else
          error_msg "MacOS and neither Homebrew or MacPorts is installed!"
          exit 1
      fi

      return
  fi

#-----------------------------------------------------------------------------
#   # NetBSD
# 
#   if [[ $version_id == netbsd* ]]; then
#       declare -a packages=( \
#           "build-essential" "autoconf" "automake" "cmake" "flex" "gawk" "m4" \
#           "bzip2" "zlib1g-dev"
#       )
# 
#       for package in "${packages[@]}"; do
#           echo "-----------------------------------------------------------------"
#           echo "Checking for package: $package"
# 
#           is_installed=$(pkg_info -E $package)
#           status=$?
# 
#           # install if missing
#           if [ $status -eq 0 ] ; then
#               echo "package: $package is already installed"
#           else
#               echo "$package : must be installed"
#           fi
#       done
# 
#     return
#   fi

#-----------------------------------------------------------------------------
  # FreeBSD

  if [[ $version_id == freebsd* ]]; then
      if [[ $version_major -ge 12 ]]; then
          echo "FreeBSD version 12 or later found"

          declare -a packages=( \
              "autoconf" "automake" "cmake" "flex" "gawk" "m4" \
              "bzip2" \
              "gmake" "libltdl" "libtool"
          )

          echo    # print a newline
          echo "Required packages: "
          echo "${packages[*]}"
          echo    # print a newline

          for package in "${packages[@]}"; do
              echo -n "Checking for package: $package ... "

              is_installed=$(pkg info $package 2>&1)
              status=$?

              if [ $status -eq 0 ] ; then
                  echo "is already installed"
              else
                  echo "is missing"
              fi
          done
      fi

    return
  fi

  if [ $os_is_supported != true ]; then
    error_msg "Your system ( $version_pretty ) is not (yet) supported!"
    exit 1
  fi
}

#------------------------------------------------------------------------------

detect_system

detect_darwin

# echo "OS Type          : $os_name"
# echo "VERSION_ID       : $version_id"
# echo "OS Version       : $version_major"

check_packages

# end
