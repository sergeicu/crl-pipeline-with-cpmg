#!/bin/sh

if [ $# -ne 3 ]; then
    echo "----------------------------------------------------------"
    echo " CRL Analysis Pipeline - FMRI Common module"
    echo 
    echo " (c) CRL, Benoit Scherrer, 2011"
    echo "     benoit.scherrer@childrens.harvard.edu"
    echo "----------------------------------------------------------"
    echo "SYNTAX: fmri_common.sh [NIIFOLDER] [FMRIid] [0:frmi/1:rsfmri]"
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

FMRIFOLDER="$1"
FMRIid="$2"
RSFMRI="$3"


#------------------------------------------
# Check that we have nii files in the folder
#------------------------------------------
nbnii=`find "${FMRIFOLDER}"/* -type f -name *.nii | wc -l`
if [ $nbnii -eq 0 ]; then
    echo "ERROR. No nii files found in ${FMRIFOLDER}."
    exit 1
fi


#------------------------------------------
# Output folder for the module
#------------------------------------------
OFOLDER="$CommonProcessedFolder/modules/fmri/${FMRIid}"
mkdir -p "$OFOLDER"


#------------------------------------------
# Check some variables
#------------------------------------------
checkIfVariablesAreSet "T1W_REF"


#-------------------------------------------------
# Go! Run the matlab processing
#-------------------------------------------------
showStepTitle "Run MATLAB fMRI processing"
CACHE_DoStepOrNot "${FMRIid}_COMMON_MATLAB" 
if [  $? -eq 0 ]; then
    echo "- Use previously computed matlab processing."
else
    mkdir -p "$OFOLDER/spm"
    cp ${FMRIFOLDER}/*.nii "$OFOLDER/spm"
   
  #-------------------------------------------------
  # run matlab processing. Need to be in the folder with the niftis
  #-------------------------------------------------
    prevdir=`pwd`
    cd "$OFOLDER/spm"
    cp `dirname $0`/batch_fmri.m ./
  #matlab -nodesktop -nosplash -r "fmrimatlabprocessing;quit;"
    /opt/matlab/matlab-R2010b/bin/matlab  -nodesktop -nosplash -r "batch_fmri('${FMRIid}');quit;"
    mv $OFOLDER/spm/sr*.nii $OFOLDER
    mv $OFOLDER/spm/spmT_* $OFOLDER
    mv $OFOLDER/spm/con_* $OFOLDER
    cd "$prevdir"

    rm $OFOLDER/spm/rfmri_*.nii
    
    ifmri=`find "$FMRIFOLDER"/* -type f -name *.nii|head -1`
    ofmri=`find "$OFOLDER"/* -type f -name sr*.nii|head -1`  
    CACHE_StepHasBeenDone "${FMRIid}_COMMON_MATLAB" "`dirname $0`/batch_fmri.m,$ifmri" "$ofmri"
fi
echo ""


#-------------------------------------------------
# Register the mean fmri space to the t1w
#-------------------------------------------------
showStepTitle "Register fMRI to t1w"
CACHE_DoStepOrNot "${FMRIid}_REG_FMRItoT1" "1.01"
if [  $? -eq 0 ]; then
    echo "- Use previously computed registration."
else
    meanfmri=`find "$OFOLDER"/* -type f -name meanfmri*.nii|head -1`
    crlRigidRegistration "${T1W_REF_MASKED}" $meanfmri "$OFOLDER/${prefix}fMRItoT1W.nrrd" "$OFOLDER/${prefix}fMRItoT1W.tfm"
        
    CACHE_StepHasBeenDone "${FMRIid}_REG_FMRItoT1" "$meanfmri,${T1W_REF_MASKED}" "$OFOLDER/${prefix}fMRItoT1W.nrrd,$OFOLDER/${prefix}fMRItoT1W.tfm"
fi
echo ""


#-----------------------------------------------------------------
# Resample rsfmri volumes and Compute correlation between parcels
#-----------------------------------------------------------------
if [ $RSFMRI -eq 1 ]; then
    showStepTitle "Compute resting state correlation between parcels"
    CACHE_DoStepOrNot "${FMRIid}_RSFMRI_CORR"
    if [  $? -eq 0 ]; then
	echo "- Use previously computed step."
    else
	echo "Resampling fMRI volumes..."
	for d in `find $OFOLDER -name sr*.nii`; do crlResampler "$d" "$OFOLDER/${prefix}fMRItoT1W.tfm" "$OFOLDER/${prefix}fMRItoT1W.nrrd" linear  "$OFOLDER/a`basename $d`"; done
	crlConstructVectorImage `find "$OFOLDER" -name asr*.nii|sort` "$OFOLDER/${prefix}asrfmri.nrrd"
	rm `find $OFOLDER -name asr*.nii`
	
	if [ ! -z "$PARCELLATION_IBSR" ] && [ -f "$PARCELLATION_IBSR" ]; then
	    echo "IBSR..."
	    /home/ch125552/projects/crkit/install/x86_64/bin/crlrfcMRILabelCorrelationsCSV -m -s "$PARCELLATION_IBSR" -o "$OFOLDER/${prefix}IBSR_rsfMRI_Correlation.csv" -i "$OFOLDER/${prefix}asrfmri.nrrd"
	fi
	if [ ! -z "$PARCELLATION_NMM" ] && [ -f "$PARCELLATION_NMM" ]; then
	    echo "NMM..."
	    /home/ch125552/projects/crkit/install/x86_64/bin/crlrfcMRILabelCorrelationsCSV -m -s "$PARCELLATION_NMM" -o "$OFOLDER/${prefix}NMM_rsfMRI_Correlation.csv" -i "$OFOLDER/${prefix}asrfmri.nrrd"
	fi
	
    #ifmri=`find "$OFOLDER"/* -type f -name sr*.nii|head -1`  
	CACHE_StepHasBeenDone "${FMRIid}_RSFMRI_CORR" "$OFOLDER/${prefix}fMRItoT1W.tfm" "$OFOLDER/${prefix}asrfmri.nrrd,$OFOLDER/${prefix}IBSR_rsfMRI_Correlation.csv"
    fi
    echo ""
fi
