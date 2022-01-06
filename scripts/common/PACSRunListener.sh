echo "------------------------------------------------------"
echo " PACSRunListener.sh"
echo " Run the PACS listener to get DICOMs files with" 
echo " PACSGet/PACSGetMultiple"
echo "------------------------------------------------------"

#--------------------------------------
# Get the config file.
# Currently only used to define the variable:"
# TEMPORARYFOLDER
#--------------------------------------
sdir=`dirname $0`
sdir=`readlink -f ${sdir}`
echo "- Read configuration file <$sdir/PACS_script_config.txt>"
if [ -f "$sdir/PACS_script_config.txt" ]; then
  source "$sdir/PACS_script_config.txt" || exit 1
else
  echo "  NOT FOUND. USE DEFAULT SETTINGS."
fi

#--------------------------------------
# Default init for temporary folder
#--------------------------------------
if [ -z "$TEMPORARYFOLDER" ]; then
  TEMPORARYFOLDER="~/tmp/fromRadCrl"
fi

mkdir -p "$TEMPORARYFOLDER" 
if [ $? -ne 0 ]; then
  echo "  ERROR CREATING $TEMPORARYFOLDER"
fi
TEMPORARYFOLDER=`readlink -f "$TEMPORARYFOLDER"`
echo "- Temporary folder: <$TEMPORARYFOLDER>"

#--------------------------------------
# Run the listener!
#--------------------------------------
echo "- Starting the listener..."
echo ""


/usr/local/dcm4che-tools/bin/dcmrcv LOCALRCV@:11113 -dest "$TEMPORARYFOLDER"
if [ $? -ne 0 ]; then
  echo "----------------------------------------"
  echo "ERROR. Are you sure you are running "
  echo "this script from radcrl?"
  echo "----------------------------------------"
fi

echo
