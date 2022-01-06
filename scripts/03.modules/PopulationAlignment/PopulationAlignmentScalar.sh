#################################################
#---- REFERENCE POPULATION ALIGNMENT MODULE ----#
#################################################

function doInitializeRegistration()
{
  local Population=$1

  CRLThirdParty="/common/projects/xavier/Code/build"

  if [[ ${POPULATION_ALIGNMENT_ALGORITHM} -eq 0 ]]; then 
    #------------------------------------------#
    #---- Use CRL Block Matching Algorithm ----#
    #------------------------------------------#
    Registration="crlBlockMatchingRegistration"
    Resampler="crlBlockMatchingRegistration"

    #---- Define CRL Block Matching Parameters ----#
    CRLRigidParameters="-t similarity -s 3 -e 0 -k 0.8 -l 0.80 --sig 4.0 --mv 1.0 -n 5 --bh 3 --sb 3 --blv 3 --rs 2 --ssi cc -I linear"
    CRLAffineParameters="-t affine -s 3 -e 0 -k 0.8 -l 0.80 --sig 4.0 --mv 1.0 -n 10 --bh 3 --sb 3 --blv 2 --rs 2 --ssi cc -I linear"
    CRLDenseParameters="-t dense -s 4 -e 0 -k 0.8 -l 0.80 --sig 4.0 --mv 1.0 -n 10 --bh 4 --sb 3 --blv 3 --rs 2 --ssi cc -I linear"
    CRLResamplerParameters="-s 0 -e 0 -k 0.8 -l 0.8 --sig 4.0 --mv 0.0 -n 0 --bh 3 --sb 3 --blv 3 --rs 2 --ssi cc -N"
   
  elif [[ ${POPULATION_ALIGNMENT_ALGORITHM} -eq 1 ]]; then
    #----------------------------#
    #---- Use ANTS Algorithm ----#
    #----------------------------#
    N4="${CRLThirdParty}/ANTs/bin/N4BiasFieldCorrection"
    Registration="${CRLThirdParty}/ANTs/bin/ANTS"
    Resampler="${CRLThirdParty}/ANTs/bin/WarpImageMultiTransform"

    #---- Define ANTS Parameters ----#
    ANTSParameters="-r Gauss[0,2] -t SyN[0.5] -i 50x90x30 --use-Histogram-Matching"

  fi
}

function doInitializePopulation()
{
  local Population=$1

  if [[ ${Population} == "IBSR" ]]; then
    GetTemplateLibraryDir "IBSR"			# Get dir in TemplateLibraryDir
    
    AVERAGETEMPLATES_FOLDER="${TemplateLibraryDir}/AverageTemplate"
    T1WAVERAGETEMPLATE="t1w-Template.nii.gz"
    
    TEMPLATES_FOLDER="${TemplateLibraryDir}"
    TEMPLATESNUMBER=18
    TEMPLATESMODALITIES="t1w"
    TEMPLATESLABELMASK="parcellation tissues"

    exportVariable "${Population}_TEMPLATE_NUMBER" "${TEMPLATESNUMBER}"

  elif [[ ${Population} == "NMM" ]]; then
    #GetTemplateLibraryDir "NMM"
    GetTemplateLibraryDir "R01Controls"			# Get dir in TemplateLibraryDir
    
    AVERAGETEMPLATES_FOLDER="${TemplateLibraryDir}/AverageTemplate"
    T1WAVERAGETEMPLATE="t1w-Template.nrrd"
    
    #TEMPLATES_FOLDER="${TemplateLibraryDir}"
    TEMPLATES_FOLDER="${TemplateLibraryDir}/Masked"
    TEMPLATESNUMBER=15
    TEMPLATESMODALITIES="t1w t2w flair"
    TEMPLATESLABELMASK="nmm-parcellation"
    #TEMPLATESLABELMASK="parcellation tissues"

    exportVariable "${Population}_TEMPLATE_NUMBER" "${TEMPLATESNUMBER}"

  elif [[ ${Population} == "NVM" ]]; then
    #GetTemplateLibraryDir "NVMRelease"
    GetTemplateLibraryDir "R01Controls"			# Get dir in TemplateLibraryDir
    
    AVERAGETEMPLATES_FOLDER="${TemplateLibraryDir}/AverageTemplate"
    T1WAVERAGETEMPLATE="t1w-Template.nrrd"
    
    #TEMPLATES_FOLDER="${TemplateLibraryDir}"
    TEMPLATES_FOLDER="${TemplateLibraryDir}/Masked"
    TEMPLATESNUMBER=15
    TEMPLATESMODALITIES="t1w t2w flair"
    TEMPLATESLABELMASK="nvm-parcellation"
    #TEMPLATESLABELMASK="parcellation"

    exportVariable "${Population}_TEMPLATE_NUMBER" "${TEMPLATESNUMBER}"

  elif [[ ${Population} == "ICC" ]]; then
    GetTemplateLibraryDir "R01Controls"			# Get dir in TemplateLibraryDir
    
    AVERAGETEMPLATES_FOLDER="${TemplateLibraryDir}/WithScalpTemplate"
    T1WAVERAGETEMPLATE="t1w-Template.nii.gz"
    T2WAVERAGETEMPLATE="t2w-Template.nii.gz"
    
    TEMPLATES_FOLDER="${TemplateLibraryDir}/WithScalp"
    TEMPLATESNUMBER=15
    TEMPLATESMODALITIES="t1w t2w"
    TEMPLATESLABELMASK="icc tissues"

    exportVariable "${Population}_TEMPLATE_NUMBER" "${TEMPLATESNUMBER}"

  elif [[ ${Population} == "RefinedICC" ]]; then
    GetTemplateLibraryDir "R01Controls"			# Get dir in TemplateLibraryDir
    
    AVERAGETEMPLATES_FOLDER="${TemplateLibraryDir}/Masked"
    T1WAVERAGETEMPLATE="i-t1w-Template.nii.gz"
    
    TEMPLATES_FOLDER="${TemplateLibraryDir}/Masked"
    TEMPLATESNUMBER=15
    TEMPLATESMODALITIES="t1w t2w flair"
    TEMPLATESLABELMASK="icc tissues multilabel"

    exportVariable "${Population}_TEMPLATE_NUMBER" "${TEMPLATESNUMBER}"
    
  elif [[ ${Population} == "BabyICC" ]]; then
    GetTemplateLibraryDir "BabyControls"			# Get dir in TemplateLibraryDir
    
    AVERAGETEMPLATES_FOLDER="${TemplateLibraryDir}/WithScalpTemplate"
    T1WAVERAGETEMPLATE="t1w-Template.nii.gz"
    T2WAVERAGETEMPLATE="t2w-Template.nii.gz"
    
    TEMPLATES_FOLDER="${TemplateLibraryDir}/WithScalp"
    TEMPLATESNUMBER=15
    TEMPLATESMODALITIES="t1w t2w"
    TEMPLATESLABELMASK="icc tissues"

    exportVariable "${Population}_TEMPLATE_NUMBER" "${TEMPLATESNUMBER}"

  elif [[ ${Population} == "RefinedBabyICC" ]]; then
    GetTemplateLibraryDir "BabyControls"			# Get dir in TemplateLibraryDir
    
    AVERAGETEMPLATES_FOLDER="${TemplateLibraryDir}/Masked"
    T1WAVERAGETEMPLATE="i-t1w-Template.nii.gz"
    
    TEMPLATES_FOLDER="${TemplateLibraryDir}/Masked"
    TEMPLATESNUMBER=15
    TEMPLATESMODALITIES="t1w t2w"
    TEMPLATESLABELMASK="icc tissues"

    exportVariable "${Population}_TEMPLATE_NUMBER" "${TEMPLATESNUMBER}"

  else
     local VT100RED='\e[0;31m'
     local VT100CLEAR='\e[0m'
     echo -e "${VT100RED}ERROR. INVALID population <${Population}> when calling doInitializePopulation${VT100CLEAR}"
     exit
  fi
}

function doResampling()
{
  local input=${1}
  local output=${2}
  local reference=${3}
  local transform=${4}

  ${Resampler} 3 ${input} ${output} -R ${reference} ${transform} >> "${output}-log.txt" 2>&1
  exitIfError "${Resampler}-${output}"
}

function doPopulationAlignment_COMPOSED()
{
  local Population=$1
  local Target=$2
  local Modality=$3

  ###########################################
  #### BLOCK MATCHING BASED REGISTRATION ####
  ###########################################
  if [[ ${POPULATION_ALIGNMENT_ALGORITHM} -eq 0 ]]; then
    echo

  #################################
  #### ANTS BASED REGISTRATION ####
  #################################
  elif [[ ${POPULATION_ALIGNMENT_ALGORITHM} -eq 1 ]]; then
    
    #-------------------------------------#
    #---- ANTs Non-Rigid Registration ----#
    #-------------------------------------#
    #CACHE_DoStepOrNot "${Population}-${RegistrationTitle}-TargetToAverageTemplate-Warp"
    if [ $? -eq 0 ]; then
      echo "- Use previously estimated registration."
      echo
    else
      ${Registration} 3 -m PR[${AVERAGETEMPLATES_FOLDER}/${T1WAVERAGETEMPLATE},${Target},1,2] -o ${OFOLDER}/TargetToTemplate ${ANTSParameters}
      exitIfError "${Registration}"

      mv ${OFOLDER}/TargetToTemplateAffine.txt ${OFOLDER}/TargetToTemplate-Affine.txt
      mv ${OFOLDER}/TargetToTemplateInverseWarp.nii.gz ${OFOLDER}/TargetToTemplate-InverseWarp.nii.gz
      mv ${OFOLDER}/TargetToTemplateWarp.nii.gz ${OFOLDER}/TargetToTemplate-Warp.nii.gz

      #CACHE_StepHasBeenDone "${Population}-${RegistrationTitle}-TargetToAverageTemplate-Warp" "${T1W_REF}" "${OFOLDER}/TargetToTemplate-InverseWarp.nii.gz"
      #CACHE_StepHasBeenDone "${Population}-${RegistrationTitle}-TargetToAverageTemplate-Warp" "${T1W_REF},${BRAIN_MASK}" "${OFOLDER}/TargetToTemplate-InverseWarp.nii.gz"
    fi

    #------------------------------------------------#
    #---- Resample template population to target ----#
    #------------------------------------------------#
    for i in `seq 0 ${TEMPLATESNUMBER}`; do
      num=$(printf %03d ${i})

      for j in ${TEMPLATESMODALITIES}; do   
        #CACHE_DoStepOrNot "${Population}-${StrategyTitle}-${RegistrationTitle}-Template-${num}-${j}"
        if [ $? -eq 0 ]; then
          echo "- Use previously resampled ${Population} template-${num}-${j}"
          echo
        else
          doResampling "${TEMPLATES_FOLDER}/c${num}-${j}.nrrd" "${OFOLDER}/r-c${num}-${j}.nrrd" "${Target}" "-i ${OFOLDER}/TargetToTemplate-Affine.txt ${OFOLDER}/TargetToTemplate-InverseWarp.nii.gz ${AVERAGETEMPLATES_FOLDER}/c${num}-ToTemplate-Warp.nii.gz ${AVERAGETEMPLATES_FOLDER}/c${num}-ToTemplate-Affine.txt"
          exitIfError "${Resampler}-c${num}-${j}"

          #CACHE_StepHasBeenDone "${Population}-${StrategyTitle}-${RegistrationTitle}-Template-${num}-${j}" "${T1W_REF}" "${OFOLDER}/r-c${num}-${j}.nrrd" 
          #CACHE_StepHasBeenDone "${Population}-${StrategyTitle}-${RegistrationTitle}-Template-${num}-${j}" "${T1W_REF},${BRAIN_MASK}" "${OFOLDER}/r-c${num}-${j}.nrrd"
        fi      
      done

      for j in ${TEMPLATESLABELMASK}; do   
        #CACHE_DoStepOrNot "${Population}-${StrategyTitle}-${RegistrationTitle}-Template-${num}-${j}"
        if [ $? -eq 0 ]; then
          echo "- Use previously resampled ${Population} template-${num}-${j}"
          echo
        else
          doResampling "${TEMPLATES_FOLDER}/c${num}-${j}.nrrd" "${OFOLDER}/r-c${num}-${j}.nrrd" "${Target}" "-i ${OFOLDER}/TargetToTemplate-Affine.txt ${OFOLDER}/TargetToTemplate-InverseWarp.nii.gz ${AVERAGETEMPLATES_FOLDER}/c${num}-ToTemplate-Warp.nii.gz ${AVERAGETEMPLATES_FOLDER}/c${num}-ToTemplate-Affine.txt --use-NN"
          exitIfError "${Resampler}-c${num}-${j}"

          #CACHE_StepHasBeenDone "${Population}-${StrategyTitle}-${RegistrationTitle}-Template-${num}-${j}" "${T1W_REF}" "${OFOLDER}/r-c${num}-${j}.nrrd"
          #CACHE_StepHasBeenDone "${Population}-${StrategyTitle}-${RegistrationTitle}-Template-${num}-${j}" "${T1W_REF},${BRAIN_MASK}" "${OFOLDER}/r-c${num}-${j}.nrrd"
        fi      
      done
    done

  fi
}

function doPopulationAlignment_DIRECT()
{
  local Population=$1
  local num=$2
  local Target=$3
  local Modality=$4
  local nthreads=$5

  ###########################################
  #### BLOCK MATCHING BASED REGISTRATION ####
  ###########################################
  if [[ ${POPULATION_ALIGNMENT_ALGORITHM} -eq 0 ]]; then
    #----------------------------#
    #---- Rigid Registration ----#
    #----------------------------#
    #CACHE_DoStepOrNot "${Population}-${RegistrationTitle}-Template${num}-To-Target-Rigid"
    #if [ $? -eq 0 ]; then
      #echo "- Use previously estimated rigid registration."
      #echo
    #else
      ${Registration} -f ${TEMPLATES_FOLDER}/c${num}-${Modality}.nrrd -r ${Target} -o ${OFOLDER}/c${num}-ToTarget-Rigid ${CRLRigidParameters} -p ${nthreads}
      mv ${OFOLDER}/c${num}-ToTarget-Rigid_FinalS.tfm ${OFOLDER}/c${num}-ToTarget-Rigid.tfm
      rm ${OFOLDER}/c${num}-ToTarget-Rigid_FinalS.nrrd
      exitIfError "crlRigidRegistration-c${num}-${j}"
 
      #CACHE_StepHasBeenDone "${Population}-${RegistrationTitle}-Template${num}-To-Target-Rigid" "${T1W_REF}" "${OFOLDER}/c${num}-ToTarget-Rigid.tfm"
      #CACHE_StepHasBeenDone "${Population}-${RegistrationTitle}-Template${num}-To-Target-Rigid" "${T1W_REF},${BRAIN_MASK}" "${OFOLDER}/c${num}-ToTarget-Rigid.tfm"
    #fi
    
    #-----------------------------#
    #---- Affine Registration ----#
    #-----------------------------#
    #CACHE_DoStepOrNot "${Population}-${RegistrationTitle}-Template${num}-To-Target-Affine"
    #if [ $? -eq 0 ]; then
      #echo "- Use previously estimated affine registration."
      #echo
    #else
      ${Registration} -i ${OFOLDER}/c${num}-ToTarget-Rigid.tfm -f ${TEMPLATES_FOLDER}/c${num}-${Modality}.nrrd -r ${Target} -o ${OFOLDER}/c${num}-ToTarget-Affine ${CRLAffineParameters} -p ${nthreads} 
      mv ${OFOLDER}/c${num}-ToTarget-Affine_FinalS.tfm ${OFOLDER}/c${num}-ToTarget-Affine.tfm
      rm ${OFOLDER}/c${num}-ToTarget-Affine_FinalS.nrrd
      exitIfError "crlAffineRegistration-c${num}-${j}"
 
      #CACHE_StepHasBeenDone "${Population}-${RegistrationTitle}-Template${num}-To-Target-Affine" "${T1W_REF}" "${OFOLDER}/c${num}-ToTarget-Affine.tfm"
      #CACHE_StepHasBeenDone "${Population}-${RegistrationTitle}-Template${num}-To-Target-Affine" "${T1W_REF},${BRAIN_MASK}" "${OFOLDER}/c${num}-ToTarget-Affine.tfm"
    #fi
    
    #---------------------------------------------------#
    #---- CRL Block Matching Non-Rigid Registration ----#
    #---------------------------------------------------#
    #CACHE_DoStepOrNot "${Population}-${RegistrationTitle}-Template${num}-To-Target-Warp"
    #if [ $? -eq 0 ]; then
      #echo "- Use previously estimated registration."
      #echo
    #else
      ${Registration} -i ${OFOLDER}/c${num}-ToTarget-Affine.tfm -f ${TEMPLATES_FOLDER}/c${num}-${Modality}.nrrd -r ${Target} -o ${OFOLDER}/c${num}-ToTarget-Warp ${CRLDenseParameters} -p ${nthreads}
      mv ${OFOLDER}/c${num}-ToTarget-Warp_FinalS.tfm ${OFOLDER}/c${num}-ToTarget-Warp.tfm
      mv ${OFOLDER}/c${num}-ToTarget-Warp_FinalS.tfm.nrrd ${OFOLDER}/c${num}-ToTarget-Warp.tfm.nrrd
      rm ${OFOLDER}/c${num}-ToTarget-Warp_FinalS.nrrd
      exitIfError "${Registration}-c${num}-${j}"
      
      #CACHE_StepHasBeenDone "${Population}-${RegistrationTitle}-Template${num}-To-Target-Warp" "${T1W_REF}" "${OFOLDER}/c${num}-ToTarget-Warp.tfm"
      #CACHE_StepHasBeenDone "${Population}-${RegistrationTitle}-Template${num}-To-Target-Warp" "${T1W_REF},${BRAIN_MASK}" "${OFOLDER}/c${num}-ToTarget-Warp.tfm"
    #fi

    #----------------------------------#
    #---- Resample Template Images ----#
    #----------------------------------#
    for j in ${TEMPLATESMODALITIES}; do
      #CACHE_DoStepOrNot "${Population}-${StrategyTitle}-${RegistrationTitle}-Template-${num}-${j}"
      #if [ $? -eq 0 ]; then
        #echo "- Use previously resampled ${Population} template-${num}-${j}"
        #echo
      #else
        ${Resampler} -i ${OFOLDER}/c${num}-ToTarget-Warp.tfm -f ${TEMPLATES_FOLDER}/c${num}-${j}.nrrd -r ${Target} -o ${OFOLDER}/r-c${num}-${j} -t dense ${CRLResamplerParameters} -p ${nthreads}
        mv ${OFOLDER}/r-c${num}-${j}_FinalS.nrrd ${OFOLDER}/r-c${num}-${j}.nrrd
        exitIfError "${Resampler}-c${num}-${j}"

        #CACHE_StepHasBeenDone "${Population}-${StrategyTitle}-${RegistrationTitle}-Template-${num}-${j}" "${T1W_REF}" "${OFOLDER}/r-c${num}-${j}.nrrd"
        #CACHE_StepHasBeenDone "${Population}-${StrategyTitle}-${RegistrationTitle}-Template-${num}-${j}" "${T1W_REF},${BRAIN_MASK}" "${OFOLDER}/r-c${num}-${j}.nrrd"
      #fi 
    done

    for j in ${TEMPLATESLABELMASK}; do
      #CACHE_DoStepOrNot "${Population}-${StrategyTitle}-${RegistrationTitle}-Template-${num}-${j}"
      #if [ $? -eq 0 ]; then
        #echo "- Use previously resampled ${Population} template-${num}-${j}"
        #echo
      #else
        ${Resampler} -i ${OFOLDER}/c${num}-ToTarget-Warp.tfm -f ${TEMPLATES_FOLDER}/c${num}-${j}.nrrd -r ${Target} -o ${OFOLDER}/r-c${num}-${j} -I NN -t dense ${CRLResamplerParameters} -p ${nthreads}
        mv ${OFOLDER}/r-c${num}-${j}_FinalS.nrrd ${OFOLDER}/r-c${num}-${j}.nrrd
        exitIfError "${Resampler}-c${num}-${j}"

        #CACHE_StepHasBeenDone "${Population}-${StrategyTitle}-${RegistrationTitle}-Template-${num}-${j}" "${T1W_REF}" "${OFOLDER}/r-c${num}-${j}.nrrd"
        #CACHE_StepHasBeenDone "${Population}-${StrategyTitle}-${RegistrationTitle}-Template-${num}-${j}" "${T1W_REF},${BRAIN_MASK}" "${OFOLDER}/r-c${num}-${j}.nrrd"
      #fi 
    done

    #################################
    #### ANTS BASED REGISTRATION ####
    #################################
    elif [[ ${POPULATION_ALIGNMENT_ALGORITHM} -eq 1 ]]; then

      #-------------------------------------#
      #---- ANTs Non-Rigid Registration ----#
      #-------------------------------------#
      #CACHE_DoStepOrNot "${Population}-${RegistrationTitle}-Template${num}-To-Target-Warp"
      #if [ $? -eq 0 ]; then
        #echo "- Use previously estimated registration."
        #echo
      #else
        ${Registration} 3 -m PR[${Target},${TEMPLATES_FOLDER}/c${num}-${Modality}.nrrd,1,2] -o ${OFOLDER}/c${num}-ToTarget ${ANTSParameters}
        exitIfError "${Registration}"

        mv ${OFOLDER}/c${num}-ToTargetAffine.txt ${OFOLDER}/c${num}-ToTarget-Affine.txt
        mv ${OFOLDER}/c${num}-ToTargetWarp.nii.gz ${OFOLDER}/c${num}-ToTarget-Warp.nii.gz
        mv ${OFOLDER}/c${num}-ToTargetInverseWarp.nii.gz ${OFOLDER}/c${num}-ToTarget-InverseWarp.nii.gz

        #CACHE_StepHasBeenDone "${Population}-${RegistrationTitle}-Template${num}-To-Target-Warp" "${T1W_REF}" "${OFOLDER}/c${num}-ToTarget-Warp.nii.gz"
        #CACHE_StepHasBeenDone "${Population}-${RegistrationTitle}-Template${num}-To-Target-Warp" "${T1W_REF},${BRAIN_MASK}" "${OFOLDER}/c${num}-ToTarget-Warp.nii.gz"
      #fi

      #----------------------------------#
      #---- Resample Template Images ----#
      #----------------------------------#
      for j in ${TEMPLATESMODALITIES}; do
        #CACHE_DoStepOrNot "${Population}-${StrategyTitle}-${RegistrationTitle}-Template-${num}-${j}"
        #if [ $? -eq 0 ]; then
          #echo "- Use previously resampled ${Population} template-${num}-${j}"
          #echo
        #else
          ${Resampler} 3 ${TEMPLATES_FOLDER}/c${num}-${j}.nrrd ${OFOLDER}/r-c${num}-${j}.nrrd -R ${Target} ${OFOLDER}/c${num}-ToTarget-Warp.nii.gz ${OFOLDER}/c${num}-ToTarget-Affine.txt
          exitIfError "${Resampler}-c${num}-${j}"
         
          #CACHE_StepHasBeenDone "${Population}-${StrategyTitle}-${RegistrationTitle}-Template-${num}-${j}" "${T1W_REF}" "${OFOLDER}/r-c${num}-${j}.nrrd"
          #CACHE_StepHasBeenDone "${Population}-${StrategyTitle}-${RegistrationTitle}-Template-${num}-${j}" "${T1W_REF},${BRAIN_MASK}" "${OFOLDER}/r-c${num}-${j}.nrrd"
        #fi 
      done  

      for j in ${TEMPLATESLABELMASK}; do
        #CACHE_DoStepOrNot "${Population}-${StrategyTitle}-${RegistrationTitle}-Template-${num}-${j}"
        #if [ $? -eq 0 ]; then
          #echo "- Use previously resampled ${Population} template-${num}-${j}"
          #echo
        #else
          ${Resampler} 3 ${TEMPLATES_FOLDER}/c${num}-${j}.nrrd ${OFOLDER}/r-c${num}-${j}.nrrd -R ${Target} ${OFOLDER}/c${num}-ToTarget-Warp.nii.gz ${OFOLDER}/c${num}-ToTarget-Affine.txt --use-NN
          exitIfError "${Resampler}-c${num}-${j}"
         
          #CACHE_StepHasBeenDone "${Population}-${StrategyTitle}-${RegistrationTitle}-Template-${num}-${j}" "${T1W_REF}" "${OFOLDER}/r-c${num}-${j}.nrrd"
          #CACHE_StepHasBeenDone "${Population}-${StrategyTitle}-${RegistrationTitle}-Template-${num}-${j}" "${T1W_REF},${BRAIN_MASK}" "${OFOLDER}/r-c${num}-${j}.nrrd"
        #fi 
      done      

    fi

    #CACHE_StepHasBeenDone "${Population}-${StrategyTitle}-${RegistrationTitle}-Reference-${num}" "${T1W_REF}" "${OFOLDER}/r-c${num}-t1w.nrrd"
    #CACHE_StepHasBeenDone "${Population}-${StrategyTitle}-${RegistrationTitle}-Reference-${num}" "${T1W_REF},${BRAIN_MASK}" "${OFOLDER}/r-c${num}-t1w.nrrd"
}

function doPopulationAlignment_SCALAR()
{
  local Population="$1"
  local Target="$2"
  local Modality="$3"

  if [[ ${Modality} == "" ]] ; then
    Target=${T1W_REF}
    Modality="t1w"
  fi

  #--------------------------------#
  #---- Check for Dependencies ----#
  #--------------------------------#
  #checkIfVariablesAreSet "T1W_REF,BRAIN_MASK"
  #DEPENDENCIES="$T1W_REF,$BRAIN_MASK"

  checkIfVariablesAreSet "T1W_REF"
  DEPENDENCIES="$T1W_REF"
  
  local RegistrationTitle=""
  if [[ ${POPULATION_ALIGNMENT_ALGORITHM} == 0 ]]; then
    RegistrationTitle="crlBlockMatching"
  else
    RegistrationTitle="ANTS"
  fi

  local StrategyTitle=""
  if [[ ${POPULATION_ALIGNMENT_STRATEGY} == 1 ]]; then
    StrategyTitle="Composed"
  else
    StrategyTitle="Direct"
  fi
  

  showStepTitle "${Population} Reference - ${StrategyTitle} Registration - ${RegistrationTitle} Algorithm"

  CACHE_DoStepOrNot "${Population}_${RegistrationTitle}_${Modality}"
  if [ $? -eq 0 ]; then
     echo "- Use previously estimated alignment."
     echo
  else


     OFOLDER="${folder}/modules/ReferencePopulationAlignment/${Population}"
     mkdir -p "${OFOLDER}"
   
     prevdir=`pwd`
     cd ${OFOLDER}

     #---- Initialize Registration Algorithm Variables ----#
     doInitializeRegistration ${Population}

     #---- Initialize Reference Population Variables ----#
     doInitializePopulation "${Population}"

     #---- Correct Intensity Inhomogeneity of Target Images ----#
     cTarget=""
     if [ "${Population}" == "ICC" ]; then
       cTarget="${Target}"
     elif [ "${Population}" == "BabyICC" ]; then
       cTarget="${Target}"
     else
	crlMaskImage "${Target}" "${ICC_MASK}" "${OFOLDER}/i-StructuralReference.nrrd"
       cTarget="${OFOLDER}/i-StructuralReference.nrrd"       
     fi

    if [ -x crlN4BiasFieldCorrection ]; then
      crlN4BiasFieldCorrection ${cTarget} ${OFOLDER}/in-StructuralReference.nrrd
    else
      cp ${cTarget} ${OFOLDER}/in-StructuralReference.nrrd
    fi

    #---- Compute Reference Population Alignment ----#
    if [[ ${POPULATION_ALIGNMENT_STRATEGY} == 1 ]]; then
      #doPopulationAlignment_COMPOSED "${Population}" "${Target}" "${Modality}"
      doPopulationAlignment_COMPOSED "${Population}" "${OFOLDER}/in-StructuralReference.nrrd" "${Modality}" 

    else
      nThreadPerTemplate=`echo "scale=10; n=(${NBTHREADS}/${TEMPLATESNUMBER}+0.5); scale=0; n/1 " | bc`		# Number of threads... depends on number of templates
    if [[ $nThreadPerTemplate -eq 0 ]]; then
      nThreadPerTemplate=1
    fi
    echo "Alignment of ${TEMPLATESNUMBER} templates with ${NBTHREADS} threads -> Uses ${nThreadPerTemplate} threads per template"

      #---- We are going to run multiple registrations in parallel ----#
      export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=${nThreadPerTemplate}

      local npr=0
      local tcount=1
      local total=$(( ${TEMPLATESNUMBER}+1 ))
      while( [ ${tcount} -lt ${total} ] ); do
        while ( [ ${npr} -lt ${NBTHREADS} ] ); do
          if [ ${tcount} -lt ${total} ]; then
            num=$(printf %03d ${tcount})        

            #CACHE_DoStepOrNot "${Population}-${StrategyTitle}-${RegistrationTitle}-Reference-${num}"
            #if [ $? -eq 0 ]; then
              #echo "- Use previously resampled ${Population} template-${num}"
              #echo
            #else
              echo "Estimating alignment of Reference${num}..."
              doPopulationAlignment_DIRECT "${Population}" "${num}" "${OFOLDER}/in-StructuralReference.nrrd" "${Modality}" ${nThreadPerTemplate} > "${OFOLDER}/${Population}-Reference${num}-AlignmentLog.txt" &  
            #fi
        
            npr=$[ ${npr} + 1 ]
            tcount=$[ ${tcount} + 1 ]
          else
            npr=${NBTHREADS}
          fi
        done

        wait
        npr=0
      done
      
      rm "${OFOLDER}/*.tfm"
      
    fi 

    export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=${NBTHREADS}

    exportVariable "${Population}_ALIGNED_REFERENCE_FOLDER" "${OFOLDER}"

    cd "$prevdir"

    #---- Generates the list of output files, for the cache
    local ofiles="${OFOLDER}/r-c001-t1w.nrrd" 
    for tcount in `seq 2 ${TEMPLATESNUMBER}`
    do
      num=$(printf %03d ${tcount})        
      ofiles="$ofiles,${OFOLDER}/r-c${num}-t1w.nrrd" 
    done

    CACHE_StepHasBeenDone "${Population}_${RegistrationTitle}_${Modality}" "${T1W_REF},${ICC_MASK}" "$ofiles"
    #CACHE_StepHasBeenDone "${Population}_${RegistrationTitle}_${Modality}" "${T1W_REF}" "$ofiles"
    #CACHE_StepHasBeenDone "${Population}_${RegistrationTitle}_${Modality}" "${T1W_REF},${BRAIN_MASK}" "$ofiles"
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

doPopulationAlignment_SCALAR "$1" "$2" "$3"

  
