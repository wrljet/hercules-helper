# Hercules-Helper

Utility scripts to help with building and deploying the Hercules emulator

The current hardened workflow uses checksum-verified source archives and exact
Git commits for Hercules and its external packages. See
[`DEPENDENCIES.md`](DEPENDENCIES.md) for the maintained source identities.

For Windows, go [here](https://github.com/wrljet/hercules-helper-windows)

The most recent version of this project can be obtained with:
```
   git clone https://github.com/wrljet/hercules-helper.git
```
or, if you don't have git, or simply prefer:
```
   wget https://github.com/wrljet/hercules-helper/archive/master.zip
```

Please read everything before doing anything.

You shouldn't have to mark the bash scripts as executable before running them.
They hopefully will clone ready to run.

Please don't run this process as root.  That can be damaging.
These scripts will prompt for your sudo password where required.

Report errors in this to me so everyone can benefit.

By default, this builds the SDL Hyperion flavor selected by
`hercules-helper.conf`. You may select Aethra with `--flavor=aethra`, select
SDL Hyperion explicitly with `--flavor=sdl-hyperion`, or supply `--config=FILE`.

## hercules-buildall.sh

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
Usage: hercules-buildall.sh [OPTIONS]

Perform a full build, test, and installation of Hercules 4 from GitHub sources

Options:
  -h,  --help         print this help
  -t,  --trace        print every command (set -x)
  -v,  --verbose      print lots of messages
       --version      prints version info and exits
       --flavor=      specify major flavor: aethra, sdl-hyperion, etc.
       --git-branch=  specify repo branch to checkout
       --git-commit=  specify repo commit to checkout
       --beeps        beep at each prompt
  -p,  --prompts      print a prompt before each major step
       --config=FILE  specify config file containing options
  -s,  --sudo         use 'sudo' for installing
       --askpass      use 'sudo -A' askpass helper
       --accept-root  accept running as root user
  -a,  --auto         run everything, with --verbose (but not --prompts),
                      and create a full log file (this is the default)
       --homebrew     assume Homebrew package manager on MacOS
       --macports     assume MacPorts package manager on MacOS
       --force-pi     process for a Raspberry Pi (even if not auto-detected)
       --prefix       installation dir prefix for configure

Sub-functions (in order of operation):
       --detect-only  run detection only and exit
       --no-packages  skip installing required packages
       --no-rexx      skip building Regina REXX, and no REXX support in Hercules
       --no-gitclone  skip 'git clone' steps
       --no-bldlvlck  skip 'util/bldlvlck' steps
       --no-extpkgs   skip building Hercules external packages
       --autogen      run 'autoreconf' and 'autogen'
       --no-autogen   skip running 'autogen'
       --no-configure skip running 'configure'
       --no-clean     skip running 'make clean'
       --no-make      skip running 'make'
       --no-tests     skip running 'make check'
       --no-install   skip 'make install' after building
       --no-setcap    skip running 'setcap'
       --no-envscript skip creating script to set environment variables
       --no-bashrc    skip modifying .bashrc to set environment variables

Email bug reports, questions, etc. to <bill@wrljet.com>
```

To use, create a build directory and cd to it, then run this script.
First timers, it is recommended to use the `--auto` option.

`--auto` is noninteractive. On macOS it will not invoke an interactive Regina
installer when Regina is missing or unusable. Install Regina first, set
`HERCULES_REGINA_PREFIX` to its prefix, or use `--no-rexx`.

Note, while it works, it is not recommended to build directly into
the directory you've cloned Hercules-Helper into.

_In these examples below, it assumes you cloned the repo into your
home directory, i.e. ~/hercules-helper.  And, that you are using
~/herctest as the build directory.  Please adjust the directories
below to suit your actual setup._

The full process is:

```
$ cd ~
$ git clone https://github.com/wrljet/hercules-helper.git
$ mkdir herctest && cd herctest
$
$ ~/hercules-helper/hercules-buildall.sh --auto
```

Or for your first run, for finer control:
```
$ ~/hercules-helper/hercules-buildall.sh --verbose --prompts
```

To control where Hercules is installed, use the `--prefix=` switch.
Such as:
```
--prefix=/usr/local/hercules
```

You may build Hercules from either Fish's SDL-Hercules-390 or Jay Maynard's Aethra repo
using the `--flavor=` switch.

```
--flavor=aethra
```
or
```
--flavor=sdl-hyperion
```

`--flavor` will select from a canned config for the repo selected.
Some directory and filenames will be altered to "aethra" vs "hyperion"

For finer control of what gets built, you can use:

```
--git-branch=
```
and/or
```
--git-commit=
```

Use a full immutable commit, for example
`--git-branch=develop --git-commit=5744d9b216a3dc38f6c4f96849b1eb94abe7a6c6`.

You can still use the `--config=` to point to a local config for fine tuning.

On MacOS, either Homebrew or MacPorts may be used.
Supply either the `--homebrew` or `--macports` option accordingly.

### Regina REXX on macOS

The build detects a custom Regina installation through `regina-config`. Set
`HERCULES_REGINA_PREFIX` if that command is not already on `PATH`:

```bash
export HERCULES_REGINA_PREFIX="$HOME/.local/regina-3.9.7"
./hercules-buildall.sh --auto --homebrew --flavor=sdl-hyperion
```

The standalone installer builds the verified Regina 3.9.7 source into a
user-owned prefix by default:

```bash
./helper-build-regina.sh --yes
```

Regina is intentionally compiled serially because its upstream Makefile has
object-renaming races under parallel `make`.

During `make check` on macOS, Helper temporarily exposes `libregina.dylib` in
Hyperion's libtool `.libs` directory. This prevents the protected `/bin/sh`
test-launch boundary from incorrectly skipping testcase 3211. The temporary
link is removed after the test run.

### Operational safeguards

- Remote archives require a maintained SHA-256 value before extraction.
- Hercules and external-package checkouts are detached at exact commits.
- Package helpers install named prerequisites only; they do not perform broad
  Homebrew, Alpine, or openSUSE upgrades.
- Archive members and links are checked before extraction.
- Recursive cleanup is constrained to the selected build workspace.
- Extra configure/CMake option strings reject shell control syntax.
- `--accept-root` is recognized only as an exact command-line option.

Custom configurations must provide matching `opt_regina_sha256`,
`git_commit_hercules`, and all four `git_commit_extpkg_*` values. Updating a
dependency is therefore an explicit lock update, not an implicit branch move.

The legacy Debian Hyperion 4.4 packager is retired because its package template
is absent and its original implementation depended on unsafe dynamic command
execution and fixed local paths.

For MacOS and Homebrew, be sure /opt/homebrew/bin appears at the front of your
search PATH, so newer packages from Brew override older defaults from MacOS or
the Xcode command line tools. (this may only be a requirement for Apple M1
silicon -- to be determined)

If packages need to be installed you may be asked to supply your sudo password.

You will be prompted a number of times between the major steps, to give you a chance
to see the results of the last step, and to clue you into what will be happening next.

For Raspberry Pi Desktop on a x86_64 PC, prefix the command with `linux32`, for example:
```
$ linux32 ~/hercules-helper/hercules-buildall.sh --verbose --prompts
```

Hercules will be "installed" (unless you include the --no-install option), defaulting
into ~/herctest/herc4x

To set the required environment variables after installation, a script will be added
to ~/herctest/herc4x/hyperion-init-bash.sh.  This will be "sourced" from ~/.bashrc, or
~/.zshrc, depending on your shell.  (currently this is for Bash and Zsh only)

To make the newly created Hercules available immediately in the current shell
or terminal session, simply source this script with the '.' command.  For example:

```
. ~/herctest/herc4x/hyperion-init-bash.sh
```
  or

```
. ~/herctest/herc4x/hyperion-init-zsh.sh
```

If anything seems to go wrong, please stop and ask questions at that point.
Your repair attempts may destroy evidence that would be useful in improving
this process for others.

Enjoy!
