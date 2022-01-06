# init 
sh scripts/install_pipeline.sh .

# MANUAL STEP 1:
  # copy T1, T2 and (optionally) CPMG and FLAIR files in the following format to 'data_for_analysis/' folder: 
  # <name>_bestt1w.nrrd, <name>_bestt2w.nrrd, `<name>_bestCPMG.nrrd, <name>_FLAIR.nrrd` 
  # to view how to process CPMG file correctly, refer to: process_CPMG_example.sh

# MANUAL STEP 2:
  # manually update the following file: 
  nano scripts/common/Settings.txt

  # with correct full path to folder:
  DataForAnalysisDir="<full_path_to_folder>/data_for_analysis"
  BaseProcessedDir="<full_path_to_folder>/"
  SrcScriptDir="<full_path_to_folder>/scripts"

# run the pipeline 
source /opt/el7/pkgs/crkit/release-current/bin/crkit-env.sh; 
cd <full_path_to_folder>
sh run-common-processed.sh

