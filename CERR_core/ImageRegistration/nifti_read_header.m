function [fileinfo,tempfile] = nifti_read_header(filename)
% Reads NIFTI file headers
% ==============================================================================================
% Usage    : fileinfo = nifti_read_header(filename);
% Examples : info = nifti_read_header('volume.nii');
%            info = nifti_read_header('volume.img') (or) info = nifti_read_header('volume.hdr');
%            (Assumes NIFTI .hdr/.img files share the same name & location)
% ---Outputs---
% fileinfo : Header file information
% tempfile : Header file (temporary file extracted in case of .gz compressed files).
% ===============================================================================================

% Handle compressed files
[fpath,fname,fextn] = fileparts(filename);
if strcmp(fextn,'.gz')
    [~, fname, fextn] = fileparts(fname);
    switch fextn
        case {'.img','.hdr'}
            gnuCERRCompression(fullfile(fpath,[fname,'.hdr.gz']), 'uncompress', tempdir);
            gnuCERRCompression(fullfile(fpath,[fname,'.img.gz']), 'uncompress', tempdir);
        otherwise
            gnuCERRCompression(filename, 'uncompress', tempdir);
    end
    fpath = tempdir;
end

%Open header file
if strcmp(fextn,'.img')
    fextn = '.hdr';
end
tempfile = fullfile(fpath,[fname,fextn]); 
fid = fopen(tempfile,'r');
if fid < 0
    error('Error opening header file');
end

%Check for byte swapping problem by looking at the dimension bit in the header file
% If dimension > 10 (we probably aren't dealing with more than 10-dimensional data), try byte swapping.
% If this fails, output an error.
fseek(fid,40,'bof');
dimension = fread(fid,8,'int16');
byteswap = 'n';
if (dimension(1) > 10)
    byteswap = 'b';
    fclose(fid);
    fid = fopen(tempfile,'r',byteswap);
    if fid < 0
        error('Error opening header file');
    end
    fseek(fid,40,'bof');
    dimension = fread(fid,8,'int16');
    if (dimension(1) > 10)
        byteswap = 'l';
        fclose(fid);
        fid = fopen(tempfile,'r',byteswap);
        if fid < 0
            error('Error opening header file');
        end
        fseek(fid,40,'bof');
        dimension = fread(fid,8,'int16');
        if (dimension(1) > 10)
            fclose(fid);
            error('Error opening file. Dimension argument is not valid');
        end
    end
end

%Read information from header file
% Note: Some header information is not currently read (like intent codes).

% datatype
fseek(fid,40+30,'bof');
datatype = fread(fid,1,'int16');

% pixel dimension
fseek(fid,40+36,'bof');
pixdim = fread(fid,8,'float');

% bits per pixel
fseek(fid,40+32,'bof');
bitpix = fread(fid,1,'int16');

% data offset
fseek(fid,108,'bof');
voxoffset = fread(fid,1,'float');

% orientation
fseek(fid,252,'bof');
formcodes = fread(fid,2,'int16');
fseek(fid,256,'bof');
qmatrix = fread(fid,6,'float');
fseek(fid,280,'bof');
smatrix = fread(fid,12,'float');

%Close header file
fclose(fid);

%Return fileinfo
pixdim = pixdim(2:(dimension(1)+1));
orientation = struct('qfac',pixdim(1),...
    'qform',formcodes(1),...
    'qmatrix',qmatrix,...
    'sform',formcodes(2),...
    'smatrix',smatrix);

fileinfo = struct('dimension',dimension,...
    'pixdim',pixdim,...
    'datatype',datatype,...
    'bitpix',bitpix,...
    'voxoffset',voxoffset,...
    'byteswap',byteswap,...
    'orientation',orientation);


end