#!/bin/sh

if [ $# -ne 2 ]; then
  echo "----------------------------------------------------------"
  echo " Estimate a DCI/MFM model from single shell acquisition"
  echo 
  echo " (c) CRL, Benoit Scherrer, 2015"
  echo "     benoit.scherrer@childrens.harvard.edu"
  echo "----------------------------------------------------------"
  echo "SYNTAX: DCIFromHARDI_3F_t1wres.sh [DWIid] [0:DWI/1:CUSP]"
  echo
  exit 1
fi

if [ $2 -ne 0 ]; then
  echo "- This is a multi b-value acquisition. Skip this module."
  exit 0
fi


#------------------------------------------
# Load the cache manager, init the prefix, etc...
# After the file is sourced, we are in the folder 
# "$ScanProcessedDir/common-processed"
#------------------------------------------
source "`dirname $0`/../../../ScanInfo.sh" || exit 1
source $ScriptDir/common/PipelineUtils.txt || exit 1
source $ScriptDir/common/PipelineInit.txt || exit 1

DWIid="$1"

#------------------------------------------
# Check some variables
#------------------------------------------
checkIfVariablesAreSet "${DWIid}_RMASKED_NHDR"

#-------------------------------------------------
# Get the High Resolution NHDR (resampled)
#------------------------------------------------- 
nhdr="${DWIid}_RMASKED_NHDR"
nhdr=${!nhdr}
if [ -z "$nhdr" ] || [ ! -f "$nhdr" ]; then
  echo "FATAL ERROR. Invalid file <$nhdr.>"
  exit 1
fi

RevisionNumber=`crlDCIEstimate 2>&1 | grep REVISION | cut -f2 -d:`
if [[ $RevisionNumber -lt 8 ]]; then
  errorAndExit "Invalid revision number for crlDCIEstimate. Must be >=8"
fi

OFOLDER="${folder}/modules/MFM/${DWIid}"
mkdir -p "$OFOLDER"


#-------------------------------------------------
# MFM Estimation
#-------------------------------------------------
showStepTitle "MFM estimation from HARDI"
CACHE_DoStepOrNot "${DWIid}_MODULE_MFMFromHARDI_3T" "2.00"
if [  $? -eq 0 ]; then
  echo "- Use previously estimated MFM."
else
 
  s=`crlImageInfo "${T1W_REF}" | grep Spacing`
  s=`echo "$s" | sed -e "s/Spacing: \[\(.*\)\]/\1/"`
  sx=`echo "$s" | sed -e "s/\([0-9.]*\).*/\1/"`

  GetTemplateLibraryDir "DCIAtlas"			# Get dir in TemplateLibraryDir
  DCIAtlasLibraryDir=${TemplateLibraryDir}

  DELETETMP=0

  THISPATH=$(cd `dirname "${BASH_SOURCE[0]}"` && pwd)

  run_tool $THISPATH/crlDCIEstimateFromHARDI --log -i "$nhdr" --reg 1 --estimb0 1 \
    -n 3 --fascicle tensorcyl --waterfraction 1 --automose aicu \
    -o "${OFOLDER}/${prefix}MFMfromHARDI_T1WRES_3T.nrrd" \
    -p ${NBTHREADS}  \
    --res $sx --dtiAtlas $DCIAtlasLibraryDir/atlas_dti.nrrd --prior $DCIAtlasLibraryDir/atlas_dci_prior/atlas_dci_prior.txt --priorweight 0.2 \
    --deletetmp ${DELETETMP}

  exitIfError "crlDCIEstimateFromHARDI"

  exportVariable "${DWIid}_B632MFM_3F_T0" "${OFOLDER}/${prefix}MFMfromHARDI_T1WRES_3T_t0.nrrd"
  exportVariable "${DWIid}_B632MFM_3F_T1" "${OFOLDER}/${prefix}MFMfromHARDI_T1WRES_3T_t1.nrrd"
  exportVariable "${DWIid}_B632MFM_3F_T2" "${OFOLDER}/${prefix}MFMfromHARDI_T1WRES_3T_t2.nrrd"
  exportVariable "${DWIid}_B632MFM_3F_F"  "${OFOLDER}/${prefix}MFMfromHARDI_T1WRES_3T_fractions.nrrd"
  exportVariable "${DWIid}_B632MFM_3F_MOSEMAP"  "${OFOLDER}/${prefix}MFMfromHARDI_T1WRES_3T_mosemap.nrrd"

  CACHE_StepHasBeenDone "${DWIid}_MODULE_MFMFromHARDI_3T" "$nhdr" "${OFOLDER}/${prefix}MFMfromHARDI_T1WRES_3T_t0.nrrd,${OFOLDER}/${prefix}MFMfromHARDI_T1WRES_3T_t1.nrrd,${OFOLDER}/${prefix}MFMfromHARDI_T1WRES_3T_t2.nrrd,${OFOLDER}/${prefix}MFMfromHARDI_T1WRES_3T_fractions.nrrd"
fi
echo ""
