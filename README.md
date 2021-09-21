# Hercules-Helper

Utility scripts to help with building and deploying the Hercules emulator

For Windows, go [here](https://github.com/wrljet/hercules-helper-windows)

These scripts extend the existing functionality of SDL-Hercules-390 gists/extpkgs.

This is a testbed and will be updated occassionally and/or merged
into SDL-Hercules-390 and its documentation when completed.

The most recent version of this project can be obtained with:
```
   git clone https://github.com/wrljet/hercules-helper.git
```
or, if you don't have git, or simply prefer:
```
   wget https://github.com/wrljet/hercules-helper/archive/master.zip
```

You shouldn't have to mark the bash scripts as executable before running them.
They hopefully will clone ready to run.

Please don't run this process as root.  That can be damaging.
These scripts will prompt for your sudo password where required.

Report errors in this to me so everyone can benefit.

## hyperion-buildall.sh

This script will perform a complete build of Hercules and its external
packages, plus Regina REXX (if no existing REXX is found), run all the
automated tests, and optionally install.

If you already have REXX installed, you will need to have the development
package installed as well, so the build process will have access to the
header files and link libraries.

For example, if you installed Regina REXX, on Debian/Ubuntu/etc
you will also need:


```
sudo apt install libregina3-dev

```

```
Usage: hyperion-buildall.sh [OPTIONS]

Perform a full build, test, and installation of SDL-Hercules-390 Hyperion from GitHub sources

Options:
  -h,  --help         print this help
  -t,  --trace        print every command (set -x)
  -v,  --verbose      print lots of messages
  -p,  --prompts      print a prompt before each major step
  -c,  --config=FILE  specify config file containing options
  -s,  --sudo         use \'sudo\' for installing
  -a,  --auto         run everything, with --verbose and --prompts,
                      and creating a full log file
       --homebrew     assume Homebrew package manager on MacOS
       --macports     assume MacPorts package manager on MacOS

Sub-functions (in order of operation):
       --detect-only  run detection only and exit
       --no-packages  skip installing required packages
       --no-rexx      skip building Regina REXX
       --no-gitclone  skip \'git clone\' steps
       --no-bldlvlck  skip \'util/bldlvlck\' steps
       --no-extpkgs   skip building Hercules external packages
       --no-autogen   skip running \'autogen\'
       --no-configure skip running \'configure\'
       --no-clean     skip running \'make clean\'
       --no-make      skip running \'make\'
       --no-tests     skip running \'make check\'
       --no-install   skip \'make install\' after building
       --no-setcap    skip running \'setcap\'
       --no-envscript skip creating script to set environment variables
       --no-bashrc    skip modifying .bashrc to set environment variables

Email bug reports, questions, etc. to <bill@wrljet.com>
```

To use, create a build directory and cd to it, then run this script.
First timers, it is recommended to use the --auto option.

In these examples below, it assumes you cloned the repo into your
home directory, i.e. ~/hercules-helper.  And that you are using
~/herctest as the build directory.  Please adjust the directories
below to suit your actual setup.

The full process is:

```
$ cd ~
$ git clone https://github.com/wrljet/hercules-helper.git
$ mkdir herctest && cd herctest
$
$ ~/hercules-helper/hyperion-buildall.sh --auto
```

Or for your first run, for finer control:
```
$ ~/hercules-helper/hyperion-buildall.sh --verbose --prompts
```

On MacOS, either Homebrew or MacPorts may be used.
Supply either the --homebrew or --macports option accordingly.

For MacOS and Homebrew, be sure /opt/homebrew/bin appears at the front of your
search PATH, so newer packages from Brew override older defaults from MacOS or
the Xcode command line tools. (this may only be a requirement for Apple M1
silicon -- to be determined)

If packages need to be installed you may be asked to supply your sudo password.

You will be prompted a number of times between the major steps, to give you a chance
to see the results of the last step, and to clue you into what will be happening next.

Hercules will be "installed" (unless you include the ---no-install option), defaulting
into ~/herctest/herc4x

To set the required environment variables after installation, a script will be added
to ~/herctest/herc4x/hyperion-init-bash.sh.  This will be "sourced" from ~/.bashrc.
(currently this is for Bash only)

To make the newly created Hercules available immediately in the current shell
or terminal session, simply source this script with the '.' command:

```
. ~/herctest/herc4x/hyperion-init-bash.sh
```

If anything seems to go wrong, please stop and ask questions at that point.
Your repair attempts may destroy evidence that would be useful in improving
this process for others.

Enjoy!

