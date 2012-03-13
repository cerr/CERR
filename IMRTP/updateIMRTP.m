function IM = updateIMRTP(statement)
%"IMRTP"
%   Master function to run IMRTP plans in CERR.  Takes as an input an IM
%   structure.
%
%JOD, 12 Nov 03.
%LM:  24 Nov 03, JOD, mod to always write struct name even
%                     with no dose values.
%     24 Nov 03, CZ,  mods to reduce memory requirements.
%     26 Aug 04, JRA, major revision to add MC engine.  Broke code into
%                     many smaller infile functions.  See end of file.
%     16 Oct 06, APA, changed name to updateIMRTP from IMRTP since we keep
%                     a track of which beamlets need to be updated.
%
% Copyright 2010, Joseph O. Deasy, on behalf of the CERR development team.
% 
% This file is part of The Computational Environment for Radiotherapy Research (CERR).
% 
% CERR development has been led by:  Aditya Apte, Divya Khullar, James Alaly, and Joseph O. Deasy.
% 
% CERR has been financially supported by the US National Institutes of Health under multiple grants.
% 
% CERR is distributed under the terms of the Lesser GNU Public License. 
% 
%     This version of CERR is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
% CERR is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
% without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
% See the GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with CERR.  If not, see <http://www.gnu.org/licenses/>.

global planC
global stateS
indexS=planC{end};

%If input is a string, pass to IMSetup, else input is an IM.
if ischar(statement)
    IM = IMSetup(statement);
elseif isstruct(statement) & isfield(statement, 'beams')
    IM = statement;
else
    error('Input to IMRTP must be a string or an IM structure.');
end

%Form target by looping over target examples and getting the union
%of the target objects

%check if assocScan and structures exist
if ~ismember(IM.assocScanUID,{planC{indexS.scan}.scanUID})
    error('Associated scan not present !')
end
if any(~ismember({IM.goals.strUID},{planC{indexS.structures}.strUID}))
    error('some structures not present. Please delete these structures and try again.')
end

%Check if structures are registered to same associated scan
structNumV = getAssociatedStr({IM.goals.strUID});
%Figure out what scan we are registered to.
scanNumV = getStructureAssociatedScan(structNumV);
if length(unique(scanNumV))>1 | any(unique(scanNumV)~=getAssociatedScan(IM.assocScanUID))
    error(['All structures must be registered to scan ',num2str(getAssociatedScan(IM.assocScanUID))]);
end

% OUT OF COMMISSION FOR NOW
% if isfield(stateS.optS, 'IMRTCheckResolution') & strcmpi(stateS.optS.IMRTCheckResolution, 'on') & size(planC{indexS.scan}(scanNumV(1)).scanArray,1) == 512
%     planC = getplanCDownSample(planC, stateS.optS, 2,scanNumV(1));
% 
%     %Compensate for slice position changing.
%     try
%         stateS.sliceNumCor = round(stateS.sliceNumCor/2);
%         stateS.sliceNumSag = round(stateS.sliceNumSag/2);
%     end
% end

%Calculate isocenter if required.
IM = checkAutoIsocenter(IM);

%Check for beamlet deltaX and deltaY
uniformSlcThickness = planC{indexS.scan}(scanNumV(1)).uniformScanInfo.sliceThickness;
reUnifFlag = 0;
minBeamletDelta = inf;
for i = 1:length(IM.beams)
    if uniformSlcThickness > min(IM.beams(i).beamletDelta_x, IM.beams(i).beamletDelta_y)
        reUnifFlag = 1;
        minBeamletDelta = min(minBeamletDelta,min(IM.beams(i).beamletDelta_x, IM.beams(i).beamletDelta_y));
    end
end

if reUnifFlag
    ButtonName = questdlg(['Beamlet size must be greater than or equal to ', num2str(uniformSlcThickness)], ...
        'Re-Uniformize Scan?', ...
        'Re-uniformize scan and continue','Cancel to change beamlet size','Re-uniformize scan and continue');
    switch ButtonName
        case 'Re-uniformize scan and continue',
            planC{indexS.scan}(scanNumV(1)).uniformScanInfo         = [];
            planC{indexS.scan}(scanNumV(1)).scanArraySuperior       = [];
            planC{indexS.scan}(scanNumV(1)).scanArrayInferior       = [];
            planC{indexS.structureArray}(scanNumV(1)).indicesArray  = [];
            planC{indexS.structureArray}(scanNumV(1)).bitsArray     = [];
            planC{indexS.structureArrayMore}(scanNumV(1)).indicesArray  = [];
            planC{indexS.structureArrayMore}(scanNumV(1)).bitsArray     = [];            
            optS = planC{indexS.CERROptions};
            optS.lowerLimitUniformCTSliceSpacing = 0;
            optS.upperLimitUniformCTSliceSpacing = 0;
            optS.alternateLimitUniformCTSliceSpacing = minBeamletDelta;
            planC = setUniformizedData(planC,optS);
        case 'Cancel to change beamlet size',
            error(['Beamlet size must be greater than or equal to ', num2str(uniformSlcThickness)])
    end
end

%Get surfacePoints of all target structures.
edgeS = getTargetSurfacePoints(IM);

%Get ROI StructureList
[structROIV, sampleRateV] = getROIStructureList(IM);

%Set PB vectors, determine which PBs are required to cover the target.
IM = getPBList(IM, edgeS);

%create a #structs x #beams matrix containing 0 and 1's to tell which
%structs and beams need to be updated
updateM = zeros([length(IM.goals) length(IM.beams)]);
for stuctNum = 1:length(IM.goals)
    if ~ismember(IM.goals(stuctNum).strUID,{planC{indexS.structures}.strUID}) || (~isempty(IM.beams(1).beamlets) && ~ismember(IM.goals(stuctNum).strUID,{IM.beams(1).beamlets(:,1).strUID}))
        %re/compute beamlets for all beams
        updateM(stuctNum,:) = 1;
    end
end
for beamNum = 1:length(IM.beams)
    if isempty(IM.beams(beamNum).beamlets)
        %re/compute beamlets for all structures
        updateM(:,beamNum) = 1;
    end
end        
%updateM = [];

%Here is where QIB and MC diverge. Update only passed struct/beam pairs
switch upper(IM.params.algorithm)
    case 'QIB'
        IM = updateQIBInfluence(IM, structROIV, sampleRateV, updateM);
    case 'VMC++'
        IM = updateVMCInfluence(IM, structROIV, sampleRateV, updateM);
end
%----------- END OF MAIN FUNCTION -------------%
return;


function IM = checkAutoIsocenter(IM)
%"checkAutoIsocenter"
%   Examines IM structure for auto-isocenter calculation.  If an auto
%   method is specified, calculates isocenter, stores in IM and returns.
calcCOM = 0;
for i = 1:length(IM.beams);
    if strcmpi(IM.beams(i).isocenter.x, 'COM') | strcmpi(IM.beams(i).isocenter.y, 'COM') | strcmpi(IM.beams(i).isocenter.z, 'COM')
        calcCOM = 1;
    end
end
if calcCOM
    disp('Auto calculating ISOCENTER using center of mass...')
    try
        IMRTPGui('statusbar', 'Auto calculating ISOCENTER using center of mass...');
    end

    %         structNums = [IM.goals.structNum];
    %         targets = structNums(strcmpi({IM.goals.isTarget}, 'yes'));
    indTargetV   = strcmpi({IM.goals.isTarget}, 'yes');
    targetsV     = getAssociatedStr({IM.goals(indTargetV).strUID});
    [xCOM, yCOM, zCOM] = calcIsocenter(targetsV, 'COM');
    disp(['ISOCENTER found at x = ' num2str(xCOM) ' y = ' num2str(yCOM) ' z = ' num2str(zCOM) '.']);
    try
        IMRTPGui('statusbar', ['ISOCENTER found at x = ' num2str(xCOM) ' y = ' num2str(yCOM) ' z = ' num2str(zCOM) '.']);
    end

    for i = 1:length(IM.beams)
        if strcmpi(IM.beams(i).isocenter.x, 'COM')
            IM.beams(i).isocenter.x = xCOM;
        end
        if strcmpi(IM.beams(i).isocenter.y, 'COM')
            IM.beams(i).isocenter.y = yCOM;
        end
        if strcmpi(IM.beams(i).isocenter.z, 'COM')
            IM.beams(i).isocenter.z = zCOM;
        end
    end
end
%-------------------------------------------


function edgeS = getTargetSurfacePoints(IM)
%"getTargetSurfacePoints"
%   Returns surface points of all targets in IM structure.

%   VECTORIZE
%   structTargetV = [];
% 	PBMarginV = [];
% 	for i = 1 : length(IM.goals)
%       if strcmpi(IM.goals(i).isTarget(1),'y')
%         structTargetV = [structTargetV, IM.goals(i).structNum];
%         PBMarginV = [PBMarginV, IM.goals(i).PBMargin];
%       end
% 	end
indTargetV      = strcmpi({IM.goals.isTarget}, 'yes');
structTargetV   = getAssociatedStr({IM.goals(indTargetV).strUID});
PBMarginV       =  [IM.goals(indTargetV).PBMargin];

%Get unique list:
[structTargetV,iV,jV] = unique(structTargetV);
PBMarginV = PBMarginV(iV);

disp('Get target surface points...')
try
    IMRTPGui('statusbar', 'Getting target surface points...');
end
tic
[edgeS] = getSurface(structTargetV,PBMarginV+0.5, IM.params.xyDownsampleIndex); %%%should be IM.params.xyDownsampleIndex
toc
%-------------------------------------------


function IM = getPBList(IM, edgeS);
%"getPBList"
%   Populates the beam fields in IM to describe the pencil beams that cover
%   the target.
for i = 1 : length(IM.beams)
    disp(['Get ray trace for beam ' num2str(i) '.'])
    try
        IMRTPGui('statusbar', ['Getting ray trace for beam ' num2str(i) '...']);
    end
    tic
    [CTTraceS, RTOGPBVectorsM, RTOGPBVectorsM_MC, PBMaskM, rowPBV, colPBV, xPBPosV, yPBPosV] = ...
        getPBRayData(edgeS, IM.beams(i), IM.params.numCTSamplePts, IM.params.xyDownsampleIndex, getAssociatedScan(IM.assocScanUID));
    toc

    IM.beams(i).RTOGPBVectorsM_MC = RTOGPBVectorsM_MC;
    IM.beams(i).RTOGPBVectorsM    = RTOGPBVectorsM;
    IM.beams(i).xPBPosV           = xPBPosV;
    IM.beams(i).yPBPosV           = yPBPosV;
    IM.beams(i).rowPBV            = rowPBV;
    IM.beams(i).colPBV            = colPBV;
    IM.beams(i).CTTraceS          = CTTraceS;

    %RTOG positions of sources
    IM.beams(i).x = IM.beams(i).xRel + IM.beams(i).isocenter.x;
    IM.beams(i).y = IM.beams(i).yRel + IM.beams(i).isocenter.y;
    IM.beams(i).z = IM.beams(i).zRel + IM.beams(i).isocenter.z;
end


function [structROIV, sampleRateV] = getROIStructureList(IM)
%"getROIStructureList"
%   Assumes each goal that uses the same structure has the same downsampling.

%%% VECTORIZE
% structROIV = [];
% sampleRateV = [];
% for i = 1 : length(IM.goals)
%     structROIV = [structROIV, IM.goals(i).structNum];
%     sampleRateV = [sampleRateV, IM.goals(i).xySampleRate];
% end
structROIV      = getAssociatedStr({IM.goals.strUID});
sampleRateV     = [IM.goals.xySampleRate];

%Get unique list:
[structROIV,iV,jV] = unique(structROIV);
sampleRateV = sampleRateV(iV);
