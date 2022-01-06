#!/bin/sh

if [ $# -lt 1 ]; then
  echo "----------------------------------------------------------"
  echo " Install the pipeline for a new single subject directory"
  echo " It will copy the scripts and prepare everything"
  echo " to run the pipeline"
  echo 
  echo " (c) CRL, Benoit Scherrer, 2011"
  echo "     benoit.scherrer@childrens.harvard.edu"
  echo "----------------------------------------------------------"
  echo "SYNTAX: install_pipeline [DestProcessedDir] [[DataForAnalysisDir]]"
  echo
  exit 1
fi

# LOCAL scripts with a different CUSP processing
SRC_SCRIPT=`dirname $0`
SRC_SCRIPT=`readlink -f "${SRC_SCRIPT}"`

if [[ ! -z "$2" ]]; then
  dfadir=`readlink -f "$2"`
else
  dfadir=""
fi


umask 002

mkdir -p "$1"
cd "$1"
mkdir -p scripts
mkdir -p common-processed

#chmod +t common-processed

sh ${SRC_SCRIPT}/CopyScripts.sh .
sh ${SRC_SCRIPT}/common/InstallPipelineForOneSubject.sh . $dfadir

