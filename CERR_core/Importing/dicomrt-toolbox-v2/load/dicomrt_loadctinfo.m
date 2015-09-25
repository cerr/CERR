function [ctinfo] = dicomrt_loadctinfo(filename,num)
% dicomrt_loadctinfo(filename,num)
%
% Read dicom CT for a case using MATLAB native function dicomread.
%
% filename contains a list of CT slices to import
%
% CT are stored in a single 3D matrix: case_study
% x-y coordinates of the center of the dose-pixel are stored in xmash and ymesh
%
% See also dicomrt_loaddose
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org)

% Get CT images and create 3D Volume
fid=fopen(filename);
nct=0;

ctinfo=cell(num,1);

%loop until the end-of-file is reached and build 3D CT matrix
while (feof(fid)~=1);
    nct=nct+1;
    ct_file_location{1,nct}=fgetl(fid);
    dictFlg = checkDictUse;
    if dictFlg
        temp_info=dicominfo(ct_file_location{1,nct}, 'dictionary', 'ES - IPT4.1CompatibleDictionary.mat');
    else
        temp_info=dicominfo(ct_file_location{1,nct});
    end

    ctinfo{nct}=temp_info;
end

fclose(fid);

% 3D CT matrix and mesh matrix imported
