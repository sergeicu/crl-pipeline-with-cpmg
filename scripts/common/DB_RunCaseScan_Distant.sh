usage()
{
   echo "--------------------------------------------------------------"
   echo " `basename $0` "
   echo " (c) Benoit Scherrer, 2018"
   echo " benoit.scherrer@childrens.harvard.edu"
   echo ""
   echo " Run the pipeline on a specified case/scan"
   echo " The pipeline may be runned on a distant machine"
   echo "--------------------------------------------------------------"
   echo " `basename $0` [--user <user>] [--host <host>] [--distantfolder <folder>] [--docker] [--nthreads <n>] [--modulesettings <var> <val>] <CaseNumber> <ScanNumber>"
   echo ""
   echo "Examples:"
   echo "`basename $0` P0039 1"
   echo "`basename $0` --user ch137122 --host researchpacs --distantfolder /data/ch137122/titi --docker --nthreads 4 --modulesettings NBTHREADS 6 --modulesettings USE_REFERENCE_POPULATION_ALIGNMENT_NVM NO --modulesettings USE_PARCELLATION_NVM YES P0039 1"
}

#-------------------------------------------
# Check the number of parameters
#-------------------------------------------
user=
host=
distantFolder=
useDocker=0
isDistant=0
nThreads=0

modulesettingsvars=()
modulesettingsvals=()


args=("$@")
otherargs=()
k=0
while (( k<$# ))
do
    arg=${args[$k]}
    case "$arg" in
        ( "--user" )    let k=k+1; user=${args[$k]}; isDistant=1;;
        ( "--host" )   let k=k+1; host=${args[$k]}; isDistant=1;;
        ( "--distantfolder") let k=k+1; distantFolder=${args[$k]}; isDistant=1;;
        ( "--nthreads") let k=k+1; nThreads=${args[$k]};;
        ( "--modulesettings") let k=k+1; var=${args[$k]}; let k=k+1; val=${args[$k]}; modulesettingsvars+=($var); modulesettingsvals+=($val);;
        ( "--docker" )           useDocker=1;;
        ( "-h" | "--help" )     usage; exit;;
        (*) if [[ $arg == -* ]]; then echo "Unknown option: $arg"; else otherargs+=($arg); fi ;;
    esac
    let k=k+1
done

if [[ ${#otherargs[@]} -ne 2 ]]; then
  usage;
  exit 1
fi

CaseNumber=${otherargs[0]} 
ScanNumber=`echo "${otherargs[1]}" | sed 's/^0*//g'`

#-------------------------------------------
# Import the global settings
#-------------------------------------------
source `dirname $0`/Settings.txt || exit 1
source `dirname $0`/DBUtils.txt || exit 1

ScriptDir=$SrcScriptDir
source `dirname $0`/PipelineUtils.txt || exit 1

setupThirdPartyTools
checkIfPipelineCanRun
if [ $? -ne 0 ]; then
  exit 1
fi


#-------------------------------------------
# First update the case locally
#-------------------------------------------
echo -e "${VT100BLUE}-------------------------------"
echo -e "(1) FIRST UPDATE"
echo -e "-------------------------------${VT100CLEAR}"
sh `dirname $0`/DB_UpdateCaseScan.sh $CaseNumber $ScanNumber

if [ $? -ne 0 ]; then
  exit 1
fi


#////////////////////////////////////////////////////////
# LOCATE CASE/SCAN FOLDER (Exit if error)
# Sets the variables:
# $PatientName, $CaseName, $ScanName, $CaseRawDir,
# $CaseProcessedDir, $CaseRelativeDir, $ScanRawDir,
# $ScanProcessedDir, $ScanRelativeDir
#////////////////////////////////////////////////////////
echo -e "${VT100BLUE}-------------------------------"
echo -e "(2) PREPARE"
echo -e "-------------------------------${VT100CLEAR}"
getCaseScan $CaseNumber $ScanNumber || exit 1
if [ $? -ne 0 ]; then
  exit 1
fi

if [ ! -d "$ScanProcessedDir" ]; then
  echo "FATAL ERROR. Cannot find <$ScanProcessedDir>"
  exit 1
fi

#-------------------------------------------
# Backup the cache before anything else
#-------------------------------------------
mkdir -p "$ScanProcessedDir/common-processed/logs"
BackupCache "$ScanProcessedDir/common-processed/logs"
if [ $? -ne 0 ]; then
  exit 1
fi

#-------------------------------------------
# Setup the log file
#-------------------------------------------
logfile=`GetLogFileName "$ScanProcessedDir/common-processed/logs"`
if [ -z "$logfile" ]; then
  echo "Error. Cannot determine log file name."
  echo "Cannot continue"
  exit 1
fi
logfile="${logfile}_log.txt"

#-------------------------------------------
# If local execution, just run locally
#-------------------------------------------
if [[ isDistant -eq 0 ]]; then
    echo -e "${VT100BLUE}-------------------------------"
    echo -e "(3) Run Pipeline ($CaseName, $ScanName)!"
    echo -e "-------------------------------${VT100CLEAR}"

    #-------------------------------------------
    # Update and run !
    # run-all will update the scripts and run everything
    #-------------------------------------------
    cd "$ScanProcessedDir/common-processed/"
    sh run-all.txt | tee -a ${logfile}	# Remark: run-all.txt calls DB_UpdateCaseScan



#----------------------------------------------------------------------
#----------------------------------------------------------------------
# Distant execution (with or without Docker)
#----------------------------------------------------------------------
#----------------------------------------------------------------------
else
    #----------------------------------------------------------------------
    #----------------------------------------------------------------------
    # FIRST COPY DATA
    #----------------------------------------------------------------------
    #----------------------------------------------------------------------
    echo
    echo -e "${VT100BLUE}-------------------------------"
    echo -e "(3) COPY TO HOST"
    echo -e "-------------------------------${VT100CLEAR}"

    UserAtHost=$user@$host

    #-------------------------------------------
    # Init the pipeline
    # To have access to getDataForAnalysis
    #-------------------------------------------
    source `dirname $0`/PipelineInit.txt || exit 1

    #------------------------------------------------
    # Dest folders
    #------------------------------------------------
    baseDestDir=$distantFolder/${CaseName}_${ScanName}
    destProcessDir=$baseDestDir/Processed/${CaseName}/${PatientName}/${ScanName}
    destRawDir=$baseDestDir/Raw/${CaseName}/${PatientName}/${ScanName}
    destScriptDir=$baseDestDir/scripts
    inDir=$ScanProcessedDir

    #------------------------------------------------
    # Copy Processed data
    #------------------------------------------------
    #!!!TMP remove --exclude *.tmp/* (temporarily to avoid copying dense trasnform MFMFromHARDI)
    echo -e "${VT100BOLD}Copy $inDir > ${UserAtHost}:${destProcessDir}${VT100CLEAR}"
    sshpass -p $MYPASS rsync -avzt --exclude *.tmp/* --rsync-path="mkdir -p $destProcessDir && rsync" $inDir/ ${UserAtHost}:${destProcessDir} || errorAndExit "Error"

    echo -e "${VT100BOLD}Copy $BaseProcessedDir/00_ModuleSettings.txt > ${UserAtHost}:${baseDestDir}/Processed/${VT100CLEAR}"
    sshpass -p $MYPASS rsync -avzt $BaseProcessedDir/00_ModuleSettings.txt ${UserAtHost}:${baseDestDir}/Processed/ || errorAndExit "Error"

    #------------------------------------------------
    # Copy Raw/data_for_analysis
    #------------------------------------------------
    dfa=`getDataForAnalysis`
    echo -e "${VT100BOLD}Copy $dfa > ${UserAtHost}:${destRawDir}${VT100CLEAR}"
    sshpass -p $MYPASS rsync -avzt --rsync-path="mkdir -p $destRawDir && rsync" $dfa/ ${UserAtHost}:${destRawDir}/data_for_analysis || errorAndExit "Error"

    #------------------------------------------------
    # Copy current version of scripts
    #------------------------------------------------
    echo -e "${VT100BOLD}Copy $SrcScriptDir > ${UserAtHost}:${destScriptDir}${VT100CLEAR}"
    sshpass -p $MYPASS rsync -avzt --rsync-path="mkdir -p $destScriptDir && rsync" --exclude=.svn $SrcScriptDir/ ${UserAtHost}:${destScriptDir} || errorAndExit "Error"


    #----------------------------------------------------------------------
    #----------------------------------------------------------------------
    # PREPARE PIPELINE - Modify Settings.txt and 00_ModuleSettings.txt
    #----------------------------------------------------------------------
    #----------------------------------------------------------------------
    echo -e "${VT100BLUE}-------------------------------"
    echo -e "(5) Prepare pipeline"
    echo -e "-------------------------------${VT100CLEAR}"

    #------------------------------------------------
    # First changes to 00_ModuleSettings
    #------------------------------------------------
    echo -e "${VT100BOLD}Changes to ${baseDestDir}/Processed/00_ModuleSettings.txt ${VT100CLEAR}"
    changeModuleSettings=""
    if [[ $nThreads -gt 0 ]]; then
        echo "- CHANGE NBTHREADS=$nThreads"
        changeModuleSettings="sed -i \"/NBTHREADS=/c\NBTHREADS=\\\"${nThreads}\\\"\" \"${baseDestDir}/Processed/00_ModuleSettings.txt\""
    fi
    nchgs=${#modulesettingsvars[@]}
    if [[ ${#modulesettingsvars[@]} -gt 0 ]]; then
        n=$((${#modulesettingsvars[@]}-1))
        for i in `seq 0 $n`;
        do
            var=${modulesettingsvars[$i]}
            val=${modulesettingsvals[$i]}
            echo "- CHANGE $var=$val"
            changeModuleSettings="$changeModuleSettings; sed -i \"/${var}=/c\\$var=\\\"${val}\\\"\" \"${baseDestDir}/Processed/00_ModuleSettings.txt\""
        done
    fi
    echo

    if [[ -f $PARCELLATION_NVM ]]; then
        echo "!!!tmp PARCELLATION ALREADY DONE $PARCELLATION_NVM"
        val="NO"
    else
        echo "!!! TMP add parcelisation NVM"
        val="YES"
    fi
    echo

    var="USE_REFERENCE_POPULATION_ALIGNMENT_NVM"
    changeModuleSettings="$changeModuleSettings; sed -i \"/${var}=/c\\$var=\\\"${val}\\\"\" \"${baseDestDir}/Processed/00_ModuleSettings.txt\""

    var="USE_PARCELLATION_NVM"
    changeModuleSettings="$changeModuleSettings; sed -i \"/${var}=/c\\$var=\\\"${val}\\\"\" \"${baseDestDir}/Processed/00_ModuleSettings.txt\""
   

    #------------------------------------------------
    # And prepare the script to run on the distant machine
    #------------------------------------------------
    if [[ $useDocker -eq 0 ]]; then
        read -r -d '' cmdline << EOM
        cd $destDir
        pwd
        hostname
        export v="`echo "$baseDestDir" | sed 's/\//\\\\\//g'`"
        sed -i "/BaseRawDir=/c\BaseRawDir=\"\$v\/Raw\"" "$baseDestDir/scripts/common/Settings.txt"
        sed -i "/BaseProcessedDir=/c\BaseProcessedDir=\"\$v\/Processed\"" "$baseDestDir/scripts/common/Settings.txt"
        sed -i "/SrcScriptDir=/c\SrcScriptDir=\"\$v\/scripts\"" "$baseDestDir/scripts/common/Settings.txt"
        $changeModuleSettings
        echo "--- $baseDestDir/scripts/common/Settings.txt ---"
        cat "$baseDestDir/scripts/common/Settings.txt"
        echo "---"
        sh $baseDestDir/scripts/common/DB_InstallPipeline.sh
        exit
EOM

    else

        read -r -d '' cmdline << EOM
        cd $destDir
        pwd
        hostname
        export v="`echo "$baseDestDir" | sed 's/\//\\\\\//g'`"
        sed -i "/BaseRawDir=/c\BaseRawDir=\"\$v\/Raw\"" "$baseDestDir/scripts/common/Settings.txt"
        sed -i "/BaseProcessedDir=/c\BaseProcessedDir=\"\$v\/Processed\"" "$baseDestDir/scripts/common/Settings.txt"
        sed -i "/SrcScriptDir=/c\SrcScriptDir=\"\$v\/scripts\"" "$baseDestDir/scripts/common/Settings.txt"
        sed -i "/PipelineTemplatesDir=/c\PipelineTemplatesDir=\"\/data\/atlases\/\"" "$baseDestDir/scripts/common/Settings.txt"
        sed -i "/ThirdPartySoftwareDir=/c\ThirdPartySoftwareDir=\"\/software/3rdparty\/\"" "$baseDestDir/scripts/common/Settings.txt"
        $changeModuleSettings
        echo -e "${VT100BLUE}--- $baseDestDir/scripts/common/Settings.txt ---${VT100CLEAR}"
        cat "$baseDestDir/scripts/common/Settings.txt"
        echo "---"
        echo -e "${VT100BLUE}--- $baseDestDir/Processed/00_ModuleSettings.txt ---${VT100CLEAR}"
        cat "$baseDestDir/Processed/00_ModuleSettings.txt"
        echo "---"
        sh $baseDestDir/scripts/common/DB_InstallPipeline.sh
        exit
EOM

    fi
    #------------------------------------------------
    # Run prepare script on distant machine
    #------------------------------------------------
    echo $cmdline
    sshpass -p $MYPASS ssh ${UserAtHost} "$cmdline"


    #----------------------------------------------------------------------
    #----------------------------------------------------------------------
    # NOW RUN THE PIPELINE!
    #----------------------------------------------------------------------
    #----------------------------------------------------------------------
    echo -e "${VT100BLUE}-------------------------------"
    echo -e "(5) Run Pipeline on ${UserAtHost} !"
    echo -e "-------------------------------${VT100CLEAR}"
    if [[ $useDocker -eq 0 ]]; then
        cmdline="$baseDestDir/Processed/RunCaseScan.sh ${CaseName} $ScanNumber; exit"
    else
        cmdline="sudo docker run -v $baseDestDir:$baseDestDir -e DOCKER_UID=\`id -u $user\` -e DOCKER_GID=\`id -g $user\` -t bs/crkitwithpipeline /bin/sh $baseDestDir/Processed/RunCaseScan.sh ${CaseName} $ScanNumber; exit"
    fi
    
    echo $cmdline
    sshpass -p $MYPASS ssh ${UserAtHost} "$cmdline"


    #----------------------------------------------------------------------
    #----------------------------------------------------------------------
    # COPY THE DATA BACK
    #----------------------------------------------------------------------
    #----------------------------------------------------------------------

    echo -e "${VT100BLUE}-------------------------------"
    echo -e "(6) COPY BACK"
    echo -e "-------------------------------${VT100CLEAR}"    

    # No || errorAndExit "Error"  below because file/attrs errors can return a non null error (eg "rsync error: some files/attrs were not transferred")
    # but the files are copied
    #!!!! tmp --exclude *ReferencePopulationAlignment*
    echo -e "${VT100BOLD}Copy ${UserAtHost}:${destProcessDir}/ > ${inDir}${VT100CLEAR}"
    sshpass -p $MYPASS rsync -avzt --exclude=clean* --exclude=run* --exclude *Settings.txt --exclude ScanInfo.sh --exclude CaseInfo.sh  --exclude *scripts/* --exclude *ReferencePopulationAlignment* ${UserAtHost}:${destProcessDir}/ $inDir 


    #sed -i -e "s/^BaseRawDir=\(\S*\).*/BaseRawDir=\"\$v\/Raw\"/" "$baseDestDir/scripts/common/Settings.txt"
    #sed -i -e "s/^BaseProcessedDir=\(\S*\).*/BaseProcessedDir=\"\$v\/Processed\"/" "$baseDestDir/scripts/common/Settings.txt"
    #sed -i -e "s/^SrcScriptDir=\(\S*\).*/SrcScriptDir=\"\$v\/scripts\"/" "$baseDestDir/scripts/common/Settings.txt"



fi


