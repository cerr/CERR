function [t50Map3M,s50Map3M,planC] = TTHP_main(planC,strNum,varargin)
% [t50Map3M,s50Map3M] = TTHP_main(planC,strNum,varargin)
% AI 2/02/16
%==========================================================================
% INPUTS
% planC : CERR archive
% strNum: Structure number
% --- Optional -----
% varargin{1} :  Flag for temporal smoothing (Default:0)
% varargin{2} :  Flag for resampling         (Default:0)
% varargin{3} :  Spatial smoothing filter size & sigma
%                filtV =[fSize, fSigma] (Default: no smoothing)
%==========================================================================
%% Check inputs
minargs = 2;
maxargs = 5;
narginchk(minargs,maxargs);
% Set defaults
smoothFlag = 0;
resampFlag = 0;
filtV = 0;
optArgC = {smoothFlag,resampFlag,filtV};
% Replace with user input where available
numOptIns = nargin-minargs;
[optArgC{1:numOptIns}] = varargin{:};
[smoothFlag,resampFlag,filtV] = optArgC{:};
indexS = planC{end};
% Construct spatial smoothing filt (if reqd)
if ~filtV==0
    fSize = filtV(1);
    fSigma = filtV(2);
    hFilt = fspecial('gaussian',11,5); %fSize=11, fSigma=5
end

%% Get masked data
%Extract mask
assocScanNum = getStructureAssociatedScan(strNum, planC);
sizV = size(getScanArray(assocScanNum,planC));
mask3M = false(sizV);

rasterSegments = getRasterSegments(strNum,planC);
[mask,roiSlicesV] = rasterToMask(rasterSegments,assocScanNum,planC);
mask3M(:,:,roiSlicesV) = mask;
nMaskSlices = numel(roiSlicesV);

%Apply mask
scanS = planC{indexS.scan};
sizV = [sizV(1),sizV(2),numel(scanS),sizV(3)];
filtSlice3M = zeros(sizV(1:3));
normDCE4M = zeros(sizV(1),sizV(2),sizV(3),nMaskSlices);
for n = 1:nMaskSlices
    
    %Get data
    sliceC = arrayfun(@(x) x.scanArray(:,:,roiSlicesV(n)),scanS,'un',0);
    slice3M = double(cat(3,sliceC{:}));
    
    %Smooth
    if ~filtV==0
        for l = 1:size(filtSlice3M,3)
            filtSlice3M(:,:,l) = filter2(hFilt,slice3M(:,:,l));
        end
    else
        filtSlice3M = slice3M;
    end
    
    %Mask data
    maskM = mask3M(:,:,roiSlicesV(n));
    maskedDCE3M = bsxfun(@times,filtSlice3M,maskM);
    if n==1
        %Get user-input shift to start of uptake curve
        [shift,nbase] = getShift(maskedDCE3M,maskM);
    end
    %Normalize
    base3M = maskedDCE3M(:,:,1:nbase); %Baseline signal
    baseM = mean(base3M,3);            %Mean baseline signal
    baseM(baseM==0) = eps;
    normDCE4M(:,:,:,roiSlicesV(n)) = bsxfun(@rdivide,maskedDCE3M,baseM);
end


%% Get time pts (in min) of DCE image acquisition
timeV = getAcqTime(scanS);
%Apply shift correction
timeShiftV = timeV - timeV(shift+1);
timeShiftV = timeShiftV(shift+1:end);
normDCEShift4M = normDCE4M(:,:,shift+1:end,:);

%% Get T50, s50
CERRStatusString('Computing TTHP...','console');
t50C = cell(1,nMaskSlices);
s50C = cell(1,nMaskSlices);
t50Map3M = zeros(sizV(1),sizV(2),sizV(4));
s50Map3M = zeros(sizV(1),sizV(2),sizV(4));
for n = 1:nMaskSlices
    [ROIidxV,ROIDataM] = getRasterROI(normDCEShift4M(:,:,:,roiSlicesV(n)));
    
    %Compute TTHP, SHP
    [resampSigM,t50C{n},s50C{n},timeOutV] = halfPeak(ROIDataM,timeShiftV,smoothFlag,resampFlag);
    
    %Create maps
    t50MapV = zeros(sizV(1)*sizV(2),1);
    s50MapV = zeros(sizV(1)*sizV(2),1);
    t50MapV(ROIidxV) = t50C{n};
    t50Map3M(:,:,roiSlicesV(n)) = reshape(t50MapV,sizV(2),sizV(1)).';
    s50MapV(ROIidxV) = s50C{n};
    s50Map3M(:,:,roiSlicesV(n)) = reshape(s50MapV,sizV(2),sizV(1)).';
end

%% Add maps to planC
scanNum = getStructureAssociatedScan(strNum,planC);
[xVals, yVals, zVals] = getScanXYZVals(planC{indexS.scan}(scanNum));
dx = abs(mean(diff(xVals)));
dy = abs(mean(diff(yVals)));
dz = abs(mean(diff(zVals)));
deltaXYZv = [dy dx dz];
regParamsS.horizontalGridInterval = deltaXYZv(1);
regParamsS.verticalGridInterval   = deltaXYZv(2);
regParamsS.coord1OFFirstPoint   = xVals(1);
regParamsS.coord2OFFirstPoint   = yVals(sizV(1));
regParamsS.zValues  = zVals;
regParamsS.sliceThickness =[planC{indexS.scan}(scanNum).scanInfo(:).sliceThickness];

assocTextureUID1 = createUID('texture');
planC = scan2CERR(t50Map3M,'TTHP','Passed',regParamsS,assocTextureUID1,planC);

assocTextureUID2 = createUID('texture');
planC = scan2CERR(s50Map3M,'SHP','Passed',regParamsS,assocTextureUID2,planC);

CERRStatusString('Complete.','console');



%% -- Sub-functions --
    function [shift,nbase] = getShift(maskedDCE3M,maskM)
        [i,j] = find(maskM);
        ROISigM = (maskedDCE3M(i,j,:));
        avgROIsigV = squeeze(sum(sum(ROISigM)))/size(maskedDCE3M,3);
        h = figure('Name','ROI avg signal');
        plot(0:length(avgROIsigV)-1,avgROIsigV,'-dr');
        inShift = inputdlg('Enter shift (time) to start of uptake curve)','User-input shift');
        shift = str2num(inShift{1});
        if isempty(shift) || shift<1
            error('Invalid input: user shift');
            return
        end
        close(h)
        % Get number of baseline points (prior to uptake)
        if shift>1
            nbase = shift-1;
        else
            nbase = 1;
        end
    end

end