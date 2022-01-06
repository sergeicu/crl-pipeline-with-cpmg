function doLocalizeTemplates()
{
  local Population=${1}

   if [[ ${Population} == "IBSR" ]]; then
     TARGETIMAGE=${IBSR_ALIGNED_REFERENCE_FOLDER}/in-StructuralReference.nrrd
     NUMBER_REFERENCES=${IBSR_TEMPLATE_NUMBER}
     REFERENCES_FOLDER=${IBSR_ALIGNED_REFERENCE_FOLDER}
     PARCELLATION_SUFFIX="parcellation"
   elif [[ ${Population} == "NMM" ]]; then
     TARGETIMAGE=${NMM_ALIGNED_REFERENCE_FOLDER}/in-StructuralReference.nrrd
     NUMBER_REFERENCES=${NMM_TEMPLATE_NUMBER}
     REFERENCES_FOLDER=${NMM_ALIGNED_REFERENCE_FOLDER}
     PARCELLATION_SUFFIX="nmm-parcellation"
   elif [[ ${Population} == "NVM" ]]; then
     TARGETIMAGE=${NVM_ALIGNED_REFERENCE_FOLDER}/in-StructuralReference.nrrd
     NUMBER_REFERENCES=${NVM_TEMPLATE_NUMBER}
     REFERENCES_FOLDER=${NVM_ALIGNED_REFERENCE_FOLDER}
     PARCELLATION_SUFFIX="nvm-parcellation"
   fi
}

#------------------------------------------
# Load the cache manager, init the prefix, etc...
# After the file is sourced, we are in the folder 
# "$ScanProcessedDir/common-processed"
#------------------------------------------
source "`dirname $0`/../../../ScanInfo.sh" || exit 1
source $ScriptDir/common/PipelineUtils.txt || exit 1
source $ScriptDir/common/PipelineInit.txt || exit 1

Population=${1}

#------------------------------------------
# Check some variables
#------------------------------------------
checkIfVariablesAreSet "T1W_REF,BRAIN_MASK"
showStepTitle "${Population} Brain Parcellation"

OFOLDER="${folder}/modules/Parcellation/${Population}"
mkdir -p "$OFOLDER/tmpDir"

doLocalizeTemplates "${Population}"

CACHE_DoStepOrNot "${Population}_BRAIN_PARCELLATION"
if [ $? -eq 0 ]; then
  echo "- Use previously computed ${Population} parcellation."
else
  crlOrientImage "${TARGETIMAGE}" "${OFOLDER}/StructuralReference.nrrd" axial
  crlMaskImage "${OFOLDER}/StructuralReference.nrrd" "$BRAIN_MASK" "${OFOLDER}/i-StructuralReference.nrrd"
  t1wTarget="${OFOLDER}/i-StructuralReference.nrrd"

  ###########################################
  #### RELAX REGISTRATION REGULARIZATION ####
  ###########################################
  SIZE=$(crlExtractRegion ${t1wTarget} 2)
  crlExtractROI ${t1wTarget} ${OFOLDER}/tmpDir/Input_T1w_Crop.nrrd $SIZE

  if [[ -f ${OFOLDER}/tmpDir/CroppedImages.txt ]]; then
    rm ${OFOLDER}/tmpDir/CroppedImages.txt
  fi

  for i in `seq 1 ${NUMBER_REFERENCES}`; do
    num=$( printf %03d ${i} )
    
    CACHE_DoStepOrNot "${Population}-Cropped-Template-${num}"
    if [ $? -eq 0 ]; then
          echo "- Use previously cropped ${Population}-template-${num}"
          echo
    else
      crlExtractROI ${REFERENCES_FOLDER}/r-c${num}-t1w.nrrd ${OFOLDER}/tmpDir/r-c${num}-t1w-cropped.nrrd $SIZE 
      crlExtractROI ${REFERENCES_FOLDER}/r-c${num}-${PARCELLATION_SUFFIX}.nrrd ${OFOLDER}/tmpDir/r-c${num}-parcellation-cropped.nrrd $SIZE
      #crlExtractROI ${REFERENCES_FOLDER}/r-c${num}-parcellation.nrrd ${OFOLDER}/tmpDir/r-c${num}-parcellation-cropped.nrrd $SIZE

      echo ${OFOLDER}/tmpDir/r-c${num}-t1w-cropped.nrrd >> ${OFOLDER}/tmpDir/CroppedImages.txt

      #CACHE_StepHasBeenDone "${Population}-Cropped-Template-${num}" "${T1W_REF},${BRAIN_MASK}" "${OFOLDER}/tmpDir/r-c${num}-parcellation-cropped.nrrd"
      CACHE_StepHasBeenDone "${Population}-Cropped-Template-${num}" "${T1W_REF},${ICC_MASK}" "${OFOLDER}/tmpDir/r-c${num}-parcellation-cropped.nrrd"
    fi
  done

  crlGenerateMaskFromInputImages -s ${OFOLDER}/tmpDir/CroppedImages.txt -m ${OFOLDER}/tmpDir/Cropped_ComputationMask.nrrd -n ${NBTHREADS} 

  if [[ -f ${OFOLDER}/tmpDir/${Population}-Reference-Labels.txt ]]; then
    rm ${OFOLDER}/tmpDir/${Population}-Reference-Labels.txt
    rm ${OFOLDER}/tmpDir/${Population}-Reference-Structural.txt
  fi

  for i in `seq 1 ${NUMBER_REFERENCES}`; do
    num=$( printf %03d ${i} )

    CACHE_DoStepOrNot "WR-${Population}-Cropped-Template-${num}"
    if [ $? -eq 0 ]; then
          echo "- Use previously weakly regularized ${Population}-template-${num}"
          echo
    else

      crlModifyIntensityAndSegmentationUsingNonDiffeomorphicMatching -p ${NBTHREADS} -X 2 -Y 2 -Z 2 -m ${OFOLDER}/tmpDir/Cropped_ComputationMask.nrrd -x 2 -y 2 -z 2 -o ${OFOLDER}/tmpDir/wr-c${num}-t1w-cropped.nrrd -O ${OFOLDER}/tmpDir/wr-c${num}-parcellation-cropped.nrrd -T ${OFOLDER}/tmpDir/Input_T1w_Crop.nrrd -A ${OFOLDER}/tmpDir/r-c${num}-t1w-cropped.nrrd -L ${OFOLDER}/tmpDir/r-c${num}-parcellation-cropped.nrrd

      #CACHE_StepHasBeenDone "WR-${Population}-Cropped-Template-${num}" "${T1W_REF},${BRAIN_MASK}" "${OFOLDER}/tmpDir/wr-c${num}-parcellation-cropped.nrrd"
      CACHE_StepHasBeenDone "WR-${Population}-Cropped-Template-${num}" "${T1W_REF},${ICC_MASK}" "${OFOLDER}/tmpDir/wr-c${num}-parcellation-cropped.nrrd"
    fi

    echo ${OFOLDER}/tmpDir/wr-c${num}-t1w-cropped.nrrd >> ${OFOLDER}/tmpDir/${Population}-Reference-Structural.txt
    echo ${OFOLDER}/tmpDir/wr-c${num}-parcellation-cropped.nrrd >> ${OFOLDER}/tmpDir/${Population}-Reference-Labels.txt
  done

  ################################
  #### ESTIMATE STAPLE FUSION ####
  ################################
  CACHE_DoStepOrNot "${Population}-STAPLE-Fusion"
  if [ $? -eq 0 ]; then
          echo "- Use previously weakly regularized ${Population}-template-${num}"
          echo
  else
    if [[ ${PARCELLATION_STRATEGY} == 0 ]]; then
      crlLocalLOPSTAPLE -p ${NBTHREADS} -x 3 -y 3 -z 3 -O ${OFOLDER}/tmpDir/tmp-${Population}-STAPLE.nrrd -o ${OFOLDER}/tmpDir/tmp-${Population}-STAPLE-weights.nrrd -l ${OFOLDER}/tmpDir/${Population}-Reference-Labels.txt -F
    elif [[ ${PARCELLATION_STRATEGY} == 1 ]]; then
      crlProbabilisticGMMSTAPLE -p ${NBTHREADS} -x 16 -y 16 -z 16 -X 1 -Y 1 -Z 1 -T ${OFOLDER}/tmpDir/Input_T1w_Crop.nrrd -S ${OFOLDER}/tmpDir/${Population}-Reference-Labels.txt -I ${OFOLDER}/tmpDir/${Population}-Reference-Structural.txt -t 4 -O ${OFOLDER}/tmpDir/tmp-${Population}-STAPLE.nrrd
    fi

    #CACHE_StepHasBeenDone "${Population}-STAPLE-Fusion" "${T1W_REF},${BRAIN_MASK}" "${OFOLDER}/tmpDir/tmp-${Population}-STAPLE.nrrd"
    CACHE_StepHasBeenDone "${Population}-STAPLE-Fusion" "${T1W_REF},${ICC_MASK}" "${OFOLDER}/tmpDir/tmp-${Population}-STAPLE.nrrd"
  fi

  k=0
  for i in $SIZE; do
    START[$k]=$i
    ((++k))
  done
  crlCreateNullImageFromImage ${T1W_REF} ${OFOLDER}/${prefix}Parcellation${Population}.nrrd
  exitIfError "crlCreateNullImageFromImage"

  crlInsertROI ${OFOLDER}/${prefix}Parcellation${Population}.nrrd ${OFOLDER}/tmpDir/tmp-${Population}-STAPLE.nrrd ${START[0]} ${START[1]} ${START[2]}
  exitIfError "crlInsertROI"

  rm -rf "${REFERENCES_FOLDER}"

  exportVariable "PARCELLATION_${Population}" "${OFOLDER}/${prefix}Parcellation${Population}.nrrd"

  #CACHE_StepHasBeenDone "${Population}_BRAIN_PARCELLATION" "${T1W_REF},${BRAIN_MASK}" "${OFOLDER}/${prefix}Parcellation${Population}.nrrd"
  CACHE_StepHasBeenDone "${Population}_BRAIN_PARCELLATION" "${T1W_REF},${ICC_MASK}" "${OFOLDER}/${prefix}Parcellation${Population}.nrrd"
  echo
fi

#############################################################################
#### IF NVM PARCELLATION - GENERATE TISSUE SEGMENTATION FOR TRACTOGRAPHY ####
#############################################################################
if [[ ${Population} == "NVM" ]]; then

  CACHE_DoStepOrNot "PARCELLATION_TISSUES_NVM" 1.02
  if [ $? -eq 0 ]; then
    echo "- Use previously computed WM/GM parcellation."
  else
    crlScalarImageAlgebra -i ${PARCELLATION_NVM} -o "${OFOLDER}/${prefix}ParcellationNVM_WM.nrrd" -s "(v1==7 || v1==12 || v1==13 || v1==14 || v1==15 || v1==29 || v1==30 )?1:0"
    crlScalarImageAlgebra -i ${PARCELLATION_NVM} -o "${OFOLDER}/${prefix}ParcellationNVM_CSF.nrrd" -s "(v1==19 || v1==20 || v1==21 || v1==22 || v1==1 || v1==2 || v1==16 || v1==135)?1:0"
    crlScalarImageAlgebra -i ${PARCELLATION_NVM} -i "${OFOLDER}/${prefix}ParcellationNVM_WM.nrrd" -i "${OFOLDER}/${prefix}ParcellationNVM_CSF.nrrd" -o "${OFOLDER}/${prefix}ParcellationNVM_GM.nrrd" -s "(v1!=0 && v2==0 && v3==0)?1:0"

    crlScalarImageAlgebra -i ${PARCELLATION_NVM} -i "${OFOLDER}/${prefix}ParcellationNVM_GM.nrrd" -o "${OFOLDER}/${prefix}ParcellationNVM_CX.nrrd" -s "(v2!=0 && (v1!=3 && v1!=4 && v1!=5 && v1!=6 && v1!=7 && v1!=8 && v1!=9 && v1!=17 && v1!=18 && v1!=23 && v1!=24 && v1!=25 && v1!=26 && v1!=27 && v1!=28 && v1!=29 && v1!=30 ))?1:0"

    exportVariable "PARCELLATION_NVM_GM" "${OFOLDER}/${prefix}ParcellationNVM_GM.nrrd"
    exportVariable "PARCELLATION_NVM_WM" "${OFOLDER}/${prefix}ParcellationNVM_WM.nrrd"
    exportVariable "PARCELLATION_NVM_CSF" "${OFOLDER}/${prefix}ParcellationNVM_CSF.nrrd"
    exportVariable "PARCELLATION_NVM_CX" "${OFOLDER}/${prefix}ParcellationNVM_CX.nrrd"

    CACHE_StepHasBeenDone "PARCELLATION_TISSUES_NVM" "${PARCELLATION_NVM}" "${OFOLDER}/${prefix}ParcellationNVM_GM.nrrd,${OFOLDER}/${prefix}ParcellationNVM_WM.nrrd,${OFOLDER}/${prefix}ParcellationNVM_CSF.nrrd,${OFOLDER}/${prefix}ParcellationNVM_CX.nrrd"
    echo
  fi
  echo ""

  if [[ ${NB_DWI_FOLDERS} -ge 1 ]]; then
    for (( i=0; i<${NB_DWI_FOLDERS} ; i++ ))
    do
      d="${DWI_FOLDERS[$i]}" 
      dwikey=`basename $d`

      showStepTitle "Align NVM Parcellation to ${dwikey}"
      CACHE_DoStepOrNot "PARCELLATION_TISSUES_NVM_${dwikey}" 1.03
	  if [ $? -eq 0 ]; then
	    echo "- Use previously computed DWI parcellation for ${dwikey}."
	  else
	    trsf="${dwikey}_T1W2DWI_TRSF"; trsf=${!trsf}
	    geom="${dwikey}_TENSOR_1T_FA"; geom=${!geom}
	    crlResampler2 -i "${PARCELLATION_NVM_GM}" -g "${geom}" -t "${trsf}" -o ${OFOLDER}/${prefix}${dwikey}_NVM_GM.nrrd --interp nearest
	    crlResampler2 -i "${PARCELLATION_NVM_WM}" -g "${geom}" -t "${trsf}" -o ${OFOLDER}/${prefix}${dwikey}_NVM_WM.nrrd --interp nearest
	    crlResampler2 -i "${PARCELLATION_NVM_CSF}" -g "${geom}" -t "${trsf}" -o ${OFOLDER}/${prefix}${dwikey}_NVM_CSF.nrrd --interp nearest
	    crlResampler2 -i "${PARCELLATION_NVM_CX}" -g "${geom}" -t "${trsf}" -o ${OFOLDER}/${prefix}${dwikey}_NVM_CX.nrrd --interp nearest
	    crlResampler2 -i "${PARCELLATION_NVM}" -g "${geom}" -t "${trsf}" -o ${OFOLDER}/${prefix}${dwikey}_NVM.nrrd --interp nearest

            exportVariable "${dwikey}_PARCELLATION_NVM_GM" "${OFOLDER}/${prefix}${dwikey}_NVM_GM.nrrd"
            exportVariable "${dwikey}_PARCELLATION_NVM_WM" "${OFOLDER}/${prefix}${dwikey}_NVM_WM.nrrd"
            exportVariable "${dwikey}_PARCELLATION_NVM_CSF" "${OFOLDER}/${prefix}${dwikey}_NVM_CSF.nrrd"
            exportVariable "${dwikey}_PARCELLATION_NVM_CX" "${OFOLDER}/${prefix}${dwikey}_NVM_CX.nrrd"


	    CACHE_StepHasBeenDone "PARCELLATION_TISSUES_NVM_${dwikey}" "${PARCELLATION_NVM_GM},${PARCELLATION_NVM_WM},${PARCELLATION_NVM_CSF}" "${OFOLDER}/${prefix}${dwikey}_NVM_GM.nrrd,${OFOLDER}/${prefix}${dwikey}_NVM_WM.nrrd,${OFOLDER}/${prefix}${dwikey}_NVM_CSF.nrrd,${OFOLDER}/${prefix}${dwikey}_NVM_CX.nrrd"   
	  fi

          echo
    done
  fi

  if [[ ${NB_MULTIB_DWI_FOLDERS} -ge 1 ]]; then
    for (( i=0; i<${NB_MULTIB_DWI_FOLDERS} ; i++ ))
    do
      d="${MULTIB_DWI_FOLDERS[$i]}" 
      dwikey=`basename $d`

      showStepTitle "Align NVM Parcellation to ${dwikey}"
      CACHE_DoStepOrNot "PARCELLATION_TISSUES_NVM_${dwikey}" 1.03
      if [ $? -eq 0 ]; then
        echo "- Use previously computed DWI parcellation for ${dwikey}."
      else
        trsf="${dwikey}_T1W2DWI_TRSF"; trsf=${!trsf}
	geom="${dwikey}_TENSOR_1T_FA"; geom=${!geom}
	crlResampler2 -i "${PARCELLATION_NVM_GM}" -g "${geom}" -t "${trsf}" -o ${OFOLDER}/${prefix}${dwikey}_NVM_GM.nrrd --interp nearest
	crlResampler2 -i "${PARCELLATION_NVM_WM}" -g "${geom}" -t "${trsf}" -o ${OFOLDER}/${prefix}${dwikey}_NVM_WM.nrrd --interp nearest
	crlResampler2 -i "${PARCELLATION_NVM_CSF}" -g "${geom}" -t "${trsf}" -o ${OFOLDER}/${prefix}${dwikey}_NVM_CSF.nrrd --interp nearest
	crlResampler2 -i "${PARCELLATION_NVM_CX}" -g "${geom}" -t "${trsf}" -o ${OFOLDER}/${prefix}${dwikey}_NVM_CX.nrrd --interp nearest
	crlResampler2 -i "${PARCELLATION_NVM}" -g "${geom}" -t "${trsf}" -o ${OFOLDER}/${prefix}${dwikey}_NVM.nrrd --interp nearest

        exportVariable "${dwikey}_PARCELLATION_NVM_GM" "${OFOLDER}/${prefix}${dwikey}_NVM_GM.nrrd"
        exportVariable "${dwikey}_PARCELLATION_NVM_WM" "${OFOLDER}/${prefix}${dwikey}_NVM_WM.nrrd"
        exportVariable "${dwikey}_PARCELLATION_NVM_CSF" "${OFOLDER}/${prefix}${dwikey}_NVM_CSF.nrrd"
        exportVariable "${dwikey}_PARCELLATION_NVM_CX" "${OFOLDER}/${prefix}${dwikey}_NVM_CX.nrrd"

	CACHE_StepHasBeenDone "PARCELLATION_TISSUES_NVM_${dwikey}" "${PARCELLATION_NVM},${PARCELLATION_NVM_GM},${PARCELLATION_NVM_WM},${PARCELLATION_NVM_CSF}" "${OFOLDER}/${prefix}${dwikey}_NVM.nrrd,${OFOLDER}/${prefix}${dwikey}_NVM_GM.nrrd,${OFOLDER}/${prefix}${dwikey}_NVM_WM.nrrd,${OFOLDER}/${prefix}${dwikey}_NVM_CSF.nrrd,${OFOLDER}/${prefix}${dwikey}_NVM_CX.nrrd"         
      fi

      echo
     done
  fi
fi

if [ ! -z "${OFOLDER}" ]; then
  rm -Rf "${OFOLDER}/tmpDir"
fi

echo ""
