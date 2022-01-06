umask 002

#------------------------------------------
# Load the scan informations
#------------------------------------------
source "`dirname $0`/../../ScanInfo.sh" || exit 1
prevdir=`pwd`

#------------------------------------------
# Load the cache manager, prepare the prefix, etc...
# After the file is sourced, we are in the folder 
# "$ScanProcessedDir/common-processed"
#------------------------------------------
source $ScriptDir/common/PipelineUtils.txt || exit 1
source $ScriptDir/common/PipelineInit.txt || exit 1
source $ScriptDir/common/HtmlReportManager.txt || exit 1

source "`dirname $0`/01.diffusion_prepare.txt" || exit 1
source "`dirname $0`/02.diffusion_1T.txt" || exit 1
source "`dirname $0`/02.diffusion_report.txt" || exit 1

d=$1
multiB=$2

RunDWIPipeline_prepare "$d" "$multiB"
RunDWIPipeline_1T "$d" "$multiB"


