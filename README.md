# Hercules-Helper

Utility scripts to help with building and deploying the Hercules emulator

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

## hyperion-prepare.sh

hyperion-prepare.sh is deprecated.  Its functionality has been merged
into hyperion-buildall.sh.

## hyperion-buildall.sh

This script will perform a complete build of Hercules and its external
packages, plus Regina REXX (if no existing REXX is found), run all the
automated tests, and optionally install.

```
usage: hyperion-buildall.sh [-h|--help] [-t|--trace] [-v|--verbose] [--no-packages] [--no-install] [--sudo]

Perform a full build, test, and installation of Hercules Hyperion from GitHub sources

where:
  -h, --help      display this help
  -t, --trace     display every command (set -x)
  -v, --verbose   display lots of messages
  -p, --prompts   display a prompt before each major step
      --no-packages  skip checking for and installing required packages
      --no-install   skip \'make install\' after building
  -s, --sudo      use \'sudo\' for installing"
```

To use, create a build directory and cd to it, then run this script.
It is recommended to use the --verbose and --prompts options.

Tee-ing the output to a log file will help track down problems.
Addition separate log files for major steps will be created automatically.

The full process is:

```
$ cd ~
$ git clone https://github.com/wrljet/hercules-helper.git
$ mkdir herctest && cd herctest
$ ~/hercules-helper/hyperion-buildall.sh -verbose --prompts 2>&1 | tee ./hyperion-buildall.log
```

If packages need to be installed you may be asked to supply your sudo password.

You will be prompted a number of times between the major steps, to give you a chance
to see the results of the last step, and to clue you into what will be happening next.

Hercules will be "installed" (unless you include the ---no-install option), defaulting
into ~/herctest/herc4x

To set the required environment variables after installation, a script will be added
to /etc/profile.d.  It will be "sourced" from ~/.bashrc.
(currently this is for Bash only)

If anything seems to go wrong, please stop and ask questions at that point.
Your repair attempts may destroy evidence that would be useful in improving
this process for others.

Enjoy!

