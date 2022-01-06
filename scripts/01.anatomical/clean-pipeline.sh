#!/bin/sh

#=================================================================
# ANATOMICAL ANALYSIS PIPELINE - CLEAN SCRIPT
# Benoit Scherrer, CRL, 2012
#-----------------------------------------------------------------
# 
#=================================================================


#------------------------------------------
# Load the scan informations, cache manager, init the prefix, etc...
# After the file is sourced, we are in the folder 
# "$ScanProcessedDir/common-processed"
#------------------------------------------
prevdir=`pwd`
source "`dirname $0`/../../ScanInfo.sh" || exit 1
source $ScriptDir/common/PipelineUtils.txt || exit 1
source $ScriptDir/common/PipelineInit.txt || exit 1

folder="$ScanProcessedDir/common-processed/anatomical"
echo "- Clean $folder"

#=============================================================
# Clean ICC Extraction
#=============================================================
rm -rf "${folder}/03-ICC/tmp"

