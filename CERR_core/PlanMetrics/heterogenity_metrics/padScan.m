function [outScan3M,outMask3M, outLimitsV] = padScan(scan3M,mask3M,...
    method,marginV,cropFlag)
% padScan.m
% Crop scan around ROI and pad using specified method.
% ----------------------------------------------------------------------
% INPUTS
% scan3M  : Scan array
% mask3M  : ROI mask
% method  : Supported options include 'expand','padzeros',
%           'periodic','nearest','mirror', and 'none'.
% margin  : 3-element vector specifying amount of padding (in voxels) along
%           each dimension.
%cropFlag : Set to 1 to crop to mask bounds prior to padding (default)
%           or zero to use original scan extents.
%-----------------------------------------------------------------------
% AI 06/05/20
% ----------------------------------------------------------------------

if ~exist('cropFlag','var')
    cropFlag = 1;
end

if strcmpi(method,'none')
    marginV = [0,0,0];
end

%% Crop scan & mask
if cropFlag
    [minr, maxr, minc, maxc, mins, maxs] = compute_boundingbox(mask3M);
    croppedScan3M = scan3M(minr:maxr,minc:maxc,mins:maxs);
    croppedMask3M = mask3M(minr:maxr,minc:maxc,mins:maxs);
    minr = minr-marginV(1);
    maxr = maxr+marginV(1);
    minc = minc-marginV(2);
    maxc = maxc+marginV(2);
    mins = mins-marginV(3);
    maxs = maxs+marginV(3);
else
    inputSizeV = size(scan3M);
    [minr,minc,mins] = deal(1);
    maxr = inputSizeV(1);
    maxc = inputSizeV(2);
    maxs = inputSizeV(3);
    minr = minr-marginV(1);
    maxr = maxr+marginV(1);
    minc = minc-marginV(2);
    maxc = maxc+marginV(2);
    mins = mins-marginV(3);
    maxs = maxs+marginV(3);
    croppedScan3M = scan3M;
    croppedMask3M = mask3M;
end

%% Compute padded image size
outLimitsV = [minr,maxr,minc,maxc,mins,maxs];

%% Apply padding
switch lower(method)
    
    case 'expand'
        %requires cropFlag=1
        if ~cropFlag
            error('padScan.m: Set cropFlag=1 to use method ''expand''');
        end
        minr = max(minr,1);
        maxr = min(maxr,size(mask3M,1));
        minc = max(minc,1);
        maxc = min(maxc,size(mask3M,2));
        mins = max(mins,1);
        maxs = min(maxs,size(mask3M,3));
        %     minr = max(minr-marginV(1),1);
        %     maxr = min(maxr+marginV(1),size(mask3M,1));
        %     minc = max(minc-marginV(2),1);
        %     maxc = min(maxc+marginV(2),size(mask3M,2));
        %     mins = max(mins-marginV(3),1);
        %     maxs = min(maxs+marginV(3),size(mask3M,3));
        outScan3M = scan3M(minr:maxr,minc:maxc,mins:maxs);
        outMask3M = mask3M(minr:maxr,minc:maxc,mins:maxs);
        
    case 'padzeros'
        if exist('padarray.m','file')
            outScan3M = padarray(croppedScan3M,marginV,0,'both');
            outMask3M = padarray(croppedMask3M,marginV,0,'both');
        else
            outScan3M = padarray_oct(croppedScan3M,marginV,0,'both');
            outMask3M = padarray_oct(croppedMask3M,marginV,0,'both');
        end
        
    case {'periodic','nearest','mirror'}
        
        supportedMethodsC = {'circular','replicate','symmetric'};
        matchIdx = strcmpi(method,{'periodic','nearest','mirror'});
        matchingMethod = supportedMethodsC{matchIdx};
        if exist('padarray.m','file')
            outScan3M = padarray(croppedScan3M,marginV,matchingMethod,'both');
            outMask3M = padarray(croppedMask3M,marginV,0,'both');
        else
            outScan3M = padarray_oct(croppedScan3M,marginV,matchingMethod,'both');
            outMask3M = padarray_oct(croppedMask3M,marginV,0,'both');
        end
        
    case 'none'
        outScan3M = croppedScan3M;
        outMask3M = croppedMask3M;
        
    otherwise
        error(['Invalid method ''%s''. Supported methods include ',...
            '''expand'',''padzeros'',''periodic'',''nearest'', '...
            '''mirror'' and ''none''.'],method);
        
end

end