#---------------------------------------------------------
# WBC common function for 1T whole brain connectivity
#---------------------------------------------------------
# $1 : ${DWIid}
# $2 : 0=single b-value / 1 = multi b-value dwi
# $3 : SeedingStrategy. '' = From WM 
#                       'SeedingInterface' = WM/GM interface

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
if [[ -z "$3" ]]; then
  SeedingStrategy=""
else
  SeedingStrategy="_${3}"
fi

checkIfVariablesAreSet "${DWIid}_B632MFM_3F_T0,${DWIid}_B632MFM_3F_T1,${DWIid}_B632MFM_3F_T2,${DWIid}_B632MFM_3F_F,PARCELLATION_NVM_CX,PARCELLATION_NVM_WM,PARCELLATION_NVM_GM"

t0="${DWIid}_B632MFM_3F_T0"; t0=${!t0}
t1="${DWIid}_B632MFM_3F_T1"; t1=${!t1}
t2="${DWIid}_B632MFM_3F_T2"; t2=${!t2}
f="${DWIid}_B632MFM_3F_F"; f=${!f}

if [[ "${USE_MFM_3T_T1WRES}" == "NO" ]] && [[ "${USE_MFMFromHARDI_3T_T1WRES}" == "NO" ]]; then
  echo "Need either USE_MFM_3T_T1WRES=YES or USE_MFMFromHARDI_3T_T1WRES=YES"
  exit 1
fi


#------------------------------------------
# Compute WBC
#------------------------------------------

OFOLDER="${CommonProcessedFolder}/modules/wbc/${DWIid}-3T"
mkdir -p "$OFOLDER"

OTRACTS="${OFOLDER}/${prefix}WBC_tracts${SeedingStrategy}.vtp64"

showStepTitle "Whole Brain Connectivity - 3T"
CACHE_DoStepOrNot "${DWIid}_WBC_3T${SeedingStrategy}" "2.1"
if [ $? -eq 0 ]; then
  echo "- Use previously computed wbc."
  echo
else
  #------------------------------------------
  # Define the seeding ROI from the WM parcellation
  #------------------------------------------
  if [[ "${SeedingStrategy}" == "_SeedingInterface" ]]; then
    SEEDINGroi="$OFOLDER/${prefix}SeedingROIWMGM.nrrd"
    crlBinaryMorphology $PARCELLATION_NVM_GM dilate 1 2 $SEEDINGroi
    crlScalarImageAlgebra -i "$PARCELLATION_NVM_WM" -i "$SEEDINGroi" -o "$SEEDINGroi" -s "(v1==1 && v2==1)?1:0" 

  else
    SEEDINGroi="$OFOLDER/${prefix}SeedingROI.nrrd"
    cp ${PARCELLATION_NVM_WM} ${SEEDINGroi}
  fi
  
  #------------------------------------------
  # Define the stop tracts mask from the cortex parcellation
  #------------------------------------------
  StopTractMask="$OFOLDER/${prefix}StopTractMask.nrrd"
  crlBinaryMorphology $PARCELLATION_NVM_CX erode 1 1 $StopTractMask

  #------------------------------------------
  # Tracto parameters
  #------------------------------------------
  

  if [[ "${SeedingStrategy}" == "_SeedingInterface" ]]; then
    TRACTO_N=15    # Seeding from WM/GM: 15  ;  Seeding from WM: 4
    TRACTO_S=4
    TRACTO_A=30
    TRACTO_FA=0.2
  else
    TRACTO_N=4   # Seeding from WM/GM: 15  ;  Seeding from WM: 4
    TRACTO_S=5
    TRACTO_A=35
    TRACTO_FA=0.15
  fi

  #------------------------------------------
  # Run tracto!
  #------------------------------------------
  crlMFMTractGenerator -i "$t0" -i "$t1" -i "$t2" --fractions "$f" \
                                -r "${SEEDINGroi}" -l 1 \
                                -o "$OTRACTS" \
                                --famomentum 0.5 -a ${TRACTO_A} -f ${TRACTO_FA} -s ${TRACTO_S} -n ${TRACTO_N} -d 0.5 \
                                --tractsimplify 1 -p "$NBTHREADS" \
                                --interp cquaternion \
                                --stoptracts_roi ${StopTractMask}

  exitIfError "crlMFMTractGenerator"
  exportVariable "${DWIid}_WBC_3T_TRACTS${SeedingStrategy}" "$OTRACTS"

  CACHE_StepHasBeenDone "${DWIid}_WBC_3T${SeedingStrategy}" "${PARCELLATION_NVM_WM},${PARCELLATION_NVM_CX},$t0,$t1,$t2,$f" "$OTRACTS"
fi
echo ""


#------------------------------------------
# Compute connectomes
#------------------------------------------
showStepTitle "WBC Connectivity Analysis - 3T"
CACHE_DoStepOrNot "${DWIid}_WBC_3T${SeedingStrategy}_CONNECTOMES" "2.1"
if [ $? -eq 0 ]; then
  echo "- Use previously computed WBC Connectivity Analysis."
  echo
else
  ParcellationWithoutWM="$OFOLDER/${prefix}ParcellationWithoutWM.nrrd"
  crlScalarImageAlgebra -i "$PARCELLATION_NVM" -i "$PARCELLATION_NVM_GM" -o "$ParcellationWithoutWM" -s "(v2!=0)?v1:0"
  #crlNMaskImage $PARCELLATION_NVM $PARCELLATION_NVM_GM $ParcellationWithoutWM
  mkdir -p ${OFOLDER}/Connectomes

  crlDCIExtractConnectivity -s $OTRACTS -t $t0 -t $t1 -t $t2 --fractions $f -p "$NBTHREADS" \
      --parcellation $ParcellationWithoutWM --maxlabelid 135 \
      -o ${OFOLDER}/Connectomes/WBC_NVM \
      --graphcoords --streamlinecount --streamlineratio --volumeratio --arclength \
      --weightedcRD --weightedcFA --weightedcMD \
      --cRD --cFA --cMD --wisoF 
  exitIfError "crlDCIExtractConnectivity"
  
  exportVariable "${DWIid}_WBC_3T_TRACTS${SeedingStrategy}_CONNECTOMES_DIR" "${OFOLDER}/Connectomes/"


  CACHE_StepHasBeenDone "${DWIid}_WBC_3T${SeedingStrategy}_CONNECTOMES" "${OTRACTS},${PARCELLATION_NVM_WM},${PARCELLATION_NVM_CX}" ""
fi

echo
