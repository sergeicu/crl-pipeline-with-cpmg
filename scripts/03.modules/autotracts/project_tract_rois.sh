#=================================================================
# AUTOMATED TRACTS PIPELINE
# pipeline scripts: Neil Weisenfeld, 2011
# methodology scripts: Ralph Suarez, 2011
#-----------------------------------------------------------------
# 
#=================================================================

# $1 : ${DWIid}
# $3 : 'RALPH' or other for future rois?

#------------------------------------------
# Load the cache manager, init the prefix, etc...
# After the file is sourced, we are in the folder 
# "$ScanProcessedDir/common-processed"
#------------------------------------------
source "`dirname $0`/../../../ScanInfo.sh" || exit 1
source $ScriptDir/common/PipelineUtils.txt || exit 1
source $ScriptDir/common/PipelineInit.txt || exit 1

GetTemplateLibraryDir "tracttemplates"			# Get dir in TemplateLibraryDir

DB_SUBJECTS_LIST="007 008 009 011 014 015 020 021 023 024 025 027 029 036 039"

DWIid="$1"
ROIS="$3"

if [ "$ROIS" == "RALPH" ]; then
  DB_ROI_FOLDER="${TemplateLibraryDir}/ralph_roi"
  DB_ROI_LIST="CC CS CI OR TR SF"
elif [ "$ROIS" == "WILL" ]; then
  DB_ROI_FOLDER="${TemplateLibraryDir}/will_roi"
  DB_ROI_LIST="IFOF ILF UF AFfromdensity"
else
  echo "ERROR. Invalid ROI argument: $ROIS"
  return 1;
fi

#------------------------------------------
# Check some variables
#------------------------------------------

checkIfVariablesAreSet "${DWIid}_RTENSOR_1T,REGISTER_TRACTTEMPLATES_COUNT"

#-------------------------------------------
# Run  script
#-------------------------------------------
echo "----------------------------------------"
echo " ${DWIid}"
echo " Project Rois for $ROIS"
echo "----------------------------------------"

OFOLDER="$ScanProcessedDir/common-processed/modules/autotracts/projected-rois_${ROIS}/on-target"
mkdir -p "$OFOLDER"
prevfolder=`pwd`

tensors="${DWIid}_RTENSOR_1T"
tensors=${!tensors}

nbtemplates="REGISTER_TRACTTEMPLATES_COUNT"
nbtemplates=${!nbtemplates}

fafile="$ScanProcessedDir/common-processed/modules/autotracts/tract_templates/target_fa.nrrd"

#--------------------------------------------------------------
# PROJECT THE RALPH ROIs
#--------------------------------------------------------------

for (( i=1; i<=${nbtemplates} ; i++ ))
do
  echo "- Template $i/${nbtemplates}"
  CACHE_DoStepOrNot "PROJECTROI_${ROIS}_T${i}"
  if [ $? -eq 0 ]; then
    echo "  - Use previously projected rois for this template."
    echo
  else
    trsf="REGISTER_TRACTTEMPLATE_${i}_TRSF"
    trsf=${!trsf}
    ref="REGISTER_TRACTTEMPLATE_${i}_REF"
    ref=${!ref}

    ofiles=""

    for roi in $DB_ROI_LIST;
    do
      if [ -f "${DB_ROI_FOLDER}/case${ref}/${ref}-${roi}-roi.nrrd" ]; then
        cd "$ScanProcessedDir/common-processed/modules/autotracts/tract_templates/"

        echo "  - Project ${ref}-${roi}-roi.nrrd ($ROIS)"

        # Resample the ROIs from the moving data set to match the target
        itkApplyTrsfSerie \
         -i "${DB_ROI_FOLDER}/case${ref}/${ref}-${roi}-roi.nrrd" \
         -o "${OFOLDER}/${ref}-on-target-${roi}-roi.nrrd" \
         -t "$trsf"  \
         -g "${fafile}"  \
         -p -1 

        if [ -z "$ofiles" ]; then
          ofiles="${OFOLDER}/${ref}-on-target-${roi}-roi.nrrd"
        else
          ofiles="${ofiles},${OFOLDER}/${ref}-on-target-${roi}-roi.nrrd"
        fi

        cd "$prevfolder"
      fi
    done
    
    CACHE_StepHasBeenDone "PROJECTROI_${ROIS}_T${i}" "$trsf" "$ofiles"
  fi
done

#--------------------------------------------------------------
# COMPUTE STAPLE ROI
#--------------------------------------------------------------
showStepTitle "Compute STAPLE rois"
OFOLDER="$ScanProcessedDir/common-processed/modules/autotracts/projected-rois_${ROIS}"
mkdir -p "$OFOLDER"

for roi in $DB_ROI_LIST;
do
  CACHE_DoStepOrNot "PROJECTROI_${ROIS}_STAPLE_R${roi}"
  if [ $? -eq 0 ]; then
    echo "- Use previously STAPLE roi for ${roi}."
    echo
  else
    echo "- Run STAPLE for roi ${roi}."

    cd "$OFOLDER"

    cmdline=""
    for (( i=1; i<=${nbtemplates} ; i++ ))
    do
      ref="REGISTER_TRACTTEMPLATE_${i}_REF"
      ref=${!ref}

      if [ -f "${OFOLDER}/on-target/${ref}-on-target-${roi}-roi.nrrd" ]; then
        cmdline="$cmdline ${OFOLDER}/on-target/${ref}-on-target-${roi}-roi.nrrd"
      fi
    done

    crlSTAPLE -o "${OFOLDER}/on-target/${roi}-staple-weights.nrrd" $cmdline > ./STAPLE_${roi}-output_log.txt


    # write STAPLE roi from weights file
    crlIndexOfMaxComponent \
      "${OFOLDER}/on-target/${roi}-staple-weights.nrrd" \
      "${OFOLDER}/${roi}-roi.nrrd"

    cd "$prevfolder"

    rm -f "${OFOLDER}/on-target/${roi}-staple-weights.nrrd"

    CACHE_StepHasBeenDone "PROJECTROI_${ROIS}_STAPLE_R${roi}" "$trsf" "${OFOLDER}/${roi}-roi.nrrd" 
  fi
done

