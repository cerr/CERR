function planC = deriveProstateCTVfromPTV(ptvStructNum, planC)
% function deriveProstateCTVfromPTV(ptvStructNum, planC)
%
% APA, 08/24/2012

if ~exist('planC','var')
    global planC
end

global stateS

indexS = planC{end};

scanNum = getStructureAssociatedScan(ptvStructNum,planC);

gtvStructNum = length(planC{indexS.structures}) + 1;

gtvStructS = newCERRStructure(scanNum, planC, gtvStructNum);

rasterSegments = [];

for slcNum = 1:length(planC{indexS.scan}(scanNum).scanInfo)
    
    % Calculate centroid for this slice
    [rasterSegs, planC] = getRasterSegments(ptvStructNum,planC,slcNum);

    if ~isempty(rasterSegs)        
        
        meanY = mean(rasterSegs(:,2));
        
        %rasterSegmentsPosterior = rasterSegs(rasterSegs(:,2) <= meanY,:);
        %rasterSegmentsAnterior  = rasterSegs(rasterSegs(:,2) > meanY,:);
        
        rasterSegmentsShrinked_10_6 = structMargin(rasterSegs, [10 6]/10, scanNum, planC);
        rasterSegmentsShrinked_10_6 = structDiff(rasterSegs,rasterSegmentsShrinked_10_6, scanNum, planC);
        
        rasterSegmentsShrinked_10 = structMargin(rasterSegs, 10/10, scanNum, planC);
        rasterSegmentsShrinked_10 = structDiff(rasterSegs,rasterSegmentsShrinked_10, scanNum, planC);
        
        patientPosition = planC{indexS.scan}.scanInfo(1).DICOMHeaders.PatientPosition;
        if isequal(patientPosition,'HFP') || isequal(patientPosition,'FFP')
            rasterSegmentsAnterior = rasterSegmentsShrinked_10(rasterSegmentsShrinked_10(:,2) <= meanY, :);
            rasterSegmentsPosterior = rasterSegmentsShrinked_10_6(rasterSegmentsShrinked_10_6(:,2) > meanY, :);            
        else            
            rasterSegmentsPosterior = rasterSegmentsShrinked_10_6(rasterSegmentsShrinked_10_6(:,2) <= meanY, :);
            rasterSegmentsAnterior = rasterSegmentsShrinked_10(rasterSegmentsShrinked_10(:,2) > meanY, :);
        end
        
        rasterSegments = [rasterSegments; rasterSegmentsAnterior; rasterSegmentsPosterior];
        
    end
    
end

gtvStructS.rasterSegments = rasterSegments;
gtvStructS.rasterized = 1;

contourS = rasterToPoly(rasterSegments, scanNum, planC);

gtvStructS.contour = contourS;

gtvStructS.structureName = 'PROSTATE_CTV';

planC{indexS.structures} = dissimilarInsert(planC{indexS.structures}, gtvStructS, gtvStructNum);

planC = updateStructureMatrices(planC, gtvStructNum);

% Refresh View
if ~isempty(stateS) && isfield(stateS,'handle') && isfield(stateS.handle,'CERRSliceViewer') && isnumeric(stateS.handle.CERRSliceViewer)    
    stateS.structsChanged = 1;
    CERRRefresh
end


