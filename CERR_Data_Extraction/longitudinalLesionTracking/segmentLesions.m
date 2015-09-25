function planC = segmentLesions(planC,lesionS)
% function planC = segmentLesions(planC,lesionS)
%
% APA, 6/14/2013

scanNum = 1;
indexS = planC{end};

[xVals, yVals, zVals] = getScanXYZVals(planC{indexS.scan}(scanNum));

%% Using elliptical c/s ROI
for i=1:length(lesionS)
    
    x = lesionS(i).xV;
    y = lesionS(i).yV;
    zLesion = lesionS(i).zV;
    
    try        
        y = [y; y+0.001*y.*rand(length(y),1)];
        x = [x+0.001*x.*rand(length(x),1); x];
        % Fit Elipse
        [z, a, b, alpha] = fitellipse([x(:)'; y(:)']);
        % Generate points along ellipse
        npts = 100;
        t = linspace(0, 2*pi, npts);
        
        % Rotation matrix
        Q = [cos(alpha), -sin(alpha); sin(alpha) cos(alpha)];
        
        % Generate points along ellipse
        xyContourPoints = Q * [a * cos(t); b * sin(t)] + repmat(z, 1, npts);
        
        % Check dimensions of fitted ellipse
        minX = min(xyContourPoints(:,1));
        maxX = max(xyContourPoints(:,1));
        minY = min(xyContourPoints(:,2));
        maxY = max(xyContourPoints(:,2));
        
        minDataX = min(x);
        maxDataX = max(x);
        minDataY = min(y);
        maxDataY = max(y);
    
        deltaX = maxDataX-minDataX;
        deltaY = maxDataY-minDataY;
        
        ellDeltaX = maxX-minX;
        ellDeltaY = maxY-minY;
        
        if ellDeltaX/deltaX > 4 || ellDeltaY/deltaY > 4
            error('Cannot fit ellipse. Fitting Circle.')
        end
        
    catch
        
        % Fit Circle
        centerPt = [mean(x) mean(y)];        
        radius = max(sqrt((x-centerPt(1)).^2 + (y-centerPt(2)).^2));
        
        % Generate points along circle
        npts = 100;
        t = linspace(0, 2*pi, npts);
        xyContourPoints = [centerPt(1)+radius*cos(t); centerPt(2)+radius*sin(t)];
        
    end
    
    [~,sliceNum] = findnearest(zVals,zLesion(1));
    minSlice = max([1 sliceNum-4]);
    maxSlice = min([length(zVals) sliceNum+4]);
    sliceNumsV = minSlice:maxSlice;
        
    % Create Structures segments on sacn slices
    newStructS = newCERRStructure(scanNum, planC);
    for slcNum = 1:length(zVals)
        if ismember(slcNum,sliceNumsV)
            points = [xyContourPoints' zVals(slcNum)*ones(size(xyContourPoints,2),1)];
            newStructS.contour(slcNum).segments(1).points = points;
        else
            newStructS.contour(slcNum).segments.points = [];
        end
    end
    
    newStructNum = length(planC{indexS.structures}) + 1;
    newStructS.structureName = ['Annotation ROI ', num2str(i)];
    
    planC{indexS.structures} = dissimilarInsert(planC{indexS.structures}, newStructS, newStructNum);
    planC = getRasterSegs(planC, newStructNum);
    planC = updateStructureMatrices(planC, newStructNum, sliceNumsV);

end

return;



%% Using Harini's grow-cut segmentation method
segmentationToolFileName = 'R:\SPI\Software\SegmentationTools\GrowCutSegmentationExec\Release\GrowCutSegmentExec.exe';
fileID = num2str(floor(rand*1000));
annotFileName = [fileID,'.mha'];
scanFileName = [fileID,'_scan.mha'];
mhaAnnotFileName = fullfile(tempdir,annotFileName);
mhaScanFileName = fullfile(tempdir,scanFileName);
[success,annot3M] = exportAnnotationsToMha(mhaAnnotFileName, planC, lesionS);
numLesions = max(annot3M(:));
cmdString = [segmentationToolFileName, ' ', escapeSlashes(mhaScanFileName), ' ', escapeSlashes(mhaAnnotFileName), ' ', sprintf('%d',numLesions)];
system(cmdString);

segmentedImageFileName = fullfile(tempdir,'segmentedImage.mha');

[data3M,infoS] = readmha(segmentedImageFileName);
struct3M = flipdim(permute(data3M,[2,1,3]),3);

isUniform = 1;
scanNum = 1;
numStructs = max(struct3M(:));
for structNum = 1:numStructs
    strName = ['Annotation ', num2str(structNum)];
    planC = maskToCERRStructure(struct3M == structNum, isUniform, scanNum, strName, planC);
end
% Clean-up
try, delete(mhaAnnotFileName), end
try, delete(mhaScanFileName), end
try, delete(segmentedImageFileName), end

