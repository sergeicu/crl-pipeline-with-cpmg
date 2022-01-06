=========================================================================================
  COMMON CRL PIPELINE

  (c) Benoit Scherrer, 2011
  e-mail: benoit.scherrer@childrens.harvard.edu
=========================================================================================

-----------------------------------------------------------------------------------------
PIPELINE INSTALLATION
-----------------------------------------------------------------------------------------
- Create the patient folder and make it the current folder.
  For example: 
    []$ mkdir Case001
    []$ cd Case001

- Check out the pipeline source code from the SVN repository to the patient folder (ex Case001)
    [Case001]$ svn co https://dreev.tch.harvard.edu/svn/crkit/trunk/pipelines/CRLAnalysisPipeline scripts/

- Install the pipeline for this subject
    [Case001]$ sh scripts/install_pipeline.sh .
  It will setup the pipeline and creates default directories

- If you have DICOM files only, convert the DICOM to nrrd with the import_from_dicom.sh script
    [Case001]$ sh import_from_dicom.sh [YOUR_DICOM_FOLDER]

  The tree structure should now look like:
     Case001
        |--- common-processed
        |--- data_for_analysis
        |--- nrrds
        |--- scripts

- Then select the T1-weighted, T2-weighted images and copy them in data_for_analysis with the
  name bestt1w.nrrd and bestt2w.nrrd. Any name *bestt1w.nrrd and *bestt2w.nrrd also works.
  (for example case001_bestt1w.nrrd, case001_bestt2w.nrrd)

- Copy the diffusion folder (many if needed) in data_for_analysis.
  If the folder's name is dwi (or dwi*, such as dwi35) only the ONE tensor analysis will be 
  performed. If the folder's name is cusp (or cusp*, such as cusp45) the ONE and the TWO tensor 
  analyses will be performed.

- Modify (if needed) the settings for the pipeline modules by editing the file 
  common-processed/00_ModuleSettings.txt 
  ex: [Case001]$ gedit common-processed/00_ModuleSettings.txt &

- Then you can RUN THE PIPELINE !
     [Case001]$ sh run-common-processed.sh




- For reference:
  If a folder is moved or renamed, all entries in the cache manager will be invalid because
  the pipeline uses absolute folder names. Here is a command to change the content of the
  cache manager. For example:
    find ./Processed/ -type f -name 00_Cache.txt          -exec sed -i 's/\/common\/projects\/Controls/\/common\/projects\/ControlsOld/g' {} \;    
    find ./Processed/ -type f -name CaseInfo.sh -exec sed -i 's/\/common\/projects\/Controls/\/common\/projects\/ControlsOld/g' {} \; 
    find ./Processed/ -type f -name ScanInfo.sh -exec sed -i 's/\/common\/projects\/Controls/\/common\/projects\/ControlsOld/g' {} \; 
    find ./Processed/ -type f -name Settings.txt -exec sed -i 's/\/common\/projects\/Controls/\/common\/projects\/ControlsOld/g' {} \; 
    find ./Processed/ -type f -name \*PipelineResults.txt -exec sed -i 's/\/common\/projects\/Controls/\/common\/projects\/ControlsOld/g' {} \; 


=========================================================================================

