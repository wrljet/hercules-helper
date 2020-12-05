# Hercules-Helper

Utility scripts to help with building and deploying the Hercules emulator

These scripts extend the existing functionality of SDL-Hercules-390 gists/extpkgs.

This is a temporary testbed and will be updated occassionally and/or merged
into SDL-Hercules-390 and its documentation when completed.

The most recent version of this script can be obtained with:
```
   git clone https://github.com/wrljet/hercules-helper.git
```
or:
```
   wget https://github.com/wrljet/hercules-helper/archive/master.zip
```

You will have to mark the bash scripts as executable before running them.

Please don't run this process as root.  The scripts will prompt for your
sudo password where required.

Report errors in this to me so everyone can benefit.

## hyperion-prepare.sh

This script will prepare a Linux system by installing the required
development tool packages.

Be sure to run hyperion-prepare.sh one time before the buildall script.

## hyperion-buildall.sh

This script will perform a complete build of Hercules and its external
packages, plus Regina Rexx, run all the automated tests, and optionally install.

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
$ chmod +x ~/hercules-helper/*.sh

$ ~/hercules-helper/hyperion-prepare.sh

$ mkdir herctest && cd herctest
$ ~/hercules-helper/hyperion-buildall.sh -verbose --prompts --install 2>&1 | tee ./hyperion-buildall.log
```

