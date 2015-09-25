function newIndex = createNewIM()
% function IM = createNewIM()
%
% This function creates a new IM structure for dose calculation and adds it to planC. 
% Note that the beams field is left empty to be populated by batchCalcDose
% This IM can be accessed from planC{indexS.IM}(newIndex).IMDosimetry
%
% APA, 03/20/2012


global planC
indexS = planC{end};

% Structures where dose needs to be calculated
% structV = [12 13];
% isTargetC = {'Yes','Yes'};
% PBMarginV = [0 0];
% xySampleRateV = [2 2];

structV = [13];
isTargetC = {'Yes'};
PBMarginV = [0];
xySampleRateV = [2];


% Create goalS structure
goalInitS = struct('structNum','','strUID','','structName','','isTarget','','PBMargin','','xySampleRate','');
ind = 0;
for structNum = 1:length(structV)
    ind = ind + 1;
    goalS(ind) = goalInitS;
    goalS(ind).structNum = structV(structNum);
    goalS(ind).strUID = planC{indexS.structures}(structV(structNum)).strUID;
    goalS(ind).structName = planC{indexS.structures}(structV(structNum)).structureName;
    goalS(ind).isTarget = isTargetC{ind};
    goalS(ind).PBMargin = PBMarginV(ind);
    goalS(ind).xySampleRate = xySampleRateV(ind);    
end


% Create paramS structure
Scatter.Threshold = 0.01;
Scatter.RandomStep = 30;
paramS = struct('algorithm','QIB','writeScale','','debug','','ScatterMethod','threshold','xyDownsampleIndex',1,'numCTSamplePts',300, ...
                    'cutoffDistance',4,'VMC','','Scatter',Scatter,'DoseTerm','GaussPrimary+scatter');

% Create beam
% tmp.beams = createDefaultBeam(ud.bl.currentBeam, [], ud.bp.isAuto, fieldNames);


% IM setup consists of the following components:
beamS           = '';
assocScanUID    = planC{indexS.scan}(1).scanUID;
imName            = 'TotalBody';
isFresh         = 1;
solutions       = [];

IM.beams = beamS;
IM.goals = goalS;
IM.solutions = solutions;
IM.params = paramS;
IM.assocScanUID = assocScanUID;
IM.name = imName;
IM.isFresh = isFresh;

% Add this IM to planC
[planC, newIndex] = addIM(IM, planC, 0);

