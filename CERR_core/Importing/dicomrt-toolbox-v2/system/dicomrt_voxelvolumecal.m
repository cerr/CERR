function [volume,status] = dicomrt_voxelvolumecal(inpstudy,xmesh,ymesh,zmesh)
% dicomrt_voxelvolumecal(inpstudy,xmesh,ymesh,zmesh)
%
% Calculates the volume of voxels on eaxh slice of the provided study.
%
% If the modality of the study is RTPLAN the slice thickness is calculated as
% the difference between two consecutive slices, assuming that they are equally spaced.
% If the modality of the study is CT the slice thickness is calculated first
% on the basis of the SliceThickness DICOM value for each slice. 
%
% In the first case (RTPLAN) the returned volme is a single value.
% In the second case (CT) the returned volme is an array of volumes.
% In both cases voxels are assumed to have uniform spacing along X and Y.
% 
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

[study_temp,type,label,PatientPosition]=dicomrt_checkinput(inpstudy);
study_array=dicomrt_varfilter(study_temp);

study_pointer=study_temp{1,1};
temp_study_header=study_pointer{1};

xdim=abs(xmesh(2)-xmesh(1));
ydim=abs(ymesh(2)-ymesh(1));

slice_thickness=zeros(length(zmesh),1);

if strcmpi(type,'CT')
    for k=1:length(zmesh)
        slice_thickness(k)=(study_pointer{1,k}.SliceThickness).*0.1;
    end
    status=0;
    volume=slice_thickness.*xdim.*ydim;
elseif strcmpi(type,'RTPLAN') | strcmpi(type,'MC') | strcmpi(type,'GAMMA') | strcmpi(type,'DIFF')
    diff_vect=diff(zmesh);
    grad_diff_vect=gradient(dicomrt_mmdigit(diff_vect,4));
    uniformspacing=find(grad_diff_vect);
    if isempty(uniformspacing)==1
        status=0;
    else
        status=1;
    end
    slice_thickness(:)=abs(zmesh(2)-zmesh(1));
    volume=slice_thickness.*xdim.*ydim;
end
