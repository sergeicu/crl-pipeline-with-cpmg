#---------------------------------------------------------
# WBC from whole brain connectivity (from the DIAMOND model)
#---------------------------------------------------------
# $1 : ${DWIid}

if [ $2 -ne 1 ]; then
  echo "- Not a multi b-value acquisition. Skip this module."
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

#------------------------------------------
# Check some variables
#------------------------------------------
DWIid="$1"
checkIfVariablesAreSet "${DWIid}_RTENSOR_1T_FA,${DWIid}_B632DIAMOND_3F_T0,${DWIid}_B632DIAMOND_3F_T1,${DWIid}_B632DIAMOND_3F_T2,${DWIid}_B632DIAMOND_3F_F,PARCELLATION_NVM_CX,PARCELLATION_NVM_WM"

#------------------------------------------
# Compute WBC
#------------------------------------------
showStepTitle "Whole Brain Connectivity - DIAMOND"

OFOLDER="${folder}/modules/wbc/${DWIid}-DIAMOND"
mkdir -p "$OFOLDER"

CACHE_DoStepOrNot "${DWIid}_WBCDIAMOND" "1.0"
if [ $? -eq 0 ]; then
    echo "- Use previously computed wbc."
    echo

else
    #------------------------------------------
    # Define the seeding ROI from the WM parcellation
    #------------------------------------------
    SEEDINGroi="$OFOLDER/${prefix}SeedingROI.nrrd"
    cp ${PARCELLATION_NVM_WM} ${SEEDINGroi}

    #------------------------------------------
    # Define the stop tracts mask from the cortex parcellation
    #------------------------------------------
    StopTractMask="$OFOLDER/${prefix}StopTractMask.nrrd"
    crlBinaryMorphology $PARCELLATION_NVM_CX erode 1 1 $StopTractMask

    t0="${DWIid}_B632DIAMOND_3F_T0"; t0=${!t0}
    t1="${DWIid}_B632DIAMOND_3F_T1"; t1=${!t1}
    t2="${DWIid}_B632DIAMOND_3F_T2"; t2=${!t2}
    f="${DWIid}_B632DIAMOND_3F_F"; f=${!f}

    OTRACTS="${OFOLDER}/${prefix}WBC_tracts.vtp64"

    crlMFMTractGenerator -i "$t0" -i "$t1" -i "$t2" --fractions "$f" \
                             -r "${SEEDINGroi}" -l 1 \
                             -o "$OTRACTS" \
                             --famomentum 0.5 -a 35 -f 0.15 -s 5 -n 4 -d 0.5 \
                             --tractsimplify 1 -p "$NBTHREADS" \
                             --interp cquaternion \
                             --stoptracts_roi ${StopTractMask}

    exitIfError "crlMFMTractGenerator"

    exportVariable "${DWIid}_WBC_DIAMOND_TRACTS" "$OTRACTS"

    CACHE_StepHasBeenDone "${DWIid}_WBCDIAMOND" "${PARCELLATION_NVM_WM},${PARCELLATION_NVM_CX},$t0,$t1,$t2,$f" "$OTRACTS"
fi
echo ""




