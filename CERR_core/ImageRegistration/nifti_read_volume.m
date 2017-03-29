function [vol,fileinfo] = nifti_read_volume(filename)
% Read MRI files in the NIFTI format
% =======================================================================================================
% Usage    : [vol,info] = nifti_read_volume(filename);
% Examples : [vol,info] = nifti_read_volume('volume.nii');
%                   vol = nifti_read_volume('volume.hdr'); (or) vol = nifti_read_volume('volume.hdr');
%                   (Assumes NIFTI .hdr/.img files share the same name & location)
% =========================================================================================================

%Get header information
[fileinfo,tmpfile] = nifti_read_header(filename);

%Open image file
[fpath,fname,fextn] = fileparts(tmpfile);
switch fextn
% For .nii files or if base filename is used, open '.nii' file
% For .hdr or .img files, open '.img' file
case {'.img','.hdr'}
    fid = fopen(fullfile(fpath,[fname,'.img']),'r',fileinfo.byteswap);
    if fid < 0
        error('Error opening image file');
    end
otherwise
    fid = fopen(tmpfile,'r',fileinfo.byteswap);
    if fid < 0
        error('Error opening image file');
    end
    fseek(fid,fileinfo.voxoffset,'bof');
end

%Get matlab datatype
switch fileinfo.datatype
  case 2
    dtype = 'uint8';
  case 4
    dtype = 'int16';
  case 8
    dtype = 'int32';
  case 16
    dtype = 'float';
  case 64
    dtype = 'double';
  case 132
    dtype = 'int16';
  otherwise
    error('Unsupported datatype');
end
dimension = fileinfo.dimension;

%Read binary data
vol = fread(fid,inf,dtype);
fclose(fid);

%Reshape data
switch dimension(1)
    case 4
        % 4-D data
        if dimension(5) == 1
            vol = reshape(vol,dimension(2),dimension(3),dimension(4));
        else
            vol = reshape(vol,dimension(2),dimension(3),dimension(4), ...
                dimension(5));
        end
    case 3
        % 3-D data
        vol = reshape(vol,dimension(2),dimension(3),dimension(4));
    case 2
        % 2-D data
        vol = reshape(vol,dimension(2),dimension(3));
    case 1
        % 1-D data
    otherwise
        fprintf('Warning: data not reshaped\n');
end


end