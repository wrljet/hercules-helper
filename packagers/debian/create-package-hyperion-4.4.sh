#!/usr/bin/env bash

# Create Debian package for SDL-Hercules 4.x
# Updated: 18 DEC 2021

#==============================================================================

# Changelog:
#
# Updated: 18 DEC 2021
# - initial commit to GitHub

if [[ $TRACE == true ]]; then
    set -x # For debugging, show all commands as they are being run
fi

#==============================================================================

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

if ((BASH_VERSINFO[0] < 4))
then
    echo "Bash version < v4"
else
    shopt -s globstar
fi

shopt -s nullglob
shopt -s extglob # Required for MacOS

require(){ hash "$@" || exit 127; }

current_time=$(date "+%Y-%m-%d")

# Find and read in the helper functions

# Print verbose progress information
opt_verbose=${opt_verbose:-true}

# Prompt the user before each major step is started
opt_prompts=${opt_prompts:-true}

opt_beeps=true

fns_dir="$(dirname "$0")"
fns_file="$fns_dir/helper-fns.sh"

if test -f "$fns_file" ; then
    source "$fns_file"
else
    echo "Helper functions script file not found!"
    exit 1
fi

#==============================================================================

#------------------------------------------------------------------------------
#                               the_works
#------------------------------------------------------------------------------

# Put everthing in an I/O redirection
function the_works
{

version_name="4.4"
release_date="2021-12-18"
# Sat, 18 Dec 2021 15:32:00 -0500

# FIXME: this doesn't work if this script is running off a symlink
SCRIPT_PATH=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR="$(dirname $SCRIPT_PATH)"

package_name="hyperion-$version_name"
dpkg_src="$SCRIPT_DIR/packagers/debian/$package_name"   # hercules-helper/packagers/debian/hyperion-4.4
build_path="/home/bill/hyperion-build-package"

install_prefix="/usr/local/$package_name"

# Git repo for SDL-Hercules Hyperion
git_repo_hyperion=${git_repo_hyperion:-https://github.com/SDL-Hercules-390/hyperion.git}

# Git checkout branch for Hyperion
git_branch_hyperion=${git_branch_hyperion:-""}

# Git checkout commit for Hyperion
# git_commit_hyperion=${git_commit_hyperion:-""}
git_commit_hyperion=bf377f6 # Official release 4.4

# Git repo for Hyperion Gists
git_repo_gists=${git_repo_gists:-https://github.com/SDL-Hercules-390/gists.git}

# Git checkout branch for Hyperion Gists
git_branch_gists=${git_branch_gists:-""}
# git_branch_gists="build-mods-i686"

# Git repo for Hyperion External Packages
git_repo_extpkgs=${git_repo_extpkgs:-https://github.com/SDL-Hercules-390}

# Git checkout branch for Hyperion External Packages
git_branch_extpkgs=${git_extpkgs_extpkgs:-""}

echo "Using logfile: $logfile.log"


echo_and_run "pushd $(dirname "$0") >/dev/null;"
    which_git=$(which git 2>/dev/null) || true
    which_status=$?

    if [ -z $which_git ]; then
        verbose_msg "git is not installed"
        script_version="unknown"
    else
        verbose_msg "Script version: $SCRIPT_DIR/$(basename $0): $(git describe --long --tags --dirty --always 2>/dev/null)"
        script_version="$(git describe --long --tags --dirty --always 2>/dev/null)"
    fi
echo_and_run "popd"

#==============================================================================

if [ -z "$git_branch_hyperion" ] ; then
    verbose_msg "GIT_REPO_HYPERION    : $git_repo_hyperion [default branch]"
else
    verbose_msg "GIT_REPO_HYPERION    : $git_repo_hyperion [checkout $git_branch_hyperion]"
fi

if [ ! -z "$git_commit_hyperion" ] ; then
    verbose_msg "GIT_REPO_HYPERION    : $git_repo_hyperion [checkout $git_commit_hyperion]"
fi

if [ -z "$git_branch_gists" ] ; then
    verbose_msg "GIT_REPO_GISTS       : $git_repo_gists [default branch]"
else
    verbose_msg "GIT_REPO_GISTS       : $git_repo_gists [checkout $git_branch_gists]"
fi

if [ -z "$git_branch_extpkgs" ] ; then
    verbose_msg "GIT_REPO_EXTPKGS     : $git_repo_extpkgs [default branch]"
else
    verbose_msg "GIT_REPO_EXTPKGS     : $git_repo_extpkgs [checkout $git_branch_extpkgs]"
fi

#==============================================================================

# Step: install packages

verbose_msg # output a newline
status_prompter "Step: Install required packages:"

declare -a debian_packages=( \
  "git" "wget" "time" "ncat" \
  "build-essential" "cmake" \
  "autoconf" "automake" "flex" "gawk" "m4" "libltdl-dev" "libtool-bin" \
  "libcap2-bin" \
  "libbz2-dev" "zlib1g-dev"
  "gnupg" "dpkg-sig" "reprepro"
)

for package in "${debian_packages[@]}"; do
  verbose_msg -n "Checking for package: $package ... "

  # the following only works on Ubuntu newer than 12.04
  # another method is:
  # /usr/bin/dpkg-query -s <packagename> 2>/dev/null | grep -q ^"Status: install ok installed"$

  is_installed=$(/usr/bin/dpkg-query --show --showformat='${db:Status-Status}\n' $package 2>&1)
  status=$?

  # install if missing
  if [ $status -eq 0 ] && [ "$is_installed" == "installed" ]; then
      verbose_msg "is already installed"
  else
      verbose_msg "is missing, installing"
      echo_and_run "sudo apt-get -y install $package"
      verbose_msg "-----------------------------------------------------------------"
  fi
done

#==============================================================================
# Step: clean up

verbose_msg # output a newline
status_prompter "Step: Clean up:"

echo_and_run "pushd $build_path >/dev/null;"
echo_and_run   "rm -rf hyperion/"
echo_and_run   "rm -rf extpkgs/"
# echo_and_run   "rm -f Release_$version_name.tar.gz*"
echo_and_run "popd"

# remove traces of existing package install
echo_and_run "sudo dpkg --remove hyperion-$version_name"
# sudo rm -rf "/usr/local/$package_name"

#==============================================================================
# Step: build Regina REXX

# verbose_msg # output a newline
# status_prompter "Step: Clean up:"
#
# cd regina-rexx-3.9.3/
# ./configure --prefix=/home/bill/foo/rexx
# make clean
# make
# make install

#==============================================================================
# Step: clone sources

verbose_msg # output a newline
status_prompter "Step: Clone sources:"

echo_and_run "pushd $build_path >/dev/null;"

    # echo_and_run "git clone $git_repo_hyperion"

    if [ -z "$git_repo_hyperion" ] ; then
        error_msg "git_repo_hyperion variable is not set!"
        exit 1
    fi

    if [ -z "$git_branch_hyperion" ] ; then
        verbose_msg "git clone $git_repo_hyperion"

        git clone $git_repo_hyperion
        if [[ $? != 0 ]] ; then
            error_msg "git clone failed!"
            exit 1
        fi
    else
        verbose_msg "git clone -b $git_branch_hyperion $git_repo_hyperion"

        git clone -b "$git_branch_hyperion" "$git_repo_hyperion"
        if [[ $? != 0 ]] ; then
            error_msg "git clone failed!"
            exit 1
        fi
    fi

    if [ ! -z "$git_commit_hyperion" ] ; then
        verbose_msg "git checkout $git_commit_hyperion"

        pushd hyperion >/dev/null;

        git checkout "$git_commit_hyperion"
        if [[ $? != 0 ]] ; then
            error_msg "git checkout failed!"
            exit 1
        fi

        popd >/dev/null;
    fi

#---------------

verbose_msg "clone extpkgs"
echo_and_run "mkdir extpkgs"
echo_and_run "pushd extpkgs >/dev/null;"
echo_and_run "git clone \"$git_repo_gists\""

  echo_and_run "mkdir repos"
  echo_and_run "pushd repos >/dev/null;"
  echo_and_run   "rm -rf *"

    if [ -z "$git_repo_extpkgs" ] ; then
        error_msg "git_repo_extpkgs variable is not set!"
        exit 1
    fi
    declare -a pgms=("crypto" "decNumber" "SoftFloat" "telnet")

    for pgm in "${pgms[@]}"; do
        verbose_msg "-----------------------------------------------------------------
    "
        if [ -z "$git_branch_extpkgs" ] ; then
            verbose_msg "git clone $git_repo_extpkgs/$pgm $pgm-0"
            git clone "$git_repo_extpkgs/$pgm.git" "$pgm-0"
        else
            verbose_msg "git clone -b $git_branch_extpkgs $git_repo_extpkgs/$pgm $pgm-0"
            echo_and_run "git clone -b $git_branch_extpkgs $git_repo_extpkgs/$pgm.git $pgm-0"
        fi
    done
  echo_and_run "popd" # repos
echo_and_run "popd" # extpkgs

#==============================================================================
# Step: build external packages

verbose_msg # output a newline
status_prompter "Step: Build external packages:"

echo_and_run "pushd extpkgs >/dev/null;"
echo_and_run   "cp gists/extpkgs.sh ."
echo_and_run   "cp gists/extpkgs.sh.ini ."
echo_and_run   "./extpkgs.sh c d s t"
echo_and_run "popd"

#==============================================================================
# Step: configure

verbose_msg # output a newline
status_prompter "Step: Configure:"

#------------------------------------------------------------------------------
# LD_LIBRARY_PATH is often empty, and we don't want to error out on that
set +u

#set -x # For debugging, show all commands as they are being run
#   export PATH=./rexx/bin:$PATH
    newpath="$build_path/rexx/bin"
    if [ -d "$newpath" ] && [[ ":$PATH:" != *":$newpath:"* ]]; then
        export PATH="$newpath${PATH:+":$PATH"}"
    fi

#   export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$opt_build_dir/rexx/lib
    newpath="$build_path/rexx/lib"
    if [ -d "$newpath" ] && [[ ":$LD_LIBRARY_PATH:" != *":$newpath:"* ]]; then
        export LD_LIBRARY_PATH="$newpath${LD_LIBRARY_PATH:+":$LD_LIBRARY_PATH"}"
    fi

    export CPPFLAGS="-I$build_path/rexx/include"
#set +x # For debugging, show all commands as they are being run

verbose_msg "PATH = $PATH"
verbose_msg "LD_LIBRARY_PATH = $LD_LIBRARY_PATH"
verbose_msg "CPPFLAGS = $CPPFLAGS"
verbose_msg # output a newline

#------------------------------------------------------------------------------
echo_and_run "pushd hyperion >/dev/null;"

echo_and_run   "./autogen.sh"

echo_and_run   "./configure '--enable-optimization=-g -g3 -ggdb3 -O3' \
    --enable-extpkgs=../extpkgs \
    --prefix=$install_prefix \
    --libdir=/usr/local/lib \
    '--enable-custom=Built using Hercules-Helper (version: $script_version)' \
    --enable-regina-rexx"

verbose_msg # output a newline
echo_and_run   "./config.status --config"
verbose_msg # output a newline
echo_and_run "popd"

#==============================================================================

# Step: make

verbose_msg # output a newline
status_prompter "Step: make:"

echo_and_run "pushd hyperion >/dev/null;"

echo_and_run   "make clean"
nprocs="$(nproc 2>/dev/null || echo 1)"
echo_and_run   "time make -j $nprocs 2>&1"

verbose_msg # output a newline
status_prompter "Step: make check:"

verbose_msg "Rexx: $(which rexx)"
verbose_msg # output a newline

echo_and_run   "make check"

echo_and_run "popd" # hyperion

#==============================================================================
# Step: make install
status_prompter "Step: make install:"

echo_and_run "pushd hyperion >/dev/null;"
    # sudo mkdir -p "/usr/local/$package_name"
    echo_and_run "sudo make install 2>&1"

    #------------------------------------------------------------------------------
    verbose_msg # output a newline
    echo_and_run "sudo setcap 'cap_sys_nice=eip' $install_prefix/bin/hercules"
    echo_and_run "sudo setcap 'cap_sys_nice=eip' $install_prefix/bin/herclin"
    echo_and_run "sudo setcap 'cap_net_admin+ep' $install_prefix/bin/hercifc"
echo_and_run "popd" # hyperion

#==============================================================================

verbose_msg # output a newline
status_prompter "Step: prime work directory, edit version info:"

this_dir="$(readlink -f .)"
verbose_msg "cd = $this_dir"
echo_and_run "pushd $SCRIPT_DIR >/dev/null;"
  echo           "Packager script version: $0: $(git describe --long --tags --dirty --always 2>/dev/null)"
    version_info="$0: $(git describe --long --tags --dirty --always)"
echo_and_run "popd"

#------------------------------------------------------------------------------

echo_and_run "pushd ./hyperion >/dev/null;"
  hercules_vers="$(./_dynamic_version . VERSION | awk '{sub("-modified","", $0); print}' | sed 's/"//g')"
echo_and_run "popd"

verbose_msg "Hercules version: $hercules_vers"
verbose_msg # output a newline

echo_and_run "sudo rm -rf ./$package_name"
echo_and_run "cp -R $dpkg_src $package_name/"
echo_and_run "sudo cp ./$package_name/DEBIAN/control ./$package_name/DEBIAN/control.orig"
# must 'sudo sh -c' to get the redirection to run as root
echo_and_run "sudo sh -c \"sed 's/Version:.*$/Version: $hercules_vers/' ./$package_name/DEBIAN/control.orig > ./$package_name/DEBIAN/control\""

#------------------------------------------------------------------------------
verbose_msg # output a newline
status_prompter "Step: copy everything locally; correct libs dir:"

echo_and_run "pushd $package_name >/dev/null;"
    echo_and_run   "sudo rm -rf usr"
    echo_and_run   "sudo mkdir -p ./usr/local"
    echo_and_run   "sudo cp -R /usr/local/$package_name/* ./usr/local/"
    #sudo mv ./usr/local/lib/hercules/* ./usr/local/lib

    echo_and_run   "sudo mkdir -p ./usr/local/lib"
    echo_and_run   "sudo cp /usr/local/lib/libh* ./usr/local/lib"
    echo_and_run   "sudo cp -R /usr/local/lib/hercules ./usr/local/lib/hercules"
    verbose_msg # output a newline
    echo_and_run   "ls -R --format=horizontal ./usr/local/lib"
    verbose_msg # output a newline
echo_and_run "popd"

echo_and_run "sudo chown root:root -R ./$package_name"

#==============================================================================
# Step: delete the temporary 'make install' dir

verbose_msg # output a newline
status_prompter "Step: delete temporary install directory:"

echo_and_run "sudo rm -rf /usr/local/$package_name"

#==============================================================================
# Step: create the Debian package

verbose_msg # output a newline
status_prompter "Step: create the Debian package:"

echo_and_run "dpkg -b ./$package_name"
echo_and_run "ls -lh $package_name.deb"

#==============================================================================
# Step: install the deb, and then prepare dpkg deb

verbose_msg # output a newline
status_prompter "Step: test install the newly created Debian package:"

echo_and_run "sudo dpkg --install $package_name.deb"
echo_and_run "dpkg -L $package_name"
verbose_msg # output a newline

# test
# /usr/local/bin/hercules -f ~/hercules.cnf

echo_and_run "dpkg-deb -f $package_name.deb"
verbose_msg # output a newline

echo_and_run "dpkg -s $package_name"
verbose_msg # output a newline

echo_and_run "dpkg -l $package_name"
verbose_msg # output a newline

# Desired=Unknown/Install/Remove/Purge/Hold
# | Status=Not/Inst/Conf-files/Unpacked/halF-conf/Half-inst/trig-aWait/Trig-pend
# |/ Err?=(none)/Reinst-required (Status,Err: uppercase=bad)
# ||/ Name           Version      Architecture Description
# +++-==============-============-============-============================================
# ii  hyperion       4.3x         amd64        SDL-Hercules-390, built with Hercules-Helper

#==============================================================================

verbose_msg # output a newline
verbose_msg "Done!"
verbose_msg "Your Debian package is: $build_path/$package_name.deb"
verbose_msg # output a newline
# verbose_msg "Next, optionally create the apt repo files"

echo_and_run "popd"

} # End of I/O redirection function

#------------------------------------------------------------------------------
#                               finish
#------------------------------------------------------------------------------
finish()
{
  echo "finish() called, exit status = $?"
}

#-----------------------------------------------------------------------------

logfile="$(basename "$0")"
logfile="${logfile%.*}-$current_time"

if [[ -e $logfile.log || -L $logfile.log ]] ; then
    i=1
    while [[ -e $logfile-$i.log || -L $logfile-$i.log ]] ; do
        let i++
    done
    logfile=$logfile-$i
fi

# Call all of the above as a function so we can grab and
# tee the output to the log file.

trap finish EXIT
the_works 2>&1 | tee "$logfile.log"

# ---- end of script ----

