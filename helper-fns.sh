#!/usr/bin/env bash

# Hercules-Helper utility functions
# Updated: 16 DEC 2021
#
# The most recent version of this project can be obtained with:
#   git clone https://github.com/wrljet/hercules-helper.git
# or:
#   wget https://github.com/wrljet/hercules-helper/archive/master.zip
#
# Please report errors in this to me so everyone can benefit.
#
# Bill Lewis  bill@wrljet.com


#------------------------------------------------------------------------------
#                               verbose_msg
#------------------------------------------------------------------------------
verbose_msg()
{
    if ($opt_verbose); then
        echo "$@"
    fi
}

#------------------------------------------------------------------------------
#                               ANSI escape codes
#------------------------------------------------------------------------------
# Black        0;30     Dark Gray     1;30
# Red          0;31     Light Red     1;31
# Green        0;32     Light Green   1;32
# Brown/Orange 0;33     Yellow        1;33
# Blue         0;34     Light Blue    1;34
# Purple       0;35     Light Purple  1;35
# Cyan         0;36     Light Cyan    1;36
# Light Gray   0;37     White         1;37
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
#                               error_msg
#------------------------------------------------------------------------------
error_msg()
{
#   printf "\033[1;37m[[ \033[1;31merror: \033[1;37m]] \033[0m$1\n"
    printf "\033[1;31m[[ error: ]] \033[0m$1\n"
}

#------------------------------------------------------------------------------
#                               note_msg
#------------------------------------------------------------------------------
note_msg()
{
    printf "\033[0;32m[[ note: ]] \033[0m$1\n"
}

#------------------------------------------------------------------------------
#                               trace_msg
#------------------------------------------------------------------------------
trace_msg()
{
  if [ -n $debug ]  || \
     [ -n $DEBUG ]; then
    echo  "++ $1"
  fi
}

#------------------------------------------------------------------------------
#                               set_yes_or_no
#------------------------------------------------------------------------------
yes_or_no="no"

set_yes_or_no()
{
    if ($1 == true); then
        yes_or_no="yes"
    else
        yes_or_no="no "
    fi
}

#------------------------------------------------------------------------------
#                              confirm
#------------------------------------------------------------------------------
confirm() {
    # call with a prompt string or use a default
    read -r -p "${1:-Are you sure? [y/N]} " response
    case "$response" in
        [yY][eE][sS]|[yY])
            true
            ;;
        *)
            false
            ;;
    esac
}

#------------------------------------------------------------------------------
#                               status_prompter
#------------------------------------------------------------------------------

# called with:
#   status_prompter "Step: Create shell profile."

status_prompter()
{
    if ($opt_prompts); then
        read -p "$1  Hit return to continue"
    else
        echo "$1"
    fi

    echo   # output a newline
}

#------------------------------------------------------------------------------
#                               echo_and_run
#------------------------------------------------------------------------------

echo_and_run() { echo "\$ $@" ; eval "$@" ; }
