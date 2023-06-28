#!/usr/bin/env bash

# This file is part of the Hercules-Helper project.
#
# (C) Copyright William R. Lewis, 2020-2023
#
# This software is released under the terms of the MIT License.
#
# https://github.com/wrljet/hercules-helper/blob/master/LICENSE

# Updated: 27 JUN 2023
VERSION_STR=v0.9.14+
#
# The most recent version of this project can be obtained with:
#   git clone https://github.com/wrljet/hercules-helper.git
# or:
#   wget https://github.com/wrljet/hercules-helper/archive/master.zip
#
# Please report errors in this project to me so everyone can benefit.
#
# Bill Lewis  bill@wrljet.com

#-----------------------------------------------------------------------------
#
# To run, create a build directory and cd to it, then run this script.
#
#  $ mkdir herctest && cd herctest
#  $
#  $ ~/hercules-helper/hercules-buildall.sh --auto
#     or
#  $ ~/hercules-helper/hercules-buildall.sh --verbose --prompts
#     or
#  $ ~/hercules-helper/hercules-buildall.sh --auto --flavor=aethra
#
#-----------------------------------------------------------------------------

#-----------------------------------------------------------------------------
#
# The major steps are (most can be optionally skipped):
#
# dostep_detect      Detect system and configuration
# dostep_packages    Check for required system packages
#                    Check for REXX and compiler settings (needed to run Hercules tests)
# dostep_regina_rexx Build Regina REXX
# dostep_gitclone    Git clone Hercules and external packages
# dostep_bldlvlck    Run bldlvlck
# dostep_extpkgs     Build Hercules external packages
# dostep_autogen     Run autogen
# dostep_configure   Run configure
# dostep_clean       Run make clean
# dostep_make        Run make (compile and link)
# dostep_tests       Run make check
# dostep_install     Run make install
# dostep_setcap      setcap executables
# dostep_envscript   Create script to set environment variables
# dostep_bashrc      Add "source" to set environment variables from .bashrc
#
#-----------------------------------------------------------------------------

# Changelog:
#
# Updated: 27 JUN 2023
# - run 'sudo ldconfig' after installation, if --sudo is in effect
#
# Updated: 14 JUN 2023
# - move search for existing binaries to helper-find-existing-binaries.sh
#   for performance reasons. This can be extremely slow on some systems.
# - loosen up the tests for existing env var scripts in the shell profile
#
# Updated: 12 JUN 2023
# - correct typo in default config git branch
#
# Updated: 11 JUN 2023
# - correct wording describing adding env vars to shell profile
# - correct year in dates in recent ChangeLog entries
# - add minor clarification to "Build tools versions:" message
#
# Updated: 10 JUN 2023
# - fix typos in config files
#
# Updated: 09 JUN 2023
# - add info about Zsh profile to the README
#
# Updated: 08 JUN 2023
# - support adding to Zsh profile
# - don't ask y/N for sudo if --sudo option is present
#
# Updated: 06 JUN 2023
# - added/update copyright and license info
# - make --auto the default
# - improve handling of 'sudo' detection
# - prompt to continue if 'sudo' will be required later
# - rearrange some of the major steps to put 'sudo' warning sooner
# - create 'extra-info...log' file to unclutter main output
#
# Updated: 31 MAY 2023
# - rename main script to hercules-buildall.sh
# - print deprecation msg from old hyperion-buildall.sh
#
# Updated: 30 MAY 2023
# - accommodate building from non-Hyperion named repos
# - add --flavor= switch, to select aethra.conf vs. sdl-hyperion.conf, etc.
#
# Updated: 11 MAY 2023
# - improve warning messages when not adding profile commands
#
# Updated: 08 MAY 2023
# - search for and list existing Hercules binaries
#
# Updated: 17 APR 2023
# - add detection for aarch64 linuxkit
# - add detection for Raspberry Pi 400 1.1 [c03131]
#
# Updated: 11 APR 2023
# - improve unfinished support for OpenBSD (tested with 7.3)
#   correct # of CPUs detection
#   skip 'setcap'
#   remove old output libs before building extpkgs
# - hide error output from 'which'
#
# Updated: 29 MAR 2023
# - detect aarch64 based rockchip64 / Linux g6sbc01
#
# Updated: 23 MAR 2023
# - detect and warn if sudo is missing
#
# Updated: 02 MAR 2023
# - add support for Chromebook (Penguin Debian Linux)
# - detect and warn about a new installation not being added to bashrc
#
# Updated: 28 JAN 2023
# - add --beeps option, to beep at each prompt
#
# Updated: 25 JAN 2023
# - use 'gmake' instead of BSD 'make' on NetBSD
#
# Updated: 23 JAN 2023
# - remove incorrectly escaped quotes from 'setcap' commands in build cmdfile
#
# Updated: 22 JAN 2023
# - initial support for Peppermint Devuan
#
# Updated: 28 DEC 2022
# - use sudo where requested to mkdir the installation directory
# - correct bug introduced in variable renaming, affecting non-Hurd
# - add support for 'opt_configure' config file option
#
# Updated: 27 DEC 2022
# - add --version option
# - rename various version related variables
#
# Updated: 26 DEC 2022
# - add initial support for Debian GNU Hurd
#
# Updated: 06 DEC 2022
# - add support for Gentoo (thanks to Gavin de la Rey)
#
# Updated: 01 DEC 2022
# - correct bitness checks on NetBSD for sparc64
#
# Updated: 28 NOV 2022
# - correct bitness checks on NetBSD for amd64
# - add helper-build-regina-netbsd.sh
#
# Updated: 16 NOV 2022
# - add support for RedHat RHEL 9
#
# Updated: 16 NOV 2022
# - add support for CentOS 9 Stream, AlmaLinux 9, and Rocky Linux 9
#   thanks to Matthew Wilson the fix, and Michael Richmond for finding it
#
# Updated: 27 SEP 2022
# - add support for OpenBSD (tested with 7.1)
#
# Updated: 13 SEP 2022
# - fix broken Debian 32-bit
#
# Updated: 09 SEP 2022
# - add support for Rocky Linux
#
# Updated: 25 AUG 2022
# - add support for Slackware
#
# Updated: 17 AUG 2022
# - correct bitness detection for POWER8 and later ppc64le CPUs
#   thanks Matthew for fixing this

# Updated: 24 JUL 2022
# - add support for macOS 13 Ventura
#
# Updated: 12 JUL 2022
# - add config option to override CMake extpkgs optimization settings
#
# Updated: 05 JUL 2022
# - add detection of new Raspberry Pi 4B rev 1.5 PCB
#
# Updated: 11 JUN 2022
# - add support for RISC-V CPU
#
# Updated: 09 MAR 2022
# - add support for macOS 10.12 Sierra
#
# Updated: 09 MAR 2022
# - add SLES to openSUSE detection (got lost somewhere along the way)
#
# Updated: 07 MAR 2022
# - bail out if CMake for extpkgs fails
#
# Updated: 16 FEB 2022
# - fix incomplete --config= option
#
# Updated: 12 FEB 2022
# - correct logic for Homebrew vs. MacPorts and x86 vs. M1
#
# Updated: 09 FEB 2022
# - disallow running as the root user (this check got lost 7 JAN 2021)
#
# Updated: 30 JAN 2022
# - rename macOS-prequisites.sh to prerequsites-macOS.sh
#
# Updated: 29 JAN 2022
# - add 'bitness' detection for use when building the external packages
# - replace Fish's 'extpkgs.sh' build scheme with direct use of cmake
#   this is to avoid changing the extpkgs to add E2K CPU
#
# Updated: 26 JAN 2022
# - beta support for Elbrus Linux, E2K CPU (also requires Hercules changes)
# - detect if compiler recognizes '-frecord-gcc-switches' before using it
# - limit 'make -j' to 4 maximum
# - correct Regina/ooRexx options written to build log
# - refer to 'ps' rather than '/bin/ps', as it's not there on some systems
# - display LD_LIBRARY_PATH environment variable for debugging
# - correct logic enabling/disabling Regina/ooRexx options for 'configure'
# - correct Regina detection so it's not fooled by ooRexx earlier in the path
#
# Updated: 19 JAN 2022
# - fix bug in display of SUDO_ASKPASS environment variable
# - additional work to get NetBSD working fully
#
# Updated: 14 JAN 2022
# - add new '--askpass' option to use a 'sudo -A' askpass helper
# - display SUDO_ASKPASS environment variable
# - add missing 'setcap' commands to the build log
# - replace 'read -p' with something that works over KVM ssh
#
# Updated: 05 JAN 2022
# - add package 'time' to Fedora.  Found missing using Vagrant.
# - add package 'time' to Alma Linux.  Found missing using Vagrant.
#
# Updated: 03 JAN 2022
# - fix bug related to '--no-rexx' erroring out on missing headers
# - help FreeBSD find headers and libraries (for Vagrant)
# - rearrange order of various infos displays
# - display info about ability to create crash dumps on MacOS
#
# Updated: 31 DEC 2021
# - not wanting REXX support in Hercules no longer means skipping 'make check'
# - if '--no-rexx' option is used, don't mention building Regina REXX
# - for MacOS, use 'sysctl hw.memsize' rather than 'hw.physmem' to get 64-bit value
# - display $GCC environment variable if present
#
# Updated: 21 DEC 2021
# - pretty up memory display presented before running 'make check'
#
# Updated: 20 DEC 2021
# - add memory detction for MacOS
#
# Updated: 19 DEC 2021
# - add support for Mageia v8
#
# Updated: 18 DEC 2021
# - move various utility functions to helper-fns.sh
# - change compiler optimization level to '-O3' by default
#
# Updated: 11 DEC 2021
# - change 'cmake' from an openSUSE pattern, to a package
# - correct detection of Raspberry Pi under openSUSE 42.2
#
# Updated: 06 DEC 2021
# - test the C compiler to see if '-march=native' works before using it
# - add '--force-pi' option, for Raspberry Pi OSes that hide the CPU ID
# - add 'time' package to requirements for openSUSE
# - add detection of Raspberry Pi with openSUSE 15
# - skip 'mainsize' test on low memory openSUSE (Pi 3B)
#
# Updated: 26 NOV 2021
# - add 'libbz2-devel' package for OpenSUSE
#
# Updated: 24 NOV 2021
# - add TRACEability to rebuild script
# - add detection for MacOS 12 Monterey
# - allow for skipping 'autogen' on MacOS
#
# Updated: 20 NOV 2021
# - correct 'configure' 'libdir' for Regina on RedHat/CentOS/etc
#
# Updated: 19 NOV 2021
# - respect --no-rexx to mean don't build any version of Rexx
#   and don't enable support in Hercules for any existing Rexx
# - fix bug related to script path
# - minor improvements to rebuild script generation
#
# Updated: 17 NOV 2021
# - add 'devpkg-zlib' to required packages for Intel Clear Linux
#
# Updated: 16 NOV 2021
# - add 'libtool' to required packages (Alma, Debian, Fedora, FreeBSD)
#
# Updated: 08 NOV 2021
# - add support for Intel Clear Linux
# - add '-g -g3 -ggdb3' compiler switches to core dumps contain symbolic info
#
# Updated: 06 NOV 2021
# - add detection for a bunch of newer Raspberry Pi PCB revisions
# - add support for new Raspberry Pi Zero 2 W
#
# Updated: 01 NOV 2021
# - don't exit if grep returns unexpected failure when 'cc1' found
# - use $CC instead of 'cc' when checking Clang for 'frecord_gcc_switches'
#
# Updated: 27 OCT 2021
# - check for failure of Regina 'sudo make install' and exit
# - fix bug allowing Raspberry Pi 3B+ FreeBSD to run 'mainsize' test
#   introduced when I moved the build process out of the source dir
#
# Updated: 16 OCT 2021
# - for Debian, replaced 'libtool' with 'libltdl-dev'
#
# Updated: 12 OCT 2021
# - use 1.5 times as many processes as CPUs during build
# - for FreeBSD 12.2, Clang doesn't seem to know about /usr/local
# - for FreeBSD, add 'libltdl' package
#
# Updated: 30 SEP 2021
# - corrections for 'realpath' which doesn't exist on MacOS or BSDs
# - add environment variables to the rebuild log
#
# Updated: 19 SEP 2021
# - add error detection to 'git clone' and 'git checkout' commands
# - better detect and skip tests for Rexx installations missing dev files
#
# Updated: 12 SEP 2021
# - fix bug writing config options to the build steps log
# - fix bug so opt_no_envscript=true and opt_no_bashrc=true config file
#   options work together correctly
#
# Updated: 01 SEP 2021
# - attempted corrections to CentOS 7 cc1 and cc1plus detection
# - fix bug preventing running from our own directory
# - add support for 'opt_configure_optimization' config file option
#
# Updated: 28 AUG 2021
# - try to detect a defective MacOS Xcode command line tools installation
# - add System76 Pop!_OS as a Debian alternative (thanks to Jay Maynard!)
# - when 'sudo' is needed for the install dir, use it for everything there
#   (thanks to Jay Maynard!)
#
# Updated: 27 AUG 2021
# - add required 'time' package for Manjaro
# - fix bug created by recent Raspberry Pi detection fix
#
# Updated: 20 AUG 2021
# - fix Raspberry Pi detection on non-rpios such as Ubuntu
# - display search path with system info
# - add 'libtool' to packages for MacOS
#
# Updated: 16 AUG 2021
# - corrections to reusable build script (for MacPorts)
#
# Updated: 15 AUG 2021
# - add Debian package installation to reusable build script
# - warn when Debian apt gets an error for a missing CD-ROM
#
# Updated: 12 AUG 2021
# - remove DEBUG mode when building extpkgs
#
# Updated: 11 AUG 2021
# - create reusable script of commands to rebuild
# - don't run util/bldlvlck on MacOS
#
# Updated: 10 AUG 2021
# - support MacPorts package manager on MacOS
# - use either '--homebrew' or '--macports' required to specify
#
# Updated: 03 AUG 2021
# - fix bug causing --autogen option to not work
#
# Updated: 01 AUG 2021
# - bug out earlier if the system is known to not be supported
# - add support for Zorin Linux
#
# Updated: 29 JUL 2021
# - corrections to Raspberry Pi detection
# - don't display a bunch of errors if /etc/os-release is missing
#
# Updated: 16 JUL 2021
# - add support for AlmaLinux 8.4
# - skip setcap operations on Raspberry Pi with single CPU core
#
# Updated: 15 JUL 2021
# - correct patch for Regina REXX 3.6 on Raspberry Pi 64-bit OS Beta
#
# Updated: 04 JUL 2021
# - add 'libtool' to required packages for openSUSE
# - skip setcap operations on Apple macOS
# - add error handling to various steps
#
# Updated: 01 JUL 2021
# - Fedora 34 support
#
# Updated: 23 JUN 2021
# - fix error introduced in Regina build by Raspberry Pi detection
# - install gsed on macOS
#
# Updated: 21 JUN 2021
# - add '-Wno-error=implicit-function-declaration' to Regina REXX build for Clang
#   rather than macOS Darwin
#
# Updated: 18 JUN 2021
# - patch Regina-REXX 3.6 source for building on Raspberry Pi Ubuntu
#
# Updated: 17 JUN 2021
# - remove sdl4x directory, as it is not necessary
# - compile Hercules in a build subdirectory, rather than in-source
#
# Updated: 15 JUN 2021
# - for Apple Mac M1:
#   always run 'autogen.sh' but skip 'autoreconf'
#   use '--without-included-ltdl' configure option
#   find include files and librarys with 'brew --cellar libtool'
#   skip 'setcap'
#   (currently only works with apple-m1 branch of wrljet hyperion fork)
# - don't run 'readelf' for Clang
#
# Updated: 14 JUN 2021
# - some initial work for the Apple Mac M1 CPU, detection
# - add '-Wno-error=implicit-function-declaration' to Regina REXX build for Clang
#
# Updated: 14 JUN 2021
# - before telling the user how to source the script to set environment vars
#   make sure we actually created it.
# - add '--no-packages' command, and fix related bugs in command parsing
#
# Updated: 14 JUN 2021
# - fix zypper install patterns vs. packages on openSUSE
# - add 'sudo ldconfig' after building Regina on openSUSE
#   (this might be required elsewhere as well)
#
# Updated: 12 JUN 2021
# - install 'libcap-progs' on openSUSE to use set capabilities
# - configure Regina with --libdir=/usr/lib on openSUSE
#
# Updated: 11 JUN 2021
# - remove prompts from '--auto' mode
# - add '--prompt' as a synonym for '--prompts' because it's an easy typo to make
#
# Updated: 10 JUN 2021
# - add Hercules-Helper version (git commit ID) to the Hercules custom build string
# - patch configure for Regina REXX 3.9.3 to add build support for 64-bit Pi
#
# Updated: 08 JUN 2021
# - look for both 'arm64' and 'aarch64' in uname -m detection
#
# Updated: 07 JUN 2021
# - install 'time' which is missing on some Debian based systems
# - install 'ncat' because it's useful for submitting JCL to test Hercules
#
# Updated: 06 JUN 2021
# - don't use gcc -O3
#
# Updated: 06 JUN 2021
# - configure Regina with --libdir=/usr/lib
#   (so far just on Debian derivatives)
# - bug in Regina 3.7+ that affects MVS-SYSGEN found, and may be worked
#   around with LINES(,'C')
#
# Updated: 04 JUN 2021
# - build Regina using the default PREFIX
# - don't bother adding our Regina to path, etc.  Use system defaults
#
# Updated: 04 JUN 2021
# - make Regina download configurable
# - switch default Regina from 3.9.3 to 3.6 due to bug affecting MVS-SYSGEN
#
# Updated: 28 MAY 2021
# - default to skipping autoreconf/autogen
# - add --autogen switch
#
# Updated: 27 MAY 2021
# - CFLAGS=-frecord-gcc-switches broke macOS
#
# Updated: 26 MAY 2021
# - add configure option: CFLAGS=-frecord-gcc-switches
#   for: 'readelf -p .GCC.command.line herc4x/bin/hercules'
#
# Updated: 26 MAY 2021
# - clean up display around 'autoreconf'
#
# Updated: 26 MAY 2021
# - add feature to 'git checkout' a specific revision
#
# Updated: 15 MAY 2021
# - corrected macOS version detection to now recognize 10.15 (Catalina)
#
# Updated: 12 MAY 2021
# - call 'autoreconf --force --install' to get latest libtool, etc.
#
# Updated: 11 MAY 2021
# - add package libtool-ltdl-devel for CentOS and newer autoconf/libtool
#
# Updated: 09 MAY 2021
# - corrected comment-only if/else clause
#
# Updated: 06 MAY 2021
# - corrected macOS version detection to now recognize 10.13 (High Sierra),
#   10.14 (Mojave), and 11 (Big Sur)
#
# Updated: 02 MAY 2021
# - add initial support for macOS Mojave 10.14 (Darwin)
# - various changes to work with Bash 3.2
# - replace 'printf %()T' with 'date +%s'
# - remove /etc/profile.d/hyperion.sh stuff entirely
# - requires 'libtool' package until updates have been applied to Hyperion
#
# Updated: 12 APR 2021
# - add --detect-only option
#
# Updated: 08 APR 2021
# - a few corrections related to 'set -u'
# - correct memory size check for FreeBSD 'mainsize' from MB to KB
# - now also works on FreeBSD 12.2 on x86-64
# - fix bug in --sudo option
# - additional system info display
#
# Updated: 07 APR 2021
# - FreeBSD 12 on Raspberry Pi 3B improvements
# - skip 'mainsize' test on low memory FreeBSD
#
# Updated: 06 APR 2021
# - major changes to the options.  Be sure to check --help
# - most of the sub steps can now be individually skipped
# - lowercase all internal variable names
# - added FreeBSD 12 on Raspberry Pi 3B support (incomplete)
#
# Updated: 18 FEB 2021
# - correct WSL1 detection so it doesn't show both WSL1 and WSL2 together
# - capture Debian dpkg stderr output so it doesn't show up to the user
#
# Updated: 31 JAN 2021
# - add --noclone option to use existing source directories
# - add detection and support for Alpine Linux (under construction)
#
# Updated: 25 JAN 2021
# - for Manjaro: add "--needed" option to pacman command
#
# Updated: 24 JAN 2021
# - add wget as a required package for Debian and Manjaro
# - add instructions to make the new build immediately available
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

fns_dir="$(dirname "$0")"
fns_file="$fns_dir/helper-fns.sh"

if test -f "$fns_file" ; then
    source "$fns_file"
else
    echo "Helper functions script file not found!"
    exit 1
fi

#------------------------------------------------------------------------------
#
# Default Configuration Parameters:
#

# Show/trace every Bash command
TRACE=${TRACE:-false}  # If TRACE variable not set or null, default to FALSE

# Overall working build diretory is the current directory
opt_build_dir=${opt_build_dir:-$(pwd)}

# Prefix (target) directory
opt_install_dir=${opt_install_dir:-$(pwd)/herc4x}

# Git repo for Hercules
git_repo_hercules=${git_repo_hercules:-https://github.com/SDL-Hercules-390/hyperion.git}
# git_repo_hercules=https://github.com/wrljet/hyperion.git

# Git checkout branch for Hercules
git_branch_hercules=${git_branch_hercules:-""}
# git_branch_hercules="build-netbsd"

# Git checkout commit for Hercules
git_commit_hercules=${git_commit_hercules:-""}
# git_commit_hercules=cb24398

# Git repo for Hercules External Packages
git_repo_extpkgs=${git_repo_extpkgs:-https://github.com/SDL-Hercules-390}
# git_repo_extpkgs=https://github.com/wrljet

# Git checkout branch for Hercules External Packages
git_branch_extpkgs=${git_extpkgs_extpkgs:-""}
# git_branch_extpkgs="build-mods-i686"

# Regina download
opt_regina_dir=${opt_regina_dir:-"Regina-REXX-3.6"}
opt_regina_tarfile=${opt_regina_tarfile:-"Regina-REXX-3.6.tar.gz"}
opt_regina_url=${opt_regina_url:-"http://www.wrljet.com/ibm360/Regina-REXX-3.6.tar.gz"}

opt_configure=${opt_configure:-""}
opt_configure_optimization=${opt_configure_optimization:-""}
opt_cmake_defines=${opt_cmake_defines:-""}

# Print verbose progress information
opt_verbose=${opt_verbose:-false}

# Prompt the user before each major step is started
opt_prompts=${opt_prompts:-false}

# Beep to alert the user that a prompt is waiting
opt_beeps=${opt_beeps:-false}

# Run detection only and exit
opt_detect_only=${opt_detect_only:-false}

# Use 'sudo' for 'make install'
opt_usesudo=${opt_usesudo:-false}

# Use 'sudo -A' askpass helper
opt_askpass=${opt_askpass:-false}

# Sub-functions, in order of operation
#
# --no-packages  skip installing required packages
# Do not install missing packages if true
opt_no_packages=${opt_no_packages:-false}

# --no-rexx      skip building Regina REXX
# Do not build Regina REXX
opt_no_rexx=${opt_no_rexx:-false}

# --no-gitclone  skip \'git clone\' steps
# Do not 'git clone' if true
opt_no_gitclone=${opt_no_gitclone:-false}

# --no-bldlvlck  skip \'util/bldlvlck\' steps
opt_no_bldlvlck=${opt_no_bldlvlck:-false}

# --no-extpkgs   skip building Hercules external packages
opt_no_extpkgs=${opt_no_extpkgs:-false}

# --no-autogen   skip running \'autogen\'
opt_no_autogen=${opt_no_autogen:-true}

# --no-configure skip running \'configure\'
opt_no_configure=${opt_no_configure:-false}

# --no-clean     skip running \'make clean\'
opt_no_clean=${opt_no_clean:-false}

# --no-make      skip running \'make\'
opt_no_make=${opt_no_make:-false}

# --no-tests     skip running \'make check\'
opt_no_tests=${opt_no_tests:-false}

# --no-install   skip \'make install\' after building
# Skip 'make install' after building
opt_no_install=${opt_no_install:-false}

# --no-setcap    skip running \'setcap\'
opt_no_setcap=${opt_no_setcap:-false}

# --no-envscript skip creating script to set environment variables
opt_no_envscript=${opt_no_envscript:-false}

# --no-bashrc    skip modifying .bashrc to set environment variables
opt_no_bashrc=${opt_no_bashrc:-false}

# --force-pi     force use of Raspberry Pi code (for systems that may conceal the CPU type)
opt_force_pi=${opt_force_pi:-false}

# Optional steps we perform
#
dostep_packages=${dostep_packages:-true}       # Check for required system packages
dostep_regina_rexx=${dostep_regina_rexx:-true} # Build Regina REXX
dostep_gitclone=${dostep_gitclone:-true}       # Git clone Hercules and external packages
dostep_bldlvlck=${dostep_bldlvlck:-true}       # Run bldlvlck
dostep_extpkgs=${dostep_extpkgs:-true}         # Build Hercules external packages
dostep_autogen=${dostep_autogen:-false}        # Run autoreconf / autogen
dostep_configure=${dostep_configure:-true}     # Run configure
dostep_clean=${dostep_clean:-true}             # Run make clean
dostep_make=${dostep_make:-true}               # Run make (compile and link)
dostep_tests=${dostep_tests:-true}             # Run make check
dostep_install=${dostep_install:-true}         # Run make install
dostep_setcap=${dostep_setcap:-true}           # setcap executables
dostep_envscript=${dostep_envscript:-true}     # Create script to set environment variables
dostep_bashrc=${dostep_bashrc:-true}           # Add "source" to set environment variables from .bashrc

#-----------------------------------------------------------------------------
# Set up default empty values for our variables

debug=${debug:-""}
DEBUG=${DEBUG:-""}

version_distro=""
os_version_id=""
os_version_rpidesktop=0
os_version_wsl=0
os_version_freebsd_cpu=""
os_version_freebsd_model=""
os_version_memory_size=""
os_version_multicore_with_low_memory=false
version_regina=0

uname_system="$( (uname -s) 2>/dev/null)" || uname_system="unknown"

CC=${CC:-"cc"}
CFLAGS=${CFLAGS:-""}
CPPFLAGS=${CPPFLAGS:-""}
LD=${LD:-"ld"}
LDFLAGS=${LDFLAGS:-""}

#-----------------------------------------------------------------------------

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

#-----------------------------------------------------------------------------

uname_system="$( (uname -s) 2>/dev/null)" || uname_system="unknown"

# Check for Apple macOS and prerequisites

darwin_have_homebrew=false
darwin_have_macports=false

if [ "$uname_system" == "Darwin" ]; then
    darwin_need_prereqs=false

  # echo "Checking for Xcode command line tools ..."
    xcode-select -p 1>/dev/null 2>/dev/null
    if [[ $? == 2 ]] ; then
        darwin_need_prereqs=true
    else
  #     echo "    Command line tools are already installed"
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

    if ( $darwin_need_prereqs == true ) ; then
        echo   # output a newline
        echo "Please run prerequisites-macOS.sh first"
        echo   # output a newline
        exit 1
    fi

    echo   # output a newline
fi

#-----------------------------------------------------------------------------

# 'realpath' doesn't exist on MacOS or BSDs
# SCRIPT_PATH=$(dirname $(realpath -s $0))

# FIXME: this doesn't work if this script is running off a symlink
SCRIPT_PATH=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR="$(dirname $SCRIPT_PATH)"

pushd "$(dirname "$0")" >/dev/null;
    which_git=$(which git 2>/dev/null) || true
    which_status=$?

    if [ -z $which_git ]; then
        # verbose_msg "git is not installed"
        version_info="$VERSION_STR"
    elif [ ! -d "$SCRIPT_DIR/.git" ]; then
        # verbose_msg "not a git repo"
        version_info="$VERSION_STR"
    else
        version_info="$(git describe --long --tags --dirty --always 2>/dev/null)"
    fi
popd > /dev/null;

usage="Hercules-Helper $version_info
Usage: $(basename "$0") [OPTIONS]

Perform a full build, test, and installation of Hercules from git sources

Options:
  -h,  --help         print this help
  -t,  --trace        print every command (set -x)
  -v,  --verbose      print lots of messages
       --version      prints version info and exits
  -p,  --prompts      print a prompt before each major step
       --beeps        beep at each prompt
       --flavor=      specify major flavor: aethra, sdl-hyperion, etc.
       --config=FILE  specify config file containing options
  -s,  --sudo         use \'sudo\' for installing
       --askpass      use \'sudo -A\' askpass helper
  -a,  --auto         run everything, with --verbose (but not --prompts),
                      and create a full log file (this is the default)
       --homebrew     assume Homebrew package manager on MacOS
       --macports     assume MacPorts package manager on MacOS
       --force-pi     process for a Raspberry Pi

Sub-functions (in order of operation):
       --detect-only  run detection only and exit
       --no-packages  skip installing required packages
       --no-rexx      skip building Regina REXX, no REXX support in Hercules
       --no-gitclone  skip \'git clone\' steps
       --no-bldlvlck  skip \'util/bldlvlck\' steps
       --no-extpkgs   skip building Hercules external packages
       --autogen      run \'autoreconf\' and \'autogen\'
       --no-autogen   skip running \'autogen\'
       --no-configure skip running \'configure\'
       --no-clean     skip running \'make clean\'
       --no-make      skip running \'make\'
       --no-tests     skip running \'make check\'
       --no-install   skip \'make install\' after building
       --no-setcap    skip running \'setcap\'
       --no-envscript skip creating script to set environment variables
       --no-bashrc    skip modifying .bashrc to set environment variables

Please email bug reports, questions, etc. to: <bill@wrljet.com>
"

#------------------------------------------------------------------------------
#                               finish
#------------------------------------------------------------------------------
finish()
{
  echo "finish() called, exit status = $?"
}

#------------------------------------------------------------------------------
#                               set_run_or_skip
#------------------------------------------------------------------------------
run_or_skip="no"

set_run_or_skip()
{
    if ($1 == true); then
        run_or_skip="run "
    else
        run_or_skip="skip"
    fi
}

#------------------------------------------------------------------------------
#                               add_build_entry
#------------------------------------------------------------------------------
add_build_entry()
{
    echo "$@" >>"$cmdsfile"
}

#------------------------------------------------------------------------------
#                               log_extra_info
#------------------------------------------------------------------------------
log_extra_info()
{
    echo "$@" >>"$extra_file"
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
        os_is_supported=true

        RPI_REVCODE=$(awk '/Revision/ {print $3}' /proc/cpuinfo)
        verbose_msg "Raspberry Pi rev : $RPI_REVCODE"

        RPI_CPUS=$(awk '/^processor/{n+=1}END{print n}' /proc/cpuinfo)
        verbose_msg "CPU count        : $RPI_CPUS"
    else
        verbose_msg "nope"
    fi
}

function check_pi_version()
{
    # Source:
    # https://www.raspberrypi.org/documentation/hardware/raspberrypi/revision-codes/README.md

  local -rA RPI_REVISIONS=(
    [900021]="A+        1.1     512MB   Sony UK"
    [900032]="B+        1.2     512MB   Sony UK"
    [900092]="Zero      1.2     512MB   Sony UK"
    [900093]="Zero      1.3     512MB   Sony UK"
    [9000c1]="Zero W    1.1     512MB   Sony UK"
    [9020e0]="3A+       1.0     512MB   Sony UK"
    [902120]="Zero 2 W  1.0     512MB   Sony UK"
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
    [b03114]="4B        1.4     2GB     Sony UK"
    [b03115]="4B        1.5     2GB     Sony UK"
    [c03111]="4B        1.1     4GB     Sony UK"
    [c03112]="4B        1.2     4GB     Sony UK"
    [c03114]="4B        1.4     4GB     Sony UK"
    [c03115]="4B        1.5     4GB     Sony UK"
    [d03114]="4B        1.4     8GB     Sony UK"
    [d03115]="4B        1.5     8GB     Sony UK"
    [c03130]="Pi 400    1.0     4GB     Sony UK"
    [c03131]="Pi 400    1.1     4GB     Sony UK"
    [a03140]="CM4       1.0     1GB     Sony UK"
    [b03140]="CM4       1.0     2GB     Sony UK"
    [c03140]="CM4       1.0     4GB     Sony UK"
    [d03140]="CM4       1.0     8GB     Sony UK"
  )

    verbose_msg "Raspberry Pi     : ${RPI_REVISIONS[$RPI_REVCODE]} ($RPI_REVCODE)"
}

function detect_pi()
{
    verbose_msg " "  # output a newline

# Raspberry Pi 4B,   Ubuntu 20 64-bit,  uname -m == aarch64
# Raspberry Pi 4B,   RPiOS     32-bit,  uname -m == armv7l
# Raspberry Pi Zero, RPiOS     32-bit,  uname -m == armv6l

    grep -iqe  "Raspberry Pi" /proc/cpuinfo 2>&1
    status=$?
    if [ $status -eq 0 ]; then
        # Raspberry Pi CPU
        verbose_msg "Running on Raspberry Pi hardware"

        get_pi_version
        check_pi_version

        # Try to detect a Raspberry Pi Zero 2 W.
        # This has the same multi-core CPU as a Pi 3B, but with only 512MB RAM.
        # Running parallel 'make' jobs on this will cause the Linux
        # Out-Of-Memory killer to kick in.

        if [[ $RPI_CPUS -gt 1 && $os_version_memory_size -lt 1000 ]]; then
            verbose_msg "                 : Multi-core Raspberry Pi with low memory"
            os_version_multicore_with_low_memory=true
        fi
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

# 31 JAN 2021
#
# /etc/os-release
# NAME="Alpine Linux"
# ID=alpine
# VERSION_ID=3.13.1
# PRETTY_NAME="Alpine Linux v3.13"
# HOME_URL="https://alpinelinux.org/"
# BUG_REPORT_URL="https://bugs.alpinelinux.org/"
#
# /etc/alpine-release
# 3.13.1

# $ cat /boot/issue.txt | head -1
#  Raspberry Pi reference 2020-05-27

# 19 JAN 2021
#
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

# /etc/os-release
#
# NAME="Peppermint"
# VERSION_CODENAME="chimaera"
# PRETTY_NAME="PeppermintOS Devuan"
# ID=peppermint

# /etc/os-release
#
# NAME=Fedora
# VERSION="34 (Workstation Edition)"
# ID=fedora
# VERSION_ID=34
# PRETTY_NAME="Fedora 34 (Workstation Edition)"

# /etc/os-release
#
# NAME="Red Hat Enterprise Linux"
# VERSION="9.1 (Plow)"
# ID="rhel"
# ID_LIKE="fedora"
# VERSION_ID="9.1"
# PLATFORM_ID="platform:el9"
# PRETTY_NAME="Red Hat Enterprise Linux 9.1 (Plow)"

    verbose_msg "System detection:"

    RPI_MODEL=""
    os_is_supported=false

    os_name=$(uname -s)
    verbose_msg "OS Type          : $os_name"

    machine=$(uname -m)
    verbose_msg "Machine Arch     : $machine"

    if [ "$os_name" = "Linux" ]; then
        os_version_id="??? unknown ???"
        os_version_id_like="??? unknown ???"
        os_version_pretty_name="??? unknown ???"
        os_version_str="??? unknown ???"

        if [ -f /etc/os-release ]; then
            # awk -F= '$1=="ID" { gsub(/"/, "", $2); print $2 ;}' /etc/os-release
            os_version_id=$(awk -F= '$1=="ID" { gsub(/"/, "", $2); print $2 ;}' /etc/os-release)
            # echo "VERSION_ID is $os_version_id"

            os_version_id_like=$(awk -F= '$1=="ID_LIKE" { gsub(/"/, "", $2); print $2 ;}' /etc/os-release)
            # echo "VERSION_ID_LIKE is $os_version_id_like"

            os_version_pretty_name=$(awk -F= '$1=="PRETTY_NAME" { gsub(/"/, "", $2); print $2 ;}' /etc/os-release)
            # echo "VERSION_STR is $os_os_version_str"

            os_version_str=$(awk -F= '$1=="VERSION_ID" { gsub(/"/, "", $2); print $2 ;}' /etc/os-release)
            # echo "VERSION_STR is $os_version_str"
        fi

        os_version_memory_size="$(free -m | awk '/^Mem:/{print $2}')"
        verbose_msg "Memory Total (MB): $os_version_memory_size"
        verbose_msg "Memory Free  (MB): $(free -m | awk '/^Mem:/{print $4}')"

        verbose_msg "VERSION_ID       : $os_version_id"
        verbose_msg "VERSION_ID_LIKE  : $os_version_id_like"
        verbose_msg "VERSION_PRETTY   : $os_version_pretty_name"
        verbose_msg "VERSION_STR      : $os_version_str"

        # Look for Slackware Linux

        if [[ $os_version_id == slackware* ]];
        then
            version_distro="slackware"
            version_major=$(echo $os_version_str | cut -f1 -d.)
            version_minor=$(echo $os_version_str | cut -f2 -d.)

            verbose_msg "OS               : $version_distro variant"
            verbose_msg "OS Version       : $version_major"

            os_is_supported=true
        fi

        # Look for Gentoo Linux

        if [[ $os_version_id == gentoo* ]];
        then
            version_distro="gentoo"
            version_major=$(echo $os_version_str | cut -f1 -d.)
            version_minor=$(echo $os_version_str | cut -f2 -d.)

            verbose_msg "OS               : $version_distro variant"
            verbose_msg "OS Version       : $version_major"

            os_is_supported=true
        fi

        # Look for Alpine Linux

        if [[ $os_version_id == alpine* ]];
        then
            version_distro="alpine"
            version_major=$(echo $os_version_str | cut -f1 -d.)
            version_minor=$(echo $os_version_str | cut -f2 -d.)

            verbose_msg "OS               : $version_distro variant"
            verbose_msg "OS Version       : $version_major"

            os_is_supported=false
            error_msg "Alpine Linux is not yet supported!"
        fi

        # Look for Manjaro

        if [[ $os_version_id == arch* || $os_version_id == manjaro* ]];
        then
            version_distro="arch"
            os_version_str=$(awk -F= '$1=="DISTRIB_RELEASE" { gsub(/"/, "", $2); print $2 ;}' /etc/lsb-release)
            version_major=$(echo $os_version_str | cut -f1 -d.)
            version_minor=$(echo $os_version_str | cut -f2 -d.)

            verbose_msg "OS               : $version_distro variant"
            verbose_msg "OS Version       : $version_major"
            os_is_supported=true
        fi

        # Look for Debian/Ubuntu/Mint

        if [[ $os_version_id == debian*    || $os_version_id == ubuntu*     || \
              $os_version_id == linuxmint* || $os_version_id == peppermint* || \
              $os_version_id == raspbian*  || $os_version_id == neon*       || \
              $os_version_id == pop*       || $os_version_id == zorin* ]];
        then
            version_distro="debian"
            version_major=$(echo $os_version_str | cut -f1 -d.)
            version_minor=$(echo $os_version_str | cut -f2 -d.)

            verbose_msg "OS               : $version_distro variant"
            verbose_msg "OS Version       : $version_major"
            os_is_supported=true
        fi

        if [[ $os_version_id == raspbian* ]]; then
            echo "$(cat /boot/issue.txt | head -1)"
        fi

        # Look for Rocky Linux
        if [[ $os_version_id == rocky* ]]; then
            verbose_msg "We have an Rocky Linux system"

            # Rocky Linux 8.6
            # $ rpm --query centos-release
            # package centos-release is not installed
            # $ cat /etc/redhat-release 
            # Rocky Linux release 8.6 (Green Obsidian)

          # rockylinux_vers=$(rpm --query centos-release) || true
            rockylinux_vers=$(cat /etc/redhat-release) || true
            rockylinux_vers="${rockylinux_vers#*release }"
            rockylinux_vers="${rockylinux_vers/ */}"

            version_distro="rockylinux"
            version_major=$(echo $rockylinux_vers | cut -f1 -d.)
            version_minor=$(echo "$rockylinux_vers.0" | cut -f2 -d.)

            verbose_msg "VERSION_MAJOR    : $version_major"
            verbose_msg "VERSION_MINOR    : $version_minor"
            os_is_supported=true
        fi

        # Look for AlmaLinux
        if [[ $os_version_id == almalinux* ]]; then
            verbose_msg "We have an AlmaLinux system"

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

            verbose_msg "VERSION_MAJOR    : $version_major"
            verbose_msg "VERSION_MINOR    : $version_minor"
            os_is_supported=true
        fi

        # Look for CentOS
        if [[ $os_version_id == centos* ]]; then
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

          # centos_vers=$(rpm --query centos-release) || true
            centos_vers=$(cat /etc/redhat-release) || true
            centos_vers="${centos_vers#*release }"
            centos_vers="${centos_vers/-/.}"

            version_distro="redhat"
            version_major=$(echo $centos_vers | cut -f1 -d.)
            version_minor=$(echo "$centos_vers.0" | cut -f2 -d.)

            verbose_msg "VERSION_MAJOR    : $version_major"
            verbose_msg "VERSION_MINOR    : $version_minor"

            if [[ $version_major -ge 7 ]]; then
              os_is_supported=true
            fi
        fi

        # Look for RedHat
# NAME="Red Hat Enterprise Linux"
# VERSION="9.1 (Plow)"
# ID="rhel"
# ID_LIKE="fedora"
# VERSION_ID="9.1"
# PLATFORM_ID="platform:el9"
# PRETTY_NAME="Red Hat Enterprise Linux 9.1 (Plow)"

        if [[ $os_version_id == rhel* ]]; then
            verbose_msg "We have a RedHat RHEL system"

            # cat /etc/redhat-release
            # Red Hat Enterprise Linux release 9.1 (Plow)
            redhat_vers=$(cat /etc/redhat-release) || true

            redhat_vers="${redhat_vers#*release }"
            redhat_vers="${redhat_vers/-/.}"

            version_distro="redhat"
            version_major=$(echo $redhat_vers | cut -f1 -d'.')
            verbose_msg "VERSION_MAJOR    : $version_major"

            if [[ $version_major -ge 9 ]]; then
              os_is_supported=true
            fi
        fi

        # Look for Fedora
# NAME=Fedora
# VERSION="34 (Workstation Edition)"
# ID=fedora
# VERSION_ID=34
# PRETTY_NAME="Fedora 34 (Workstation Edition)"

        if [[ $os_version_id == fedora* ]]; then
            verbose_msg "We have a Fedora system"

            # cat /etc/redhat-release
            # Fedora release 34 (Thirty Four)
            fedora_vers=$(cat /etc/redhat-release) || true

            fedora_vers="${fedora_vers#*release }"
            fedora_vers="${fedora_vers/-/.}"

            version_distro="redhat"
            version_major=$(echo $fedora_vers | cut -f1 -d' ')
            verbose_msg "VERSION_MAJOR    : $version_major"

            if [[ $version_major -ge 34 ]]; then
              os_is_supported=true
            fi
        fi

        # Look for Mageia
# VERSION_ID       : mageia
# VERSION_ID_LIKE  : mandriva fedora
# VERSION_PRETTY   : Mageia 8
# VERSION_STR      : 8

        if [[ $os_version_id == mageia* ]]; then
            verbose_msg "We have a Mageia system"

            version_distro="redhat"
            version_major=$(echo $os_version_str | cut -f1 -d' ')
            verbose_msg "VERSION_MAJOR    : $version_major"

            if [[ $version_major -ge 8 ]]; then
              os_is_supported=true
            fi
        fi
#######################################################

        # Look for Intel Clear Linux
# NAME="Clear Linux OS"
# VERSION=1
# ID=clear-linux-os
# ID_LIKE=clear-linux-os
# VERSION_ID=35130
# PRETTY_NAME="Clear Linux OS"
# ANSI_COLOR="1;35"
# HOME_URL="https://clearlinux.org"
# SUPPORT_URL="https://clearlinux.org"
# BUG_REPORT_URL="mailto:dev@lists.clearlinux.org"
# PRIVACY_POLICY_URL="http://www.intel.com/privacy"
# BUILD_ID=35130

        if [[ $os_version_id == clear-linux-os* ]]; then
            verbose_msg "We have a Intel Clear Linux system"

            version_distro="clear-linux"
            version_major=$(echo $os_version_str | cut -f1 -d.)
            version_minor=$(echo $os_version_str | cut -f2 -d.)

            verbose_msg "OS               : $version_distro variant"
            verbose_msg "OS Version       : $version_major"
            os_is_supported=true
        fi
#######################################################

#  uname -a        : Linux yukari 5.4.0-3.13-e8c #1 SMP Sun Nov 21 22:58:49 GMT 2021 e2k E8C E8C-SWTX GNU/Linux
#  uname -m        : e2k
#  uname -p        : E8C
#  uname -s        : Linux
#
# OS Type          : Linux
# Machine Arch     : e2k
# Memory Total (MB): 128704
# Memory Free  (MB): 14653
# VERSION_ID       : elbrus
# VERSION_ID_LIKE  : 
# VERSION_PRETTY   : Elbrus Linux 6.0.1
# VERSION_STR      : 6
# Language         : LANG=ru_RU.UTF-8

        if [[ $os_version_id == elbrus* ]]; then
            verbose_msg "We have an Elbrus Linux system"

            version_distro="elbrus"
            version_major=$(echo $os_version_str | cut -f1 -d.)
            version_minor=$(echo $os_version_str | cut -f2 -d.)

            verbose_msg "OS               : $version_distro variant"
            verbose_msg "OS Version       : $version_major"

            if [[ $version_major -ge 6 ]]; then
                os_is_supported=true
            fi
        fi
#######################################################

        # Look for openSUSE
        if [[ $os_version_id == opensuse* || \
              $os_version_id == sles*     ]];
        then
            version_distro="openSUSE"
            version_major=$(echo $os_version_str | cut -f1 -d.)
            version_minor=$(echo $os_version_str | cut -f2 -d.)

            verbose_msg "OS               : $version_distro variant"
            verbose_msg "OS Version       : $version_major"
            os_is_supported=true

            version_opensuse_model="$(dmesg | grep -i "Machine model" | cut -f2 -d: | awk '{$1=$1};1')"

            if [[ "$version_opensuse_model" =~ "Raspberry Pi" ]]; then
                verbose_msg "System           : $version_opensuse_model"
                opt_force_pi=true
            fi

            if (dmesg | grep -i "raspberrypi-firmware" >/dev/null); then
                verbose_msg "System           : Raspberry Pi"
                opt_force_pi=true
            fi

            if [[ $opt_force_pi && $os_version_memory_size -lt 2000 ]]; then
                verbose_msg "                 : openSUSE Raspberry Pi with low memory"
                os_version_multicore_with_low_memory=true
            fi
        fi

        # show the default language
        # i.e. LANG=en_US.UTF-8
        verbose_msg "Language         : $(env | grep LANG)"

        # Check if running under Windows WSL
        verbose_msg " "  # output a newline
        os_version_wsl=0

        verbose_msg -n "Checking for Windows WSL2... "
        if [ $(uname -r | sed -n 's/.*\( *Microsoft *\).*/\1/ip') ]; then
            verbose_msg "running on WSL2"
            os_version_wsl=2
        else
            verbose_msg "nope"

            verbose_msg -n "Checking for Windows WSL1... "
            if [[ "$(< /proc/version)" == *@(Microsoft|WSL)* ]]; then
                verbose_msg "running on WSL1"
                os_version_wsl=1
            else
                verbose_msg "nope"
            fi
        fi

        # Check if running under Raspberry Pi Desktop (for PC)
        #
        # Raspberry Pi, native and x86_64 Desktop
        # $ cat /etc/rpi-issue
        # Raspberry Pi reference 2020-02-12
        # Generated using pi-gen, https://github.com/RPi-Distro/pi-gen, f3b8a04dc10054b328a56fa7570afe6c6d1b856e, stage5

        os_version_rpidesktop=0
        RPI_CPUS=0

        if [ -f /etc/rpi-issue ]; then
            if [[ "$(< /etc/rpi-issue)" == *@(Raspberry Pi reference)* &&
                  "$machine" == "x86_64" ]];
            then
                verbose_msg "Running on Raspberry Pi Desktop (for PC)"
                os_version_rpidesktop=1
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

        version_distro="netbsd"
        os_version_id="netbsd"
        os_version_pretty_name="netbsd"

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
        #verbose_msg "Memory Free  (MB): $(cat /proc/meminfo | awk '/^Mem:/{mb = $4/1024/1024; printf "%.0f", mb}')"

        os_version_memory_size="$(cat /proc/meminfo | awk '/^Mem:/{mb = $2/1024/1024; printf "%.0f", mb}')"
        verbose_msg "Memory Total (MB): $os_version_memory_size"

        # 9.0_STABLE
        os_version_str=$(uname -r)

        verbose_msg "VERSION_ID       : $os_version_id"
        verbose_msg "VERSION_STR      : $os_version_str"

        version_substr=$(echo $os_version_str | cut -f1 -d_)
        verbose_msg "VERSION_SUBSTR   : $version_substr"
        version_major=$(echo $version_substr | cut -f1 -d.)
        verbose_msg "VERSION_MAJOR    : $version_major"
        version_minor=$(echo $version_substr | cut -f2 -d.)
        verbose_msg "VERSION_MINOR    : $version_minor"

        # show the default language
        # i.e. LANG=en_US.UTF-8
        verbose_msg "Language         : <unknown>"

        if [[ $version_major -ge 9 ]]; then
          os_is_supported=true
        fi

#------------------------------------------------------------------------------
    elif [ "$os_name" = "OpenBSD" ]; then
        verbose_msg "OpenBSD is not yet supported!"

        version_distro="openbsd"
        os_version_id="openbsd"

        HH_SUDOCMD="doas"
        add_build_entry "HH_SUDOCMD=\"doas\""

        os_version_memory_size="$(($(sysctl -n hw.physmem) / 1024 / 1024))"
        verbose_msg "Memory Total (MB): $(($(sysctl -n hw.physmem) / 1024 / 1024))"

        # sysctl hw.model
        # hw.model: ARM Cortex-A53 r0p4
        os_version_freebsd_model="$(sysctl hw.model | cut -f2 -d: | awk '{$1=$1};1')"
        verbose_msg "CPU Model        : $(sysctl hw.model | cut -f2 -d: | awk '{$1=$1};1')"

        # 12.2-RELEASE
        os_version_str=$(uname -r)

        verbose_msg "VERSION_ID       : $os_version_id"
        verbose_msg "VERSION_STR      : $os_version_str"

        version_substr=$(echo $os_version_str | cut -f1 -d-)
        # verbose_msg "VERSION_SUBSTR   : $version_substr"
        version_major=$(echo $version_substr | cut -f1 -d.)
        # verbose_msg "VERSION_MAJOR    : $version_major"
        version_minor=$(echo $version_substr | cut -f2 -d.)
        # verbose_msg "VERSION_MINOR    : $version_minor"

        # show the default language
        # i.e. LANG=en_US.UTF-8
        verbose_msg "Language         : <unknown>"

        if [[ $version_major -ge 7 ]]; then
          os_is_supported=true
        fi

#------------------------------------------------------------------------------
    elif [ "$os_name" = "FreeBSD" ]; then

# top -n1 | head -n 4
#
# last pid:  1279;  load averages:  0.00,  0.00,  0.00  up 0+00:30:35    15:11:28
# 23 processes:  1 running, 22 sleeping
# CPU:  0.2% user,  0.0% nice,  0.2% system,  0.2% interrupt, 99.4% idle
# Mem: 14M Active, 1636K Inact, 78M Wired, 47M Buf, 813M Free

        version_distro="freebsd"
        os_version_id="freebsd"

        # FREEBSD_MEMINFO="$(sysctl hw | grep hw.phys)"
        os_version_memory_size="$(sysctl hw.physmem | awk '/^hw.physmem:/{mb = $2/1024/1024; printf "%.0f", mb}')"
        verbose_msg "Memory Total (MB): $(sysctl hw.physmem | awk '/^hw.physmem:/{mb = $2/1024/1024; printf "%.0f", mb}')"

        # sysctl hw.model
        # hw.model: ARM Cortex-A53 r0p4
        os_version_freebsd_model="$(sysctl hw.model | cut -f2 -d: | awk '{$1=$1};1')"
        verbose_msg "CPU Model        : $(sysctl hw.model | cut -f2 -d: | awk '{$1=$1};1')"

        # Try to detect FreeBSD on a Raspberry Pi
        # bcm2835_cpufreq0: <CPU Frequency Control> on cpu0
        os_version_freebsd_cpu="$(dmesg | grep CPU | grep bcm2)"

        # Raspberry Pi BCM chipset?
        if (dmesg | grep CPU | grep -Fqe "bcm2"); then
            verbose_msg "                 : $os_version_freebsd_cpu"
            verbose_msg "                 : assuming Raspberry Pi"

            if [ $os_version_memory_size -lt 2000 ]; then
                verbose_msg "                 : FreeBSD Raspberry Pi with low memory"
            fi
        fi

        # 12.2-RELEASE
        os_version_str=$(uname -r)

        verbose_msg "VERSION_ID       : $os_version_id"
        verbose_msg "VERSION_STR      : $os_version_str"

        version_substr=$(echo $os_version_str | cut -f1 -d-)
        # verbose_msg "VERSION_SUBSTR   : $version_substr"
        version_major=$(echo $version_substr | cut -f1 -d.)
        # verbose_msg "VERSION_MAJOR    : $version_major"
        version_minor=$(echo $version_substr | cut -f2 -d.)
        # verbose_msg "VERSION_MINOR    : $version_minor"

        # show the default language
        # i.e. LANG=en_US.UTF-8
        verbose_msg "Language         : <unknown>"

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

        os_version_id="darwin"
        os_version_str=$(sw_vers -productVersion)

        echo "VERSION_ID       : $os_version_id"
        echo "VERSION_STR      : $os_version_str"

        version_major=$(echo $os_version_str | cut -f1 -d.)
        echo "VERSION_MAJOR    : $version_major"
        version_minor=$(echo $os_version_str | cut -f2 -d.)
        echo "VERSION_MINOR    : $version_minor"
        version_build=$(echo $os_version_str | cut -f3 -d.)
        echo "VERSION_BUILD    : $version_build"

        os_version_memory_size="$(sysctl hw.memsize | awk '/^hw.memsize:/{mb = $2/1024/1024; printf "%.0f", mb}')"
        verbose_msg "Memory Total (MB): $os_version_memory_size"

        if [[ $version_major -eq 10 && $version_minor -eq 12 ]]; then
            os_is_supported=true
            echo "Apple macOS version $os_version_str (Sierra) found"
        elif [[ $version_major -eq 10 && $version_minor -eq 13 ]]; then
            os_is_supported=true
            echo "Apple macOS version $os_version_str (High Sierra) found"
        elif [[ $version_major -eq 10 && $version_minor -eq 14 ]]; then
            os_is_supported=true
            echo "Apple macOS version $os_version_str (Mojave) found"
        elif [[ $version_major -eq 10 && $version_minor -eq 15 ]]; then
            os_is_supported=true
            echo "Apple macOS version $os_version_str (Catalina) found"
        elif [[ $version_major -eq 11 ]]; then
            os_is_supported=true

            if [[ "$(uname -m)" =~ ^arm64 ]]; then
                echo "Apple macOS version $os_version_str (Big Sur) on ARM CPU found"
            else
                echo "Apple macOS version $os_version_str (Big Sur) found"
            fi
        elif [[ $version_major -eq 12 ]]; then
            os_is_supported=true

            if [[ "$(uname -m)" =~ ^arm64 ]]; then
                echo "Apple macOS version $os_version_str (Monterey) on ARM CPU found"
            else
                echo "Apple macOS version $os_version_str (Monterey) found"
            fi
        elif [[ $version_major -eq 13 ]]; then
            os_is_supported=true

            if [[ "$(uname -m)" =~ ^arm64 ]]; then
                echo "Apple macOS version $os_version_str (Ventura) on ARM CPU found"
            else
                echo "Apple macOS version $os_version_str (Ventura) found"
            fi
        else
            os_is_supported=false
            echo "Apple macOS version $version_major.$version_minor found, is currently unsupported"
            exit 1
        fi
        #
#------------------------------------------------------------------------------
    elif [ "$os_name" = "GNU" ]; then
        os_version_id="??? unknown ???"
        os_version_id_like="??? unknown ???"
        os_version_pretty_name="??? unknown ???"
        os_version_str="??? unknown ???"

# PRETTY_NAME="Debian GNU/Hurd bookworm/sid"
# NAME="Debian GNU/Hurd"
# VERSION_CODENAME=bookworm
# ID=debian
# HOME_URL="https://www.debian.org/"
# SUPPORT_URL="https://www.debian.org/support"
# BUG_REPORT_URL="https://bugs.debian.org/"
#
# uname -r
# 0.9

        if [ -f /etc/os-release ]; then
            # awk -F= '$1=="ID" { gsub(/"/, "", $2); print $2 ;}' /etc/os-release
            os_version_id=$(awk -F= '$1=="ID" { gsub(/"/, "", $2); print $2 ;}' /etc/os-release)
            # echo "VERSION_ID is $os_version_id"

            os_version_id_like="GNU"
            # echo "VERSION_ID_LIKE is $os_version_id_like"

            os_version_pretty_name=$(awk -F= '$1=="PRETTY_NAME" { gsub(/"/, "", $2); print $2 ;}' /etc/os-release)
            # echo "VERSION_PRETTY_NAME is $os_version_pretty_name"

            os_version_str=$(uname -r)
            # echo "VERSION_STR is $os_version_str"
        fi

        if [[ $os_version_id =~ debian* ]];
        then
            version_distro="debian"
            os_is_supported=true
        fi

        os_version_memory_size="$(free -m | awk '/^Mem:/{print $2}')"
        verbose_msg "Memory Total (MB): $os_version_memory_size"
        verbose_msg "Memory Free  (MB): $(free -m | awk '/^Mem:/{print $4}')"

        verbose_msg "VERSION_ID       : $os_version_id"
        verbose_msg "VERSION_ID_LIKE  : $os_version_id_like"
        verbose_msg "VERSION_PRETTY   : $os_version_pretty_name"
        verbose_msg "VERSION_STR      : $os_version_str"
    fi
}

#------------------------------------------------------------------------------
#                              detect_bitness
#------------------------------------------------------------------------------

detect_bitness()
{
    # Platform specific tests to guess the "bitness"

    os_osis64bit=no
    os_bitflag="32"

    case "${os_name}" in
       *hp-hpux*)
          ;;
       *ibm-aix*)
          rc=`lsconf -k | grep -c 64-bit`
          if test $rc -eq 1; then
             os_bitflag="64"
             os_osis64bit=yes
          fi
          ;;
       i*86*solaris*)
          ;;
       *solaris*)
          rc=`isainfo -v | grep -c 64-bit`
          if test $rc -eq 1; then
             os_bitflag="64"
             os_osis64bit=yes
          fi
          ;;
       sparc*sunos*)
          ;;
       Linux)
          mach="`uname -m`"
          if test "$mach" = "aarch64" -o "$mach" = "x86_64" -o "$mach" = "ia86" -o "$mach" = "alpha" -o "$mach" = "ppc64" -o "$mach" = "ppc64le" -o "$mach" = "s390x" -o "$mach" = "e2k" -o "$mach" = "riscv64" ; then
             os_bitflag="64"
             os_osis64bit=yes
          fi
          ;;
       FreeBSD|OpenBSD|NetBSD)
          mach="`uname -m`"
          if test "$mach" = "amd64" -o "$mach" = "sparc64" ; then
             os_bitflag="64"
             os_osis64bit=yes
          fi
          ;;
       Darwin)
          os_osx_64bit=`sysctl hw.cpu64bit_capable | cut -f2 -d' '`
          if test $os_osx_64bit -eq 1; then
             os_bitflag="64"
             os_osis64bit=yes
          fi
          ;;
    esac

    verbose_msg "Platform Bitness : $os_bitflag"
}

#------------------------------------------------------------------------------
#                              detect_regina
#------------------------------------------------------------------------------

detect_regina()
{
    verbose_msg -n "Checking for Regina-REXX... " # no newline!

    version_regina=0

    which_regina=$(which regina) || true
    which_status=$?

    # echo "(which rexx) status: $which_status"

    if [ -z $which_regina ]; then
        verbose_msg "nope"
        # verbose_msg "Regina-REXX      : is not installed"
    else
        # regina -v
        # REXX-Regina_3.6 5.00 31 Dec 2011
        # regina: REXX-Regina_3.9.3 5.00 5 Oct 2019 (32 bit)

        regina_v=$(regina -v 2>&1 | grep "Regina" | sed "s#^regina: ##")
        if [ -z "$regina_v" ]; then
            verbose_msg "nope"
        else
            verbose_msg " "  # output a newline
            verbose_msg "Found REXX       : $regina_v"

            regina_name=$(echo $regina_v | cut -f1 -d_)

            if [[ $regina_name == "REXX-Regina" ]]; then
                # echo "we have Regina REXX"

                regina_verstr=$(echo {$regina_v | cut -f2 -d_)
                # echo "regina ver string: $regina_verstr"
                version_regina=$(echo $regina_verstr | cut -f1 -d.)
                # echo "regina version major: $version_regina"
                regina_verminor=$(echo $regina_verstr | cut -f2 -d. | cut -f1 -d' ')
                # echo "regina version minor: $regina_verminor"
                verbose_msg "Regina version   : $version_regina.$regina_verminor"
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

    version_oorexx=0

    which_rexx=$(which rexx) || true
    which_status=$?

    # echo "(which rexx) status: $which_status"

    if [ -z $which_rexx ]; then
        verbose_msg "nope"
        # verbose_msg "ooRexx           : is not installed"
    else
        # rexx -v
        # Open Object Rexx Version 5.0.0 r12142

        oorexx_v=$(rexx -v 2>&1 | grep "Open Object Rexx" | sed "s#^rexx: ##")

        if [ -z "$oorexx_v" ]; then
            verbose_msg "nope"
            verbose_msg "Found REXX, but not ooRexx"
        else
            verbose_msg " "  # output a newline
            verbose_msg "Found REXX       : $oorexx_v"

            if [[ $oorexx_v =~ "Open Object Rexx" ]]; then
                # echo "we have ooRexx"

                oorexx_verstr=$(echo $oorexx_v | sed "s#^Open Object Rexx Version ##")
                # echo "oorexx ver string: $oorexx_verstr"
                version_oorexx=$(echo $oorexx_verstr | cut -f1 -d.)
                # echo "oorexx version major: $version_oorexx"
                oorexx_verminor=$(echo $oorexx_verstr | cut -f2 -d.)
                # echo "oorexx version minor: $oorexx_verminor"
                verbose_msg "ooRexx version   : $version_oorexx.$oorexx_verminor"
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

  if ($dostep_regina_rexx); then
    # See if the compiler can find the Regina-REXX include file(s)
    if [[ $version_regina -ge 3 ]]; then
        echo "#include \"rexxsaa.h\"" | $CC $CPPFLAGS $CFLAGS -dI -E -x c - >/dev/null 2>&1
        cc_status=$?

        # #include "rexx.h"
        # # 1 "/usr/include/rexx.h" 1 3 4

        # cc returns exit code 1 if this fails
        # <stdin>:1:10: fatal error: rexx.h: No such file or directory
        # compilation terminated.
        # #include "rexx.h"

        cc_find_h=$(echo "#include \"rexxsaa.h\"" | $CC $CPPFLAGS $CFLAGS -dI -E -x c - 2>&1 | grep "rexxsaa.h" )
        if [[ $cc_status -eq 0 ]]; then
            verbose_msg "cc_status = $cc_status"
            verbose_msg "rexxsaa.h is found in $CC search path"
            log_extra_info "$cc_find_h"
            rexxsaa_h_present=true
        else
            verbose_msg "cc_status = $cc_status"
            error_msg "rexxsaa.h is not found in $CC search path"
            log_extra_info "$cc_find_h"
            rexxsaa_h_present=false
        fi
    fi
  fi

    detect_oorexx

    # See if the compiler can find the ooRexx include file(s)
    if [[ $version_oorexx -ge 4 ]]; then
        echo "#include \"rexx.h\"" | $CC $CPPFLAGS $CFLAGS -dI -E -x c - >/dev/null 2>&1
        cc_status=$?

        # #include "rexx.h"
        # # 1 "/usr/include/rexx.h" 1 3 4

        # cc returns exit code 1 if this fails
        # <stdin>:1:10: fatal error: rexx.h: No such file or directory
        # compilation terminated.
        # #include "rexx.h"

        cc_find_h=$(echo "#include \"rexx.h\"" | cc $CPPFLAGS $CFLAGS -dI -E -x c - 2>&1 | grep "rexx.h" )

        if [[ $cc_status -eq 0 ]]; then
            verbose_msg "cc_status = $cc_status"
            verbose_msg "rexx.h is found in $CC search path"
            log_extra_info "$cc_find_h"
        else
            verbose_msg "cc_status = $cc_status"
            error_msg "rexx.h is not found in $CC search path"
            log_extra_info "$cc_find_h"
        fi
    fi
}

#------------------------------------------------------------------------------
# Process command line
#-----------------------------------------------------------------------------

# The command line options are parsed first, in case there is a config
# file mentioned.  And if there is a config file we need to override
# what's in it with the options from the command line.
#
# So, we set the 'opt_override_...' variables while parsing the options
# and then apply them over top of the config file later.

if [[ $TRACE == true ]]; then
    set -x # For debugging, show all commands as they are being run
fi

opt_override_trace=false
opt_override_verbose=false
opt_override_prompts=false
opt_override_beeps=false
opt_override_usesudo=false
opt_override_askpass=false
opt_override_auto=true

opt_override_detect_only=false    # Run detection only and exit
opt_override_no_packages=false    # Check for required system packages
opt_override_no_rexx=false        # Build Regina REXX, include Hercules REXX support
opt_override_no_gitclone=false    # Git clone Hercules and external packages
opt_override_no_bldlvlck=false    # Run bldlvlck
opt_override_no_extpkgs=false     # Build Hercules external packages
opt_override_do_autogen=false     # Run autoreconf / autogen
opt_override_no_autogen=false     # Skip autogen
opt_override_no_configure=false   # Run configure
opt_override_no_clean=false       # Run make clean
opt_override_no_make=false        # Run make (compile and link)
opt_override_no_tests=false       # Run make check
opt_override_no_install=false     # Run make install
opt_override_no_setcap=false      # setcap executables
opt_override_no_envscript=false   # Create script to set environment variables
opt_override_no_bashrc=false      # Add "source" to set environment variables from .bashrc

opt_use_homebrew=false            # User Homebrew package manager on MacOS
opt_use_macports=false            # User MacPorts package manager on MacOS

CONFIG_FILE=""

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
  --flavor=*)
    opt_flavor="${1#*--flavor=}"
    shift # past --flavor=xxx option
    ;;

  --config=*)
    opt_config_file="${1#*--config=}"
    CONFIG_FILE=$(cd "$(dirname "$opt_config_file")" && pwd)/$(basename "$opt_config_file")
    shift # past --config=xxx option
    ;;

  -h|--help)
    echo "$usage"
    exit
    ;;

     --version)
    echo "Hercules-Helper $version_info"
    exit
    ;;

  -t|--trace)
    opt_override_trace=true
    shift # past argument
    ;;

  -v|--verbose)
    opt_override_verbose=true
    opt_verbose=true
    shift # past argument
    ;;

  -p|--prompt|--prompts)
    opt_override_prompts=true
    shift # past argument
    ;;

  --beep|--beeps)
    opt_override_beeps=true
    shift # past argument
    ;;

  -a|--auto)  # run everything using all defaults, w/o prompts, and with logging
    opt_override_auto=true
    opt_override_verbose=true
    opt_override_prompts=false
    shift # past argument
    ;;

  -s|--sudo)
    opt_override_usesudo=true
    shift # past argument
    ;;

  --askpass)
    opt_override_askpass=true
    shift # past argument
    ;;

  --detect-only) # run detection only and exit
    opt_override_detect_only=true
    shift # past argument
    ;;

  --no-packages) # skip checking for and installing packages
    opt_override_no_packages=true
    shift # past argument
    ;;

  --no-rexx) # skip building Regina REXX, or adding support to Hercules
    opt_override_no_rexx=true
    shift # past argument
    ;;

  --no-clone|--noclone|--no-gitclone) # skip 'git clone' of sources
    opt_override_no_gitclone=true
    shift # past argument
    ;;

  --no-bldlvlck) # skip 'util/bldlvlck'
    opt_override_no_bldlvlck=true
    shift # past argument
    ;;

  --no-extpkgs) # skip build Hercules external packages
    opt_override_no_extpkgs=true
    shift # past argument
    ;;

  --autogen) # run 'autoreconf' and 'autogen'
    opt_override_do_autogen=true
    shift # past argument
    ;;

  --no-autogen) # skip 'autogen'
    opt_override_no_autogen=true
    shift # past argument
    ;;

  --no-configure) # skip 'configure'
    opt_override_no_configure=true
    shift # past argument
    ;;

  --no-clean) # skip 'make clean'
    opt_override_no_clean=true
    shift # past argument
    ;;

  --no-make) # skip 'make'
    opt_override_no_make=true
    shift # past argument
    ;;

  --no-tests) # skip 'make check'
    opt_override_no_tests=true
    shift # past argument
    ;;

  --no-install) # skip 'make install'
    opt_override_no_install=true
    shift # past argument
    ;;

  --install)
    opt_override_no_install=false
    shift # past argument
    ;;

  --no-setcap) # skip 'setcap'
    opt_override_no_setcap=true
    shift # past argument
    ;;

  --no-envscript) # skip creating script to set environment variables
    opt_override_no_envscript=true
    shift # past argument
    ;;

  --no-bashrc) # skip modifying .bashrc to set environment variables
    opt_override_no_bashrc=true
    shift # past argument
    ;;

  --homebrew)
    opt_use_homebrew=true
    shift # past argument
    ;;

  --macports)
    opt_use_macports=true
    shift # past argument
    ;;

  --force-pi)
    opt_force_pi=true
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
set -- "${POSITIONAL[@]-default}" # restore positional parameters

if [[ "$TRACE" == true ]]; then
    # Show all commands as they are being run
    set -x
fi

#-----------------------------------------------------------------------------

#------------------------------------------------------------------------------
#                               The_Works
#------------------------------------------------------------------------------
function the_works {  # Put everthing in an I/O redirection

echo "Using logfile: $logfile.log"

# Create filename for our log of executed commands
cmdsfile="build-commands"
cmdsfile="${cmdsfile%.*}-$current_time"

if [[ -e $cmdsfile.log || -L $cmdsfile.log ]] ; then
    i=1
    while [[ -e $cmdsfile-$i.log || -L $cmdsfile-$i.log ]] ; do
        let i++
    done
    cmdsfile=$cmdsfile-$i
fi

cmdsfile="$(pwd)/$cmdsfile.log"
echo "Creating build cmds file: $cmdsfile"

# Create filename for our log of extra diagnostic information
extra_file="extra-info"
extra_file="${extra_file%.*}-$current_time"

if [[ -e $extra_file.log || -L $extra_file.log ]] ; then
    i=1
    while [[ -e $extra_file-$i.log || -L $extra_file-$i.log ]] ; do
        let i++
    done
    extra_file=$extra_file-$i
fi

extra_file="$(pwd)/$extra_file.log"
echo "Creating extra diagnostic info file: $extra_file"
log_extra_info "Creating extra diagnostic info file: $extra_file"
log_extra_info ""

#------------------------------------------------------------------------------
add_build_entry "#!/usr/bin/env bash"
add_build_entry # newline

add_build_entry "if [[ \$TRACE == true ]]; then"
add_build_entry "    set -x # For debugging, show all commands as they are being run"
add_build_entry "fi"
add_build_entry # newline

pushd "$(dirname "$0")" >/dev/null;
    which_git=$(which git 2>/dev/null) || true
    which_status=$?

    if [ -z $which_git ]; then
        echo "git is not installed"
        hercules_helper_version="unknown"
    else
        add_build_entry "# Created by Hercules-Helper version: "
        add_build_entry "# $SCRIPT_DIR/$(basename $0): $(git describe --long --tags --dirty --always 2>/dev/null)"
        echo "Script version: $SCRIPT_DIR/$(basename $0): $(git describe --long --tags --dirty --always 2>/dev/null)"

        # add hercules-helper version to the build description
        hercules_helper_version="$(git describe --long --tags --dirty --always 2>/dev/null)"
    fi
popd > /dev/null;
echo    # print a newline

# Process --flavor

#if (! $opt_detect_only); then
    opt_flavor=${opt_flavor:-}

    # Using 'tr' here so this works on Bash 3.2
    if [ ! -z "$opt_flavor" ]; then
        opt_flavor="$(echo $opt_flavor | tr '[:upper:]' '[:lower:]')"
    fi

    # Check for a valid "flavor"
    if [ -z "$opt_flavor" ]; then
        verbose_msg "--flavor= is not specified.  Assuming build style: SDL-Hyperion"
        opt_flavor="sdl-hyperion"
    elif [ "$opt_flavor" == "sdl-hyperion" ]; then
        verbose_msg "--flavor=sdl-hyperion specified.  Build style: SDL-Hyperion"
    elif [ "$opt_flavor" == "aethra" ]; then
        verbose_msg "--flavor=aethra specified.  Build style: Hercules Aethra"
    else
        error_msg "--flavor=$opt_flavor is not supported!"
        exit 1
    fi

    if [ ! -z "$CONFIG_FILE" ]; then
        verbose_msg "--config specified.  Overriding default for build flavor \"$opt_flavor\""
    else
        verbose_msg "No --config specified.  Using default for build flavor $opt_flavor"
        config_dir="$(dirname "$0")"
        CONFIG_FILE="$config_dir/$opt_flavor.conf"
    fi
    verbose_msg    # print a newline
# fi

# Find and read in the configuration

# If there was a config file specified on the command line, use that
if [ ! -z "$CONFIG_FILE" ]; then
    # Ensure the config file actually exists
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "Config file specified with --config=\"$CONFIG_FILE\" not found."
        exit 3
    fi
else
    config_dir="$(dirname "$0")"
    CONFIG_FILE="$config_dir/hercules-helper.conf"
fi

echo "Config file: $CONFIG_FILE"

if test -f "$CONFIG_FILE" ; then
    source "$CONFIG_FILE"
else
    echo "Config file not found.  Using defaults."
fi
echo    # print a newline

if [ $opt_override_trace       == true ]; then TRACE=true; fi
if [ $opt_override_verbose     == true ]; then opt_verbose=true; fi
if [ $opt_override_prompts     == true ]; then opt_prompts=true; fi
if [ $opt_override_beeps       == true ]; then opt_beeps=true; fi
if [ $opt_override_usesudo     == true ]; then opt_usesudo=true; fi
if [ $opt_override_askpass     == true ]; then opt_askpass=true; fi
if [ $opt_override_auto        == true ]; then opt_auto=true; fi

if [ $opt_override_detect_only == true ]; then opt_detect_only=true; fi
if [ $opt_override_no_packages == true ]; then opt_no_packages=true; fi
if [ $opt_override_no_rexx     == true ]; then opt_no_rexx=true; fi
if [ $opt_override_no_gitclone == true ]; then opt_no_gitclone=true; fi
if [ $opt_override_no_bldlvlck == true ]; then opt_no_bldlvlck=true; fi
if [ $opt_override_no_extpkgs  == true ]; then opt_no_extpkgs=true; fi

if [ $opt_override_do_autogen == true ] && [ $opt_override_no_autogen == true ]; then
  error_msg "--autogen and --no-autogen are mutually exclusive"
  exit 1
fi
if [ $opt_override_do_autogen   == true ]; then opt_no_autogen=false; fi
if [ $opt_override_no_autogen   == true ]; then opt_no_autogen=true; fi

if [ $opt_override_no_configure == true ]; then opt_no_configure=true; fi
if [ $opt_override_no_clean     == true ]; then opt_no_clean=true; fi
if [ $opt_override_no_make      == true ]; then opt_no_make=true; fi
if [ $opt_override_no_tests     == true ]; then opt_no_tests=true; fi
if [ $opt_override_no_install   == true ]; then opt_no_install=true; fi
if [ $opt_override_no_setcap    == true ]; then opt_no_setcap=true; fi
if [ $opt_override_no_envscript == true ]; then opt_no_envscript=true; fi
if [ $opt_override_no_bashrc    == true ]; then opt_no_bashrc=true; fi

if [[ $TRACE == true ]]; then
    set -x # For debugging, show all commands as they are being run
fi
# Add environment variables to the rebuild log
# e.g.
# CC               : clang
# CFLAGS           :
# CPPFLAGS         : -I/usr/local/opt/llvm@11/include -I/usr/local/include
# LDFLAGS          : -L/usr/local/opt/llvm@11/lib
# clang            : Homebrew clang version 11.1.0

add_build_entry # newline
add_build_entry "# $(uname -a)"
add_build_entry # newline
add_build_entry "# C compiler: $($CC --version | head -1)"
add_build_entry # newline
add_build_entry "# Environment variables used:"
add_build_entry "# PATH=\"$PATH\""
add_build_entry "# SUDO_ASKPASS=\"${SUDO_ASKPASS:-""}\""
add_build_entry "# CC=\"$CC\""
add_build_entry "# GCC=\"${GCC:-""}\""
add_build_entry "# CFLAGS=\"$CFLAGS\""
add_build_entry "# CPPFLAGS=\"$CPPFLAGS\""
add_build_entry "# LDFLAGS=\"$LDFLAGS\""
add_build_entry "# LD_LIBRARY_PATH=\"${LD_LIBRARY_PATH:-""}\""

add_build_entry # newline
add_build_entry "opt_build_dir=\"$opt_build_dir/hyperion\""
add_build_entry "opt_install_dir=\"$opt_install_dir\""
add_build_entry "opt_regina_dir=\"$opt_regina_dir\""
add_build_entry "opt_regina_tarfile=\"$opt_regina_tarfile\""
add_build_entry "opt_regina_url=\"$opt_regina_url\""

add_build_entry "git_repo_hercules=\"$git_repo_hercules\""
add_build_entry "git_branch_hercules=\"$git_branch_hercules\""
add_build_entry "git_commit_hercules=\"$git_commit_hercules\""
add_build_entry "git_repo_extpkgs=\"$git_repo_extpkgs\""
add_build_entry "git_branch_extpkgs=\"$git_branch_extpkgs\""

add_build_entry "opwd=\"$(pwd)\""

#------------------------------------------------------------------------------
#                              prepare_packages
#------------------------------------------------------------------------------
prepare_packages()
{
  # Look for Debian/Ubuntu/Mint

  if [ "$version_distro" == "debian"  ]; then
      if [ "$os_name" = "GNU" ]; then
          declare -a debian_packages=( \
            "git" "wget" "time" "ncat" \
            "build-essential" "cmake" \
            "autoconf" "automake" "flex" "gawk" "m4" "libltdl-dev" "libtool-bin" \
            "libbz2-dev" "zlib1g-dev"
          )
      else
          declare -a debian_packages=( \
            "git" "wget" "time" "ncat" \
            "build-essential" "cmake" \
            "autoconf" "automake" "flex" "gawk" "m4" "libltdl-dev" "libtool-bin" \
            "libcap2-bin" \
            "libbz2-dev" "zlib1g-dev"
          )
      fi

      add_build_entry # newline
      add_build_entry "# Install required packages: "
      add_build_entry "\$HH_SUDOCMD apt install ${debian_packages[*]}"

      # First let's see if apt is expecting to find a CD-ROM
      # This happened to me on a fresh out-of-the box install
      # of Debian 11, the day after it was released.
      #
      # This detection isn't foolproof, but it's somewhat useful

      # sudo apt update 2>&1
      #
      # Ign:1 cdrom://[Debian GNU/Linux 11.0.0 _Bullseye_ - Official amd64 DVD Binary-1 20210814-10:04] bullseye InRelease
      # Err:2 cdrom://[Debian GNU/Linux 11.0.0 _Bullseye_ - Official amd64 DVD Binary-1 20210814-10:04] bullseye Release
      #   Please use apt-cdrom to make this CD-ROM recognized by APT. apt-get update cannot be used to add new CD-ROMs
      # Hit:3 http://deb.debian.org/debian bullseye InRelease
      # Hit:4 http://security.debian.org/debian-security bullseye-security InRelease
      # Hit:5 http://deb.debian.org/debian bullseye-updates InRelease
      # Reading package lists...
      # E: The repository 'cdrom://[Debian GNU/Linux 11.0.0 _Bullseye_ - Official amd64 DVD Binary-1 20210814-10:04] bullseye Release' does not have a Release file.

      output=$(grep -iqe "^deb cdrom:" /etc/apt/sources.list)
      found_cdrom_in_sources=$?
      if [ $found_cdrom_in_sources -eq 0 ]; then
          note_msg "/etc/apt/sources.list contains a CD-ROM reference!"
      fi

      verbose_msg "sudo apt update ... may take a while ..."
      output=$($HH_SUDOCMD apt update 2>&1)
      found_apt_cdrom_error=$?

      echo "$output" | grep -iqe "Err:. cdrom:"
      found_apt_cdrom_error=$?

      if [ $found_apt_cdrom_error -eq 0 ]; then
          error_msg "\'apt update\' returned a CD-ROM error!"
          verbose_msg "
It appears you have installed from a CD/DVD that is still required to
supply information about packages.  Please see this URL for information
about how to correct apt errors:

https://my.velocihost.net/knowledgebase/29/Fix-the-apt-get-install-error-Media-change-please-insert-the-disc-labeled--on-your-Linux-VPS.html
"
          exit 1
      fi

      for package in "${debian_packages[@]}"; do
          echo -n "Checking for package: $package ... "

          # the following only works on Ubuntu newer than 12.04
          # another method is:
          # /usr/bin/dpkg-query -s <packagename> 2>/dev/null | grep -q ^"Status: install ok installed"$

          is_installed=$(/usr/bin/dpkg-query --show --showformat='${db:Status-Status}\n' $package 2>&1)
          status=$?

          # install if missing
          if [ $status -eq 0 ] && [ "$is_installed" == "installed" ]; then
              echo "is already installed"
          else
              echo "is missing, installing"
              $HH_SUDOCMD apt -y install $package 2>&1
              echo "-----------------------------------------------------------------"
          fi
      done

      if [[ $version_regina -ge 3 ]]; then
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
              $HH_SUDOCMD apt-get -y install $package
          fi
      fi

    return
  fi

#-----------------------------------------------------------------------------
# Look for Elbrus Linux (apt similar to Debian, but different packages)

  if [ "$version_distro" == "elbrus"  ]; then
      declare -a elbrus_packages=( \
          "git" "wget" "time" \
          "build-essential" "cmake" \
          "autoconf" "automake" "flex" "gawk" "m4" "libtool" \
          "libcap" \
          "bzip2" "zlib"
      )

      add_build_entry # newline
      add_build_entry "# Install required packages: "
      add_build_entry "\$HH_SUDOCMD apt install ${elbrus_packages[*]}"

      for package in "${elbrus_packages[@]}"; do
          echo -n "Checking for package: $package ... "

          is_installed=$(/usr/bin/dpkg-query --show --showformat='${db:Status-Status}\n' $package 2>&1)
          status=$?

          # install if missing
          if [ $status -eq 0 ] && [ "$is_installed" == "installed" ]; then
              echo "is already installed"
          else
              note_msg "is missing, must be installed"
              # $HH_SUDOCMD apt -y install $package 2>&1
              echo "-----------------------------------------------------------------"
          fi
      done

      return
  fi

#-----------------------------------------------------------------------------
  # Look for Arch/Manjaro

  if [ "$version_distro" == "arch"  ]; then
      declare -a arch_packages=( \
          "git" "wget" "time" \
          "base-devel" "make" "autoconf" "automake" "cmake" "flex" "gawk" "m4" \
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
              $HH_SUDOCMD pacman -S --needed --noconfirm $package
              echo "-----------------------------------------------------------------"
          fi
      done

      if [[ $version_regina -ge 3 ]]; then
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
              $HH_SUDOCMD apt-get -y install $package
          fi
      fi

    return
  fi

#-----------------------------------------------------------------------------
  # Fedora

  if [[ $os_version_id == fedora* ]]; then
      if [[ $version_major -ge 34 ]]; then
          echo "Fedora version 34 or later found"

          declare -a fedora_packages=( \
              "git" "wget" "time" \
              "gcc" "make" "flex" "gawk" "m4" \
              "autoconf" "automake" "libtool-ltdl-devel" "libtool" \
              "cmake"
              "bzip2-devel" "zlib-devel"
              )

          for package in "${fedora_packages[@]}"; do
              echo "-----------------------------------------------------------------"

              dnf list installed $package
              status=$?

              # install if missing
              if [ $status -eq 0 ]; then
                  echo "package $package is already installed"
              else
                  echo "installing package: $package"
                  $HH_SUDOCMD dnf -y install $package
              fi
          done
      else
          error_msg "Fedora version 33 or earlier found, and not supported"
          exit 1
      fi
    return
  fi

#-----------------------------------------------------------------------------
  # CentOS, Alma, or Rocky Linux

# To update/add packages on RedHat requires some fiddling around.
#
# sudo subscription-manager register --username wrljet --force
# sudo subscription-manager syspurpose role --set "Red Hat Enterprise Linux Workstation"

# To get ltdl.h and friends, requires special fiddling around
# after version 9.  Refer to:
# https://www.redhat.com/sysadmin/install-epel-linux

  if [[ $os_version_id == rhel* ||
        $os_version_id == almalinux* ||
        $os_version_id == rocky* ]];
      then
      if [[ $version_major -ge 8 ]]; then
          echo "RedHat, Alma, or Rocky Linux version 8 or later found"

          declare -a almalinux_packages=( \
              "git" "wget" "time" \
              "gcc" "make" "flex" "gawk" "m4" \
              "autoconf" "automake" "libtool-ltdl-devel" "libtool" \
              "cmake" \
              "bzip2-devel" "zlib-devel"
              )

          if [[ $version_major -ge 9 ]]; then
              if [[ $os_version_id == rhel* ]]; then
                  echo "Enabling CodeReady Linux Builder repository"
                  $HH_SUDOCMD subscription-manager repos --enable codeready-builder-for-rhel-9-$(arch)-rpms
              else
                  echo "Enabling CRB repository"
                  $HH_SUDOCMD yum config-manager --set-enabled crb
              fi
          fi

          for package in "${almalinux_packages[@]}"; do
              echo "-----------------------------------------------------------------"

              #yum list installed bzip2-devel  > /dev/null 2>&1 ; echo $?
              yum list installed $package
              status=$?

              # install if missing
              if [ $status -eq 0 ]; then
                  echo "package $package is already installed"
              else
                  echo "installing package: $package"
                  $HH_SUDOCMD yum -y install $package
              fi
          done
      else
          error_msg "Alma or Rocky Linux version 7 or earlier found, and not supported"
          exit 1
      fi
    return
  fi

#-----------------------------------------------------------------------------
  # Mageia v8

  if [[ $os_version_id == mageia* ]]; then
      if [[ $version_major -ge 8 ]]; then
          echo "Mageia version 8 or later found"

          declare -a mageia_packages=( \
              "git" "wget" \
              "gcc" "make" "flex" "gawk" "m4" \
              "autoconf" "automake" "lib64ltdl-devel" "libtool" \
              "cmake"
              "bzip2" "lib64bz2-devel" "lib64bz2-1" "lib64zlib-devel" \
              "libcap-utils"
              )

          for package in "${mageia_packages[@]}"; do
              echo "-----------------------------------------------------------------"

              #yum list installed bzip2-devel  > /dev/null 2>&1 ; echo $?
              yum list installed $package
              status=$?

              # install if missing
              if [ $status -eq 0 ]; then
                  echo "package $package is already installed"
              else
                  echo "installing package: $package"
                  $HH_SUDOCMD yum -y install $package
              fi
          done
      else
          error_msg "Mageia version 7 or earlier found, and not supported"
          exit 1
      fi
    return
  fi

#-----------------------------------------------------------------------------
  # CentOS 7

  if [[ $os_version_id == centos* ]]; then
      if [[ $version_major -ge 7 ]]; then
          echo "CentOS version 7 or later found"

          if [[ $version_major -eq 7 ]]; then
              declare -a centos_packages=( \
                  "git" "wget" \
                  "gcc" "make" "flex" "gawk" "m4" \
                  "autoconf" "automake" "libtool-ltdl-devel" \
                  "bzip2-devel" "zlib-devel"
              )
          fi

          if [[ $version_major -ge 8 ]]; then
              declare -a centos_packages=( \
                  "git" "wget" "time" \
                  "gcc" "make" "flex" "gawk" "m4" \
                  "autoconf" "automake" "libtool-ltdl-devel" \
                  "cmake" \
                  "bzip2-devel" "zlib-devel"
              )
          fi

          if [[ $version_major -ge 9 ]]; then
              echo "enabling CRB repository"
              $HH_SUDOCMD yum config-manager --set-enabled crb
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
                  $HH_SUDOCMD yum -y install $package
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
                  $HH_SUDOCMD make install
                  cmake --version
                  popd > /dev/null;
              fi

          fi

          # run on all CentOS, after CMAKE
          echo "-----------------------------------------------------------------"

          find_cc1=$(find / -name cc1 -print 2>&1 | grep "cc1")
          verbose_msg "cc1 presence:       $find_cc1"

          find_cc1plus=$(find / -name cc1plus -print 2>&1 | grep "cc1plus")
          verbose_msg "cc1plus presence:   $find_cc1plus"

          if (find / -name cc1plus -print 2>&1 | grep -Fqe "cc1plus"); then
              note_msg "On CentOS and there is no cc1plus"
              note_msg "Please report this"

              if (find / -name cc1 -print 2>&1 | grep -Fqe "cc1"); then
                  error_msg "We do not have cc1 either; full gcc-c++ package is required"
                  exit 1
              else
                  error_msg "We do have cc1; must link cc1plus to cc1"
                  exit 1
                # sudo ln -s "$which_cc1" /usr/bin/cc1plus
              fi
          fi
          echo    # print a newline
      else
          error_msg "CentOS version 6 or earlier found, and not supported"
          exit 1
      fi
    return
  fi

#-----------------------------------------------------------------------------
  # openSUSE (15.1)

  if [[ $os_version_id == opensuse* ]]; then

# devel_basis is a "pattern"
# libcap-progs is not, and won't install it -t pattern

      declare -a opensuse_patterns=( \
          "devel_basis" "autoconf" "automake" "flex" "gawk" "m4" \
          "libtool" \
          "bzip2" \
          "libz1" "zlib-devel"
      )

      for package in "${opensuse_patterns[@]}"; do
          echo "-----------------------------------------------------------------"
          echo "Checking for pattern: $package"

          is_installed=$(zypper search --installed-only --match-exact "$package")
          status=$?

          # install if missing
          if [ $status -eq 0 ] ; then
              echo "package: $package is already installed"
          else
              echo "installing package: $package"
              echo "sudo zypper install -y -t pattern $package"
              $HH_SUDOCMD zypper install -y -t pattern $package
          fi
      done

      declare -a opensuse_packages=( \
          "git" "cmake" \
          "libbz2-devel" \
          "libcap-progs"
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
              echo "sudo zypper install -y $package"
              $HH_SUDOCMD zypper install -y $package
          fi
      done

    return
  fi

#-----------------------------------------------------------------------------
  # Intel Clear Linux (supported from 35130 onward)
  if [[ $os_version_id == clear-linux-os* ]]; then
      declare -a clear_packages=( \
          "git" "wget" \
          "dev-utils" "perl-basic" \
          "c-basic" "flex" "os-core" \
          "devpkg-bzip2" \
          "devpkg-zlib" "zlib"
      )

      for package in "${clear_packages[@]}"; do
          echo -n "Checking for package: $package ... "

          is_installed=$($HH_SUDOCMD swupd bundle-list | grep -Fie "$package" 2>&1)
          status=$?

          # install if missing
          if [ $status -eq 0 ]; then
              echo "is already installed"
          else
              echo "is missing, installing"
              $HH_SUDOCMD swupd bundle-add $package 2>&1
          fi
          echo "-----------------------------------------------------------------"
      done
  fi

#-----------------------------------------------------------------------------
  # Alpine Linux 3.x

  if [[ $os_version_id == alpine* ]]; then
      declare -a alpine_packages=( \
          "git" "wget" "bash" \
          "build-base" "autoconf" "automake" "cmake" "flex" "gawk" "m4" \
          "bzip2" "libbz2" \
          "zlib" "zlib-dev"
      )

      echo "sudo apk -U upgrade"
      $HH_SUDOCMD apk -U upgrade

      for package in "${alpine_packages[@]}"; do
          echo "-----------------------------------------------------------------"
          echo "Checking for package: $package"

          is_installed=$(apk list --installed | grep "$package")
          status=$?

          # install if missing
          if [ $status -eq 0 ] ; then
              echo "package: $package is already installed"
          else
              echo "installing package: $package"
              echo "sudo apk add --no-cache $package"
              $HH_SUDOCMD apk add --no-cache $package
          fi
      done

    return
  fi

#-----------------------------------------------------------------------------
  # Apple Darwin (macOS)

  if [[ $os_version_id == darwin* ]]; then
      declare -a darwin_packages=( \
          "wget"    \
          "autoconf" "automake" "libtool" \
          "cmake"   \
          "gsed"
        # "flex" "gawk" "m4" \
        # "bzip2" "zlib"
      )

      echo "Required packages: "
      echo "${darwin_packages[*]}"
      echo    # print a newline

      add_build_entry # newline
      add_build_entry "# Install required packages: "

      # split cases between Homebrew and MacPorts
      if ( $darwin_have_macports == true ) ; then
          add_build_entry "# sudo port install ${darwin_packages[*]}"
          add_build_entry "$SCRIPT_DIR/helper-check-packages.sh"

          for package in "${darwin_packages[@]}"; do
              verbose_msg "-----------------------------------------------------------------"
              verbose_msg "Checking for package: $package"

              is_installed=$(port installed | grep -Fiqe "$package")
              status=$?

              # install if missing
              if [[ $status -eq 1 || $is_installed == *"Not installed"* ]] ; then
                  verbose_msg "installing package: $package"
                  $HH_SUDOCMD port install $package

                  if [ ${PIPESTATUS[0]} -ne 0 ]; then
                    echo    # print a newline
                    error_msg "MacPorts install failed!"
                    echo    # print a newline
                  fi
              else
                  verbose_msg "package: $package is already installed"
              fi
          done

      elif ( $darwin_have_homebrew == true ) ; then
          add_build_entry "# brew install ${darwin_packages[*]}"
          add_build_entry "$SCRIPT_DIR/helper-check-packages.sh"

          for package in "${darwin_packages[@]}"; do
              verbose_msg "-----------------------------------------------------------------"
              verbose_msg "Checking for package: $package"

              is_installed=$(brew info $package)
              status=$?

              # install if missing
              if [[ $status -eq 1 || $is_installed == *"Not installed"* ]] ; then
                  verbose_msg "installing package: $package"
                  brew install $package

                  if [ ${PIPESTATUS[0]} -ne 0 ]; then
                    echo    # print a newline
                    error_msg "brew install failed!"
                    echo    # print a newline
                  fi
              else
                  verbose_msg "package: $package is already installed"
              fi
          done
      else
          error_msg "MacOS and neither Homebrew or MacPorts is installed!"
          exit 1
      fi

      return
  fi

#-----------------------------------------------------------------------------
  # NetBSD

  if [[ $os_version_id == netbsd* ]]; then
      declare -a netbsd_packages=( \
          "git" "wget" \
          "gmake" "autoconf" "automake" "cmake" "flex" "gawk" "m4" \
          "libtool" "bzip2" "zlib"
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
              echo "installing package: $package"
              $HH_SUDOCMD pkgin -y install $package
          fi
      done

    return
  fi

#-----------------------------------------------------------------------------
  # FreeBSD

  if [[ $os_version_id == freebsd* ]]; then
      if [[ $version_major -ge 12 ]]; then
          echo "FreeBSD version 12 or later found"

          declare -a freebsd_packages=( \
              "git" "wget" \
              "autoconf" "automake" "cmake" "flex" "gawk" "m4" \
              "bzip2" \
              "gmake" "libltdl" "libtool"
          )

          echo "Required packages: "
          echo "${freebsd_packages[*]}"
          echo    # print a newline

          for package in "${freebsd_packages[@]}"; do
              echo "-----------------------------------------------------------------"
              echo "Checking for package: $package"

              is_installed=$(pkg info $package)
              status=$?

              # install if missing
              if [ $status -eq 0 ] ; then
                  echo "package: $package is already installed"
              else
                  # echo "$package : must be installed"
                  echo "installing package: $package"
                  $HH_SUDOCMD pkg install -y $package
              fi
          done
      fi

    return
  fi

#-----------------------------------------------------------------------------
  # OpenBSD

  if [[ $os_version_id == openbsd* ]]; then
      if [[ $version_major -ge 7 ]]; then
          echo "OpenBSD version 7 or later found"

          declare -a openbsd_packages=( \
              "git" "wget" \
              "autoconf-2.71" "automake-1.16.3" "cmake" "flex" "gawk" "m4" \
              "bzip2" \
              "gmake" "libltdl" "libtool"
          )

          echo "Required packages: "
          echo "${openbsd_packages[*]}"
          echo    # print a newline

          # update package lists
          doas pkg_add -u links

          for package in "${openbsd_packages[@]}"; do
              echo "-----------------------------------------------------------------"
              echo "Checking for package: $package"

              is_installed=$(pkg_info | grep "$package")
              status=$?

              # install if missing
              if [ $status -eq 0 ] ; then
                  echo "package: $package is already installed"
              else
                  echo "installing package: $package"
                  $HH_SUDOCMD pkg_add $package
              fi
          done
      fi

    return
  fi

#-----------------------------------------------------------------------------
  # Slackware

  if [[ $os_version_id == slackware* ]]; then
          echo "Slackware (version ?? or later) found"

          declare -a slackware_packages=( \
              "git" "wget" \
              "autoconf" "automake" "cmake" "flex" "gawk" "m4" \
              "bzip2" \
              "make" "libtool"
          )

          echo "Required packages: "
          echo "${slackware_packages[*]}"
          echo    # print a newline

          for package in "${slackware_packages[@]}"; do
              echo "-----------------------------------------------------------------"
              echo "Checking for package: $package"

              is_installed=$($HH_SUDOCMD /usr/sbin/slackpkg search $package)
              status=$?

              # install if missing
              # if [ $status -eq 0 ] ; then
              #     echo "package: $package is already installed"
              # else
                  # echo "$package : must be installed"
                  echo "Installing package: $package"
                  $HH_SUDOCMD /usr/sbin/slackpkg install $package
              # fi
          done
    return
  fi

#-----------------------------------------------------------------------------
  # Gentoo

  if [[ $os_version_id == gentoo* ]]; then
          echo "Gentoo (version ?? or later) found"

          declare -a gentoo_packages=( \
              "dev-vcs/git" "sys-process/time" "net-misc/wget" \
              "sys-devel/autoconf" "sys-devel/automake" \
              "dev-util/cmake" "sys-devel/flex" "sys-apps/gawk" "sys-devel/m4" \
              "app-arch/bzip2" \
              "sys-devel/make" "sys-devel/libtool"
          )

          echo "Required packages: "
          echo "${gentoo_packages[*]}"
          echo    # print a newline

          for package in "${gentoo_packages[@]}"; do
              echo "-----------------------------------------------------------------"
              echo "Checking for package: $package"

              is_installed=$(/usr/bin/equery list $package)
              status=$?

              # install if missing
              if [ $status -eq 0 ] ; then
                  echo "package: $package is already installed"
              else
                  echo "$package : must be installed"
                  echo "Installing package: $package"
                  $HH_SUDOCMD /usr/bin/emerge -av $package
              fi
          done
    return
  fi

#-----------------------------------------------------------------------------
  if [ $os_is_supported != true ]; then
    error_msg "Your system ( $os_version_pretty ) is not (yet) supported!"
    exit 1
  fi
}

detect_darwin

#-----------------------------------------------------------------------------
verbose_msg "General Options:"
verbose_msg "  --trace         : $TRACE"
verbose_msg "  --verbose       : $opt_verbose"
verbose_msg "  --prompts       : $opt_prompts"
verbose_msg "  --beeps         : $opt_beeps"
verbose_msg "  --sudo          : $opt_usesudo"
verbose_msg "  --askpass       : $opt_askpass"

if ( $opt_askpass ) ; then
    HH_SUDO_ASKPASS="-A"
    HH_SUDOCMD="sudo -A"
    add_build_entry "HH_SUDOCMD=\"sudo -A\""
else
    HH_SUDO_ASKPASS=""
    HH_SUDOCMD="sudo"
    add_build_entry "HH_SUDOCMD=\"sudo\""
fi

if ( $opt_use_homebrew ) ; then
    verbose_msg "  --homebrew      : $opt_use_homebrew"
fi
if ( $opt_use_macports ) ; then
    verbose_msg "  --macports      : $opt_use_macports"
fi

verbose_msg "  --detect-only   : $opt_detect_only"
verbose_msg "  --no-packages   : $opt_no_packages"
verbose_msg "  --no-rexx       : $opt_no_rexx"
verbose_msg "  --no-gitclone   : $opt_no_gitclone"
verbose_msg "  --no-bldlvlck   : $opt_no_bldlvlck"
verbose_msg "  --no-autogen    : $opt_no_autogen"
verbose_msg "  --no-configure  : $opt_no_configure"
verbose_msg "  --no-clean      : $opt_no_clean"
verbose_msg "  --no-make       : $opt_no_make"
verbose_msg "  --no-tests      : $opt_no_tests"
verbose_msg "  --no-install    : $opt_no_install"
verbose_msg "  --no-setcap     : $opt_no_setcap"
verbose_msg "  --no-envscript  : $opt_no_envscript"
verbose_msg "  --no-bashrc     : $opt_no_bashrc"
verbose_msg    # print a newline

# sysinfo:
verbose_msg "System information:"
# verbose_msg "  /etc/os-release    : $(cat /etc/os-release 2>&1)"
verbose_msg "  uname -a        : $(uname -a)"
verbose_msg "  uname -m        : $(uname -m)"
verbose_msg "  uname -p        : $(uname -p)"
verbose_msg "  uname -s        : $(uname -s)"
verbose_msg    # print a newline

# Detect type of system we're running on and display info
detect_system
detect_bitness

if [ $os_is_supported != true ]; then
    error_msg "Your system ($os_version_pretty_name) is not (yet) supported!"
    exit 1
fi

# Detect presence of sudo and complain if it's missing
which_sudo=$(which sudo 2>/dev/null) || true
which_status=$?

if [ -z $which_sudo ]; then
    # sudo is not installed

    # On FreeBSD and OpenBSD, look for doas
    if [[ "$os_name" = "FreeBSD" ||
          "$os_name" = "OpenBSD"  ]];
    then
        which_doas=$(which doas 2>/dev/null) || true
        which_status=$?

        if [ -z $which_doas ]; then
            # doas is not installed

            error_msg "Neither 'sudo' or 'doas' are installed."
            echo    # print a new line
            read -p "Hit return to exit" -n 1 -r
            echo    # print a new line
            exit 1
        fi
    else
        error_msg "'sudo' is not installed."
        echo    # print a new line
        read -p "Hit return to exit" -n 1 -r
        echo    # print a new line
        exit 1
    fi
fi

# Skip bldlvlck on MacOS
if [[ $os_version_id == darwin* ]]; then
    opt_no_bldlvlck=true
fi

# Check for ability to create a core dump on MacOS
if [ "$version_distro" == "darwin" ]; then
    verbose_msg "ulimit -c        : $(ulimit -c || true)"
    verbose_msg "ls -ld /cores    : $(ls -ld /cores || true)"

    if [ ! -w /cores ] ; then
        echo "/cores is NOT writeable.  Crash dumps will be disabled." ;
    fi

    # verbose_msg "Check for ability to create a core dump on MacOS
fi

verbose_msg    # print a newline

if ($opt_no_packages  ); then dostep_packages=false;    fi
if ($opt_no_rexx      ); then dostep_regina_rexx=false; fi
if ($opt_no_gitclone  ); then dostep_gitclone=false;    fi
if ($opt_no_bldlvlck  ); then dostep_bldlvlck=false;    fi
if ($opt_no_extpkgs   ); then dostep_extpkgs=false;     fi
if ($opt_no_autogen   ); then dostep_autogen=false; else dostep_autogen=true; fi
if ($opt_no_configure ); then dostep_configure=false;   fi
if ($opt_no_clean     ); then dostep_clean=false;       fi
if ($opt_no_make      ); then dostep_make=false;        fi
if ($opt_no_tests     ); then dostep_tests=false;       fi
if ($opt_no_install   ); then dostep_install=false;     fi

if ($opt_no_setcap    ); then dostep_setcap=false;      fi
if [[ $os_version_id == freebsd* ]]; then dostep_setcap=false; fi

if ($opt_no_envscript ); then dostep_envscript=false;   fi
if ($opt_no_bashrc    ); then dostep_bashrc=false;      fi

#-----------------------------------------------------------------------------

if [[ $os_version_rpidesktop -eq 1 ]]; then
    error_msg "Running on Raspberry Pi Desktop (for PC) is not supported!"
    exit 1
fi

if [[ $os_version_wsl -eq 1 ]]; then
    error_msg "Not supported on Windows WSL1!"
    exit 1
fi

#-----------------------------------------------------------------------------
# Check for --detect-only and exit

if ($opt_detect_only); then
    return 0
fi

if [ "$version_distro" == "darwin" ]; then
    if [[ $opt_use_homebrew == true ]]; then
        if [[ $darwin_have_homebrew == false ]] ; then
            error_msg "--homebrew is specified, but Homebrew is not installed!"
            error_msg "Try running prerequisites-macOS.sh"
            exit 1
        fi
    elif [[ $opt_use_macports == true ]]; then
        if [[ $darwin_have_macports == false ]] ; then
            error_msg "--macports is specified, but MacPorts is not installed!"
            exit 1
        fi
    else
        error_msg "On MacOS, either --homebrew or --macports must be specified!"
        exit 1
    fi
fi

#-----------------------------------------------------------------------------

# If --sudo was specified, we'll just use sudo and be done with it.
# Otherwise, we'll try to create the installation directory, and if
# that fails, OR, if a set of certain options are listed, we'll
# remind the user that sudo might be needed and/or asked for.

HH_SUDO_WARNED=false
HH_SUDO_REQUIRED=false

if ($opt_usesudo); then
    HH_SUDO_REQUIRED=true
else
    # Test if the installation directory is writable, and if not,
    # ensure --sudo was specified

    mkdir -p "$opt_install_dir" 2>/dev/null

    if [[ $? != 0 ]] ; then
        HH_SUDO_REQUIRED=true
    fi

    if [ ! -w "$opt_install_dir" ]; then
        HH_SUDO_REQUIRED=true
    fi
fi

if ($HH_SUDO_REQUIRED && ! $opt_usesudo); then
    opt_usesudo=true
    HH_SUDO_WARNED=true

    note_msg "Note: based on the selected options, your sudo password will be required."
    echo    # print a newline
elif ( $dostep_packages ||
       $dostep_install  ||
       $dostep_setcap   ||
       $dostep_envscript ); then

    HH_SUDO_WARNED=true

    note_msg "Note: based on the selected options, your sudo password may be required."
    echo    # print a newline
fi

if ($opt_prompts && $HH_SUDO_WARNED && ! $opt_usesudo); then
    if confirm "Continue? [y/N]" ; then
        echo    # print a newline
    else
        exit 1
    fi
fi

#-----------------------------------------------------------------------------
verbose_msg "Configuration:"
verbose_msg "FLAVOR               : $opt_flavor"
verbose_msg "Config file          : $CONFIG_FILE"

hercules_barename=$(basename "$git_repo_hercules" ".${git_repo_hercules##*.}")
verbose_msg "REPO_NAME            : $hercules_barename"

verbose_msg "OPT_BUILD_DIR        : $opt_build_dir"
verbose_msg "OPT_INSTALL_DIR      : $opt_install_dir"

verbose_msg "OPT_REGINA_DIR       : $opt_regina_dir"
verbose_msg "OPT_REGINA_TARFILE   : $opt_regina_tarfile"
verbose_msg "OPT_REGINA_URL       : $opt_regina_url"

if [ -z "$git_branch_hercules" ] ; then
    verbose_msg "GIT_REPO_HERCULES    : $git_repo_hercules [default branch]"
else
    verbose_msg "GIT_REPO_HERCULES    : $git_repo_hercules [checkout $git_branch_hercules]"
fi

if [ ! -z "$git_commit_hercules" ] ; then
    verbose_msg "GIT_REPO_HERCULES    : $git_repo_hercules [checkout $git_commit_hercules]"
fi

if [ -z "$git_branch_extpkgs" ] ; then
    verbose_msg "GIT_REPO_EXTPKGS     : $git_repo_extpkgs [default branch]"
else
    verbose_msg "GIT_REPO_EXTPKGS     : $git_repo_extpkgs [checkout $git_branch_extpkgs]"
fi

if [ ! -z "$opt_configure" ] ; then
    verbose_msg "OPT_CONFIGURE        : $opt_configure"
fi

if [ ! -z "$opt_configure_optimization" ] ; then
    verbose_msg "OPT_CONFIGURE_OPTIMIZATION : $opt_configure_optimization"
fi

if [ ! -z "$opt_cmake_defines" ] ; then
    verbose_msg "OPT_CMAKE_DEFINES    : $opt_cmake_defines"
fi

verbose_msg # output a newline

#-----------------------------------------------------------------------------
verbose_msg "Environment variables:"
verbose_msg "Search Path      : ${PATH}"
verbose_msg "SUDO_ASKPASS     : ${SUDO_ASKPASS:-""}"
verbose_msg "CC               : $CC"
verbose_msg "                 : $($CC --version | head -1)"
verbose_msg "GCC              : ${GCC:-""}"
verbose_msg "CFLAGS           : $CFLAGS"
verbose_msg "CPPFLAGS         : $CPPFLAGS"
verbose_msg "LDFLAGS          : $LDFLAGS"
verbose_msg "LD_LIBRARY_PATH  : ${LD_LIBRARY_PATH:-""}"

#-----------------------------------------------------------------------------

verbose_msg    # print a newline
verbose_msg "Performing Steps:"
set_run_or_skip $dostep_packages;    verbose_msg "$run_or_skip : Check for required system packages"
set_run_or_skip $dostep_regina_rexx; verbose_msg "$run_or_skip : Include REXX support, build Regina REXX if needed"
set_run_or_skip $dostep_gitclone;    verbose_msg "$run_or_skip : Git clone Hercules and external packages"
set_run_or_skip $dostep_bldlvlck;    verbose_msg "$run_or_skip : Run bldlvlck"
set_run_or_skip $dostep_extpkgs;     verbose_msg "$run_or_skip : Build Hercules external packages"
set_run_or_skip $dostep_autogen;     verbose_msg "$run_or_skip : Run autogen"
set_run_or_skip $dostep_configure;   verbose_msg "$run_or_skip : Run configure"
set_run_or_skip $dostep_clean;       verbose_msg "$run_or_skip : Run make clean"
set_run_or_skip $dostep_make;        verbose_msg "$run_or_skip : Run make (compile and link)"
set_run_or_skip $dostep_tests;       verbose_msg "$run_or_skip : Run make check"
set_run_or_skip $dostep_install;     verbose_msg "$run_or_skip : Run make install"
set_run_or_skip $dostep_setcap;      verbose_msg "$run_or_skip : setcap executables"
set_run_or_skip $dostep_envscript;   verbose_msg "$run_or_skip : Create script to set environment variables"
shell="$(basename "$SHELL")"
set_run_or_skip $dostep_bashrc;      verbose_msg "$run_or_skip : Add setting environment variables to $shell profile"

#-----------------------------------------------------------------------------
verbose_msg    # print a newline
verbose_msg "Existing build tools versions:"
verbose_msg "  autoconf       : $(autoconf --version 2>&1 | head -n 1)"
verbose_msg "  automake       : $(automake --version 2>&1 | head -n 1)"

libtool_str="$(libtool --version 2>/dev/null)"
if [[ $? -ne 0 ]]; then
    libtool_str="$(libtool -V 2>/dev/null)"
    if [[ $? -ne 0 ]]; then
        libtool_str="unknown"
    fi
fi
libtool_str="$(echo "$libtool_str" | head -n 1)"
verbose_msg "  libtool        : $libtool_str"

verbose_msg "  m4             : $(m4   --version 2>&1 | head -n 1 | sed 's/.*illegal option.*/BSD version of m4/')"
verbose_msg "  make           : $(make --version 2>&1 | head -n 1 | sed 's/^usage: make.*/BSD version of make/')"
verbose_msg "  compiler       : $($CC --version 2>&1 | head -n 1)"
verbose_msg "  linker         : $($LD --version 2>&1 | head -n 1)"
verbose_msg "  gcc presence   : $(which gcc 2>/dev/null || true)"
verbose_msg "  g++ presence   : $(which g++ 2>/dev/null || true)"
verbose_msg    # print a newline

#-----------------------------------------------------------------------------
# Check for older gcc on i686 systems, that is known to fail CBUC test

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

if [[ "$(uname -m)" =~ ^(i686) && "$version_distro" == "debian" ]]; then
    verbose_msg # output a newline
    verbose_msg "Checking for gcc atomics ..."

    as_arg_v1=$hc_gcc_level
    as_arg_v2="6.3.0"

    set +e
    awk "$as_awk_strverscmp" v1="$as_arg_v1" v2="$as_arg_v2" /dev/null
    awk_rc=$?
    # FIXME fix broken Debian 32-bit
    # set -e

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

        if ($opt_prompts); then
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
verbose_msg "Looking for compiler files ... please wait ..."
verbose_msg "Adding results to $extra_file"

    # For NetBSD, gcc doesn't seem to know about /usr/local
    if [[ $os_version_id == netbsd* ]]; then
        export CFLAGS="$CFLAGS -I/usr/local/include"
        export LDFLAGS="$LDFLAGS -L/usr/lib -L/usr/local/lib"
    fi

if [[ $os_version_wsl -eq 2 ]]; then
    # echo "Windows WSL2 host system found"
    # Don't run a search on /mnt because it takes forever
    which_cc1=$(find / -path /mnt -prune -o -name cc1 -print 2>&1 | grep cc1 | head -5)
    which_cc1plus=$(find / -path /mnt -prune -o -name cc1plus -print 2>&1 | grep cc1plus | head -5)
elif [[ $os_version_id == netbsd* ]]; then
    which_cc1=$(find / -xdev -name cc1 -print 2>&1 | grep cc1 | head -5)
    which_cc1plus=$(find / -xdev -name cc1plus -print 2>&1 | grep cc1plus | head -5)
elif [[ $os_version_id == darwin* ]]; then
    # On macOS these two find commands can trigger:
    # "Terminal wants to access your contacts"
    # This looks scary, and we don't want to be suspected of being malware
    # so we'll skip these checks.  They are mostly for debugging anyways.

    which_cc1="skipped on macOS"
    which_cc1plus="skipped on macOS"
elif [[ $os_version_id == elbrus* ]]; then
    verbose_msg "Limited file search on Elbrus Linux"
    which_cc1="skipped on Elbrus Linux"
    which_cc1plus="skipped on Elbrus Linux"
else
    which_cc1="$(find / -mount -name cc1 -print 2>&1 | grep cc1 | head -5)" || true
    which_cc1plus="$(find / -mount -name cc1plus -print 2>&1 | grep cc1plus | head -5)" || true
fi

log_extra_info "cc1 presence     : $which_cc1"
log_extra_info "cc1plus presence : $which_cc1plus"
log_extra_info ""

verbose_msg    # print a newline

#-----------------------------------------------------------------------------

if ($opt_no_packages  ); then dostep_packages=false;    fi
if ($opt_no_rexx      ); then dostep_regina_rexx=false; fi
if ($opt_no_gitclone  ); then dostep_gitclone=false;    fi
if ($opt_no_bldlvlck  ); then dostep_bldlvlck=false;    fi
if ($opt_no_extpkgs   ); then dostep_extpkgs=false;     fi
if ($opt_no_autogen   ); then dostep_autogen=false; else dostep_autogen=true; fi
if ($opt_no_configure ); then dostep_configure=false;   fi
if ($opt_no_clean     ); then dostep_clean=false;       fi
if ($opt_no_make      ); then dostep_make=false;        fi
if ($opt_no_tests     ); then dostep_tests=false;       fi
if ($opt_no_install   ); then dostep_install=false;     fi

if ($opt_no_setcap    ); then dostep_setcap=false;      fi
if [[ $os_version_id == freebsd* ]]; then dostep_setcap=false; fi

if ($opt_no_envscript ); then dostep_envscript=false;   fi
if ($opt_no_bashrc    ); then dostep_bashrc=false;      fi

#-----------------------------------------------------------------------------

if [[ $os_version_rpidesktop -eq 1 ]]; then
    error_msg "Running on Raspberry Pi Desktop (for PC) is not supported!"
    exit 1
fi

if [[ $os_version_wsl -eq 1 ]]; then
    error_msg "Not supported on Windows WSL1!"
    exit 1
fi

#-----------------------------------------------------------------------------
# Check for --detect-only and exit

if ($opt_detect_only); then
    return 0
fi

if [ "$version_distro" == "darwin" ]; then
    if [[ $opt_use_homebrew == true ]]; then
        if [[ $darwin_have_homebrew == false ]] ; then
            error_msg "--homebrew is specified, but Homebrew is not installed!"
            error_msg "Try running prerequisites-macOS.sh"
            exit 1
        fi
    elif [[ $opt_use_macports == true ]]; then
        if [[ $darwin_have_macports == false ]] ; then
            error_msg "--macports is specified, but MacPorts is not installed!"
            exit 1
        fi
    else
        error_msg "On MacOS, either --homebrew or --macports must be specified!"
        exit 1
    fi
fi

#-----------------------------------------------------------------------------
verbose_msg # output a newline
status_prompter "Step: Create installation directory"

if ($opt_usesudo); then
    add_build_entry "$HH_SUDOCMD mkdir -p \$opt_install_dir"
    $HH_SUDOCMD mkdir -p $opt_install_dir
else
    add_build_entry "mkdir -p \$opt_install_dir"
    mkdir -p $opt_install_dir

    # FIXME this should never happen -- remove after fully testing
    if [[ $? != 0 ]] ; then
        error_msg "\'mkdir -p $opt_install_dir\' for installation directory failed!"
        error_msg "Did you forget the --sudo option?"
        exit 1
    fi
fi

verbose_msg "Installation directory created: $opt_install_dir"

#-----------------------------------------------------------------------------
verbose_msg # output a newline
if (! $dostep_packages); then
    verbose_msg "Step: Check for required packages: (skipped)"
else
    status_prompter "Step: Check for required packages:"
    prepare_packages
fi

#-----------------------------------------------------------------------------
verbose_msg # output a newline
status_prompter "Step: Check REXX and compiler files:"
detect_rexx

#-----------------------------------------------------------------------------
# FIXME macOS
# start_seconds="$(TZ=UTC0 printf '%(%s)T\n' '-1')"
start_seconds="$(date +%s)"
start_time=$(date)

verbose_msg # output a newline
verbose_msg "Processing started: $start_time"

#-----------------------------------------------------------------------------
# Build Regina Rexx, which we use to run the Hercules tests
verbose_msg "-----------------------------------------------------------------
"

built_regina_from_source=0

if (! $dostep_regina_rexx); then
    verbose_msg "Skipping step: build Regina-REXX from source (--no-rexx)."
elif [[  $version_regina -ge 3 ]]; then
    verbose_msg "Regina REXX is present.  Skipping build Regina from source."
elif [[  $version_oorexx -ge 4 ]]; then
    verbose_msg "ooRexx is present.  Skipping build ooRexx from source."
else
    status_prompter "Step: Build Regina Rexx [used for test scripts]:"

    # Remove any existing Regina, download and untar
    add_build_entry # newline
    add_build_entry "# Build Regina-REXX"
    add_build_entry "rm -f \$opt_regina_tarfile"
    add_build_entry "rm -rf \$opt_regina_dir"
    rm -f "$opt_regina_tarfile"
    rm -rf "$opt_regina_dir"

    add_build_entry "wget \$opt_regina_url"
    wget "$opt_regina_url"
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        error_msg "wget $opt_regina_url failed!"
        exit 1
    fi

    add_build_entry "tar xfz \$opt_regina_tarfile"
    tar xfz "$opt_regina_tarfile"
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        error_msg "tar failed!"
        exit 1
    fi

    add_build_entry "cd \$opt_regina_dir"
    cd "$opt_regina_dir"

    if [[ "$(uname -m)" =~ ^i686 ]]; then
        regina_configure_cmd="./configure --enable-32bit"
    elif [[ "$(uname -m)" =~ (^arm64|^aarch64) ]]; then
        # If it's an arm64 CPU, and not FreeBSD, enable 64-bit
        # This should work on Raspberry Pi with both FreeBSD and the Pi OSes
        if [[ $os_version_id == freebsd* ]]; then
            regina_configure_cmd="./configure"
        else
            regina_configure_cmd="./configure --enable-64bit"
        fi
    else
        # regina_configure_cmd="./configure --prefix=$opt_build_dir/rexx"
        regina_configure_cmd="./configure"
    fi

    if [[ "$version_distro" == "debian" ||
          "$version_distro" == "openSUSE" ||
          "$version_distro" == "fedora" ]];
    then
        regina_configure_cmd="$regina_configure_cmd --libdir=/usr/lib"
    fi

    if [[ "$version_distro" == "almalinux"  ||
          "$version_distro" == "rockylinux" ||
          "$version_distro" == "redhat"     ]]; then
        regina_configure_cmd="$regina_configure_cmd --libdir=/usr/lib64"
    fi

    # For FreeBSD and OpenBSD, Clang doesn't seem to know about /usr/local
    if [[ $os_version_id == freebsd* || $os_version_id == openbsd* ]]; then
        export CFLAGS="$CFLAGS -I/usr/local/include"
        export LDFLAGS="$LDFLAGS -L/usr/lib -L/usr/local/lib"
    fi

    # For NetBSD, gcc doesn't seem to know about /usr/local
    if [[ $os_version_id == netbsd* ]]; then
        export CFLAGS="$CFLAGS -I/usr/local/include"
        export LDFLAGS="$LDFLAGS -L/usr/lib -L/usr/local/lib"
    fi

    if (cc --version | grep -Fiqe "clang"); then
#   if [[ $os_version_id == darwin* &&
#         "$(uname -m)" =~ (^arm64|^aarch64) ]];
#   then
#       regina_configure_cmd="CFLAGS=\"-Wno-error=implicit-function-declaration\" ./configure"
        regina_configure_cmd="CFLAGS=\"$CFLAGS -Wno-error=implicit-function-declaration\" ./configure"
    fi

    # FIXME on macOS on Apple M1 build Regina with a separate helper
    # before running this script!

    # If this is a RPIOS 64-bit, aarch64 Chromebook, RISC-V, or ppc64le:
    #   for Regina 3.9.3:
    #     we need to patch configure
    #
    #   for Regina 3.6:
    #     we need to patch configure
    #     and supply a more modern config.{guess,sub}

    # For Chromebook:
    # uname -a
    # Linux penguin 5.10 ...

    if [[ "$(uname -m)" =~ (^arm64|^aarch64) ]]; then
      if [[ ( ! -z "$RPI_MODEL" && "$RPI_MODEL" =~ "Raspberry" ) ||
            ( $opt_force_pi == true ) ||
            ( "$(uname -r)" =~ "linuxkit" ) ||
            ( "$(uname -r)" =~ "rockchip64" ) ||
            ( "$(uname -a)" =~ "Linux g6sbc01" ) ||
            ( "$(uname -a)" =~ "Linux penguin" ) ]]; then

        if [[ "$opt_regina_dir" =~ "3.9.3" ]]; then
          verbose_msg "Patching Regina 3.9.3 source for aarch64"
          patch -u configure -i "$SCRIPT_DIR/patches/regina-rexx-3.9.3.patch"
          verbose_msg    # output a newline
        elif [[ "$opt_regina_dir" =~ "3.6" ]]; then
          verbose_msg "Patching Regina 3.6 source for aarch64"
          patch -u configure -i "$SCRIPT_DIR/patches/regina-rexx-3.6.patch"
          verbose_msg "Replacing config.{guess,sub}"
          cp "$SCRIPT_DIR/patches/config.guess" ./common/
          cp "$SCRIPT_DIR/patches/config.sub" ./common/
          verbose_msg    # output a newline
        else
          error_msg "Don't know how to build your Regina on your aarch64!"
          exit 1
        fi
      fi
    fi

    if [[ "$(uname -m)" =~ (^riscv64|^ppc64) ]]; then
        if [[ "$opt_regina_dir" =~ "3.9.3" ]]; then
          verbose_msg "Patching Regina 3.9.3"
          patch -u configure -i "$SCRIPT_DIR/patches/regina-rexx-3.9.3.patch"
          verbose_msg    # output a newline
        elif [[ "$opt_regina_dir" =~ "3.6" ]]; then
          verbose_msg "Patching Regina 3.6 source"
          patch -u configure -i "$SCRIPT_DIR/patches/regina-rexx-3.6.patch"
          verbose_msg "Replacing config.{guess,sub}"
          cp "$SCRIPT_DIR/patches/config.guess" ./common/
          cp "$SCRIPT_DIR/patches/config.sub" ./common/
          verbose_msg    # output a newline
        else
          error_msg "Don't know how to build your Regina!"
          exit 1
        fi
    fi

    verbose_msg $regina_configure_cmd
    verbose_msg    # output a newline
    add_build_entry # newline
    add_build_entry "$regina_configure_cmd"
    eval "$regina_configure_cmd"

    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        error_msg "configure failed!"
        exit 1
    fi

    add_build_entry "time make"
    time make

    note_msg "sudo required to install Regina REXX in the default system directories"
    verbose_msg    # output a newline
    add_build_entry "\$HH_SUDOCMD time make install"
    $HH_SUDOCMD time make install

    # Check to see if the above 'sudo' or the 'make install' failed
    if [[ $? != 0 ]] ; then
        error_msg "Regina installation failed!"
        exit 1
    fi

    if [[ "$version_distro" == "debian" ||
          "$version_distro" == "openSUSE" ||
          "$version_distro" == "almalinux" ||
          "$version_distro" == "rockylinux" ||
          "$version_distro" == "fedora" ]];
    then
        verbose_msg "sudo ldconfig (for libregina.so)"
        add_build_entry "# ldconfig (for libregina.so)"
        add_build_entry "\$HH_SUDOCMD ldconfig"
        $HH_SUDOCMD ldconfig
    fi

    if [[ "$version_distro" == "slackware" ]];
    then
        verbose_msg "sudo /sbin/ldconfig (for libregina.so)"
        add_build_entry "# ldconfig (for libregina.so)"
        add_build_entry "\$HH_SUDOCMD /sbin/ldconfig"
        $HH_SUDOCMD /sbin/ldconfig
    fi

#   export PATH=$opt_build_dir/rexx/bin:$PATH
#
#   export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$opt_build_dir/rexx/lib
#   newpath="$opt_install_dir/rexx/lib"
#   if [ -d "\$newpath" ] && [[ ":\$LD_LIBRARY_PATH:" != *":\$newpath:"* ]]; then
#       export LD_LIBRARY_PATH="\$newpath\${LD_LIBRARY_PATH:+":\$LD_LIBRARY_PATH"}"
#   fi
#
#   export CPPFLAGS=-I$opt_build_dir/rexx/include

    verbose_msg    # output a newline
    verbose_msg "which rexx: $(which rexx)"
    built_regina_from_source=1
fi

#
verbose_msg "-----------------------------------------------------------------
"

if (! $dostep_gitclone); then
    verbose_msg "Skipping step: git clone all required repos (--no-gitclone)."
else
    status_prompter "Step: git clone all required repos:"

    add_build_entry # newline
    add_build_entry "# git clone required repos"
    add_build_entry "cd \$opt_build_dir"
    cd $opt_build_dir

    # Grab unmodified Hercules repo
    add_build_entry "rm -rf $hercules_barename"
    rm -rf $hercules_barename

    if [ -z "$git_repo_hercules" ] ; then
        error_msg "git_repo_hercules variable is not set!"
        exit 1
    fi

    if [ -z "$git_branch_hercules" ] ; then
        verbose_msg "git clone $git_repo_hercules"
        add_build_entry "git clone \$git_repo_hercules"

        git clone $git_repo_hercules
        if [[ $? != 0 ]] ; then
            error_msg "git clone failed!"
            exit 1
        fi
    else
        verbose_msg "git clone -b $git_branch_hercules $git_repo_hercules"
        add_build_entry "git clone -b \$git_branch_hercules \$git_repo_hercules"

        git clone -b "$git_branch_hercules" "$git_repo_hercules"
        if [[ $? != 0 ]] ; then
            error_msg "git clone failed!"
            exit 1
        fi
    fi

    if [ ! -z "$git_commit_hercules" ] ; then
        verbose_msg "git checkout $git_commit_hercules"

        add_build_entry "pushd $hercules_barename"
        pushd $hercules_barename

        add_build_entry "git checkout \$git_commit_hercules"

        git checkout "$git_commit_hercules"
        if [[ $? != 0 ]] ; then
            error_msg "git checkout failed!"
            exit 1
        fi

        add_build_entry "popd"
        popd
    fi

    #-------

    add_build_entry "cd \$opt_build_dir"
    cd $opt_build_dir
    add_build_entry "rm -rf extpkgs"
    rm -rf extpkgs
    add_build_entry "mkdir extpkgs"
    mkdir extpkgs
    add_build_entry "cd extpkgs/"
    cd extpkgs/

    # add_build_entry "mkdir repos && cd repos"
    # mkdir repos && cd repos
    add_build_entry "rm -rf *"
    rm -rf *

    if [ -z "$git_repo_extpkgs" ] ; then
        error_msg "git_repo_extpkgs variable is not set!"
        exit 1
    fi

    declare -a pgms=("crypto" "decNumber" "SoftFloat" "telnet")

    for pgm in "${pgms[@]}"; do
        verbose_msg "-----------------------------------------------------------------
    "
        if [ -z "$git_branch_extpkgs" ] ; then
            verbose_msg "git clone $git_repo_extpkgs/$pgm"
            add_build_entry "git clone \$git_repo_extpkgs/$pgm"

            git clone "$git_repo_extpkgs/$pgm.git"
            if [[ $? != 0 ]] ; then
                error_msg "git clone failed!"
                exit 1
            fi
        else
            verbose_msg "git clone -b $git_branch_extpkgs $git_repo_extpkgs/$pgm"
            add_build_entry "git clone -b \$git_branch_extpkgs \$git_repo_extpkgs/$pgm"

            git clone -b "$git_branch_extpkgs" "$git_repo_extpkgs/$pgm.git"
            if [[ $? != 0 ]] ; then
                error_msg "git clone failed!"
                exit 1
            fi
        fi
    done
fi

verbose_msg "-----------------------------------------------------------------
"

if (! $dostep_bldlvlck); then
    verbose_msg "Skipping step: util/bldlvlck (--no-bldlvlck)"
else
    status_prompter "Step: util/bldlvlck:"

    add_build_entry "cd \$opt_build_dir/$hercules_barename"
    cd $opt_build_dir/$hercules_barename

    # Check for required packages and minimum versions.
    # Inspect the output carefully and do not continue if there are
    # any error messages or recommendations unless you know what you're doing.

    # On Raspberry Pi Desktop (Buster), the following are often missing:
    # autoconf, automake, cmake, flex, gawk, m4

    add_build_entry # newline
    add_build_entry "# Check program versions"
    add_build_entry "util/bldlvlck"
    util/bldlvlck
fi

verbose_msg "-----------------------------------------------------------------
"

if (! $dostep_extpkgs); then
    verbose_msg "Skipping step: prepare and build extpkgs (--no-extpkgs)"
else
    status_prompter "Step: Prepare and build extpkgs:"

    add_build_entry # newline
    add_build_entry "# Prepare and build extpkgs"

#    add_build_entry "cd \$opt_build_dir/extpkgs"
#
#    cd $opt_build_dir/extpkgs
#
#    # Edit extpkgs.sh.ini
#    # Change 'x86' to 'aarch64' for 64-bit, or 'arm' for 32-bit, etc.
#    add_build_entry "# Change 'x86' to 'aarch64' for 64-bit, or 'arm' for 32-bit, etc."
#
#    if   [[ "$(uname -m)" == x86* || "$(uname -m)" == amd64* ]]; then
#        verbose_msg "Defaulting to x86 machine type in extpkgs.sh.ini"
#        add_build_entry "# Defaulting to x86 machine type in extpkgs.sh.ini"
#    elif [[ "$(uname -m)" =~ (armv6l|armv7l) ]]; then
#        add_build_entry "mv extpkgs.sh.ini extpkgs.sh.ini-orig"
#        add_build_entry "sed \"s/x86/arm/\" extpkgs.sh.ini-orig > extpkgs.sh.ini"
#        mv extpkgs.sh.ini extpkgs.sh.ini-orig
#        sed "s/x86/arm/" extpkgs.sh.ini-orig > extpkgs.sh.ini
#    elif [[ "$(uname -m)" =~ (arm64) ]]; then
#        add_build_entry "mv extpkgs.sh.ini extpkgs.sh.ini-orig"
#        add_build_entry "sed \"s/x86/aarch64/\" extpkgs.sh.ini-orig > extpkgs.sh.ini"
#        mv extpkgs.sh.ini extpkgs.sh.ini-orig
#        sed "s/x86/aarch64/" extpkgs.sh.ini-orig > extpkgs.sh.ini
#    else
#        add_build_entry "mv extpkgs.sh.ini extpkgs.sh.ini-orig"
#        add_build_entry "sed \"s/x86/$(uname -m)/\" extpkgs.sh.ini-orig > extpkgs.sh.ini"
#        mv extpkgs.sh.ini extpkgs.sh.ini-orig
#        sed "s/x86/$(uname -m)/" extpkgs.sh.ini-orig > extpkgs.sh.ini
#    fi

    add_build_entry # newline
    add_build_entry "cd \$opt_build_dir/extpkgs"
    cd $opt_build_dir/extpkgs

    # 27JAN2022 Removed Fish's extpksg.sh building kludge
    # add_build_entry "./extpkgs.sh  c d s t"
    # ./extpkgs.sh  c d s t
    # DEBUG=1 ./extpkgs.sh  c d s t

    # Mac Mini M1
    # arm64

    # We do this to match the way it's done in Hercules configure
    target_cpu=$(uname -m)
    case "$target_cpu" in

        i*86|x86*)
            hc_cv_cpu_arch=x86
            hc_cv_pkg_lib_subdir=""
            ;;

        amd64*)
            hc_cv_cpu_arch=x86
            hc_cv_pkg_lib_subdir=""
            ;;

        aarch64*)
            hc_cv_cpu_arch=aarch64
            hc_cv_pkg_lib_subdir="/aarch64"
            ;;

        arm64*)
            hc_cv_cpu_arch=aarch64
            hc_cv_pkg_lib_subdir="/aarch64"
            ;;

        arm*)
            hc_cv_cpu_arch=arm
            hc_cv_pkg_lib_subdir="/arm"
            ;;

        e2k*)
            hc_cv_cpu_arch=e2k
            hc_cv_pkg_lib_subdir="/e2k"
            ;;

        mips*)
            hc_cv_cpu_arch=mips
            hc_cv_pkg_lib_subdir="/mips"
            ;;

        ppc*|powerpc*)
            hc_cv_cpu_arch=ppc
            hc_cv_pkg_lib_subdir="/ppc"
            ;;

        sparc*)
            hc_cv_cpu_arch=sparc
            hc_cv_pkg_lib_subdir="/sparc"
            ;;

        s390x*)
            hc_cv_cpu_arch=s390x
            hc_cv_pkg_lib_subdir="/s390x"
            ;;

        xscale*)
            hc_cv_cpu_arch=xscale
            hc_cv_pkg_lib_subdir="/xscale"
            ;;

        riscv64*)
            hc_cv_cpu_arch=riscv64
            hc_cv_pkg_lib_subdir="/riscv64"
            ;;

        *)
            hc_cv_cpu_arch=unknown
            hc_cv_pkg_lib_subdir="/unknown"
            ;;
    esac

    add_build_entry "rm -rf lib/"
    rm -rf lib/

    for pkg in crypto decNumber SoftFloat telnet; do
        verbose_msg "Building extpkg: $pkg"

        #mkdir -p build/${pkg}$os_bitflag.Debug
        #pushd build/${pkg}$os_bitflag.Debug

        add_build_entry "mkdir -p build/${pkg}$os_bitflag.Release"
        add_build_entry "pushd build/${pkg}$os_bitflag.Release"

        mkdir -p build/${pkg}$os_bitflag.Release
        pushd build/${pkg}$os_bitflag.Release

            # Clear CMake cache in case we've changed the options
            rm -f CMakeCache.txt

            # e.g. opt_cmake_defines="-DCMAKE_C_FLAGS_RELWITHDEBINFO=\"-O3 -march=native -g\""
            if [ ! -z "$opt_cmake_defines" ] ; then
                verbose_msg "Adding CMake defines: $opt_cmake_defines"
            fi

            #cmake $opt_cmake_defines -D INSTALL_PREFIX=$opt_build_dir/extpkgs  -DLIB_INSTALL_DIR=lib$hc_cv_pkg_lib_subdir  $opt_build_dir/extpkgs/$pkg

            cmake_cmd=$(cat <<-END-CMAKE
cmake $opt_cmake_defines \
    -D INSTALL_PREFIX=$opt_build_dir/extpkgs \
    -DLIB_INSTALL_DIR=lib$hc_cv_pkg_lib_subdir \
    $opt_build_dir/extpkgs/$pkg
END-CMAKE
)

            add_build_entry "rm -f CMakeCache.txt"
            add_build_entry "$cmake_cmd"
            add_build_entry "make clean"
            add_build_entry "make -j 4 all"
            add_build_entry "make install"

            verbose_msg $cmake_cmd
            verbose_msg    # output a newline
            eval "$cmake_cmd"

            rc=$?
            if (( $rc != 0 )); then
                error_msg "ERROR: Cmake has failed! rc=$rc";
                error_msg "ERROR: extpkgs not built";
                exit 3
            fi

            make clean
            make -j 2 all
            make install
         popd
    done

fi

verbose_msg "-----------------------------------------------------------------
"

add_build_entry # newline
add_build_entry "cd \$opt_build_dir/$hercules_barename"
cd $opt_build_dir/$hercules_barename

# FIXME filter out FreeBSD and Apple Darwin here also

# If we're on an Apple Mac M1 ARM CPU, run autogen, but skip autoreconf

if [[ $os_version_id == darwin* && "$(uname -m)" =~ ^arm64 ]]; then
    if (! $dostep_autogen); then
        verbose_msg "Skipping step: autogen.sh (--no-autogen)"
    else
        status_prompter "Step: forcing autogen.sh on Apple Mac M1:"

        # save away original ltdl.[ch] source files
        # verbose_msg "Saving original ltdl.[ch] source files"
        # if [ -f ltdl.c ]; then mv ltdl.c ltdl.c.orig; fi
        # if [ -f ltdl.h ]; then mv ltdl.h ltdl.h.orig; fi
        # verbose_msg    # output a newline

        # save original Makefile.am and apply our patch
        # if [ ! -f Makefile.am.orig ]; then
        #     verbose_msg "Patching Makefile.am"
        #     cp Makefile.am Makefile.am.orig
        #     patch -u Makefile.am -i "$SCRIPT_PATH/patches/Makefile.am.M1.patch"
        #     verbose_msg    # output a newline
        # fi

        verbose_msg "Running autogen.sh"
        add_build_entry "./autogen.sh"
        ./autogen.sh
    fi
else
    if (! $dostep_autogen); then
        verbose_msg "Skipping step: autogen.sh (--no-autogen)"
    # elif [[ "$(uname -m)" == x86* && "$version_distro" != "darwin" ]]; then
    #     # We will skip autogen on Linux x86_64 machines.
    #     verbose_msg "Skipping autogen step on Linux x86* architecture"
    else
        status_prompter "Step: autogen.sh:"

        # this ECHO stuff taken from Hercules autogen.sh
        case `echo "testing\c"; echo 1,2,3`,`echo -n testing; echo 1,2,3` in
          *c*,-n*) ECHO_N= ECHO_C='
        ' ECHO_T='	' ;;
          *c*,*  ) ECHO_N=-n ECHO_C= ECHO_T= ;;
          *)       ECHO_N= ECHO_C='\c' ECHO_T= ;;
        esac

        add_build_entry # newline
        add_build_entry "autoreconf --force --install >./autoreconf.log 2>&1"
        echo $ECHO_N "autoreconf... $ECHO_C" && autoreconf --force --install >./autoreconf.log 2>&1 && echo "OK."
        verbose_msg    # output a newline
        add_build_entry # newline
        add_build_entry "./autogen.sh"
        ./autogen.sh
    fi
fi

verbose_msg "-----------------------------------------------------------------
"
if (! $dostep_configure); then
    verbose_msg "Skipping step: configure (--no-configure)"
else
    status_prompter "Step: configure:"

    # Check for REXX and set up its configure option
    if ( $opt_no_rexx ); then
        note_msg "REXX support declined."
        enable_regina_option="--disable-regina-rexx"
        enable_oorexx_option="--disable-object-rexx"
        # dostep_tests=false
    else
        enable_regina_option=""
        enable_oorexx_option=""

        if [[ $version_regina -ge 3 ]]; then
            if [ $rexxsaa_h_present == true ]; then
                verbose_msg "Regina REXX is present. Using configure option: --enable-regina-rexx"
                enable_regina_option="--enable-regina-rexx"
            else
                error_msg "Regina REXX is present, but rexxsaa.h is not found.
Regina REXX support will not be built into Hercules.

Installing the Regina development package may fix this.
for example, in Debian: sudo apt install libregina3-dev
"

                if confirm "Continue anyway? [y/N]" ; then
                    echo "OK"
                else
                    exit 1
                fi

                enable_regina_option="--disable-regina-rexx"
                # dostep_tests=false
            fi
        fi

        if [[ $built_regina_from_source -eq 1 ]]; then
            enable_regina_option="--enable-regina-rexx"
        fi

        if [[ $version_oorexx -ge 4 ]]; then
            verbose_msg "ooRexx is present. Using configure option: --enable-object-rexx"
            enable_oorexx_option="--enable-object-rexx"
        fi
    fi

    # Set up IPv6 configure option
    if [[ $os_version_id == alpine* ]]; then
        verbose_msg "Disabling IPv6 support for Alpine Linux"
        enable_ipv6_option="--disable-ipv6"
    elif [[ $os_version_id == freebsd* || $os_version_id == openbsd* ]]; then
        verbose_msg "Disabling IPv6 support for FreeBSD/OpenBSD"
        enable_ipv6_option="--disable-ipv6"
    elif [[ "$os_name" == "GNU" ]]; then
        verbose_msg "Disabling IPv6 support for GNU (Hurd/Mach)"
        enable_ipv6_option="--disable-ipv6"
    else
        enable_ipv6_option=""
    fi

    # Set up compiler optimization options and special options

    # Enable cap_sys_nice so Hercules can be run as a normal user
    # FIXME this doesn't work with 'make check', so we use 'setcap' instead
    #   --enable-capabilities
    # which dpkg-query
    # dpkg-query --show libcap-dev
    # sudo apt-get install libcap-dev
    # dpkg-query --show libcap-dev
    # find / -name capability.h -print

    # Debian 10 x86_64, gcc 8.3.0
    # CBUC test fails without this
    #   --enable-optimization="-O3 -march=native"

    # Debian 8 & 9, i686, gcc older then 6.3.0 fails CBUC test

    # WRL original for Pi 4 64-bit
    #   --enable-optimization="-O3 -pipe"

    # For Alpine
    # --enable-optimization="-O2 -march=native -D__gnu_linux__=1 -D__ALPINE_LINUX__=1"

    # For Address Sanitizer:
    # config_opt_optimization="--enable-optimization=\"-O1 -g -fsanitize=address -fsanitize-recover=address -fno-omit-frame-pointer\""

    config_cc_optimizer_level="-O3"

    # For FreeBSD, Clang, and older gcc on Aarch64 don't accept -march=native
    if [[ $os_version_id == freebsd* ]]; then
        config_opt_optimization="--enable-optimization=\"-g -g3 -ggdb3 $config_cc_optimizer_level\""
    elif [[ $os_version_id == alpine* ]]; then
        config_opt_optimization="--enable-optimization=\"-g -g3 -ggdb3 $config_cc_optimizer_level -march=native -D__gnu_linux__=1 -D__ALPINE_LINUX__=1\""
    elif [[ $os_version_id == darwin* &&
            "$(uname -m)" =~ (^arm64|^aarch64) ]];
    then
        config_opt_optimization="--enable-optimization=\"-g -g3 -ggdb3 $config_cc_optimizer_level\""
    else
        # Try to compile a do-nothing program with -march=native
        cc_accepts_march_native=$(echo "#include \"stdio.h\"" | $CC $CPPFLAGS $CFLAGS -march=native -dI -E -x c - 2>&1)
        cc_status=$?

        if [[ $cc_status -eq 0 ]]; then
            verbose_msg "C compiler accepts -march=native"
            config_opt_optimization="--enable-optimization=\"-g -g3 -ggdb3 $config_cc_optimizer_level -march=native\""
        else
            verbose_msg "C compiler does not accept -march=native"
            config_opt_optimization="--enable-optimization=\"-g -g3 -ggdb3 $config_cc_optimizer_level\""
        fi
    fi

    # Our config file can override all this, for example on Raspberry Pi 4B:
    # opt_configure_optimization="-mtune=cortex-a72 -march=armv8-a+crc -O3"
    if [ ! -z "$opt_configure_optimization" ] ; then
        config_opt_optimization="--enable-optimization=\"$opt_configure_optimization\""
    fi

    # For Apple Darwin, avoid fork bomb
    if [[ $os_version_id == darwin* ]]; then
        verbose_msg "Disabling \"getopt wrapper kludge\" for Apple Darwin"
        verbose_msg    # output a newline
        enable_getoptwrapper_option="--disable-getoptwrapper"
    else
        enable_getoptwrapper_option=""
    fi

    # Unless this is Clang (e.g. Apple Darwin), record the gcc switches in the binaries

    # For NetBSD, gcc doesn't seem to know about /usr/local
    if [[ $os_version_id == netbsd* ]]; then
        export CFLAGS="$CFLAGS -I/usr/pkg/include"
        export LDFLAGS="$LDFLAGS -L/usr/pkg/lib"
    fi

    if ($CC --version | grep -Fiqe "clang"); then
        frecord_gcc_switches_option=""
echo
    else
        # Try to compile a do-nothing program with -frecord-gcc-switches
        cc_accepts_frecord_switches=$(echo "#include \"stdio.h\"" | $CC $CPPFLAGS $CFLAGS -frecord-gcc-switches -dI -E -x c - 2>&1)
        cc_status=$?

        if [[ $cc_status -eq 0 ]]; then
            verbose_msg "C compiler accepts -frecord-gcc-switches"
            frecord_gcc_switches_option="CFLAGS=\"$CFLAGS -frecord-gcc-switches\""
        else
            verbose_msg "C compiler does not accept -frecord-gcc-switches"
            frecord_gcc_switches_option="CFLAGS=\"$CFLAGS\""
        fi
    fi

    # For FreeBSD / OpenBSD, Clang doesn't seem to know about /usr/local
    if [[ $os_version_id == freebsd*|| $os_version_id == openbsd* ]]; then
        export CFLAGS="$CFLAGS -I/usr/local/include"
        export LDFLAGS="$LDFLAGS -L/usr/local/lib"
    fi

    # For Apple Mac, we use the system libltdl rather than compiling our own
    # We dig out where to find this in the brew cellar/MacPorts and set
    # our environment vars.

    without_included_ltdl_option=""

    # split cases between Homebrew and MacPorts
#   if [[ $os_version_id == darwin* && "$(uname -m)" =~ ^arm64 ]]; then
    if [[ $os_version_id == darwin* && $opt_use_homebrew == true ]]; then
        without_included_ltdl_option="--without-included-ltdl"

        add_build_entry "export CFLAGS=\"\$CFLAGS -I\$(find \$(brew --cellar libtool) -type d -name \"include\" | sort -n | tail -n 1)\""
        add_build_entry "export LDFLAGS=\"\$LDFLAGS -L\$(find \$(brew --cellar libtool) -type d -name \"lib\" | sort -n | tail -n 1)\""
        export CFLAGS="$CFLAGS -I$(find $(brew --cellar libtool) -type d -name "include" | sort -n | tail -n 1)"
        export LDFLAGS="$LDFLAGS -L$(find $(brew --cellar libtool) -type d -name "lib" | sort -n | tail -n 1)"

#    elif [[ $os_version_id == darwin* && "$(uname -m)" =~ ^x86_64 ]]; then
    elif [[ $os_version_id == darwin* && $opt_use_macports == true ]]; then
        without_included_ltdl_option="--without-included-ltdl"

# bill@Bills-MacBook-Air-2 herctest % port contents libtool | grep \"ltdl.h\"
#
# This warning comes out on stderr, printed and not found by grep
# Warning: port definitions are more than two weeks old, consider updating them by running 'port selfupdate'.

        add_build_entry "export CFLAGS=\"\$CFLAGS -I\$(dirname \$(port contents libtool | grep \"ltdl.h\" | head -n 1))\""
        add_build_entry "export LDFLAGS=\"\$LDFLAGS -L\$(dirname \$(port contents libtool | grep \"libltdl.a\" | head -n 1))\""
        export CFLAGS="$CFLAGS -I$(dirname $(port contents libtool | grep "ltdl.h" | head -n 1))"
        export LDFLAGS="$LDFLAGS -L$(dirname $(port contents libtool | grep "libltdl.a" | head -n 1))"
    elif [[ $os_version_id == freebsd*|| $os_version_id == openbsd* ]]; then
        without_included_ltdl_option="--without-included-ltdl"
    else
        without_included_ltdl_option=""
    fi

    add_build_entry # newline
    add_build_entry "# Do an out-of-source build"
    add_build_entry "pushd \$opt_build_dir/$hercules_barename"
    add_build_entry "mkdir -p build"
    add_build_entry "cd build"

    # Do an out-of-source build
    pushd $opt_build_dir/$hercules_barename
    mkdir -p build
    cd build

    configure_cmd=$(cat <<-END-CONFIGURE
$frecord_gcc_switches_option ../configure \
    $opt_configure \
    $config_opt_optimization \
    --enable-extpkgs=$opt_build_dir/extpkgs \
    --prefix=$opt_install_dir \
    --enable-custom="Built using Hercules-Helper (version: $hercules_helper_version)" \
    $enable_regina_option \
    $enable_oorexx_option \
    $enable_ipv6_option \
    $enable_getoptwrapper_option \
    $without_included_ltdl_option
END-CONFIGURE
)

# Spit the command to our build log
add_build_entry # newline
add_build_entry "# Configure and build Hercules"
add_build_entry "$frecord_gcc_switches_option ../configure \\"
add_build_entry "    $opt_configure \\"
add_build_entry "    $config_opt_optimization \\"
add_build_entry "    --enable-extpkgs=\$opt_build_dir/extpkgs \\"
add_build_entry "    --prefix=\$opt_install_dir \\"
add_build_entry "    --enable-custom=\"Built using Hercules-Helper (version: $hercules_helper_version)\" \\"
add_build_entry "    $enable_regina_option \\"
add_build_entry "    $enable_oorexx_option \\"
add_build_entry "    $enable_ipv6_option \\"
add_build_entry "    $enable_getoptwrapper_option \\"
add_build_entry "    $without_included_ltdl_option"

    # Actually do the configure
    verbose_msg "CFLAGS=$CFLAGS"
    verbose_msg "LDFLAGS=$LDFLAGS"

    verbose_msg $configure_cmd
    verbose_msg    # output a newline
    eval "$configure_cmd"

    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        error_msg "configure failed!"
        exit 1
    fi

    # Print the configuration we wound up with
    add_build_entry # newline
    add_build_entry "./config.status --config"

    verbose_msg    # output a newline
    verbose_msg "./config.status --config ..."
    ./config.status --config

    add_build_entry "popd >/dev/null;"
    popd >/dev/null;
fi

# Clean, compile and link
verbose_msg "-----------------------------------------------------------------
"

add_build_entry "cd build"
cd build

# Use 1.5 times as many processes as CPUs unless there's low memory
# But limit to 4 maximum

if [[ $os_version_multicore_with_low_memory == true ]]; then
    nprocs="1"
elif [[ $os_version_id == freebsd* || $os_version_id == netbsd* || $os_version_id == openbsd* ||
        $os_version_id == darwin* ]];
then
    nprocs="$(sysctl -n hw.ncpu 2>/dev/null || echo 1)"
    nprocs=$(( $nprocs * 3 / 2))
else
    nprocs="$(nproc 2>/dev/null || echo 1)"
    nprocs=$(( $nprocs * 3 / 2))
fi

nprocs=$(($nprocs>4 ? 4: $nprocs))

# For FreeBSD, OpenBSD, and NetBSD, the BSD make acts up, so we'll use gmake.

if [[ $os_version_id == freebsd* || $os_version_id == openbsd* ||
      $os_version_id == netbsd*  ]]; then
    make_clean_cmd="gmake clean"
    make_cmd="time gmake -j $nprocs 2>&1"
else
    make_clean_cmd="make clean"
    make_cmd="time make -j $nprocs 2>&1"
fi

# make clean
if (! $dostep_clean); then
    verbose_msg "Skipping step: make clean (--no-clean)"
else
    status_prompter "Step: make clean:"

    verbose_msg "$make_clean_cmd"
    add_build_entry "$make_clean_cmd"
    eval "$make_clean_cmd"

    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        error_msg "Make clean failed!"
        exit 1
    fi
fi

verbose_msg "-----------------------------------------------------------------
"

if (! $dostep_make); then
    verbose_msg "Skipping step: make (--no-make)"
else
    status_prompter "Step: make -j $nprocs:"

    verbose_msg    # output a newline
    verbose_msg "$make_cmd"
    add_build_entry "$make_cmd"
    eval "$make_cmd"

    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        error_msg "Make failed!"
        exit 1
    fi
fi

verbose_msg "-----------------------------------------------------------------
"

if (! $dostep_tests); then
    verbose_msg "Skipping step: make check (--no-tests)"
else
    status_prompter "Step: tests:"
    verbose_msg "Be patient, this can take a while with no output."
    verbose_msg    # output a newline

    if [[ $os_version_id == freebsd* || $os_version_id == openbsd* ]]; then
        make_check_cmd="gmake check"
    else
        make_check_cmd="make check"
    fi

    # Also for FreeBSD, openSUSE, etc. we will try to detect low memory
    # conditions such as on a Raspberry Pi 3B, and skip the 'mainsize' test.

    verbose_msg "********************"
    verbose_msg "Memory size = $os_version_memory_size"
    verbose_msg "********************"
    verbose_msg    # output a newline

    if [ $os_version_memory_size -lt 2000 ]; then
        verbose_msg "System with low memory"
        verbose_msg "Skipping 'mainsize.tst'"
        verbose_msg    # output a newline

        if [ -f ../tests/mainsize.tst ]; then
            mv ../tests/mainsize.tst ../tests/mainsize.tst.skipped
        fi
    fi

    add_build_entry "time $make_check_cmd"
    eval "time $make_check_cmd"

    # time ./tests/runtest ./tests

    # "mainsize" test fails on Raspberry Pi 3B with FreeBSD 12.2
    # and FreeBSD kills the entire prodess since the system is out of memory.
    # And sometimes wedges up the entire system requiring the big red switch!

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
fi

verbose_msg "-----------------------------------------------------------------
"
if (! $dostep_install); then
    verbose_msg "Skipping step: install (--no-install)"
else
    if [[ $os_version_id == freebsd* || $os_version_id == openbsd* ]]; then
        make_install_cmd="time gmake install 2>&1"
    else
        make_install_cmd="time make install 2>&1"
    fi

    if ($opt_usesudo); then
        status_prompter "Step: install [with sudo]:"
        add_build_entry "\$HH_SUDOCMD $make_install_cmd"
        eval "$HH_SUDOCMD $make_install_cmd"
    else
        status_prompter "Step: install [without sudo]:"
        add_build_entry "$make_install_cmd"
        eval "$make_install_cmd"
    fi

    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        error_msg "Make install failed!"
        exit 1
    fi

    # sudo ldconfig
    if ($opt_usesudo); then
        if [[ "$version_distro" == "debian" ||
              "$version_distro" == "openSUSE" ||
              "$version_distro" == "almalinux" ||
              "$version_distro" == "rockylinux" ||
              "$version_distro" == "fedora" ]];
        then
            verbose_msg    # output a newline
            verbose_msg "sudo ldconfig"
            add_build_entry "# ldconfig"
            add_build_entry "\$HH_SUDOCMD ldconfig"
            $HH_SUDOCMD ldconfig || true
        fi

        if [[ "$version_distro" == "slackware" ]];
        then
            verbose_msg    # output a newline
            verbose_msg "sudo ldconfig"
            add_build_entry "# ldconfig"
            add_build_entry "\$HH_SUDOCMD /sbin/ldconfig"
            $HH_SUDOCMD /sbin/ldconfig || true
        fi
    fi

    verbose_msg "-----------------------------------------------------------------
    "

    if [[ $os_version_id == freebsd* || $os_version_id == netbsd* || $os_version_id == openbsd* ]]; then
        verbose_msg "Skipping step: setcap operations on FreeBSD/NetBSD/OpenBSD."

  # elif [[ $os_version_id == darwin* && "$(uname -m)" =~ ^arm64 ]]; then
    elif [[ $os_version_id == darwin* ]]; then
        verbose_msg "Skipping step: setcap operations on Apple macOS."

    elif [[ ! -z "$RPI_MODEL" && "$RPI_MODEL" =~ "Raspberry" && $RPI_CPUS = 1 ]]; then
        verbose_msg "Skipping step: setcap operations on Raspberry Pi with single CPU core."

    elif [[ "$os_name" == "GNU" ]]; then
        verbose_msg "Skipping step: setcap operations on GNU Hurd."

    elif (! $dostep_setcap); then
        verbose_msg "Skipping step: setcap (--no-setcap)"
    else
        verbose_msg "Step: setcap operations so Hercules can run without elevated privileges:"

        HH_SETCAP="setcap"
        if [[ "$version_distro" == "slackware" ]];
        then
            HH_SETCAP="/sbin/setcap"
        fi

        verbose_msg    # output a newline
        verbose_msg "sudo $HH_SETCAP 'cap_sys_nice=eip' $opt_install_dir/bin/hercules"
        add_build_entry "\$HH_SUDOCMD $HH_SETCAP 'cap_sys_nice=eip' $opt_install_dir/bin/hercules"
        $HH_SUDOCMD $HH_SETCAP 'cap_sys_nice=eip' $opt_install_dir/bin/hercules

        verbose_msg "sudo $HH_SETCAP 'cap_sys_nice=eip' $opt_install_dir/bin/herclin"
        add_build_entry "\$HH_SUDOCMD $HH_SETCAP 'cap_sys_nice=eip' $opt_install_dir/bin/herclin"
        $HH_SUDOCMD $HH_SETCAP 'cap_sys_nice=eip' $opt_install_dir/bin/herclin

        verbose_msg "sudo $HH_SETCAP 'cap_net_admin+ep' $opt_install_dir/bin/hercifc"
        add_build_entry "\$HH_SUDOCMD $HH_SETCAP 'cap_net_admin+ep' $opt_install_dir/bin/hercifc"
        $HH_SUDOCMD $HH_SETCAP 'cap_net_admin+ep' $opt_install_dir/bin/hercifc
    fi

    verbose_msg    # output a newline

    if (cc --version | grep -Fiqe "clang"); then
        verbose_msg "Clang: skipping readelf"
    else
        if ($opt_usesudo); then
            $HH_SUDOCMD readelf -p .GCC.command.line "$opt_install_dir/bin/hercules" | $HH_SUDOCMD tee "$opt_install_dir/hercules-gcc-options.txt" > /dev/null
            add_build_entry "\$HH_SUDOCMD readelf -p .GCC.command.line $opt_install_dir/bin/hercules | \$HH_SUDOCMD tee $opt_install_dir/hercules-gcc-options.txt > /dev/null"
        else
            readelf -p .GCC.command.line "$opt_install_dir/bin/hercules" > "$opt_install_dir/hercules-gcc-options.txt"
            add_build_entry "readelf -p .GCC.command.line $opt_install_dir/bin/hercules > $opt_install_dir/hercules-gcc-options.txt"
        fi
    fi
fi

verbose_msg "-----------------------------------------------------------------
"

end_time=$(date)
verbose_msg "Overall build processing ended:   $end_time"

# FIXME macOS
# elapsed_seconds="$(( $(TZ=UTC0 printf '%(%s)T\n' '-1') - start_seconds ))"
elapsed_seconds="$(( $(date +%s) - start_seconds ))"
verbose_msg "Total elapsed seconds: $elapsed_seconds"

if ((BASH_VERSINFO[0] >= 4)); then
    verbose_msg "Overall elpased time: $( TZ=UTC0 printf '%(%H:%M:%S)T\n' "$elapsed_seconds" )"
fi
verbose_msg    # output a newline

if (! $dostep_install || ! $dostep_envscript); then
    verbose_msg "Skipping step: create environment variables script (--no-envscript)"
else
    status_prompter "Step: create script to set environment variables [may require sudo]:"

    # shell=$(/usr/bin/basename $(ps -p $$ -ocomm=))
    # ps on macOS adds a - to login shells
    # foo=$(ps -p $$ -ocomm=)
    # shell="${foo//-/}"
    shell="$(basename "$SHELL")"

    cat <<FOE >"TEMP-$hercules_barename-init-$shell.sh"
#
# Set up environment variables for Hercules
#
# This script was created by $0, $(date)
#

# LD_LIBRARY_PATH is often empty, and we don't want to error out on that
set +u

echo "Setting environment variables for Hercules"

newpath="$opt_install_dir/bin"
if [ -d "\$newpath" ] && [[ ":\$PATH:" != *":\$newpath:"* ]]; then
  # export PATH="\${PATH:+"\$PATH:"}\$newpath"
    export PATH="\$newpath\${PATH:+":\$PATH"}"
fi

newpath="$opt_install_dir/lib"
if [ -d "\$newpath" ] && [[ ":\$LD_LIBRARY_PATH:" != *":\$newpath:"* ]]; then
  # export LD_LIBRARY_PATH="\${LD_LIBRARY_PATH:+"\$LD_LIBRARY_PATH:"}\$newpath"
    export LD_LIBRARY_PATH="\$newpath\${LD_LIBRARY_PATH:+":\$LD_LIBRARY_PATH"}"
fi

FOE
# end of inline "here" file

#if [[ "$built_regina_from_source" -eq 1 ]]; then
#    cat <<FOE2 >>"$opt_install_dir/$hercules_barename-init-$shell.sh"
#newpath="$opt_build_dir/rexx/bin"
#if [ -d "\$newpath" ] && [[ ":\$PATH:" != *":\$newpath:"* ]]; then
#  # export PATH="\${PATH:+"\$PATH:"}\$newpath"
#    export PATH="\$newpath\${PATH:+":\$PATH"}"
#fi
#
#newpath="$opt_build_dir/rexx/lib"
#if [ -d "\$newpath" ] && [[ ":\$LD_LIBRARY_PATH:" != *":\$newpath:"* ]]; then
#  # export LD_LIBRARY_PATH="\${LD_LIBRARY_PATH:+"\$LD_LIBRARY_PATH:"}\$newpath"
#    export LD_LIBRARY_PATH="\$newpath\${LD_LIBRARY_PATH:+":\$LD_LIBRARY_PATH"}"
#fi
#
#newpath="$opt_build_dir/rexx/include"
#if [ -d "\$newpath" ] && [[ ":\$CPPFLAGS:" != *":-I\$newpath:"* ]]; then
#  # export CPPFLAGS="\${CPPFLAGS:+"\$CPPFLAGS:"}-I\$newpath"
#    export CPPFLAGS="-I\$newpath\${CPPFLAGS:+" \$CPPFLAGS"}"
#fi
#FOE2
# end of inline "here" file
#fi

    chmod +x "TEMP-$hercules_barename-init-$shell.sh"
    if ($opt_usesudo); then
        $HH_SUDOCMD mv "TEMP-$hercules_barename-init-$shell.sh" "$opt_install_dir/$hercules_barename-init-$shell.sh"
    else
        mv "TEMP-$hercules_barename-init-$shell.sh" "$opt_install_dir/$hercules_barename-init-$shell.sh"
    fi

    source "$opt_install_dir/$hercules_barename-init-$shell.sh"
    verbose_msg "Created: $opt_install_dir/$hercules_barename-init-$shell.sh"

#   echo "To set the required environment variables, run:"
#   echo "    source $opt_build_dir/hercules-setvars.sh"
fi

if ($dostep_bashrc); then
  verbose_msg "-----------------------------------------------------------------
"
    # shell=$(/usr/bin/basename $(ps -p $$ -ocomm=))
    # ps on macOS adds a - to login shells
    # foo=$(ps -p $$ -ocomm=)
    # shell="${foo//-/}"
    shell="$(basename "$SHELL")"
    profile_name=".$(basename "$SHELL")rc"

    status_prompter "Step: add 'source' environment variables to $profile_name profile:"

    if true; then # available for future system specific inclusion
        # Only do this for Bash and Zsh
        if [[ $shell != "bash" && $shell != "zsh" ]]; then
            error_msg "Login shell ($shell) is not yet supported.  Unable to create profile commands."

        elif [[ $shell == "bash" && ! -f ~/.bashrc ]]; then # Check for .bashrc existing first!
            error_msg "Not adding environment variables to ~/.bashrc. File not found."
        elif [[ $shell == "zsh" && ! -f ~/.zshrc ]]; then # Check for .zshrc existing first!
            error_msg "Not adding environment variables to ~/.ashrc. File not found."
        else
            # Add .../$hercules_barename-init-bash.sh to ~/.bashrc if not already present
            if grep -Eqe "^\. $opt_install_dir/$hercules_barename-init-$shell.sh" ~/$profile_name ; then
                note_msg "The same Hercules profile commands are already present in your ~/$profile_name. Skipping"
            else
		if grep -Fqe "$hercules_barename-init-$shell.sh" ~/$profile_name ; then
		    # FIXME create beep() function
		    echo -ne '\a'; sleep 0.2; echo -ne '\a'
		    note_msg " "
		    note_msg "Different Hercules profile commands are already present in your ~/$profile_name"
		    note_msg "Please examine your ~/$profile_name carefully"
		    note_msg " "
		    echo   # output a newline
                fi

                verbose_msg "Adding Hercules profile commands to your ~/$profile_name"
                cat <<-BASHRC >> ~/$profile_name

# For Hercules
if [ -f $opt_install_dir/$hercules_barename-init-$shell.sh ]; then
. $opt_install_dir/$hercules_barename-init-$shell.sh
fi

BASHRC
# end of inline "here" file
            fi # if commands not already present
        fi # if bash
    fi # if true
fi # if (! $dostep_bashrc)
     
#-----------------------------------------------------------------------------

if (! $opt_no_install && ! $opt_no_bashrc); then
    if [[ $shell == "bash" && -f ~/.bashrc || 
          $shell == "zsh"  && -f ~/.zshrc     ]]; then # Check for profile existing first!
      if [ -f $opt_install_dir/$hercules_barename-init-$shell.sh ]; then
        echo   # output a newline
        echo "To make this new Hercules immediately available, run:"
        echo "(note the '.', which will \"source\" the script)"
        echo   # output a newline
        echo "  . $opt_install_dir/$hercules_barename-init-$shell.sh"
      fi
    fi
fi

verbose_msg "Done!"

add_build_entry "cd \$opwd"

} # End of I/O redirection function
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

