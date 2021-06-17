function nii = vol2nii(vol3M,affineMat,qOffset,voxel_size,orientationStr,scanFileName)

R = affineMat;

% https://nifti.nimh.nih.gov/nifti-1/documentation/nifti1fields/nifti1fields_pages/quatern.html
a = 0.5  * sqrt(1+R(1,1)+R(2,2)+R(3,3));   % (not stored)
b = 0.25 * (R(3,2)-R(2,3)) / a;      %quatern_b
c = 0.25 * (R(1,3)-R(3,1)) / a;    % quatern_c
d = 0.25 * (R(2,1)-R(1,2)) / a;   % quatern_d

nii = make_nii(vol3M,voxel_size, qOffset); 

nii.hdr.hist.srow_x = affineMat(1,:);
nii.hdr.hist.srow_y = affineMat(2,:);
nii.hdr.hist.srow_z = affineMat(3,:);
nii.hdr.hist.qoffset_x = qOffset(1);
nii.hdr.hist.qoffset_y = qOffset(2);
nii.hdr.hist.qoffset_z = qOffset(3);
nii.hdr.hist.quatern_b = b;
nii.hdr.hist.quatern_c = c;
nii.hdr.hist.quatern_d = d;
nii.hdr.hist.qform_code = 1;
nii.hdr.hist.sform_code = 1;



save_nii(nii,scanFileName);