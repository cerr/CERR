function batch_runSegForPlanC(inputDirName,outputDirName,...
    algorithm,containerPath,batchSize,sessionPath)
%
% function batch_runSegForplanC(inputDirName,outputDirName,...
%     algorithm,containerPath,batchSize,sessionPath)
%
% This function calls runSegForplanC for the CERR files in inputDirName
% and saves new CERR files with segmentations to outputDirName.
%
% Example:
%
% inputDirName = '/lab/mylab/myuser/cerr_files';
% outputDirName = '/lab/mylab/myuser/cerr_files_segmented';
% algorithm = 'CT_HeartStructure_DeepLab^CT_HeartSubStructures_DeepLab^CT_Atria_DeepLab^CT_Pericardium_DeepLab^CT_Ventricles_DeepLab';
% containerPath = '/lab/mylab/myuser/cerr_seg_containers/HeartCPUAndGPU_V4.sif';
% batchSize = 1;
% sessionPath = '/lab/mylab/myuser/cerr_seg_session';
%
% batch_runSegForPlanC(inputDirName,outputDirName,...
%     algorithm,containerPath,batchSize,sessionPath)
%
% APA, 10/11/2019
%
% ================ LICENSE ===========================
%
% By downloading the software for model implementations in CERR and Singularity containers, you are agreeing to the following terms and conditions as well as to the Terms of Use of CERR software.
% 
%     THE SOFTWARE IS PROVIDED “AS IS,” AND CERR DEVELOPMENT TEAM AND ITS COLLABORATORS DO NOT MAKE ANY WARRANTY, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, NOR DO THEY ASSUME ANY LIABILITY OR RESPONSIBILITY FOR THE USE OF THIS SOFTWARE.
%         
%     This software is for research purposes only and has not been approved for clinical use.
%     
%     Software has not been reviewed or approved by the Food and Drug Administration, and is for non-clinical, IRB-approved Research Use Only. In no event shall data or images generated through the use of the Software be used in the provision of patient care.
%     
%     You may publish papers and books using results produced using software provided that you reference the appropriate citations (https://doi.org/10.1118/1.1568978, https://doi.org/10.1002/mp.13046, https://doi.org/10.1101/773929)
%     
%     YOU MAY NOT DISTRIBUTE COPIES of this software, or copies of software derived from this software, to others outside your organization without specific prior written permission from the CERR development team except where noted for specific software products.    

dirS = dir(inputDirName);
dirS(1:2) = [];

sshConfigFile = [];
hWait = NaN;

for fileNum = 1:length(dirS)
   fName = fullfile(inputDirName,dirS(fileNum).name);
   planC = loadPlanC(fName,tempdir);
   planC = updatePlanFields(planC);
   planC = quality_assure_planC(fName,planC);
   
   planC = runSegForPlanC(planC,sessionPath,algorithm,...
       sshConfigFile,hWait,containerPath,batchSize);   
   
   saveFileNam = fullfile(outputDirName,dirS(fileNum).name);
   
   planC = save_planC(planC,[],'passed',saveFileNam);
   
end

