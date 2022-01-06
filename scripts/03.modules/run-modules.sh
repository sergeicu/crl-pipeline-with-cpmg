#!/bin/sh

#------------------------------------------
# Load the scan informations
#------------------------------------------
source "`dirname $0`/../../ScanInfo.sh" || exit 1
prevdir=`pwd`

folder="$ScanProcessedDir/common-processed"
cd "$folder"

#------------------------------------------
# Initialize the pipeline
#------------------------------------------
source $ScriptDir/common/PipelineUtils.txt || exit 1
source $ScriptDir/common/PipelineInit.txt || exit 1
echo

#------------------------------------------
# For the comma-separated anatomical modules
#------------------------------------------
tmp=`echo ${LIST_ANAT_MODULES} | sed s/,/\\\n/g`
PREVIFS=$IFS
IFS=$'\n'
for m in $tmp
do
  if [ ! -z "$m" ]; then
    
    getBooleanVariable "USE_${m}"
    if [ $? -eq 1 ]; then
      scriptfile="SCRIPT_${m}"
      scriptfile=${!scriptfile}
      echo -e "${VT100BOLD}${VT100BLUE}---------------------------------------------------------"
      echo -e " RUN ANAT MODULE <${m}>"
      echo -e " script: $scriptfile"
      echo -e "---------------------------------------------------------${VT100CLEAR}"

      useModule "$m";
      if [ $? -eq 1 ]; then
        optargs="USE_${m}_OPTARGS"
        optargs=${!optargs}

        sh "$ScriptDir/$scriptfile" $optargs
      fi
      echo ""
      echo ""
    fi
  fi
done


#------------------------------------------
# For the comma-separated diffusion modules
#------------------------------------------
tmp=`echo ${LIST_DIFF_MODULES} | sed s/,/\\\n/g`
for m in $tmp
do
  if [ ! -z "$m" ]; then
    getBooleanVariable "USE_${m}"
    if [ $? -eq 1 ]; then
      scriptfile="SCRIPT_${m}"
      scriptfile=${!scriptfile}
      echo -e "${VT100BOLD}${VT100BLUE}---------------------------------------------------------"
      echo -e " RUN DIFF MODULE <${m}>"
      echo -e " script: $scriptfile"
      echo -e "---------------------------------------------------------${VT100CLEAR}"

      useModule "$m";
      if [ $? -eq 1 ]; then

        optargs="USE_${m}_OPTARGS"
        optargs=${!optargs}

        #------------------------------------------
        # OK, now run this module on DWI* folders
        #------------------------------------------
        dfa=`getDataForAnalysis`
        DWIFolders=($(find "$dfa"/ -type d -name 'dwi*' -or -type d -name 'hardi*' ))
        nbdir=${#DWIFolders[@]}
        for (( i=0; i<${nbdir} ; i++ ));
        do
          d="${DWIFolders[$i]}" 
          d=`readlink -f "$d"`
          DWIid=`basename $d`
          DWIid=`echo "${DWIid}" | sed "s/ /_/g"`
          sh "$ScriptDir/$scriptfile" "${DWIid}" 0 $optargs
        done

         #------------------------------------------
        # AMD now run this module on CUSP* folders
        #------------------------------------------
        dfa=`getDataForAnalysis`
        DWIFolders=($(find "$dfa"/ -type d -name 'cusp*' -or -type d -name 'ms*' -or -type d -name 'dsi*' ))
        nbdir=${#DWIFolders[@]}
        for (( i=0; i<${nbdir} ; i++ ));
        do
          d="${DWIFolders[$i]}" 
          d=`readlink -f "$d"`
          DWIid=`basename $d`
          DWIid=`echo "${DWIid}" | sed "s/ /_/g"`
          sh "$ScriptDir/$scriptfile" "${DWIid}" 1 $optargs
        done
       
      fi
      echo ""
      echo ""
    fi
  fi
done



#-------------------------------------
# For the comma-separated fMRI modules
#-------------------------------------
tmp=`echo ${LIST_FMRI_MODULES} | sed s/,/\\\n/g`
for m in $tmp
do
  if [ ! -z "$m" ]; then
    getBooleanVariable "USE_${m}"
    if [ $? -eq 1 ]; then
      scriptfile="SCRIPT_${m}"
      scriptfile=${!scriptfile}
      echo -e "${VT100BOLD}${VT100BLUE}---------------------------------------------------------"
      echo -e " RUN FMRI MODULE <${m}>"
      echo -e " script: $scriptfile"
      echo -e "---------------------------------------------------------${VT100CLEAR}"

      useModule "$m";
      if [ $? -eq 1 ]; then

        optargs="USE_${m}_OPTARGS"
        optargs=${!optargs}

        #------------------------------------------
        # OK, now run this module on fmri* folders
        #------------------------------------------
        dfa=`getDataForAnalysis`
        FMRIFolders=($(find $dfa/ -type d -name 'fmri*' ))
        nbdir=${#FMRIFolders[@]}       
        for (( i=0; i<${nbdir} ; i++ ));
        do
          d="${FMRIFolders[$i]}" 
          d=`readlink -f "$d"`
          FMRIid=`basename $d`
          FMRIid=`echo "${FMRIid}" | sed "s/ /_/g"`
          sh "$ScriptDir/$scriptfile" "$d" "${FMRIid}" 0 $optargs
        done

        #------------------------------------------
        # OK, now run this module on RSfmri* folders
        #------------------------------------------
        dfa=`getDataForAnalysis`
        FMRIFolders=($(find "$dfa"/ -type d -name 'rsfmri*' ))
        nbdir=${#FMRIFolders[@]}
        for (( i=0; i<${nbdir} ; i++ ));
        do
          d="${FMRIFolders[$i]}" 
          d=`readlink -f "$d"`
          FMRIid=`basename $d`
          FMRIid=`echo "${FMRIid}" | sed "s/ /_/g"`
          sh "$ScriptDir/$scriptfile" "$d" "${FMRIid}" 1 $optargs
        done

      fi
      echo ""
      echo ""
    fi
  fi
done

IFS=$PREVIFS


