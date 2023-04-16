function img = dicm_img(s, xpose)
% Read image of a dicom file.
% 
% img = DICM_IMG(metaStructOrFilename, xpose);
% 
% The mandatory first input is the dicom file name, or the struct returned by
% dicm_hdr. The output keeps the data type in dicom file.
% 
% The second input is for special purpose. When it is provided and is false, the
% returned img won't be transposed. This is likely only useful for dicm2nii.m,
% where the Columns and Rows parameters become counter-intuitive.
% 
% DICM_IMG is like dicomread from Matlab, but is independent of Image Processing
% Toolbox.
%
% See also DICM_HDR, DICM_DICT, DICM2NII

% TO DO: take care of BitsAllocated, BitsStored and HighBit related issue.
% Now we assume
%   extra bits beyond BitsStored are zeros.

% History (yymmdd):
% 130823 Write it for dicm2nii.m (xiangrui.li@gmail.com)
% 130914 Use PixelData.Bytes rather than nPixels;
%        Use PixelRepresentation to determine signed data.
% 130923 Use BitsAllocated for bits. Make it work for multiframe.
% 131018 Add jpeg de-compression part.
% 141023 Use memmapfile for temp file: ~25% speedup.
% 150109 Transpose img by default. dicm2nii needs xpose=0 to avoid transpose.
% 150115 SamplesPerPixel>1 works: put it as dim3, and push rest to dim4.
% 150211 dim3 reserved for RGB, even if SamplesPerPixel=1 (like dicomread). 
% 150404 Add 'if' block for numeric s.PixelData (BVfile). 
% 160114 cast s.PixelData.Bytes to double (thx DavidR). 
% 160127 support big endian files. 
% 160521 support dicom with BitsStored~=HighBit+1 (thx RayL).
% 171201 Bug fix for compressed dicom without offset table (thx DianaG).
% 200911 Fix error for compressed, unsigned data (thx ZWei).

persistent dict mem cleanObj;
if isstruct(s) && ~all(isfield(s, {'Rows' 'Columns' 'PixelData'})), s = s.Filename; end
if ischar(s) % input is file name
    if isempty(dict)
        dict = dicm_dict('', {'SamplesPerPixel' 'PlanarConfiguration' 'Rows' 'Columns' ...
            'BitsAllocated' 'BitsStored' 'HighBit' 'PixelRepresentation'});
    end
    [s, err] = dicm_hdr(s, dict); 
    if isempty(s), error(err); end
end

if isnumeric(s.PixelData) % data already in hdr
    img = s.PixelData;
    return;
end

if nargin<2 || isempty(xpose), xpose = true; end % same as dicomread by default

fid = fopen(s.Filename);
if fid<0
    if exist([s.Filename '.gz'], 'file')
        gunzip([s.Filename '.gz']);
        fid = fopen(s.Filename);
    end
    if fid<0, error(['File not exists: ' s.Filename]); end
end
closeFile = onCleanup(@() fclose(fid));
fseek(fid, s.PixelData.Start, -1);

if isfield(s, 'TransferSyntaxUID'), tsUID = s.TransferSyntaxUID;
else, tsUID = '1.2.840.10008.1.2.1'; % files other than dicom
end

if any(strcmp(tsUID, {'1.2.840.10008.1.2.1' '1.2.840.10008.1.2.2' '1.2.840.10008.1.2'}))
    if isfield(s, 'SamplesPerPixel'), spp = double(s.SamplesPerPixel);
    else, spp = 1;
    end
    
    if isfield(s.PixelData, 'Format') % all expl dicm
        fmt = s.PixelData.Format;
        if isfield(s, 'BitsAllocated')
            bpp = double(s.BitsAllocated);
            if bpp==8 && strcmp(fmt, 'uint16'), fmt = 'uint8'; % ugly fix
            elseif bpp==16 && strcmp(fmt, 'uint8'), fmt = 'uint16'; % by CorradoC
            end
        elseif regexp(fmt, 'single$'), bpp = 32;
        elseif regexp(fmt, 'double$'), bpp = 64;
        else, bpp = str2double(regexp(fmt, '(?<=int)\d+', 'match', 'once'));
        end
        if fmt(1) ~= '*', fmt = ['*' fmt]; end
    elseif isfield(s, 'BitsAllocated')
        bpp = double(s.BitsAllocated);
        fmt = sprintf('*uint%g', bpp);
    else
        error('Unknown data type for %s', s.Filename);
    end
    
    n = double(s.PixelData.Bytes) / (bpp/8);
    img = fread(fid, n, fmt);
    
    if all(isfield(s, {'BitsStored' 'HighBit' 'BitsAllocated'})) && ...
            (s.BitsStored ~= s.HighBit+1) && (s.BitsStored ~= s.BitsAllocated)
        img = bitshift(img, s.BitsStored-s.HighBit-1);
    end
    
    dim = double([s.Columns s.Rows]);
    nFrame = n / (spp * dim(1) * dim(2));
    if ~isfield(s, 'PlanarConfiguration') || s.PlanarConfiguration==0
        img = reshape(img, [spp dim nFrame]);
        img = permute(img, [2 3 1 4]);
    else
        img = reshape(img, [dim spp nFrame]);
    end
    if xpose, img = permute(img, [2 1 3 4]); end
    if strcmp(tsUID, '1.2.840.10008.1.2.2'), img = swapbytes(img); end % BE
else % compressed dicom: rely on imread for decompression
    b = fread(fid, inf, '*uint8'); % read all as bytes
    del = uint8([254 255 0 224]); % delimeter in LE
    if ~isequal(b(1:4)', del), error('%s is not compressed dicom', s.Filename); end
    nEnd = numel(b)-8; % 8 for terminator 0xFFFE E0DD and its zero length
    len = typecast(b(5:8), 'uint32'); % length of offset table
    if len>0
        nFrame = len / 4;
    else % no offset table: search delimiters to estimate nFrame
        nFrame = numel(strfind(b(9:end)', del)); % may count false delimeters
    end
    i = 8 + double(len); % 8 for leading delimeter and len, skip offset table
    for j = 1:nFrame
        if i>=nEnd || ~isequal(b(i+(1:4))', del) % seen terminator + padding
            img(:,:,:,j:end) = []; % truncate if less than nFrame
            break;
        end
        i = i + 4; % skip delimeter (FFFE E000)
        n = double(typecast(b(i+(1:4)), 'uint32')); i = i+4;
        if isempty(mem) || numel(mem.Data)<n
            if isempty(cleanObj) % 1st time function call
                mem.Filename = tempname;
                cleanObj = onCleanup(@() cleanup(mem.Filename));
            end
            fid = fopen(mem.Filename, 'a'); % allow to append after mapped
            n1 = max(n*4, nEnd/nFrame*32); % arbituary large
            fwrite(fid, zeros(2^nextpow2(n1), 1, 'uint8'));
            fclose(fid); 
            mem = memmapfile(mem.Filename, 'Writable', true);
        end
        mem.Data(1:n) = b(i+(1:n)); i = i+n;
        if j == 1
            img = imread(mem.Filename); % init dim and data type
            img(:,:,:,2:nFrame) = 0; % pre-allocate
        else
            img(:,:,:,j) = imread(mem.Filename);
        end
    end
    if ~xpose, img = permute(img, [2 1 3 4]); end
end
    
if isfield(s, 'PixelRepresentation') && s.PixelRepresentation>0
    cls = regexprep(class(img), '^u', '');
    img = reshape(typecast(img(:), cls), size(img)); % signed
end

    function cleanup(fname)
        try clear mem; end %#ok<*TRYNC> otherwise can't delete fname
        try delete(fname); end
    end
end

% Compressed dicom format:
%  FFFE E000 % start with delimeter
%  XXXX XXXX % length of offset table, often 0
%  Offset table in uint32 if not 0-length
%   FFFE E000 % each frame start with delimeter
%   XXXX XXXX % length of this compressed frame
%   data % len-bytes for this frame (imread reads it)
%   Repeat [delimeter, len, data] if +1 frames
%  FFFE E0DD 0000 0000 % end with terminator and 0
%  FFFC FFFC % may have DataSetTrailingPadding
