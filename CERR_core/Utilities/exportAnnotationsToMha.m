function [success,annot3M] = exportAnnotationsToMha(toMhaFileName, planC, scanLesions)
% function exportAnnotationsToMha(toMhaFileName, planC, scanLesions)
%
% Exports Annotations to Mha file format.
%
% APA, 02/25/2013


indexS = planC{end};

scanNum = 1;

% % Build a list of slices that are annotated
% for slcNum=1:length(planC{indexS.scan}(scanNum).scanInfo)
%     SOPInstanceUIDc{slcNum} = planC{indexS.scan}(scanNum).scanInfo(slcNum).DICOMHeaders.SOPInstanceUID;
% end
% numSignificantSlcs = length(planC{indexS.GSPS});
% matchingSliceIndV = [];
% matchingGSPSIndV = [];
% for i=1:numSignificantSlcs
%     sliceNum = strmatch(planC{indexS.GSPS}(i).SOPInstanceUID, SOPInstanceUIDc, 'exact');
%     sliceNumsC{i} = sliceNum;
%     if ~isempty(sliceNum)
%         matchingSliceIndV = [matchingSliceIndV sliceNum];
%         matchingGSPSIndV = [matchingGSPSIndV i];
%     end
% end
% 
% % Create 3D annotation mask same size as the scan.
% annot3M = zeros(getUniformScanSize(planC{indexS.scan}(scanNum)),'uint16');
% gspsCount = 1;
% for gspsNum = matchingGSPSIndV
%     sliceNum = matchingSliceIndV(gspsCount);
%     for iGraphic = 1:length(planC{indexS.GSPS}(gspsNum).graphicAnnotationS)
%         graphicAnnotationType = planC{indexS.GSPS}(gspsNum).graphicAnnotationS(iGraphic).graphicAnnotationType;
%         graphicAnnotationNumPts = planC{indexS.GSPS}(gspsNum).graphicAnnotationS(iGraphic).graphicAnnotationNumPts;
%         graphicAnnotationData = planC{indexS.GSPS}(gspsNum).graphicAnnotationS(iGraphic).graphicAnnotationData;
%         colV = graphicAnnotationData(1:2:end);
%         rowV = graphicAnnotationData(2:2:end);
%         if strcmpi(graphicAnnotationType,'POLYLINE')
%             % Interpolate in between to generate voxels on the line
%             % Assuming the line is contained between the start/end voxels.
%             [rowIndV,colIndV] = generateInBtwnVoxels(rowV,colV); 
%             
%         elseif strcmpi(graphicAnnotationType,'ELLIPSE')
%             [rowIndV,colIndV] = generateInBtwnVoxels(rowV(1:2),colV(1:2));
%             [rowInd2V,colInd2V] = generateInBtwnVoxels(rowV(3:4),colV(3:4));
%             rowIndV = [rowIndV(:); rowInd2V(:)];
%             colIndV = [colIndV(:); colInd2V(:)];
%         end
%         
%         annot3M(rowIndV,colIndV,sliceNum) = gspsCount;
%         
%     end
%     gspsCount = gspsCount + 1;
% end




% Find Lesions on this scan
if ~exist('scanLesions','var')
    scanLesions = findLesions(scanNum,planC);
end

% initialize annotations matrix
unifScanSize = getUniformScanSize(planC{indexS.scan}(scanNum));
annot3M = zeros(unifScanSize,'uint16');

% iterate over lesions
for lesionNum = 1:length(scanLesions)
    xV = scanLesions(lesionNum).xV;
    yV = scanLesions(lesionNum).yV;
    zV = scanLesions(lesionNum).zV;
    for lineNum = 1:length(xV)/2
        x1 = xV(lineNum*2-1);
        x2 = xV(lineNum*2);
        y1 = yV(lineNum*2-1);
        y2 = yV(lineNum*2);
        slope = (y2-y1)/(x2-x1+1e3*eps);
        yIntercept = y1 - slope*x1;
        xVox = linspace(x1,x2,500);
        yVox = slope*xVox + yIntercept;
        zVox = zV(1)*xVox.^0;
        [rV,cV,sV] = xyztom(xVox,yVox,zVox,scanNum,planC);        
        rV = round(rV);
        cV = round(cV);
        sV = round(sV);
        indV = sub2ind(unifScanSize,rV,cV,sV);
        annot3M(indV) = lesionNum;
    end
end

% Prepare annot3M to be written to .mha
[~, uniformScanInfoS] = getUniformizedCTScan(0,scanNum,planC);
annot3M = permute(annot3M, [2 1 3]);
annot3M = flipdim(annot3M,3);

% [dx, dy, dz]
resolution = [uniformScanInfoS.grid2Units, uniformScanInfoS.grid1Units, uniformScanInfoS.sliceThickness] * 10;

[xVals, yVals, zVals] = getUniformScanXYZVals(planC{indexS.scan}(scanNum));

offset = [xVals(1) -yVals(1) -zVals(end)] * 10;

% Write .mha file for scanNum1
writemetaimagefile(toMhaFileName, annot3M, resolution, offset);

[dirName,fName] = fileparts(toMhaFileName);
movScanFileName = fullfile(dirName,[fName,'_scan.mha']);
success = createMhaScansFromCERR(scanNum, movScanFileName, planC);

end


function [rowIndV,colIndV] = generateInBtwnVoxels(rowV,colV)
if rowV(2)==rowV(1)
    colIndV = round(min(colV)):round(max(colV));
    rowIndV = round(rowV(1))*colIndV.^0;
elseif colV(2)==colV(1)
    rowIndV = round(min(rowV)):round(max(rowV));
    colIndV = round(colV(1))*rowIndV.^0;
else
    if rowV(1) < rowV(2)
        rowIndV = rowV(1):0.05:rowV(2);
    else
        rowV = flipud(rowV);
        colV = flipud(colV);
        rowIndV = rowV(1):0.05:rowV(2);
    end
    colIndV = colV(1) + (rowIndV-rowV(1))*(colV(2)-colV(1))/(rowV(2)-rowV(1));
    rowIndV = round(rowIndV);
    colIndV = round(colIndV);
    [jnk,uniqueInd] = unique([rowIndV(:) colIndV(:)],'rows');
    rowIndV = rowIndV(uniqueInd);
    colIndV = colIndV(uniqueInd);
end

end

