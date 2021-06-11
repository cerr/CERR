function analyzeAirwayTreeSegments(ptDir,baseName,followupName,segmentsFile)
% function analyzeAirwayTreeSegments(ptDir,doseFile,baseTreeFile,followupTreeFile,segmentsFile)
%
% Example:
% ptDir = 'path/to/patient/dir';
% baseName = 'Baseline';
% followupName = 'Stenosis';
% segmentsFile = 'optional/path/to/segments/file.mat'; % .mat file containing segments
% segmentsFile = ''; % leave empty if no segments need to be loaded
% analyzeAirwayTreeSegments(ptDir,baseName,followupName,segmentsFile)
%
% APA, 6/9/2021

global stateS
%mergedFile = [strtok(baseTreeFile,'_'),'_',strtok(followupTreeFile,'_')];
% mergedFile = [strtok(followupTreeFile,'_')];
mergedFileName = fullfile(ptDir,'merged_files',[followupName,'.mat']);
folllowScanNum = 2;
sliceCallBack('INIT'); 
sliceCallBack('OPENNEWPLANC',mergedFileName);
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
% radInd = strfind(followupTreeFile,'_radius');
%vfFile = fullfile(ptDir,'registered',[followupTreeFile(1:radInd-1),'_vf.mat']);
% baseRadiusInd = strfind(baseTreeFile,'_radius');
vfFile = fullfile(ptDir,'registered',[baseName,'_',followupName,'_vf.mat']);
%doseFile = fullfile(ptDir,'registered',doseFile);
baseTreeFile = fullfile(ptDir,'AirwayTree',[baseName,'_radius.mat']);
followupTreeFile = fullfile(ptDir,'AirwayTree',[followupName,'_radius.mat']);

% Longitudinal selection
if ~exist('segmentsFile','var')
    segmentsFile = '';
end
select_segments_on_base_and_followup_trees(mergedFileName,baseTreeFile,...
followupTreeFile,vfFile,segmentsFile)

