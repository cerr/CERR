function varargout = nii_stc(nii, out, timing)
% Perform slice timing correction to the input NIfTI data.
% 
% Syntax:
%  nii_stc(filename_in, filename_out);
%  nii_out = NII_STC(filename_in);
%  nii_out = NII_STC(nii_in);
%  nii_out = NII_STC(nii_in, [], FSL_slice_timing);
% 
% The mandatory first input is a NIfTI file name or a struct returned by
% nii_tool('load').
% 
% If the second optional input, a NIfTI file name, is provided, the corrected
% data will be saved into the file (overwrite if exists).
% 
% The third optional input, slice timing, is needed only if there is no timing
% information in nii data. It should be in FSL custom timing style, one number
% per slice in unit of TR, with a positive number meaning to shift forwards in
% time. If this input is provided, it will override the parameters in nii
% header.
% 
% The optional output, if requested, returns the nii struct after corrected.
% 
% The dicm2nii converter stores slice timing information into nii hdr and ext.
% The numbers range from -0.5 to 0.5 in unit of TR. This means the reference
% slice is the slice acquired at the middle of TR. If nifti from dicm2nii is
% used, there is no need to provide slice order/timing information for NII_STC.
% 
% See also NII_VIEWER, NII_TOOL, DICM2NII

% Xiangrui Li (xiangrui.li@gmail.com)
% 160517 Wrote it

toSave = nargin>1 && ~isempty(out);
if toSave && ~ischar(out)
    error('Second input must be nii file name to save data.');
end
if ~toSave && nargout<1
    [out, pth] = uiputfile('*.nii;*.nii.gz', 'Input file name to save result');
    out = fullfile(pth, out);
    toSave = true;
end

if ischar(nii), nii = nii_tool('load', nii); end % file name
if ~isstruct(nii) || ~all(isfield(nii, {'hdr' 'img'}))
    error('Input must be nii struct or existing nii file name.');
end

nSL = nii.hdr.dim(4);
if nargin>2 % error check for timing
    if ~isnumeric(timing) || numel(timing)~=nSL || ~isvector(timing)
        help(mfilename);
        error('timing should have one number per slice.');
    elseif min(timing)<-1 || max(timing)>1 || max(timing)-min(timing)>1
        error('timing out of range: must be in unit of TR.');
    end
end

try
    t = nii.ext.edata_decoded.SliceTiming; % FSL style timing by dicm2nii.m
catch % get it fro hdr, but no valid code for multiband sequence
    TR = nii.hdr.pixdim(5);
    dur = nii.hdr.slice_duration;
    if dur<=0 || dur>TR/nSL, dur = TR / nSL; end % best guess
    t = 0.5 - (0:nSL-1)' * dur / TR;
    
    switch nii.hdr.slice_code
        case 1                                % ascending
        case 2,	t(nSL:-1:1) = t;              % descending
        case 3,	t([1:2:nSL 2:2:nSL]) = t;     % interleaved ascending, start 1
        case 4, t([nSL:-2:1 nSL-1:-2:1]) = t; % interleaved descending, start n
        case 5,	t([2:2:nSL 1:2:nSL]) = t;     % interleaved ascending, start 2
        case 6,	t([nSL-1:-2:1 nSL:-2:1]) = t; % interleaved descending, start n-1
        otherwise, t = [];
    end
end

if isempty(t)
    if nargin<3
        error('There is no slice order/timing info in nii header.');
    else
        t = timing;
    end
elseif nargin>2 && any(abs(diff(t(:)-timing(:)))>0.01) % timing provided
    warning(['Provided timing is inconsistent with header timing.' char(10 )...
        'The provided timing will be used for ' nii.hdr.file_name]);
    t = timing; % warn but use the provided timing
end

nVol = single(nii.hdr.dim(5));
nFFT = 2^ceil(log2(nVol+40)); % arbituary extra padding to reduce edge problem
F = (0:nFFT/2) / nFFT; % freq in unit of points: last is Nyquist
F = [F -F(end-1:-1:2)] * 2*pi; % symmetric around Nyquist, except 1st 0
F = permute(exp(F * 1i), [1 3 4 2]); % [1 1 1 nFFT]
ramp = single(permute(linspace(1, 0, nFFT-nVol), [1 3 4 2])); % [1 1 1 nRamp]
t = single(t);

nii.img = single(nii.img); % avoid integer type
for i = 1:nSL % slice by slice fft/ifft seems faster than all together
    y = nii.img(:,:,i,:); % [r c 1 nVol]
    pad = bsxfun(@times, y(:,:,1,nVol)-y(:,:,1,1), ramp); % [r c 1 nRamp]
    pad = bsxfun(@plus, pad, y(:,:,1,1)); % linear ramp from last to 1st point
    y = cat(4, y, pad); %  [r c 1 nFFT]
    y = fft(y, [], 4);
    y = bsxfun(@times, y, F.^t(i)); % shift phase
    y = real(ifft(y, [], 4));
    nii.img(:,:,i,:) = y(:,:,1,1:nVol); % update img while drop padding
end

if toSave, nii_tool('save', nii, out); end
if nargout, varargout{1} = nii_tool('update', nii); end
