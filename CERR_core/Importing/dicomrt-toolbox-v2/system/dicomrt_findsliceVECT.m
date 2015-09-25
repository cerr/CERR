function [slice_number]=dicomrt_findsliceVECT(vectref,slice,vect,PatientPosition,edges)
% dicomrt_findsliceVECT(vectref,slice,vect,PatientPosition,edges)
%
% Find the location of a point among different vectors.
%
% vectref is the vector of reference
% slice is the slice number (defined in voilookup)
% vect is the vector where to search for slice
% PatientPoisition is the code which defines the patient orientation 
% edges is an OPTIONAL parameter 
%     if edges==1 vectors define boundaries of pixels
%     if edges==0 (default) vectors define centers of pixels
% 
% Example:
%
% [num]=dicomrt_findsliceVECT(dose_xmesh,30,ct_xmesh);
%
% returns in num the slice number in ct_xmesh which correspond to slice "30" in dose_xmesh.
%
% See also dicomrt_findslice, dicomrt_getPatientPosition, hist, histc
% 
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

% Check number of argument and set-up some parameters and variables
error(nargchk(4,5,nargin))

if exist('edges')==0
    edges=1;
end

if edges==1
    if slice<=length(vectref)
        if PatientPosition==1
            locate_slice=histc(vectref(slice),vect);
            slice_number=find(locate_slice);
        elseif PatientPosition==2
            locate_slice=histc(vectref(slice),vect);
            slice_number=find(locate_slice);
        elseif PatientPosition==3
            if issorted(vectref)~=1 & issorted(vect)~=1 % if sorted this is a Z slice which is always sorted
                [vectref,index_vectref]=sort(vectref);
                [vect,index_vect]=sort(vect);
                locate_slice=histc(vectref(length(vectref)-slice+1),vect);
                slice_number=index_vect(find(locate_slice));
            else
                locate_slice=histc(vectref(slice),vect);
                slice_number=find(locate_slice);
            end
        else
            if issorted(vectref)~=1 & issorted(vect)~=1 % if sorted this is a Z slice which is always sorted
                [vectref,index_vectref]=sort(vectref);
                [vect,index_vect]=sort(vect);
                locate_slice=histc(vectref(length(vectref)-slice+1),vect);
                slice_number=index_vect(find(locate_slice));
            else
                locate_slice=histc(vectref(slice),vect);
                slice_number=find(locate_slice);
            end
        end
    else
        slice_number=[];
    end
else
    if slice<=length(vectref)
        if PatientPosition==1
            locate_slice=hist(vectref(slice),vect);
            slice_number=find(locate_slice);
        elseif PatientPosition==2
            locate_slice=hist(vectref(slice),vect);
            slice_number=find(locate_slice);
        elseif PatientPosition==3
            if issorted(vectref)~=1 & issorted(vect)~=1 % if sorted this is a Z slice which is always sorted
                [vectref,index_vectref]=sort(vectref);
                [vect,index_vect]=sort(vect);
                locate_slice=hist(vectref(length(vectref)-slice+1),vect);
                slice_number=index_vect(find(locate_slice));
            else
                locate_slice=hist(vectref(slice),vect);
                slice_number=find(locate_slice);
            end
        else
            if issorted(vectref)~=1 & issorted(vect)~=1 % if sorted this is a Z slice which is always sorted
                [vectref,index_vectref]=sort(vectref);
                [vect,index_vect]=sort(vect);
                locate_slice=hist(vectref(length(vectref)-slice+1),vect);
                slice_number=index_vect(find(locate_slice));
            else
                locate_slice=hist(vectref(slice),vect);
                slice_number=find(locate_slice);
            end
        end
    else
        slice_number=[];
    end
end