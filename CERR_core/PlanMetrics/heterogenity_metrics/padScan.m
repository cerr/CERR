function [outScan3M,outMask3M, outLimitsV] = padScan(scan3M,mask3M,method,marginV)
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
% AI 06/05/20
% ----------------------------------------------------------------------

%% Compute ROI bounding box extents
[minr, maxr, minc, maxc, mins, maxs] = compute_boundingbox(mask3M);

%% Crop scan
croppedScan3M = scan3M(minr:maxr,minc:maxc,mins:maxs);
croppedMask3M = mask3M(minr:maxr,minc:maxc,mins:maxs);

%% Compute padded image size
if strcmpi(method,'none')
    marginV=[0,0,0];
end
minr = max(minr-marginV(1),1);
maxr = min(maxr+marginV(1),size(mask3M,1));
minc = max(minc-marginV(2),1);
maxc = min(maxc+marginV(2),size(mask3M,2));
mins = max(mins-marginV(3),1);
maxs = min(maxs+marginV(3),size(mask3M,3));
outLimitsV = [minr,maxr,minc,maxc,mins,maxs];

%% Apply padding
switch lower(method)
    
    case 'expand'
       
        outScan3M = scan3M(minr:maxr,minc:maxc,mins:maxs);
        outMask3M = mask3M(minr:maxr,minc:maxc,mins:maxs);
        
    case 'padzeros'
        
        outScan3M = padarray(croppedScan3M,marginV,0,'both');
        outMask3M = padarray(croppedMask3M,marginV,0,'both');
        
    case {'periodic','nearest','mirror'}
        
        supportedMethodsC = {'circular','replicate','symmetric'};
        matchIdx = strcmpi(method,{'periodic','nearest','mirror'});
        matchingMethod = supportedMethodsC{matchIdx};
        
        outScan3M = padarray(croppedScan3M,marginV,matchingMethod,'both');
        outMask3M = padarray(croppedMask3M,marginV,0,'both');
        
    case 'none'
        outScan3M = croppedScan3M;
        outMask3M = croppedMask3M;
        
    otherwise
        error(['Invalid method ''%s''. Supported methods include ',...
            '''expand'',''padzeros'',''periodic'',''nearest'', '...
            '''mirror'' and ''none''.'],method);
        
end

end