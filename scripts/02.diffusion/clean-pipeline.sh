#!/bin/sh

#=================================================================
# DIFFUSION ANALYSIS PIPELINE - CLEAN SCRIPT
# Benoit Scherrer, CRL, 2011
#-----------------------------------------------------------------
# 
#=================================================================

doClean()
{
  folder="$1"

  echo "- Clean $folder"

  rm -rf "${folder}/01-motioncorrection/tmp"
  rm -rf "${folder}/02-artifactcorrection/tmp"
  rm -rf "${folder}/03-dwi2t1w_registration/tmp"
}


#------------------------------------------
# Load the scan informations, the cache manager, prepare the prefix, etc...
# After the file is sourced, we are in the folder 
# "$ScanProcessedDir/common-processed"
#------------------------------------------
prevdir=`pwd`
source "`dirname $0`/../../ScanInfo.sh" || exit 1
source $ScriptDir/common/PipelineUtils.txt || exit 1
source $ScriptDir/common/PipelineInit.txt || exit 1

#------------------------------------------
# Look for a dwi* or cusp* folder
#------------------------------------------
PREVIFS=$IFS
IFS=$'\n'
dfa=`getDataForAnalysis`
DWIFolders=($(find $dfa/ -type d -name 'dwi*' ))
nbdir=${#DWIFolders[@]}
IFS=$PREVIFS

if [ $nbdir -ne 0 ]; then
  
  #------------------------------------------------
  # For all folders
  #------------------------------------------------
  for (( i=0; i<${nbdir} ; i++ ));
  do
    #------------------------------------------------
    # Get and simplify the directory name
    #------------------------------------------------
    d="${DWIFolders[$i]}" 
    d=`readlink -f "$d"`

    DWIid=`basename "$d"`
    DWIid=`echo "${DWIid}" | sed "s/ /_/g"`
    DWIProcessedDir="$ScanProcessedDir/common-processed/diffusion/${DWIid}"

    doClean "$DWIProcessedDir"
  done
fi


#------------------------------------------
# Look for a cusp* folder
#------------------------------------------
PREVIFS=$IFS
IFS=$'\n'
DWIFolders=($(find $dfa/ -type d -name 'cusp*' ))
nbdir=${#DWIFolders[@]}
IFS=$PREVIFS

if [ $nbdir -ne 0 ]; then
  for (( i=0; i<${nbdir} ; i++ ));
  do
    #------------------------------------------------
    # Get and simplify the directory name
    #------------------------------------------------
    d="${DWIFolders[$i]}" 
    d=`readlink -f "$d"`

    DWIid=`basename "$d"`
    DWIid=`echo "${DWIid}" | sed "s/ /_/g"`
    DWIProcessedDir="$ScanProcessedDir/common-processed/diffusion/${DWIid}"

    doClean "$DWIProcessedDir"
  done
fi




