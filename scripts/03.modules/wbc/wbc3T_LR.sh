#---------------------------------------------------------
# WBC common function for 1T whole brain connectivity
#---------------------------------------------------------
# $1 : ${DWIid}

#------------------------------------------
# Load the cache manager, init the prefix, etc...
# After the file is sourced, we are in the folder 
# "$ScanProcessedDir/common-processed"
#------------------------------------------
source "`dirname $0`/../../../ScanInfo.sh" || exit 1
source $ScriptDir/common/PipelineUtils.txt || exit 1
source $ScriptDir/common/PipelineInit.txt || exit 1



  #------------------------------------------
  # Check some variables
  #------------------------------------------
  DWIid="$1"
  checkIfVariablesAreSet "${DWIid}_TENSOR_1T_FA,${DWIid}_B632MFM_LR_3F_T0,${DWIid}_B632MFM_LR_3F_T1,${DWIid}_B632MFM_LR_3F_T2,${DWIid}_B632MFM_LR_3F_F,${DWIid}_PARCELLATION_NVM_CX,${DWIid}_PARCELLATION_NVM_WM"

  #------------------------------------------
  # Compute WBC
  #------------------------------------------
  showStepTitle "Whole Brain Connectivity - LR 3T (no parcellation)"

  OFOLDER="${folder}/modules/wbc/${DWIid}-3T"
  mkdir -p "$OFOLDER"


  CACHE_DoStepOrNot "${DWIid}_WBC_LR_3T_NOPARCEL" "2.0"
  if [ $? -eq 0 ]; then
    echo "- Use previously computed wbc."
    echo
  else
    #------------------------------------------
    # Define the seeding ROI from the WM parcellation
    #------------------------------------------
    fwm="${DWIid}_PARCELLATION_NVM_WM"; fwm=${!fwm}
    fcx="${DWIid}_PARCELLATION_NVM_CX"; fcx=${!fcx}

    SEEDINGroi="$OFOLDER/${prefix}LR_SeedingROI.nrrd"
    cp "${fwm}" "${SEEDINGroi}"

    #------------------------------------------
    # Define the stop tracts mask from the cortex parcellation
    #------------------------------------------
    StopTractMask="$OFOLDER/${prefix}LR_StopTractMask.nrrd"
    crlBinaryMorphology ${fcx} erode 1 1 $StopTractMask

    t0="${DWIid}_B632MFM_LR_3F_T0"; t0=${!t0}
    t1="${DWIid}_B632MFM_LR_3F_T1"; t1=${!t1}
    t2="${DWIid}_B632MFM_LR_3F_T2"; t2=${!t2}
    f="${DWIid}_B632MFM_LR_3F_F"; f=${!f}

    OTRACTS="${OFOLDER}/${prefix}LR_WBC_tracts.vtp64"

    crlMFMTractGenerator -i "$t0" -i "$t1" -i "$t2" --fractions "$f" \
                             -r "${SEEDINGroi}" -l 1 \
                             -o "$OTRACTS" \
                             --famomentum 0.5 -a 35 -f 0.15 -s 5 -n 6 -d 0.5 \
                             --tractsimplify 1 -p "$NBTHREADS" \
                             --interp cquaternion \
                             --stoptracts_roi ${StopTractMask}

    exitIfError "crlMFMTractGenerator"

    exportVariable "${DWIid}_WBC_LR_3T_TRACTS" "$OTRACTS"

    CACHE_StepHasBeenDone "${DWIid}_WBC_LR_3T_NOPARCEL" "$fwm,$fcx,$t0,$t1,$t2,$f" "$OTRACTS"
  fi
  echo ""

  echo


