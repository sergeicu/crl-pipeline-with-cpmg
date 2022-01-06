#!/bin/sh

if [ $# -ne 1 ]; then
  echo "----------------------------------------------------------"
  echo " Creates a /scripts subfolder, and copy the pipeline"
  echo " scripts into it."
  echo 
  echo " (c) CRL, Benoit Scherrer, 2011"
  echo "     benoit.scherrer@childrens.harvard.edu"
  echo "----------------------------------------------------------"
  echo "SYNTAX: CopyScripts [subject folder]"
  echo
  exit 1
fi

if [ ! -d "$1" ]; then
  echo "ERROR. The directory $1 does not exist."
  exit 1
fi

SRCDIR="`dirname $0`"

rsync -a --exclude=.svn $SRCDIR/ $1/scripts/

exit 0
