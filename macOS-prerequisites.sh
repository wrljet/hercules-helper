#!/usr/bin/env bash

echo "
The Hercules build process will require a number of basic tools and
packages which are not installed by default on MacOS.  This script
will attempt to determine if they are missing, and install them
automatically.

These are:
 - Xcode command line tools
 - HomeBrew package manager

You may be asked to supply your sudo password.

Press Ctrl+C at any prompt if you wish to quit the process.

"

uname -a

uname_system="$( (uname -s) 2>/dev/null)" || uname_system="unknown"

    if [ "$uname_system" == "Darwin" ]; then
        version_distro="darwin"
    fi

        version_id="darwin"

        # version_str=$(uname -r)
        version_str=$(sw_vers -productVersion)

        echo "VERSION_ID       : $version_id"
        echo "VERSION_STR      : $version_str"

        version_major=$(echo $version_str | cut -f1 -d.)
          echo "VERSION_MAJOR    : $version_major"
        version_minor=$(echo $version_str | cut -f2 -d.)
          echo "VERSION_MINOR    : $version_minor"
        version_build=$(echo $version_str | cut -f3 -d.)
          echo "VERSION_BUILD    : $version_build"

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
          echo "Apple macOS version $version_str (Big Sur) found"
      else
          os_is_supported=false
          echo "Apple macOS version $version_major.$version_minor found, is unsupported"
      fi
echo    # print a newline

echo "Checking for Xcode command line tools"
xcode-select -p 2>/dev/null
if [[ $? == 2 ]] ; then
    echo "Requesting installation of Xcode command line tools"
    read -p "Hit return to continue (Ctrl+C to abort)"

    xcode-select --install
else
    echo "Command line tools are installed"
fi
echo    # print a newline

which -s brew
if [[ $? != 0 ]] ; then
    echo "Installing Homebrew"
    read -p "Hit return to continue (Ctrl+C to abort)"

    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    echo "Updating Homebrew"
    read -p "Hit return to continue (Ctrl+C to abort)"

    brew update
fi
echo    # print a newline

# Install Bash 4 if desired
if false ; then
    if ((BASH_VERSINFO[0] >= 4)); then
        echo "Bash version 4+ is already installed"
    else
        echo "Bash version 4+ is required"
    fi

    echo "Installing Bash via Homebrew"
    read -p "Hit return to continue (Ctrl+C to abort)"

    brew install bash
    sudo bash -c 'echo /usr/local/bin/bash >> /etc/shells'
    chsh -s /usr/local/bin/bash
    ln -s /usr/local/bin/bash /usr/local/bin/bash-terminal-app
    which -a bash
fi

