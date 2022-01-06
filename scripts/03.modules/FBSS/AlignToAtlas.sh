#!/bin/sh

if [ $# -ne 2 ]; then
  echo "----------------------------------------------------------"
  echo " Align a DW scan to atlas space"
  echo 
  echo " (c) CRL, Benoit Scherrer, 2015"
  echo "     benoit.scherrer@childrens.harvard.edu"
  echo "----------------------------------------------------------"
  echo "SYNTAX: AlignToAtlas.sh [DWIid] [0:DWI/1:CUSP]"
  echo
  exit 1
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

#-------------------------------------------------
# Get parameters for crlBlockMatchingRegistration
#------------------------------------------------- 
s=`crlImageInfo "${T1W_REF}" | grep Spacing`
s=`echo "$s" | sed -e "s/Spacing: \[\(.*\)\]/\1/"`
res=`echo "$s" | sed -e "s/\([0-9.]*\).*/\1/"`

# Compute smoothing kernel from resolution (should be 2.5mm in radius)
sig=`bc <<< "scale=1;(3.5/$res)"`

# Compute block half-size (bh), space between blocks (sb), block neighborhood (blv) from resolution (should all be 2mm in space at highest resolution)
vox=`bc <<< "scale=2;(2/$res)"`
vox=`echo $vox|awk '{print int($1+0.5)}'`
if (( vox==0 ))
then
    vox=1
fi

#-------------------------------------------------
# Go!!
#-----------------------------------------------
OFOLDER="${folder}/modules/AtlasSpace/${DWIid}"
mkdir -p "$OFOLDER"

#-------------------------------------------------
# Rigid Align using DTI
#-------------------------------------------------
dtiSource="${DWIid}_RTENSOR_1T"; dtiSource=${!dtiSource}


function doIt()
{
  GetTemplateLibraryDir "MFMAtlas"			# Get dir in TemplateLibraryDir
  local dtiTargetAtlas=${TemplateLibraryDir}/atlas_dti.nrrd
  local dtiSource="$1"
  local t0="$2"
  local t1="$3"
  local t2="$4"
  local tF="$5"

  showStepTitle "Align DTI to Atlas Space (Rigid)"
  CACHE_DoStepOrNot "${DWIid}_MODULE_ALIGNTOATLAS_RIGID" "1.0"
  if [  $? -eq 0 ]; then
    echo "- Use previously computed transform."
  else
    echo "- Compute rigid registration..."

    crlBlockMatchingRegistration -r $dtiTargetAtlas -f ${dtiSource} -o ${OFOLDER}/dti_to_atlas_rig -s 4 -e 0 -k 0.8 -l 0.8 --sig 2.5 --mv 0.0 -n 10 --bh 2 --sb 2 --blv 2 --rs 1 --ssi cc -I linear -p ${NBTHREADS} -t rigid 

    CACHE_StepHasBeenDone "${DWIid}_MODULE_ALIGNTOATLAS_RIGID" "$dtiSource,$dtiTargetAtlas" "${OFOLDER}/dti_to_atlas_rig_FinalT.tfm"
  fi

  #-------------------------------------------------
  # Affine Align using DTI
  #-------------------------------------------------
  showStepTitle "Align DTI to Atlas Space (Affine)"
  CACHE_DoStepOrNot "${DWIid}_MODULE_ALIGNTOATLAS_AFF" "1.0"
  if [  $? -eq 0 ]; then
    echo "- Use previously computed transform."
  else
    echo "- Compute affine registration..."

    crlBlockMatchingRegistration -r $dtiTargetAtlas -f ${dtiSource} -o ${OFOLDER}/dti_to_atlas_aff -i ${OFOLDER}/dti_to_atlas_rig_FinalT.tfm -s 4 -e 0 -k 0.8 -l 0.8 --sig 2.5 --mv 0.0 -n 10 --bh 2 --sb 2 --blv 2 --rs 1 --ssi cc -I linear -p ${NBTHREADS} -t affine 

    CACHE_StepHasBeenDone "${DWIid}_MODULE_ALIGNTOATLAS_AFF" "$dtiSource,$dtiTargetAtlas,${OFOLDER}/dti_to_atlas_rig_FinalT.tfm" "${OFOLDER}/dti_to_atlas_aff_FinalT.tfm"
  fi

  #-------------------------------------------------
  # Dense Align using full MFM
  #-------------------------------------------------
  GetTemplateLibraryDir "MFMAtlas"			# Get dir in TemplateLibraryDir
  mfmTargetAtlas=$OFOLDER/mfmAtlas.txt
  echo "${TemplateLibraryDir}/atlas_it1_mfm_ten0.nrrd" > $mfmTargetAtlas
  echo "${TemplateLibraryDir}/atlas_it1_mfm_ten1.nrrd" >> $mfmTargetAtlas
  echo "${TemplateLibraryDir}/atlas_it1_mfm_ten2.nrrd" >> $mfmTargetAtlas
  echo "${TemplateLibraryDir}/atlas_it1_mfm_frac.nrrd" >> $mfmTargetAtlas

  mfmSource=$OFOLDER/mfmSource.txt
  echo "$t0" > $mfmSource  
  echo "$t1" >> $mfmSource  
  echo "$t2" >> $mfmSource  
  echo "$tF" >> $mfmSource  

  showStepTitle "Align MFM to Atlas Space (Dense)"
  CACHE_DoStepOrNot "${DWIid}_MODULE_ALIGNTOATLAS_DENSE" "1.0"
  if [  $? -eq 0 ]; then
    echo "- Use previously computed transform."
  else
    echo "- Dense registration..."
    crlBlockMatchingRegistration -r $mfmTargetAtlas -f ${mfmSource} -o ${OFOLDER}/mfm_to_atlas -i ${OFOLDER}/dti_to_atlas_aff_FinalT.tfm -s 4 -e 0 -k 0.8 -l 0.8 --sig $sig --mv 0.0 -n 10 --bh $vox --sb $vox --blv $vox --rs 1 --ssi cc -I linear -p ${NBTHREADS} -t dense 

    exitIfError "crlBlockMatchingRegistration"

    exportVariable "${DWIid}_ALIGNTOATLAS_TFM" "${OFOLDER}/mfm_to_atlas_FinalMT.tfm"

    CACHE_StepHasBeenDone "${DWIid}_MODULE_ALIGNTOATLAS_DENSE" "$t0,$t1,$t2,$tF,${OFOLDER}/dti_to_atlas_aff_FinalT.tfm" "${OFOLDER}/mfm_to_atlas_FinalMT.tfm"
  fi
  echo ""



  showStepTitle "Apply dense deformation field to anatomic images"
  CACHE_DoStepOrNot "${DWIid}_MODULE_ALIGNANAT_TOATLAS" "1.0"
  if [  $? -eq 0 ]; then
    echo "- Use previously computed transform."
  else
    echo "- Apply..."

    GetTemplateLibraryDir "MFMAtlas"			# Get dir in TemplateLibraryDir
    local tfm="${DWIid}_ALIGNTOATLAS_TFM"; tfm=${!tfm}
    local atlasAnatRef="${TemplateLibraryDir}/atlas_it1_FinalS.nrrd"

    local products=${OFOLDER}/${prefix}T1W_OnAtlas_FinalS.nrrd
    crlBlockMatchingRegistration -N -n 0 -e 0 -s 0 -p $NBTHREADS -i $tfm -f ${T1W_REF} -r $atlasAnatRef -o ${OFOLDER}/${prefix}T1W_OnAtlas -I linear -t dense

    if [[ -f ${T2W_REF} ]]; then
      crlBlockMatchingRegistration -N -n 0 -e 0 -s 0 -p $NBTHREADS -i $tfm -f ${T2W_REF} -r $atlasAnatRef -o ${OFOLDER}/${prefix}T2W_OnAtlas -I linear -t dense
      products="${products},${OFOLDER}/${prefix}T2W_OnAtlas_FinalS.nrrd"
    fi

    if [[ -f ${FLAIR_REF} ]]; then
      crlBlockMatchingRegistration -N -n 0 -e 0 -s 0 -p $NBTHREADS -i $tfm -f ${FLAIR_REF} -r $atlasAnatRef -o ${OFOLDER}/${prefix}FLAIR_OnAtlas -I linear -t dense
      products="${products},${OFOLDER}/${prefix}FLAIR_OnAtlas_FinalS.nrrd"
    fi

    if [[ -f ${CT_REF} ]]; then
      crlBlockMatchingRegistration -N -n 0 -e 0 -s 0 -p $NBTHREADS -i $tfm -f ${CT_REF} -r $atlasAnatRef -o ${OFOLDER}/${prefix}CT_OnAtlas -I linear -t dense
      products="${products},${OFOLDER}/${prefix}CT_OnAtlas_FinalS.nrrd"
    fi


    exitIfError "crlBlockMatchingRegistration"

    
    CACHE_StepHasBeenDone "${DWIid}_MODULE_ALIGNANAT_TOATLAS" "$tfm,${T1W_REF}" "$products"
  fi
  echo ""
}

#-------------------------------------------------
# Check files - test with B632MFM
#------------------------------------------------- 
t0="${DWIid}_B632MFM_3F_T0"; t0=${!t0}
t1="${DWIid}_B632MFM_3F_T1"; t1=${!t1}
t2="${DWIid}_B632MFM_3F_T2"; t2=${!t2}
tF="${DWIid}_B632MFM_3F_F"; tF=${!tF}
ok=1
if [ -z "$t0" ] || [ ! -f "$t0" ]; then echo "FATAL ERROR. Invalid t0 file <$t0>"; ok=0; fi
if [ -z "$t1" ] || [ ! -f "$t1" ]; then echo "FATAL ERROR. Invalid t1 file <$t1>"; ok=0; fi
if [ -z "$t2" ] || [ ! -f "$t2" ]; then echo "FATAL ERROR. Invalid t2 file <$t2>"; ok=0; fi
if [ -z "$tF" ] || [ ! -f "$tF" ]; then echo "FATAL ERROR. Invalid tF file <$tF>"; ok=0; fi

if [[ $ok -eq 1 ]]; then
  doIt "$dtiSource" "$t0" "$t1" "$t2" "$tF"
else
  t0="${DWIid}_B632DIAMOND_3F_T0"; t0=${!t0}; t0=`echo "$t0" | sed "s@_t0.nrrd@_mtm_t0.nrrd@"`
  t1="${DWIid}_B632DIAMOND_3F_T1"; t1=${!t1}; t1=`echo "$t1" | sed "s@_t1.nrrd@_mtm_t1.nrrd@"`
  t2="${DWIid}_B632DIAMOND_3F_T2"; t2=${!t2}; t2=`echo "$t2" | sed "s@_t2.nrrd@_mtm_t2.nrrd@"`
  tF="${DWIid}_B632DIAMOND_3F_F"; tF=${!tF}; tF=`echo "$tF" | sed "s@_fractions.nrrd@_mtm_fractions.nrrd@"`
  ok=1
  if [ -z "$t0" ] || [ ! -f "$t0" ]; then echo "FATAL ERROR. Invalid t0 file <$t0>"; ok=0; fi
  if [ -z "$t1" ] || [ ! -f "$t1" ]; then echo "FATAL ERROR. Invalid t1 file <$t1>"; ok=0; fi
  if [ -z "$t2" ] || [ ! -f "$t2" ]; then echo "FATAL ERROR. Invalid t2 file <$t2>"; ok=0; fi
  if [ -z "$tF" ] || [ ! -f "$tF" ]; then echo "FATAL ERROR. Invalid tF file <$tF>"; ok=0; fi

  if [[ $ok -eq 1 ]]; then
    doIt "$dtiSource" "$t0" "$t1" "$t2" "$tF"
  fi
fi

#-------------------------------------------------
# Now resample the MFM
#-------------------------------------------------
#showStepTitle "Compute resampled MFM"
##CACHE_DoStepOrNot "${DWIid}_MODULE_ALIGNTOATLAS_DENSE" "1.0"
#if [  $? -eq 0 ]; then
#  echo "- Use previously transform."
#else
#  echo "- Dense registration..."
#  crlBlockMatchingRegistration -r $mfmTargetAtlas -f ${mfmSource} -o ${OFOLDER}/mfm_to_atlas -i ${OFOLDER}/dti_to_atlas_aff_FinalT.tfm -s 4 -e 0 -k 0.8 -l 0.8 --sig $sig --mv 0.0 -n 10 --bh $vox --sb $vox --blv $vox --rs 1 --ssi cc -I linear -p ${NBTHREADS} -t dense 
#
#  exitIfError "crlDCIEstimateFromHARDI"
#
#  exportVariable "${DWIid}_ALIGNTOATLAS_TFM" "${OFOLDER}/mfm_to_atlas_FinalT.tfm"
#
#  CACHE_StepHasBeenDone "${DWIid}_MODULE_ALIGNTOATLAS_DENSE" "$t0,$t1,$t2,$tF,${OFOLDER}/dti_to_atlas_aff_FinalT.tfm" "${OFOLDER}/mfm_to_atlas_FinalT.tfm"
#fi
#echo ""





