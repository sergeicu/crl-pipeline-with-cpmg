#!/bin/sh


echo "--------------------------------------"
echo " DB_RunNextInQueue"
echo " (c) Benoit Scherrer, 2009"
echo " benoit.scherrer@childrens.harvard.edu"
echo "--------------------------------------"
echo " DB_RunNextInQueue [NumberItemToRun]"
echo ""


NbItems="$1"
if [ -z "$1" ]; then
   NbItems=10000
fi

# First check environment
SCRIPTPATH=$(cd `dirname "${BASH_SOURCE[0]}"` && pwd)
source ${SCRIPTPATH}/PipelineUtils.txt || exit 1

setupThirdPartyTools
checkIfPipelineCanRun
if [ $? -ne 0 ]; then
  exit 1
fi


for i in `seq 1 $NbItems`
do
  prevdir=`pwd`

  sdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)"

  #------------------------------------------
  # Load the study DB
  #------------------------------------------
  source ${sdir}/Settings.txt || exit 1
  source ${sdir}/bashMutex.sh || exit 1

  cd "$BaseProcessedDir"

  #------------------------------------------
  # Read from the queue
  #------------------------------------------
  lockfile="$BaseProcessedDir/queue.lock"
  mutexLockFile "$lockfile" 60
  if [[ $? -eq 0 ]]; then

    line=`cat queue.txt | head -1`
  

    if [ -z "$line" ]; then
      echo "NO MORE ITEM IN queue.txt"
      echo
      mutexUnlockFile "$lockfile"
      exit 0
    fi

    #------------------------------------------
    # Extract case/scan
    #------------------------------------------
    CaseNum=`echo $line | sed -e 's/.*#\(.*\)# #.*#/\1/'`
    ScanNum=`echo $line | sed -e 's/.*#.*# #\(.*\)#/\1/'`

  #  CaseNum=`echo $line | sed -e 's/^\([0-9][0-9]*\) [0-9]*/\1/'`
  #  ScanNum=`echo $line | sed -e 's/^[0-9][0-9]* \([0-9][0-9]*\)/\1/'`
    echo "Case $CaseNum Scan $ScanNum"

    #------------------------------------------
    # Remove item from the queue
    #------------------------------------------
    nblines=`cat queue.txt | wc -l`
    nblines=$(($nblines-1))
    cat queue.txt | tail -n "$nblines" > queue2.txt 
    mv -f queue2.txt queue.txt

    #------------------------------------------
    # Unlock mutex
    #------------------------------------------
    mutexUnlockFile "$lockfile"

    cd "$BaseProcessedDir"
    sh RunCaseScan.sh "$CaseNum" "$ScanNum"

    #------------------------------------------
    # 
    #------------------------------------------
    if [[ $? -ne 0 ]]; then
      cd "$prevdir"
      mutexLockFile "$lockfile" 120
      echo "#$CaseNum# #$ScanNum#" >> queue_error.txt
      mutexUnlockFile "$lockfile" 120
    fi


  fi

  cd "$prevdir"
done

exit 0


