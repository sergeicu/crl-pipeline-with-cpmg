#=================================================================
# AUTOMATED TRACTS PIPELINE
# pipeline scripts: Neil Weisenfeld, 2011
# methodology scripts: Ralph Suarez, 2011
#-----------------------------------------------------------------
# 
#=================================================================

# $1 : ${DWIid}

#------------------------------------------
# Load the cache manager, init the prefix, etc...
# After the file is sourced, we are in the folder 
# "$ScanProcessedDir/common-processed"
#------------------------------------------
source "`dirname $0`/../../../ScanInfo.sh" || exit 1
source $ScriptDir/common/PipelineUtils.txt || exit 1
source $ScriptDir/common/PipelineInit.txt || exit 1

DB_SUBJECTS_LIST="007 008 009 011 014 015 020 021 023 024 025 027 029 036 039"

GetTemplateLibraryDir "tracttemplates"			# Get dir in TemplateLibraryDir

DB_TEMPLATE_FOLDER="${TemplateLibraryDir}/structural"

#---------------------------------------------------------------
# Check some variables
#---------------------------------------------------------------
DWIid="$1"
prevdir=`pwd`
checkIfVariablesAreSet "${DWIid}_RTENSOR_1T"


#---------------------------------------------------------------
# ! START !
#---------------------------------------------------------------
echo "----------------------------------------"
echo " ${DWIid}"
echo " Project the tract templates to the "
echo " high-res DWI (registered to the T1)"
echo "----------------------------------------"
OFOLDER="$ScanProcessedDir/common-processed/modules/autotracts/tract_templates"
mkdir -p "$OFOLDER"

# We will project using the full tensor
tensorfile="${DWIid}_RTENSOR_1T"
tensorfile=${!tensorfile}
fafile="$OFOLDER/target_fa.nrrd"

#---------------------------------------------------------------
# First compute the target FA
#---------------------------------------------------------------
CACHE_DoStepOrNot "REGISTER_TRACTTEMPLATES_FA"
if [ $? -eq 0 ]; then
  echo "- Use previously computed FA"
  echo
else
  echo "- Compute FA..."
  crlTensorScalarParameter -f "$fafile"  "$tensorfile"
  CACHE_StepHasBeenDone "REGISTER_TRACTTEMPLATES_FA" "$tensorfile" "$fafile"
fi

#---------------------------------------------------------------
# Then compute the non-rigid transform for each template
#---------------------------------------------------------------
let count=0
for ref in $DB_SUBJECTS_LIST;
do
  echo "- Processing template $ref" 

  CACHE_DoStepOrNot "REGISTER_TRACTTEMPLATE_T${ref}"
  if [ $? -eq 0 ]; then
    echo "- Use previously projected template for ${ref}."
    echo
  else
    echo "- Project template ${ref}..."

    #---------------------------------------------------------------
    # Rigid transform
    #---------------------------------------------------------------
    crlRigidRegistration \
      ${fafile} \
      ${DB_TEMPLATE_FOLDER}/case${ref}/case${ref}_fa.nrrd  \
      $OFOLDER/${ref}-on-target-rigid.nrrd \
      $OFOLDER/${ref}-to-target-rigid.tfm 
    exitIfError "crlRigidRegistration"

    #---------------------------------------------------------------
    # Affine transform
    #---------------------------------------------------------------
    crlAffineRegistration --metricName mi \
      ${fafile} \
      ${DB_TEMPLATE_FOLDER}/case${ref}/case${ref}_fa.nrrd  \
      $OFOLDER/${ref}-on-target-affine.nrrd \
      $OFOLDER/${ref}-to-target-affine.tfm \
      $OFOLDER/${ref}-to-target-rigid.tfm
    exitIfError "crlAffineRegistration"

    #---------------------------------------------------------------
    # Non-rigid transform
    #---------------------------------------------------------------
    # write the ITK wrapper file needed by itkSuperBaloo
    echo "<TRSF> 
TRSF_TYPE=MATRICE 
MAT_TYPE=AFFI 
INVERT=0 
FILENAME=${ref}-to-target-affine.tfm 
</TRSF>" > $OFOLDER/${ref}-to-target-affine_tr.tsl

    # NOTE: itkSuperBaloo needs to run inside the data directory 
    cd "$OFOLDER"
    itkSuperBaloo \
      -r $tensorfile \
      -f ${DB_TEMPLATE_FOLDER}/case${ref}/case${ref}_clean-masked-tensors.nrrd \
      -o ${ref}-to-target-nonrig \
      -t dense -s 3 -e 0 -k 0.8 --mvt 0.000001 -n 10 -A --bhx 3 --bhy 3 --bhz 3 --blvx 1 --blvy 1 --blvz 1 --ssi tscc -p 4 \
      -i ./${ref}-to-target-affine_tr.tsl
    exitIfError "itkSuperBaloo"
    cd "$prevdir"
 
    # save memory space?
    rm $OFOLDER/${ref}-on-target-rigid.nrrd
    rm $OFOLDER/${ref}-on-target-affine.nrrd
    rm $OFOLDER/${ref}-to-target-nonrig_0.nrrd
   
    CACHE_StepHasBeenDone "REGISTER_TRACTTEMPLATE_T${ref}" "$tensorfile,${fafile}" "$OFOLDER/${ref}-to-target-nonrig_tr_1.nrrd,$OFOLDER/${ref}-to-target-nonrig_tr.tsl"
  fi

  let count=$count+1
  setCachedValue "REGISTER_TRACTTEMPLATE_${count}_TRSF" "$OFOLDER/${ref}-to-target-nonrig_tr.tsl"
  setCachedValue "REGISTER_TRACTTEMPLATE_${count}_REF" "${ref}"
done
setCachedValue "REGISTER_TRACTTEMPLATES_COUNT" "$count"


