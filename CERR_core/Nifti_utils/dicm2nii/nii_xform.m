function varargout = nii_xform(src, target, rst, intrp, missVal)
% Transform a NIfTI into different resolution, or into a template space.
% 
%  NII_XFORM('source.nii', 'template.nii', 'result.nii')
%  NII_XFORM(nii, 'template.nii', 'result.nii')
%  NII_XFORM('source.nii', [1 1 1], 'result.nii')
%  nii = NII_XFORM('source.nii', 'template.nii');
%  NII_XFORM('source.nii', {'template.nii' 'source2template.mat'}, 'result.nii')
%  NII_XFORM('source.nii', {'template.nii' 'source2template_warp.nii.gz'}, 'result.nii')
%  NII_XFORM('source.nii', 'template.nii', 'result.nii', 'nearest', 0)
% 
% NII_XFORM transforms the source NIfTI, so it has the requested resolution or
% has the same dimension and resolution as the template NIfTI.
% 
% Input (first two mandatory):
%  1. source file (nii, hdr/img or gz versions) or nii struct to be transformed.
%  2. The second input determines how to transform the source:
%    (1) If it is numeric and length is 1 or 3, [2 2 2] for example, it will be
%         treated as requested resolution in millimeter. The result will be in
%         the same coordinate system as the source.
%    (2) If it is a nii file name, a nii struct, or nii hdr struct, it will be
%        used as the template. The result will have the same dimension and
%        resolution as the template. The source and the template must have at
%        least one common coordinate system, otherwise the transformation
%        doesn't make sense, and it will err out. With different coordinate
%        systems, a transformation to align the two dataset is needed, which is
%        the next case.
%    (3) If the input is a cell containing two file names, it will be
%        interpreted as a template nii file and a transformation. The
%        transformation can be a FSL-style .mat file with 4x4 transformation
%        matrix which aligns the source data to the template, in format of:
%          0.9983  -0.0432  -0.0385  -17.75  
%          0.0476   0.9914   0.1216  -14.84  
%          0.0329  -0.1232   0.9918  111.12  
%          0        0        0       1  
%        The transformation can also be a FSL-style warp nii file incorporating
%        both linear and no-linear transformation from the source to template.
%  3. result file name. If not provided or empty, nii struct will be returned.
%     This allows to use the returned nii in script without saving to a file.
%  4. interpolation method, default 'linear'. It can also be one of 'nearest',
%     'cubic' and 'spline'.
%  5. value for missing data, default NaN. This is the value assigned to the
%     location in template where no data is available in the source file.
% 
% Output (optional): nii struct.
%  NII_XFORM will return the struct if the output is requested or result file
%  name is not provided.
% 
% Please note that, once the transformation is applied to functional data, it is
% normally invalid to perform slice timing correction. Also the data type is
% changed to single unless the interpolation is 'nearest'.
% 
% See also NII_VIEWER, NII_TOOL, DICM2NII

% By Xiangrui Li (xiangrui.li@gmail.com)
% History(yymmdd):
% 151024 Write it.
% 160531 Remove narginchk so work for early matlab.
% 160907 allow src to be nii struct.
% 160923 allow target to be nii struct or hdr; Take care of logical src img.
% 161002 target can also be {tempFile warpFile}.
% 170119 resolution can be singular.
% 180219 treat formcode 3 and 4 the same.

if nargin<2 || nargin>5, help('nii_xform'); error('Wrong number of input.'); end
if nargin<3, rst = []; end
if nargin<4 || isempty(intrp), intrp = 'linear'; end
if nargin<5 || isempty(missVal), missVal = nan; else, missVal = missVal(1); end
intrp = lower(intrp);
quat2R = nii_viewer('func_handle', 'quat2R');
    
if isstruct(src), nii = src;
else, nii = nii_tool('load', src);
end

if isstruct(target) || ischar(target) || (iscell(target) && numel(target)==1)
    hdr = get_hdr(target);
elseif iscell(target)
    hdr = get_hdr(target{1});
    if hdr.sform_code>0, R0 = [hdr.srow_x; hdr.srow_y; hdr.srow_z; 0 0 0 1];
    elseif hdr.qform_code>0, R0 = quat2R(hdr);
    end

    [~, ~, ext] = fileparts(target{2});
    if strcmpi(ext, '.mat') % template and xform file names
        R = load(target{2}, '-ascii');
        if ~isequal(size(R), [4 4]), error('Invalid transformation file.'); end
    else % template and warp file names
        warp_img_fsl = nii_tool('img', target{2});
        if ~isequal(size(warp_img_fsl), [hdr.dim(2:4) 3])
            error('warp file and template file img size don''t match.');
        end
        R = eye(4);
    end
    
    if nii.hdr.sform_code>0
        R1 = [nii.hdr.srow_x; nii.hdr.srow_y; nii.hdr.srow_z; 0 0 0 1];
    elseif nii.hdr.qform_code>0
        R1 = quat2R(nii.hdr);
    end

    % I thought it is something like R = R0 \ R * R1; but it is way off. It
    % seems the transform info in src nii is irrevelant, but direction must be
    % used: Left/right-handed storage of both src and target img won't affect
    % FSL alignment R. Alignment R may not be diag-major, and can be negative
    % for major axes (e.g. cor/sag slices).

    % Following works for tested FSL .mat and warp.nii files: Any better way?
    % R0: target;   R1: source;  R: xform;  result is also R
    R = R0 / diag([hdr.pixdim(2:4) 1]) * R * diag([nii.hdr.pixdim(2:4) 1]);
    [~, i1] = max(abs(R1(1:3,1:3)));
    [~, i0] = max(abs(R(1:3,1:3)));
    flp = sign(R(i0+[0 4 8])) ~= sign(R1(i1+[0 4 8]));
    if any(flp)
        rotM = diag([1-flp*2 1]);
        rotM(1:3,4) = (nii.hdr.dim(2:4)-1) .* flp;
        R = R / rotM;
    end
elseif isnumeric(target) && any(numel(target)==[1 3]) % new resolution in mm
    if numel(target)==1, target = target * [1 1 1]; end
    hdr = nii.hdr;
    ratio = target(:)' ./ hdr.pixdim(2:4);
    hdr.pixdim(2:4) = target;
    hdr.dim(2:4) = round(hdr.dim(2:4) ./ ratio);
    if hdr.sform_code>0
        hdr.srow_x(1:3) = hdr.srow_x(1:3) .* ratio;
        hdr.srow_y(1:3) = hdr.srow_y(1:3) .* ratio;
        hdr.srow_z(1:3) = hdr.srow_z(1:3) .* ratio;
    end
else
    error('Invalid template or resolution input.');
end

if ~iscell(target) 
    s = hdr.sform_code;
    q = hdr.qform_code;
    sq = [nii.hdr.sform_code nii.hdr.qform_code];
    if s>0 && (any(s == sq) || (s>2 && (any(sq==3) || any(sq==4))))
        R0 = [hdr.srow_x; hdr.srow_y; hdr.srow_z; 0 0 0 1];
        frm = s;
    elseif any(q == sq) || (q>2 && (any(sq==3) || any(sq==4)))
        R0 = quat2R(hdr);
        frm = q;
    else
        switch q
            case 1
                targetqspace = 'Scanner space';
            case 2
                targetqspace = 'Coordinates aligned to another file''s, or to anatomical "truth". ';
            case 3
                targetqspace = 'Coordinates aligned to Talairach-Tournoux Atlas';
            case 4
                targetqspace = 'MNI 152 normalized coordinates.';
            otherwise
                targetqspace = 'Undefined coordinate system';
        end
        switch sq(2)
            case 1
                sourceqspace = 'Scanner space';
            case 2
                sourceqspace = 'Coordinates aligned to another file''s, or to anatomical "truth". ';
            case 3
                sourceqspace = 'Coordinates aligned to Talairach-Tournoux Atlas';
            case 4
                sourceqspace = 'MNI 152 normalized coordinates.';
            otherwise
                sourceqspace = 'Undefined coordinate system';
        end
        error('%s\ntarget file: %s\nsource file: %s','No matching transformation between source and template:',targetqspace,sourceqspace);
    end

    if sq(1) == frm || (sq(1)>2 && frm>2) || sq(2)<1
        R = [nii.hdr.srow_x; nii.hdr.srow_y; nii.hdr.srow_z; 0 0 0 1];
    else
        R = quat2R(nii.hdr);
    end
end

d = single(hdr.dim(2:4));
I = ones([4 d], 'single');
[I(1,:,:,:), I(2,:,:,:), I(3,:,:,:)] = ndgrid(0:d(1)-1, 0:d(2)-1, 0:d(3)-1);
I = reshape(I, 4, []);  % template ijk
if exist('warp_img_fsl', 'var')
    warp_img_fsl = reshape(warp_img_fsl, [], 3)';
    if det(R0(1:3,1:3))<0, warp_img_fsl(1,:) = -warp_img_fsl(1,:); end % correct?
    warp_img_fsl(4,:) = 0;
    I = R \ (R0 * I + warp_img_fsl) + 1; % ijk+1 (fraction) in source
else
    I = R \ (R0 * I) + 1; % ijk+1 (fraction) in source
end
I = reshape(I(1:3,:)', [d 3]);

V = nii.img; isbin = islogical(V);
d48 = size(V); % in case of RGB
d48(numel(d48)+1:4) = 1; d48(1:3) = [];
if isbin
    intrp = 'nearest'; missVal = false;
    nii.img = zeros([d d48], 'uint8');
elseif isinteger(V)
    nii.img = zeros([d d48], 'single');
else
    nii.img = zeros([d d48], class(V));
end
if ~isfloat(V), V = single(V); end
if strcmpi(intrp, 'nearest'), I = round(I); end % needed for edge voxels
if size(V,1)<2
    V = repmat(V,[3 1 1 1]); % replicate to help interp
    I(:,:,:,1) = I(:,:,:,1)+1; % use middle slice
    I(:,:,:,1) = I(:,:,:,1) + double(I(:,:,:,1)<1.5 | I(:,:,:,1)>2.5)*1e3; % needed for edge voxels
end
if size(V,2)<2, V = repmat(V,[1 3 1 1]); I(:,:,:,2) = I(:,:,:,2)+1; I(:,:,:,2) = I(:,:,:,2) + double(I(:,:,:,2)<1.5 | I(:,:,:,2)>2.5)*1e3; end
if size(V,3)<2, V = repmat(V,[1 1 3 1]); I(:,:,:,3) = I(:,:,:,3)+1; I(:,:,:,3) = I(:,:,:,3) + double(I(:,:,:,3)<1.5 | I(:,:,:,3)>2.5)*1e3; end

try
    F = griddedInterpolant(V(:,:,:,1), intrp, 'none'); % since 2014?
    for i = 1:prod(d48)
        F.Values = V(:,:,:,i);
        nii.img(:,:,:,i) = F(I(:,:,:,1), I(:,:,:,2), I(:,:,:,3));
    end
    if ~isnan(missVal), nii.img(isnan(nii.img)) = missVal; end
catch
    for i = 1:prod(d48)
        nii.img(:,:,:,i) = interp3(V(:,:,:,i), I(:,:,:,2), I(:,:,:,1), I(:,:,:,3), intrp, missVal);
    end
end
if isbin, nii.img = logical(nii.img); end
    
% copy xform info from template to rst nii
nii.hdr.pixdim(1:4) = hdr.pixdim(1:4);
flds = {'qform_code' 'sform_code' 'srow_x' 'srow_y' 'srow_z' ...
    'quatern_b' 'quatern_c' 'quatern_d' 'qoffset_x' 'qoffset_y' 'qoffset_z'};
for i = 1:numel(flds), nii.hdr.(flds{i}) = hdr.(flds{i}); end

if ~isempty(rst), nii_tool('save', nii, rst); end
if nargout || isempty(rst), varargout{1} = nii_tool('update', nii); end

%% 
function hdr = get_hdr(in)
if iscell(in), in = in{1}; end
if isstruct(in)
    if isfield(in, 'hdr') % nii input
        hdr = in.hdr;
    elseif isfield(in, 'sform_code') % hdr input
        hdr = in;
    else
        error('Invalid input: %s', inputname(1));
    end
else % template file name
    hdr = nii_tool('hdr', in);
end
