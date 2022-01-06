#---------------------------------------------------------
# WBC common function for 1T whole brain connectivity
#---------------------------------------------------------
# $1 : ${DWIid}
# $2: 'NMM' or 'IBSR'

function doWBC_WITH_PARCELLATION()
{
  if [ ! "${2}" == "NMM" ] && [ ! "${2}" == "IBSR" ]; then
    echo "MODULE wbc1T"
    echo "ERROR while calling doWBC(): Invalid first argument <${2}>."
    exit 1;
  fi 

  #------------------------------------------
  # Check some variables
  #------------------------------------------
  DWIid="$1"
  checkIfVariablesAreSet "PARCELLATION_${2},${DWIid}_RTENSOR_1T"

  #------------------------------------------
  # Compute WBC
  #------------------------------------------
  showStepTitle "Whole Brain Connectivity - 1T+${2}"

  OUTPUTFOLDER="${folder}/modules/wbc/${DWIid}-1T-${2}"
  mkdir -p "$OUTPUTFOLDER"

  CACHE_DoStepOrNot "${DWIid}_WBC_1T_${2}" "1.03"
  if [ $? -eq 0 ]; then
    echo "- Use previously computed wbc."
    echo
  else
    t0="${DWIid}_RTENSOR_1T"
    t0=${!t0}

    p="PARCELLATION_${2}"
    p=${!p}

    # Remove WM labels
    if [ "${2}" == "NMM" ]; then
      crlRelabelImages "$p" "$p" "2 3 4 5 6 7 14 16 20 26 31 38 40 44 53 59 58 60 61 62 63 64 65 66" "0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0" "${OUTPUTFOLDER}/${prefix}${2}_parcellation.nrrd"
      exitIfError "crlRelabelImages"
    elif [ "${2}" == "IBSR" ]; then
      crlRelabelImages "$p" "$p" "114 116 117 119 126 127 128 136 142 153 155 156 158 174 184 185 186" "0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0" "${OUTPUTFOLDER}/${prefix}${2}_parcellation.nrrd"
      exitIfError "crlRelabelImages"
    else
      echo "MODULE wbc1T"
      echo "ERROR while calling doWBC(): Invalid first argument <${2}>."
      exit 1;
    fi

    OTRACTS="${OUTPUTFOLDER}/${prefix}${2}_WBC_tracts.vtp"
    /home/ch137122/bin/crlMFMWBConnectivity -i "$t0" --parcellation "${OUTPUTFOLDER}/${prefix}${2}_parcellation.nrrd" -o "$OTRACTS" --outputseeding "${OUTPUTFOLDER}/${prefix}${2}_WBC_seeding.nrrd" --dilatelabels 0 --tractsimplify 0 -s 2 -n 10 --faroithreshold 0.4 -a 40 -f 0.14 -p "$NBTHREADS"
    exitIfError "crlMFMWBConnectivity"

    exportVariable "${DWIid}_WBC_1T_${2}_TRACTS" "$OTRACTS"

    CACHE_StepHasBeenDone "${DWIid}_WBC_1T_${2}" "$p,$t0" "$OTRACTS"
  fi
  echo ""


  #------------------------------------------
  # Compute Connectivity matrices
  #------------------------------------------
  showStepTitle "Whole Brain Connectivity Matrices - 1T+${2}"

  CACHE_DoStepOrNot "${DWIid}_WBCMATRICES_1T_${2}" "1.05"
  if [ $? -eq 0 ]; then
    echo "- Use previously computed wbc matrices."
    echo
  else
    t0="${DWIid}_RTENSOR_1T"
    t0=${!t0}

    p="${OUTPUTFOLDER}/${prefix}${2}_parcellation.nrrd"
  
    t="${OUTPUTFOLDER}/${prefix}${2}_WBC_tracts.vtp"

    /home/ch137122/bin/crlMFMWBCAnalysis -i "$t" -t "${t0}" --parcellation "${OUTPUTFOLDER}/${prefix}${2}_parcellation.nrrd" -o "${OUTPUTFOLDER}/${prefix}${2}_WBCAnalysis.xml" --graphcoords --streamlineratio --streamlinecount --volumeratio --weightedFA --weightedMD --weightedRD --FA --MD --RD -p "$NBTHREADS"
    exitIfError "crlMFMWBCAnalysis"

    exportVariable "${DWIid}_WBC_1T_${2}_MATRIX_FA" "${OUTPUTFOLDER}/${prefix}${2}_WBCAnalysis_FA.txt"
    exportVariable "${DWIid}_WBC_1T_${2}_MATRIX_MD" "${OUTPUTFOLDER}/${prefix}${2}_WBCAnalysis_MD.txt"
    exportVariable "${DWIid}_WBC_1T_${2}_MATRIX_RD" "${OUTPUTFOLDER}/${prefix}${2}_WBCAnalysis_RD.txt"
    exportVariable "${DWIid}_WBC_1T_${2}_MATRIX_WFA" "${OUTPUTFOLDER}/${prefix}${2}_WBCAnalysis_WeightedFA.txt"
    exportVariable "${DWIid}_WBC_1T_${2}_MATRIX_WMD" "${OUTPUTFOLDER}/${prefix}${2}_WBCAnalysis_WeightedMD.txt"
    exportVariable "${DWIid}_WBC_1T_${2}_MATRIX_WRD" "${OUTPUTFOLDER}/${prefix}${2}_WBCAnalysis_WeightedRD.txt"
    exportVariable "${DWIid}_WBC_1T_${2}_MATRIX_VRATIO" "${OUTPUTFOLDER}/${prefix}${2}_WBCAnalysis_VolumeRatio.txt"
    exportVariable "${DWIid}_WBC_1T_${2}_MATRIX_SRATIO" "${OUTPUTFOLDER}/${prefix}${2}_WBCAnalysis_StreamlineRatio.txt"
    exportVariable "${DWIid}_WBC_1T_${2}_MATRIX_SCOUNT" "${OUTPUTFOLDER}/${prefix}${2}_WBCAnalysis_StreamlineCount.txt"

    CACHE_StepHasBeenDone "${DWIid}_WBCMATRICES_1T_${2}" "$p,$t0,$t" "${OUTPUTFOLDER}/${prefix}${2}_WBCAnalysis.xml"
  fi
  echo



  showStepTitle "Whole Brain Connectivity Matrices - 1T+IBSR"
  CACHE_DoStepOrNot "${DWIid}_WBCMATRICES_1T_IBSR" "1.05"
  if [ $? -eq 0 ]; then
    echo "- Use previously computed wbc matrices."
    echo
  else
    OUTPUTFOLDER="${folder}/modules/wbc/${DWIid}-1T-IBSR"
    mkdir -p "$OUTPUTFOLDER"

    p="PARCELLATION_IBSR"
    p=${!p}
    crlRelabelImages "$p" "$p" "114 116 117 119 126 127 128 136 142 153 155 156 158 174 184 185 186" "0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0" "${OUTPUTFOLDER}/${prefix}IBSR_parcellation.nrrd"


    t0="${DWIid}_RTENSOR_1T"
    t0=${!t0}
    p="${OUTPUTFOLDER}/${prefix}IBSR_parcellation.nrrd"
    tracts="${folder}/modules/wbc/${DWIid}-1T-NMM/${prefix}NMM_WBC_tracts.vtp"

    /home/ch137122/bin/crlMFMWBCAnalysis -i "$tracts" -t "${t0}" --parcellation "${OUTPUTFOLDER}/${prefix}IBSR_parcellation.nrrd" -o "${OUTPUTFOLDER}/${prefix}IBSR_WBCAnalysis.xml" --graphcoords --streamlineratio --streamlinecount --volumeratio --weightedFA --weightedMD --weightedRD --FA --MD --RD -p "$NBTHREADS"
    exitIfError "crlMFMWBCAnalysis"

    exportVariable "${DWIid}_WBC_1T_IBSR_MATRIX_FA" "${OUTPUTFOLDER}/${prefix}IBSR_WBCAnalysis_FA.txt"
    exportVariable "${DWIid}_WBC_1T_IBSR_MATRIX_MD" "${OUTPUTFOLDER}/${prefix}IBSR_WBCAnalysis_MD.txt"
    exportVariable "${DWIid}_WBC_1T_IBSR_MATRIX_RD" "${OUTPUTFOLDER}/${prefix}IBSR_WBCAnalysis_RD.txt"
    exportVariable "${DWIid}_WBC_1T_IBSR_MATRIX_WFA" "${OUTPUTFOLDER}/${prefix}IBSR_WBCAnalysis_WeightedFA.txt"
    exportVariable "${DWIid}_WBC_1T_IBSR_MATRIX_WMD" "${OUTPUTFOLDER}/${prefix}IBSR_WBCAnalysis_WeightedMD.txt"
    exportVariable "${DWIid}_WBC_1T_IBSR_MATRIX_WRD" "${OUTPUTFOLDER}/${prefix}IBSR_WBCAnalysis_WeightedRD.txt"
    exportVariable "${DWIid}_WBC_1T_IBSR_MATRIX_VRATIO" "${OUTPUTFOLDER}/${prefix}IBSR_WBCAnalysis_VolumeRatio.txt"
    exportVariable "${DWIid}_WBC_1T_IBSR_MATRIX_SRATIO" "${OUTPUTFOLDER}/${prefix}IBSR_WBCAnalysis_StreamlineRatio.txt"
    exportVariable "${DWIid}_WBC_1T_IBSR_MATRIX_SCOUNT" "${OUTPUTFOLDER}/${prefix}IBSR_WBCAnalysis_StreamlineCount.txt"

    CACHE_StepHasBeenDone "${DWIid}_WBCMATRICES_1T_IBSR" "$p,$t0,$tracts" "${OUTPUTFOLDER}/${prefix}IBSR_WBCAnalysis.xml"
  fi
  echo
}



function doWBC_WITHOUT_PARCELLATION()
{
  #------------------------------------------
  # Check some variables
  # We need the cortex parcellation for stopping the tracts and for seeding
  #------------------------------------------
  DWIid="$1"
  checkIfVariablesAreSet "${DWIid}_RTENSOR_1T,PARCELLATION_NVM_CX,PARCELLATION_NVM_WM"

  #------------------------------------------
  # Compute WBC
  #------------------------------------------
  showStepTitle "Whole Brain Connectivity - 1T"

  local OFOLDER="${folder}/modules/wbc/${DWIid}-1T"
  mkdir -p "$OFOLDER"

  CACHE_DoStepOrNot "${DWIid}_WBC_1T_NOPARCEL" "2.0"
  if [ $? -eq 0 ]; then
    echo "- Use previously computed wbc."
    echo
  else

    #------------------------------------------
    # Define the seeding ROI from the WM parcellation
    #------------------------------------------
    SEEDINGroi="$OFOLDER/${prefix}SeedingROI.nrrd"
    cp ${PARCELLATION_NVM_WM} ${SEEDINGroi}

#    FA="${DWIid}_RTENSOR_1T_FA"; FA=${!FA}
#    crlBinaryThreshold "$FA" "$OFOLDER/roi.nrrd" 0 0.6 0 1

    #------------------------------------------
    # Define the stop tracts mask from the cortex parcellation
    #------------------------------------------
    StopTractMask="$OFOLDER/${prefix}StopTractMask.nrrd"
    crlBinaryMorphology $PARCELLATION_NVM_CX erode 1 1 $StopTractMask

    #------------------------------------------
    # Get the one-tensor file
    #------------------------------------------
    t0="${DWIid}_RTENSOR_1T"
    t0=${!t0}

    #------------------------------------------
    # Generates!
    #------------------------------------------
    OTRACTS="${OFOLDER}/${prefix}WBC_tracts.vtp64"

    echo "crlMFMTractGenerator -i $t0 -r ${SEEDINGroi} -l 1 -o $OTRACTS --famomentum 0.5 -a 40 -f 0.15 -s 5 -n 4 -d 0.5 --tractsimplify 1 -p $NBTHREADS --stoptracts_roi ${StopTractMask} --interp cquaternion "
    crlMFMTractGenerator -i "$t0" \
                             -r "${SEEDINGroi}" -l 1 \
                             -o "$OTRACTS" \
                             --famomentum 0.5 -a 40 -f 0.15 -s 5 -n 4 -d 0.5 \
                             --tractsimplify 1 -p "$NBTHREADS" \
                             --stoptracts_roi ${StopTractMask} \
                             --interp cquaternion 

    exitIfError "crlMFMTractGenerator"


    exportVariable "${DWIid}_WBC_1T_TRACTS" "$OTRACTS"

    CACHE_StepHasBeenDone "${DWIid}_WBC_1T_NOPARCEL" "${PARCELLATION_NVM_WM},${PARCELLATION_NVM_CX},$t0" "$OTRACTS"
  fi
  echo ""
}

#------------------------------------------
# Load the cache manager, init the prefix, etc...
# After the file is sourced, we are in the folder 
# "$ScanProcessedDir/common-processed"
#------------------------------------------
source "`dirname $0`/../../../ScanInfo.sh" || exit 1
source $ScriptDir/common/PipelineUtils.txt || exit 1
source $ScriptDir/common/PipelineInit.txt || exit 1

if [ -z "$3" ]; then
  doWBC_WITHOUT_PARCELLATION "$1"
else
  doWBC_WITH_PARCELLATION "$1" "$3"
fi

