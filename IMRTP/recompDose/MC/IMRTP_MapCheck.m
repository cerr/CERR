% function IM = IMRTP_MapCheck(statement)
% JC. 11 Aug, 05, Add more arguments
function IM = IMRTP_MapCheck(statement, planC, stateS, xPosV, yPosV, beamlet_delta_x, beamlet_delta_y, gA);
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

%JC, 11 Aug 05 
% commented out following three "global *", passing them by using arguments.
%global planC
%global stateS
%global indexS

indexS=planC{end};

% Add planC as input to functions: IMRTP_MapCheck(),
% getTargetSurfacePoints(), getSurface().

% JC Mar 1, 2007
% Do not down sample a plan, even the scan is larger than 512x512.
% % if isfield(stateS.optS, 'IMRTCheckResolution') & strcmpi(stateS.optS.IMRTCheckResolution, 'on') & size(planC{indexS.scan}.scanArray,1) == 512
% %     planC = getplanCDownSample(planC, stateS.optS, 2);
% %     %Compensate for slice position changing.
% %     try
% %         stateS.sliceNumCor = round(stateS.sliceNumCor/2);
% %         stateS.sliceNumSag = round(stateS.sliceNumSag/2);        
% %     end
% % end



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

%Calculates isocenter if required.
% IM = checkAutoIsocenter(IM);

%Get surfacePoints of all target structures.

edgeS = getTargetSurfacePoints(IM, planC);


%Get ROI StructureList
[structROIV, sampleRateV] = getROIStructureList(IM);

%Set PB vectors, determine which PBs are required to cover the target.
IM = getPBList(IM, edgeS,planC, xPosV, yPosV, beamlet_delta_x, beamlet_delta_y, gA);


function edgeS = getTargetSurfacePoints(IM, planC)
%"getTargetSurfacePoints"
%   Returns surface points of all targets in IM structure.   
	structTargetV = [];
	PBMarginV = [];
	for i = 1 : length(IM.goals)
      if strcmpi(IM.goals(i).isTarget(1),'y')
        structTargetV = [structTargetV, IM.goals(i).structNum];
        PBMarginV = [PBMarginV, IM.goals(i).PBMargin];
      end
    end
    
    if length(planC{planC{end}.structures}) <=1
        structTargetV = 1;
    end
    
	
	%Get unique list:
	[structTargetV,iV,jV] = unique(structTargetV);
	PBMarginV = PBMarginV(iV);
	
	disp('Get target surface points...')

        
%     try
%         IMRTPGui('statusbar', 'Getting target surface points...');
% 	end
	tic
    	[edgeS] = getSurface(structTargetV,PBMarginV+0.5, IM.params.xyDownsampleIndex, planC); %%%should be IM.params.xyDownsampleIndex
    toc
%-------------------------------------------


function IM = getPBList(IM, edgeS,planC, xPosV, yPosV, beamlet_delta_x, beamlet_delta_y, gA);
%"getPBList"
%   Populates the beam fields in IM to describe the pencil beams that cover
%   the target.
for i = 1 : length(IM.beams)
  disp(['Get ray trace for beam ' num2str(i) '.'])
%   try
%     IMRTPGui('statusbar', ['Getting ray trace for beam ' num2str(i) '...']);
%   end
  tic
  [CTTraceS, RTOGPBVectorsM, RTOGPBVectorsM_MC, PBMaskM, rowPBV, colPBV, xPBPosV, yPBPosV, beamletDelta_x, beamletDelta_y] = ...
   getPBRayData(edgeS, IM.beams(i), IM.params.numCTSamplePts, IM.params.xyDownsampleIndex,planC, xPosV, yPosV, beamlet_delta_x, beamlet_delta_y, gA);
  toc

  IM.beams(i).RTOGPBVectorsM_MC = RTOGPBVectorsM_MC;
  IM.beams(i).RTOGPBVectorsM    = RTOGPBVectorsM;
  IM.beams(i).xPBPosV           = xPBPosV;
  IM.beams(i).yPBPosV           = yPBPosV;
  IM.beams(i).rowPBV            = rowPBV;
  IM.beams(i).colPBV            = colPBV;
  IM.beams(i).CTTraceS          = CTTraceS;
  IM.beams(i).beamletDelta_x    = beamletDelta_x;
  IM.beams(i).beamletDelta_y    = beamletDelta_y;  

  %RTOG positions of sources
  IM.beams(i).x = IM.beams(i).xRel + IM.beams(i).isocenter.x;
  IM.beams(i).y = IM.beams(i).yRel + IM.beams(i).isocenter.y;
  IM.beams(i).z = IM.beams(i).zRel + IM.beams(i).isocenter.z;
end


function [structROIV, sampleRateV] = getROIStructureList(IM)
%"getROIStructureList"
%   Assumes each goal that uses the same structure has the same downsampling.
	structROIV = [];
	sampleRateV = [];
	for i = 1 : length(IM.goals)
      structROIV = [structROIV, IM.goals(i).structNum];
      sampleRateV = [sampleRateV, IM.goals(i).xySampleRate];
	end
	
	%Get unique list:
	[structROIV,iV,jV] = unique(structROIV);
	sampleRateV = sampleRateV(iV);