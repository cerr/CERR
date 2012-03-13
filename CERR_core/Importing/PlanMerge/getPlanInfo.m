function [planInfo, planC] = getPlanInfo(planC)
%"getPlanInfo"
%   Return a struct listing the doses, scans and structures in a plan,
%   along with the sizes in MB of each and other associated information.
%
%JRA 3/2/05
% copyright (c) 2001-2006, Washington University in St. Louis.
% Permission is granted to use or modify only for non-commercial, 
% non-treatment-decision applications, and further only if this header is 
% not removed from any file. No warranty is expressed or implied for any 
% use whatever: use at your own risk.  Users can request use of CERR for 
% institutional review board-approved protocols.  Commercial users can 
% request a license.  Contact Joe Deasy for more information 
% (radonc.wustl.edu@jdeasy, reversed).
%
%Usage:
%   planInfo = getPlanInfo(planC)

if ~iscell(planC)
    error('Invalid planC.')
end

%Get this plan's index.
indexS = planC{end};

%Create planInfo's dose struct template, set it's length to zero.
doses = struct('name', [], 'arraySize', [], 'sizeInMB', []);
doses(1) = [];

if ~isfield(indexS,'IVH')
    planC = updatePlanIVH(planC);
end
if ~isfield(planC{indexS.scan}(1),'scanUID')
    planC = updatePlanFields(planC);    
end
indexS = planC{end};

%Extract information about doses.
nDoses = length(planC{indexS.dose});
for i=1:nDoses
    doseStruct      = planC{indexS.dose}(i);
    doseInfo        = whos('doseStruct');
    dose.name       = doseStruct.fractionGroupID;
    dose.arraySize  = doseStruct.doseArray;
    dose.sizeInMB   = doseInfo.bytes / (1024*1024);
    doses(end+1) = dose;
end

%Create planInfo's scan struct template, set it's length to zero.
scans = struct('modality', [], 'arraySize', [], 'sizeInMB', []);
scans(1) = [];

%Extract information about scans.
nScans = length(planC{indexS.scan});
for i=1:nScans
    scanStruct      = planC{indexS.scan}(i);
    scanInfo        = whos('scanStruct');
    scan.modality   = scanStruct.scanInfo(1).imageType;
    scan.arraySize  = size(scanStruct.scanArray);
    scan.sizeInMB   = scanInfo.bytes / (1024*1024);
    scans(end+1) = scan;
end

%Create planInfo's structure template, set it's length to zero.
structures = struct('associatedScan', [], 'arraySizeInMB', [], 'memberStructs', []);
structures(1) = [];

%Extract information about structures.
nStructures = length(planC{indexS.structures});
%Check for mesh representation and load meshes into memory
currDir = cd;
meshDir = fileparts(which('libMeshContour.dll'));
cd(meshDir)
for strNum = 1:nStructures
    if isfield(planC{indexS.structures}(strNum),'meshRep') && ~isempty(planC{indexS.structures}(strNum).meshRep) && planC{indexS.structures}(strNum).meshRep
        try
            calllib('libMeshContour','loadSurface',planC{indexS.structures}(strNum).strUID,planC{indexS.structures}(strNum).meshS)
        catch
            planC{indexS.structures}(strNum).meshRep    = 0;
            planC{indexS.structures}(strNum).meshS      = [];
        end
    end
end
cd(currDir)

[assocScan, relStructNumV] = getStructureAssociatedScan(1:nStructures, planC);

%Determine number of structure sets.
uniqueScans = unique(assocScan);
nStructSets = length(uniqueScans);

for i=1:nStructSets
    if ~isempty(planC{indexS.structureArray});
        structArray             = planC{indexS.structureArray}(i);
        structInfo              = whos('structArray');
        structure.associatedScan= uniqueScans(i);       
        structure.arraySizeInMB = structInfo.bytes / (1024*1024);
        structure.memberStructs = find(assocScan == structure.associatedScan);
    else
        structure.associatedScan = uniqueScans(i);
        structure.arraySizeInMB = 0;
        structure.memberStructs = find(assocScan == structure.associatedScan);
    end
    structures(end+1) = structure;
end

planInfo.scans      = scans;
planInfo.doses      = doses;
planInfo.structures = structures;