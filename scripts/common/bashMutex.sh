#!/bin/sh

#=====================================================================
# BASH SCRIPTS - MUTEX in BASH
# Benoit Scherrer, CRL, 2014
# VERSION: 1.0.0 - 10/29/2014
#---------------------------------------------------------------------
# Define functions to lock/unlock mutexes using mkdir 
# (mkdir provides an atomic way to test wheter a folder exists, and
#  creates this folder if not)
#=====================================================================



#==========================================================
# MUTEX - lock mechanism
#
# INPUT
# 	$1 : file to lock
# 	$2 : If set, define the number of seconds to wait (by default: infinite)
#
# RETURN: 	0 = no error
#		1 = the folder must exists
#		2 = cannot lock the file
#==========================================================
function mutexLockFile()
{
  #------------------------------------------------
  # We can't use mkdir -p  do be sure the parent folder exists
  #------------------------------------------------
  local foldername=`dirname "$1"`
  if [[ ! -d "$foldername" ]]; then
    echo "!! FATAL ERROR in mutexLockFile !!"
    echo "Folder $foldername does not exists."
    echo "Cannot lock the file"
    return 1
  fi

  #------------------------------------------------
  # Determine folder name for mutex
  #------------------------------------------------
  local lockdir="$1.mutex.lock"
  lockdir=`readlink -f "$lockdir"`

  #------------------------------------------------
  # Initialize number of seconds to wait
  #------------------------------------------------
  local maxtests=-1;
  if [[ ! -z "$2" ]] && [[ $2 -ge 0 ]]; then
    maxtests=$(($2+1))
  fi
  

  #------------------------------------------------
  # Test the mutex! mkdir returns 0 if no error 
  #------------------------------------------------
  mkdir "$lockdir" 2>/dev/null 
  while [[ $? -eq 1 ]]
  do
    #----------------------------------------
    # If not successful, wait a little?
    #----------------------------------------
    echo "Cannot get mutex on $lockdir"
    maxtests=$((maxtests-1))
    if [[ $maxtests -eq 0 ]]; then
      echo "ERROR. Cannot get the mutex."
      echo "Return with error code"
      return 2
    fi 

    #----------------------------------------
    # If needed, wait
    #----------------------------------------
    sleep 1s
    mkdir "$lockdir" 2>/dev/null 
  done

  #------------------------------------------------
  # Here we successfully got the mutex
  #------------------------------------------------
  #echo "Successfully acquired mutex $lockdir"
  
  #------------------------------------------------
  # Remove the lock when the script finishes or when it receveives a signal
  # (e.g., Crtl+C)
  # ok no risk that we do 'rm -rf *'
  #------------------------------------------------
 # trap "echo 'Delete mutex $lockdir'; rm -rf '$lockdir'" 0
  trap "rm -rf '$lockdir'" 0
  return 0
}

#==========================================================
# MUTEX - unlock mechanism
#
# $1 : file to unlock
#==========================================================
function mutexUnlockFile()
{
  local lockdir="$1.mutex.lock"

  if [[ -d "$lockdir" ]]; then
    rm -rf "$lockdir"
  fi
}

