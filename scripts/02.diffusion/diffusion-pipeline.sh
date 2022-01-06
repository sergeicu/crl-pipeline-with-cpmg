#!/bin/sh

#=================================================================
# DIFFUSION ANALYSIS PIPELINE
# Benoit Scherrer, CRL, 2011
#-----------------------------------------------------------------
# 
#=================================================================

echo
echo "=============================================="
echo "  =========================================="
echo "      DIFFUSION WEIGHTED IMAGING  PIPELINE"
echo "  =========================================="
echo "=============================================="
echo

umask 002

#------------------------------------------
# Load the scan informations
#------------------------------------------
source "`dirname $0`/../../ScanInfo.sh" || exit 1
prevdir=`pwd`

#------------------------------------------
# Load the cache manager, prepare the prefix, etc...
# After the file is sourced, we are in the folder 
# "$ScanProcessedDir/common-processed"
#------------------------------------------
source $ScriptDir/common/PipelineUtils.txt || exit 1
source $ScriptDir/common/PipelineInit.txt || exit 1
source $ScriptDir/common/HtmlReportManager.txt || exit 1

source "`dirname $0`/01.diffusion_prepare.txt" || exit 1
source "`dirname $0`/02.diffusion_1T.txt" || exit 1
source "`dirname $0`/02.diffusion_report.txt" || exit 1
# source "`dirname $0`/03.diffusion_2T.txt" || exit 1

if [[ ${SKIP_DIFFUSION_PIPELINE} -eq 1 ]]; then
  echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
  echo " The internal variable SKIP_DIFFUSION_PIPELINE=1" 
  echo " SKIP the diffusion pipeline"
  echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
  echo
  exit
fi

#------------------------------------------
# Look for a dwi* or cusp* folder
#------------------------------------------
PREVIFS=$IFS
IFS=$'\n'
dfa=`getDataForAnalysis`
DWIFolders=($(find $dfa/ -type d -name 'dwi*' -or -type d -name 'hardi*' ))
nbdir=${#DWIFolders[@]}
IFS=$PREVIFS

#------------------------------------------------
# Save in PipelineResults 
#------------------------------------------------
exportVariable "NB_DWI_FOLDERS" "$nbdir"
for (( i=0; i<${nbdir} ; i++ ));
do
  d="${DWIFolders[$i]}" 
  d=`readlink -f "$d"`
  exportVariable "DWI_FOLDERS[$i]" "$d"
done


#------------------------------------------------
# Process folders
#------------------------------------------------
if [ $nbdir -eq 0 ]; then
  echo "WARNING: No folder dwi*/hardi* in data_for_analysis. Skip the conventional 1T analysis."
else
  #------------------------------------------------
  # NOW for all folder convert to DICOM
  #------------------------------------------------
  for (( i=0; i<${nbdir} ; i++ ));
  do
    #------------------------------------------------
    # Get and simplify the directory name
    #------------------------------------------------
    d="${DWIFolders[$i]}" 
    d=`readlink -f "$d"`

    sh `dirname $0`/diffusion-pipeline-for-folder.sh $d
    # RunDWIPipeline_prepare "$d"
    # RunDWIPipeline_1T "$d"
  done
fi






#------------------------------------------
# Look for a addoncusp* folder
# Format: addoncusp_[refdti]_[outputcusp]
#------------------------------------------
PREVIFS=$IFS
IFS=$'\n'
DWIFolders=($(find $dfa/ -type d -name 'addoncusp_*' ))
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
    addon=`basename "$d"`
    basefoldername=`dirname "$d"`

    echo "=========================================="
    echo "  ADD-ON FOLDER: "
    echo "  $addon"
    echo "=========================================="

    #------------------------------------
    # Get the cusp & reference folder
    #------------------------------------
    refdwi=`echo "$addon" | sed -e 's/^addoncusp_\(.*\)_.*/\1/'`
    destcusp=`echo "$addon" | sed -e 's/^addoncusp_.*_\(.*\)/\1/'`

    if [ -z "$refdwi" ] || [ "$refdwi" == "$addon" ]; then
      echo "  Syntax error. The syntax for a cusp addon is: addoncusp_[reffolder]_[destcusp]"
      echo "  SKIP this addon folder"
      echo
      continue
    fi    
    if [ -z "$destcusp" ] || [ "$destcusp" == "$addon" ]; then
      echo "  Syntax error. The syntax for a cusp addon is: addoncusp_[reffolder]_[destcusp]"
      echo "  SKIP this addon folder"
      echo
      continue
    fi    

    #------------------------------------
    # Check if already done
    #------------------------------------
    if [[ -d "$basefoldername/$destcusp" ]] && [[ `ls $basefoldername/$destcusp/*.nhdr | wc -l` -ne 0 ]]; then
      echo "- Destination folder $destcusp already existing."
      echo "  Do nothing"
      continue;
    fi

    #------------------------------------
    # If not, do it!
    #------------------------------------
    echo "- Create CUSP from CUSP-ADDON and a reference DWI..."

    refdwi2="$basefoldername/$refdwi"
    if [ ! -d "$refdwi2" ]; then
      echo "- ERROR. Cannot find the folder:"
      echo "  $refdwi2"
      echo "  The syntax for a cusp addon is: addoncusp_[reffolder]_[destcusp]"
      echo "  SKIP this addon folder"
      echo
      continue
    fi    
    echo "- OK. Reference Folder '$refdwi' found."
    
    #------------------------------------
    # Get the ref nhdr and check
    #------------------------------------
    refnhdr=`find "$refdwi2"/ -type f -name \*.nhdr | head -1`
    if [[ ! -f "$refnhdr" ]] ; then
      echo "ERROR. Cannot find the reference nhdr <$refdwi2>."
      echo "  SKIP this addon folder"
      echo
      continue
    fi

    #------------------------------------
    # Get the list of addon nhdrs and check
    #------------------------------------
    PREVIFS=$IFS
    IFS=$'\n'
    NhdrFiles=($(find "$d"/ -type f -name \*.nhdr ))
    nbNhdrFiles=${#NhdrFiles[@]}
    IFS=$PREVIFS
    addonnhdrs=""
    for (( n=0; n<${nbNhdrFiles} ; n++ ));
    do
      nhdr="${NhdrFiles[$n]}" 
      nhdr=`readlink -f "$nhdr"`
      if [[ -f "$nhdr" ]]; then
        addonnhdrs="$addonnhdrs -i $nhdr"
      fi
    done
    if [[ -z "$addonnhdrs" ]] ; then
      echo "ERROR. Cannot find nhdrs in <$d>."
      echo "  SKIP this addon folder"
      echo
      continue
    fi

    #------------------------------------
    # Show infos
    #------------------------------------
    echo "- REF NHDR: $refnhdr"
    echo "- ADD-ON NHDRS: $addonnhdrs"

    #------------------------------------
    # Create the cusp!
    #------------------------------------
    echo 
    echo "- Combine acquisitions and create $destcusp ..."
    mkdir -p "$basefoldername/$destcusp"
    chmod g+rw "$basefoldername/$destcusp"
    
    crlDWICombineAcquisitions -i "$refnhdr" $addonnhdrs --nonormalize -o "$basefoldername/$destcusp/diffusion.nhdr"
  done
fi



#------------------------------------------
# Look for a cusp* folder
#------------------------------------------
PREVIFS=$IFS
IFS=$'\n'
DWIFolders=($(find $dfa/ -type d -name 'cusp*' -or -type d -name 'ms*' -or -type d -name 'dsi*' ))
nbdir=${#DWIFolders[@]}
IFS=$PREVIFS


#------------------------------------------------
# Save in PipelineResults 
#------------------------------------------------
exportVariable "NB_MULTIB_DWI_FOLDERS" "$nbdir"
for (( i=0; i<${nbdir} ; i++ ));
do
  d="${DWIFolders[$i]}" 
  d=`readlink -f "$d"`
  exportVariable "MULTIB_DWI_FOLDERS[$i]" "$d"
done

#------------------------------------------------
# Process folders
#------------------------------------------------
if [ $nbdir -eq 0 ]; then
  echo "No folder cusp*/ms* in data_for_analysis."
else

  for (( i=0; i<${nbdir} ; i++ ));
  do
    #------------------------------------------------
    # Get and simplify the directory name
    #------------------------------------------------
    d="${DWIFolders[$i]}" 
    d=`readlink -f "$d"`

    sh `dirname $0`/diffusion-pipeline-for-folder.sh $d "1"

    #RunDWIPipeline_prepare "$d" "1"
    #RunDWIPipeline_1T "$d" "1"
    #RunDWIPipeline_2T "$d" "1" #USE MODULES MFM

    if [[ $CREATE_REPORT -eq 1 ]]; then
      RunDWIPipeline_report "$d" "1"
    fi

  done
fi






