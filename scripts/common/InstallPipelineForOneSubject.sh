#!/bin/sh

VT100RED='\e[0;31m'
VT100GREEN='\e[0;32m'
VT100YELLOW='\e[0;33m'
VT100BLUE='\e[0;34m'
VT100MAGENTA='\e[0;35m'
VT100CYAN='\e[0;36m'
VT100CLEAR='\e[0m'

#-------------------------------------------
# Check the number of parameters
#-------------------------------------------
if [ $# -lt 1 ]; then
  echo "----------------------------------------------------------"
  echo " Install the pipeline for a single subject"
  echo 
  echo " (c) CRL, Benoit Scherrer, 2011"
  echo "     benoit.scherrer@childrens.harvard.edu"
  echo "----------------------------------------------------------"
  echo "SYNTAX: InstallPipelineForOneSubject [DestProcessedDir] [[DataForAnalysisDir]]"
  echo
  exit 1
fi

umask 002

pdir=`readlink -f "$1"`
sdir="`dirname $0`"
sdir=`readlink -f "$sdir/../"`

if [[ ! -z "$2" ]]; then
  dfadir=`readlink -f "$2"`
else
  dfadir=""
fi

echo
echo -e "${VT100BLUE}Installing pipeline for single-subject mode... ${VT100CLEAR}"
if [[ ! -z "$dfadir" ]]; then
echo "  Data for analysis folder: $dfadir"
fi
echo "  Dest folder: $pdir"
echo "  Script folder: $sdir"

echo
echo -e "${VT100BLUE}Preparing local scripts... ${VT100CLEAR}"

ofile="$1/ScanInfo.sh"
echo "#!/bin/sh" > $ofile
if [[ ! -z "$dfadir" ]]; then
  echo "DataForAnalysisDir=$dfadir" >> $ofile
fi
echo "ScanProcessedDir=$pdir" >> $ofile
echo "ScriptDir=$pdir/scripts" >> $ofile

chmod g+rw $ofile
chmod a+r $ofile

ofile2="$1/run-common-processed.sh"
echo "#!/bin/sh" > $ofile2
echo "sh $pdir/scripts/common/RunPipelineForOneSubject.sh" >> $ofile2
chmod g+rw $ofile2
chmod a+rx $ofile2

ofile3="$1/clean-common-processed.sh"
echo "#!/bin/sh" > $ofile3
echo "sh \"$pdir/scripts/01.anatomical/clean-pipeline.sh\""  >> $ofile3
echo "sh \"$pdir/scripts/02.diffusion/clean-pipeline.sh\""  >> $ofile3
chmod g+rw $ofile3
chmod a+rx $ofile3

cp $pdir/scripts/common/import_from_dicom.sh $pdir
chmod a+rx $pdir/import_from_dicom.sh

if [ ! -f "$pdir/scripts/common/Settings.txt" ]; then
  cp "$pdir/scripts/common/SettingsExample.txt" "$pdir/scripts/common/Settings.txt"

  d=`echo "$pdir/scripts" | sed 's/\//\\\\\//g'`	
  sed -i "s/^SrcScriptDir=\(\S*\).*/SrcScriptDir=\"$d\"/" "$pdir/scripts/common/Settings.txt" ; 

  d=`echo "$pdir" | sed 's/\//\\\\\//g'`	
  sed -i "s/^BaseProcessedDir=\(\S*\).*/BaseProcessedDir=\"$d\"/" "$pdir/scripts/common/Settings.txt" ; 

  sed -i "s/^BaseRawDir=\(\S*\).*/BaseRawDir=\"\"/" "$pdir/scripts/common/Settings.txt" ; 

  if [[ ! -z "$dfadir" ]]; then
    d=`echo "$dfadir" | sed 's/\//\\\\\//g'`	
    sed -i "s/^DataForAnalysisDir=\"\(\S*\)\"\(.*\)/DataForAnalysisDir=\"$d\"\2/" "$pdir/scripts/common/Settings.txt" ; 
  fi
fi

source $ofile

mkdir -p $pdir/common-processed
cd $pdir/common-processed

echo -e "${VT100BLUE}Initializing... ${VT100CLEAR}"

source $pdir/scripts/common/PipelineUtils.txt
source $pdir/scripts/common/PipelineInit.txt

echo
echo -e "${VT100BLUE}>> Done! ${VT100CLEAR}"
echo

