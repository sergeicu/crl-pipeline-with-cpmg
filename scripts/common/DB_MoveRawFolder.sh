if [ $# -lt 1 ]; then
  echo "DB_MoveRawFolder [newraw] [1 to accept]"
  exit 1
fi

#------------------------------------------
# Load the settings
#------------------------------------------
source `dirname $0`/Settings.txt || exit 1

if [ "$2" != "1" ]; then
  echo
  echo " Move raw data from:"
  echo "     $BaseRawDir"
  echo " to:"
  echo "     $1"
  echo " Run again DB_MoveRawFolder.sh with 1 as last argument for confirmation."
  echo
  exit 1
fi

ofolder=`echo "$1" | sed 's/\//\\\\\//g'`
ifolder=`echo "$BaseRawDir" | sed 's/\//\\\\\//g'`

#-----------------------------------------------------
# Update the time stamps of the cache manager
#-----------------------------------------------------

#cusp65_MASK_NHDR_DEPS_1="/common/projects2/ASD_Wan/ProcessedData/case002/Sankalp_Venkatesh/scan01/common-processed/anatomical/03-ICC/c002-s01_ICC.nrrd"
#cusp65_MASK_NHDR_DEPS_1_TIMESTAMP="2012-06-26 13:49:01.000000000 -0400"
function updateTimeStamp()
{
  local cachefile=$1
  local folder=$2

  echo $cachefile
  local j

  #---------------------------------------------
  # look for all the lines containing 'folder'
  #---------------------------------------------
  local lines=($(more $cachefile | grep "$folder" ))
  local nblines=${#lines[@]}
  for (( j=0; j<${nblines} ; j++ ));
  do
    #---------------------------------------------
    # extract var name and value 
    #---------------------------------------------
    local l="${lines[$j]}" 
    local varname=`echo $l | sed -e 's/\(\S*\)=.*/\1/g'`
    local varval=`echo $l | sed -e 's/.*="\(\S*\)"/\1/g'`
 
    #---------------------------------------------
    # check if ok
    #---------------------------------------------
    local check=`echo $varname | sed  's/\(\S*\)_DEPS_[0-9]*/\1/g'`
    if [ -z "$varname" ] || [ -z "$varval" ] || [ -z "$check" ] || [ "$check" == "$varname" ]; then
       continue;
    fi
      
    #---------------------------------------------
    # Get new timestamp
    #---------------------------------------------
    local timestampvar="${varname}_TIMESTAMP"
    local newtimestamp=`stat -c %y "$varval"`

    echo $varname
    echo "   -> $varval"
    echo "   -> $timestampvar=\"$newtimestamp\""

    #---------------------------------------------
    # Update!
    #---------------------------------------------
    local v=`echo "$v" | sed 's/&/\\\&/g'`               #  Corrects the string for sed: convert '&' to '\&'
    sed -i "s/^${timestampvar}=\(\S*\).*/${timestampvar}=\"$newtimestamp\"/" "$cachefile" ; 

  done

echo

}

echo $ofolder
find "$SrcScriptDir"/ -type f -name Settings.txt -exec sed -i "s/$ifolder/$ofolder/g" {} \;   
find "$BaseProcessedDir"/ -type f -name 00_Cache.txt -exec sed -i "s/$ifolder/$ofolder/g" {} \;   
find "$BaseProcessedDir"/ -type f -name CaseInfo.sh -exec sed -i "s/$ifolder/$ofolder/g" {} \;   
find "$BaseProcessedDir"/ -type f -name ScanInfo.sh -exec sed -i "s/$ifolder/$ofolder/g" {} \;   
find "$BaseProcessedDir"/ -type f -name \*PipelineResults.txt  -exec sed -i "s/$ifolder/$ofolder/g" {} \;   

PREVIFS=$IFS
IFS=$'\n'

cfiles=($(find "$BaseProcessedDir"/ -type f -name 00_Cache.txt ))
nbdir=${#cfiles[@]}
for (( i=0; i<${nbdir} ; i++ ));
do
  d="${cfiles[$i]}" 
  d=`readlink -f "$d"`
  
  updateTimeStamp $d $ofolder
done
