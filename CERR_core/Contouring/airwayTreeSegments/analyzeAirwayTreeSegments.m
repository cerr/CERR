function analyzeAirwayTreeSegments(ptDir,doseFile,baseTreeFile,followupTreeFile,segmentsFile)
% function analyzeAirwayTreeSegments(ptDir,doseFile,baseTreeFile,followupTreeFile,segmentsFile)
%
% Example:
% ptDir = 'path/to/patient/dir';
% doseFile = 'planningCT_plan_ltlung.mat';
% baseTreeFile = 'Baseline_radius.mat';
% followupTreeFile = 'Stenosis_radius.mat';
% segmentsFile = 'optional/path/to/segments/file.mat'; % .mat file containing segments
% segmentsFile = '';
% analyzeAirwayTreeSegments(ptDir,doseFile,baseTreeFile,followupTreeFile,segmentsFile)
%
% APA, 6/9/2021

global stateS
mergedFile = [strtok(baseTreeFile,'_'),'_',strtok(followupTreeFile,'_')];
mergedFileName = fullfile(ptDir,'merged_files',mergedFile);
folllowScanNum = 2;
sliceCallBack('INIT'); sliceCallBack('OPENNEWPLANC',mergedFileName);
sliceCallBack('layout', 3)
hAxis = stateS.handle.CERRAxis(2);
sliceCallBack('selectaxisview', hAxis, 'transverse');
setAxisInfo(hAxis, 'scanSelectMode', 'manual', 'scanSets', folllowScanNum,...
    'xRange',[],'yRange',[]);
setAxisInfo(hAxis, 'structSelectMode', 'manual',...
    'doseSelectMode', 'manual',...
    'structureSets', [],...
    'doseSets', []);
sliceCallBack('planeLocatorToggle')
sliceCallBack('refresh');
showPatientOrientation


%% Plot trees
radInd = strfind(followupTreeFile,'_radius');
%vfFile = fullfile(ptDir,'registered',[followupTreeFile(1:radInd-1),'_vf.mat']);
baseRadiusInd = strfind(baseTreeFile,'_radius');
vfFile = fullfile(ptDir,'registered',[baseTreeFile(1:baseRadiusInd-1),'_',followupTreeFile(1:radInd-1),'_vf.mat']);
doseFile = fullfile(ptDir,'registered',doseFile);
baseTreeFile = fullfile(ptDir,'AirwayTree',baseTreeFile);
followupTreeFile = fullfile(ptDir,'AirwayTree',followupTreeFile);

% Longitudinal selection
if ~exist('segmentsFile','var')
    segmentsFile = '';
end
select_segments_on_base_and_followup_trees(doseFile,baseTreeFile,...
followupTreeFile,vfFile,segmentsFile)

