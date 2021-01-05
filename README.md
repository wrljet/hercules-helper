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

This script will prepare a Linux system by installing the required
development tool packages.

Be sure to run hyperion-prepare.sh one time before the buildall script.

## hyperion-buildall.sh

This script will perform a complete build of Hercules and its external
packages, plus Regina REXX (if no existing REXX is found), run all the
automated tests, and optionally install.

```
usage="usage: $(basename "$0") [-h|--help] [-t|--trace] [-v|--verbose] [--install] [--sudo]

Perform a full build, test, and installation of Hercules Hyperion from GitHub sources

where:
  -h, --help      display this help
  -t, --trace     display every command (set -x)
  -v, --verbose   display lots of messages
  -p, --prompts   display a prompt before each major step
  -i, --install   run \'make install\' after building
  -s, --sudo      use \'sudo\' for installing"
```

To use, create a build directory and cd to it, then run this script.
It is recommended to use the --verbose, --prompts, and --install options.

Teeing the output to a log file will help track down problems.
Addition separate log files for major steps will be created automatically.

The full process is:

```
$ cd ~
$ git clone https://github.com/wrljet/hercules-helper.git

$ ~/hercules-helper/hyperion-prepare.sh

$ mkdir herctest && cd herctest
$ ~/hercules-helper/hyperion-buildall.sh -verbose --prompts --install 2>&1 | tee ./hyperion-buildall.log
```

If packages need to be installed you may be asked to supply your sudo password.

You will be prompted a number of times between the major steps, to give you a chance
to see the results of the last step, and to clue you into what will be happening next.

Hercules will be "installed" if you include the --install option as shown above, defaulting
into ~/herctest/herc4x

To set the required environment variables after installation, a script will be added
to /etc/profile.d.  It will be "sourced" from ~/.bashrc.
(currently this is for Bash only)

If anything seems to go wrong, please stop and ask questions at that point.
Your repair attempts may destroy evidence that would be useful in improving this process for others.

Enjoy!

