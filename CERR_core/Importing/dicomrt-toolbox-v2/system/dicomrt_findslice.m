function [slice_number]=dicomrt_findslice(VOI,voilookup,slice,voi2use);
% dicomrt_findslice(VOI,voilookup,slice,voi2use);
%
% Find the location of a VOI contour among different VOIs.
%
% VOI contains the volumes of interests
% voilookup is the voi of reference
% slice is the slice number (defined in voilookup)
% voi2use is the voi where to search for slice
%
% Example:
%
% [num]=dicomrt_findslice(A,outline,5,target);
%
% returns in num the slice number in target which correspond to slice "5" in outline.
%
% See also dicomrt_findsliceVECT, dicomrt_loadvoi
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

[VOI_temp]=dicomrt_checkinput(VOI);
VOI=dicomrt_varfilter(VOI_temp);

ncont=size(VOI{voi2use,2},1); % 
locate_voi_z=[];
slice_number=[];
for i=1:ncont % loop over contour slices
    locate_voi_z=find(VOI{voi2use,2}{i}(1,3)==VOI{voilookup,2}{slice}(1,3));
    if isempty(locate_voi_z)~=1
        slice_number=i;
    end
end

if isempty(slice_number)==1
    warning('dicomrt_findslice: The value returned by dicomrt_findslice is empty: slice was not found.');
end
