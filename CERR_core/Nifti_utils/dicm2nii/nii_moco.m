function varargout = nii_moco(nii, out, ref)
% Perform motion correction to the input NIfTI data.
%
% Syntax:
%  p = NII_MOCO(filename_in); % return correction parameter only
%  NII_MOCO(filename_in, filename_out); % save corrected image file
%  [p, nii_out] = NII_MOCO(nii_in); % also return correct NIfTI without saving
%  [p, nii_out] = NII_MOCO(nii_in, fileName_out);
%  [...] = NII_MOCO(nii_in, fileName_out, ref);
%
% The mandatory first input is a NIfTI file name or a struct returned by
% nii_tool('load').
%
% If the second optional input, the result NIfTI file name, is provided, the
% corrected data will be saved into the file (overwrite if exists). A .mat file
% with the same name is also saved for the correction parameters (see first
% output argument below for meaning of the parameters). If no reference volume
% is provided (see 3rd input below), a NIfTI file, with name in format of
% fileName_out_ref.nii, will also be saved.
%
% The third optional input is the reference to align to. It can be:
%  omitted or empty: NII_MOCO will choose a good reference volume in the data;
%  a single number: volume index to align to;
%  nii struct or file name: its first volume will be used as reference.
% This argument is useful if one likes to align multiple runs to the same
% referece img. For example align all 3 runs to run1:
%  p = NII_MOCO('run1.nii', 'run1_moco.nii'); % return ref info for run1
%  NII_MOCO('run2.nii', 'run2_moco.nii', p.ref); % align run2 to ref vol of run1
%  NII_MOCO('run3.nii', 'run3_moco.nii', p.ref); % align run3
% Then run1_moco_ref.nii can be used to align to structural image.
%
% The first optional output, if requested, returns the parameters of motion. It
% is a struct with following fields:
%  ref: reference NIfTI name, or struct if no corrected img is saved.
%  R: rigid xform matrix to correct the motion to ref volume, 4 by 4 by nVol
%  mss: sum of squared diff between vol and ref img
%  trans: translation in mm, nVol by 3
%  rot: rotation in radian, nVol by 3
%  FD: frame-wise displacement in mm, nVol by 1
%
% The second optional output is nii struct after motion correction.
%
% See also NII_STC, NII_VIEWER, NII_TOOL

% Xiangrui Li (xiangrui.li@gmail.com)
% 161127 Wrote it by peeking into spm_realign.m.
% 170120 Use later ref vol: p.ref=p.ref+1

toSave = nargin>1 && ~isempty(out);
ischar = nii_tool('func_handle', 'ischar');
if toSave && ~ischar(out)
    error('Second input must be nii file name to save data.');
end
if ~toSave && nargout<1
    [out, pth] = uiputfile('*.nii;*.nii.gz', 'Input file name to save result');
    if ~ischar(out), varargout(1:nargout) = {}; return; end
    out = fullfile(pth, out);
    toSave = true;
end
if toSave && isempty(regexpi(out, '(.nii|.nii.gz)$')), out = [out '.nii']; end

if ischar(nii), nii = nii_tool('load', nii); end % file name
if ~isstruct(nii) || ~all(isfield(nii, {'hdr' 'img'}))
    error('Input must be nii struct or nii file name.');
end

d = nii.hdr.dim(2:7); d(d<1 | d>32768 | mod(d,1)) = 1;
nVol = prod(d(4:end));
if ~isfield(nii.hdr, 'file_name'), nii.hdr.file_name = ''; end
if nVol<2, error('Not multi-volume NIfTI: %s', nii.hdr.file_name); end
d = d(1:3);
Rm = nii_viewer('LocalFunc', 'nii_xform_mat', nii.hdr, 1); % moving img R

sz = nii.hdr.pixdim(2:4);
if all(abs(diff(sz)/sz(1))<0.05) && sz(1)>2 && sz(1)<4 % 6~12mm
    sz = 3; % iso-voxel, 2~4mm res, simple fast smooth
else
    sz = 9 ./ sz; % 9 mm seems good
end

% Deal with ref vol options
if nargin<3 || isempty(ref) % pick a good vol as ref: similar to next vol
    n = min(10, nVol);
    mss = double(nii.img(:,:,:,1:n));
    mss = diff(mss, 1, 4) .^ 2;
    mss = reshape(mss, [], n-1);
    mss = sum(mss);
    [~, p.ref] = min(mss);
    p.ref = p.ref + 1; % later one less affected by spin history?
    refV.hdr = nii.hdr; refV.img = nii.img(:,:,:,p.ref);
elseif isnumeric(ref) && numel(ref)==1 % ref vol index in moving nii
    refV.hdr = nii.hdr; refV.img = nii.img(:,:,:,ref);
    p.ref = ref;
else % ref NIfTI file or struct
    if isstruct(ref) && isfield(ref, 'ref'), ref = ref.ref; end % p input
    if ischar(ref) && exist(ref, 'file') % NIfTI file as ref
        refV = nii_tool('load', ref);
    elseif isstruct(ref) && isfield(ref, 'img') && isfield(ref, 'hdr')
        refV = ref;
    else
        error('Invalid reference input: %s', inputname(3));
    end
    p.ref = ref; % simply pass the ref input
end
R0 = nii_viewer('LocalFunc', 'nii_xform_mat', refV.hdr, 1);

% resample ref vol to isovoxel (often lower-res)
res = 4; % use 4 mm grid for alignment
d0 = size(refV.img); d0 = [d0 1]; d0 = d0(1:3); d0 = d0-1;
ind = find(d0<4, 1);
if ~isempty(ind), res = refV.hdr.pixdim(ind+1); end % untested
dd = res ./ refV.hdr.pixdim(2:4);
[i, j, k] = ndgrid(0:dd(1):d0(1)-0.5, 0:dd(2):d0(2)-0.5, 0:dd(3):d0(3)-0.5);
I = [i(:) j(:) k(:)]'; clear i j k;
a = rng('default'); I = I + rand(size(I))*0.5; rng(a); % used by spm
sz1 = sz .* nii.hdr.pixdim(2:4) ./ refV.hdr.pixdim(2:4);
V = smooth_mc(refV.img(:,:,:,1), sz1);
F = griddedInterpolant({0:d0(1), 0:d0(2), 0:d0(3)}, V, 'linear', 'none');
V0 = F(I(1,:), I(2,:), I(3,:)); % ref: 1 by nVox
I(4,:) = 1; % 0-based ijk: 4 by nVox
I = R0 * I; % xyz of ref voxels

% compute derivative to each motion parameter in ref vol
dG = zeros(6, numel(V0));
dd = 1e-6; % delta of motion parameter, value won't affect dG much
R0i = inv(R0); % speed up a little
for i = 1:6
    p6 = zeros(6,1); p6(i) = dd; % change only 1 of 6
    J = R0i * rigid_mat(p6) * I; %#ok<*MINV>
    dG(i,:) = F(J(1,:), J(2,:), J(3,:)) - V0; % diff now
end
dG = dG / dd; % derivative

% choose voxels with larger derivative for alignment: much faster
a = sum(dG.^2); % 6 derivatives has similar range
ind = a > std(a(~isnan(a)))/10; % arbituray threshold. Also exclude NaN
dG = dG(:, ind);
V0 = V0(ind);
I = I(:, ind);

F.GridVectors = {0:d(1)-1, 0:d(2)-1, 0:d(3)-1};
p.R = repmat(inv(Rm), [1 1 nVol]); % inv(R_rst)
for i = 1:nVol
%     R = p.R(:,:,i);
    if i>1, R = p.R(:,:,i-1); else, R = p.R(:,:,i); end % start w/ previous vol
    F.Values = smooth_mc(nii.img(:,:,:,i), sz); 
    mss0 = inf;
    for iter = 1:64
        J = R * I; % R_rst*J -> R0*ijk
        V = F(J(1,:), J(2,:), J(3,:));
        ind = ~isnan(V); % NaN means out of range
        V = V(ind);
        dV = V0(ind); % ref
        dV = dV - V * (sum(dV)/sum(V)); % diff now, sign affects p6 sign
        mss = dV*dV' / numel(dV); % mean(dV.^2)
        
%         % watch mss change over iterations
%         if iter==1
%             figure(33); pause(1*(i>1));
%             hPlot = plot(nan(1,64), 'o-', 'MarkerFaceColor', 'r');
%             title(['Volume ' num2str(i)]); set(gca, 'xtick', 1:64);
%             xlabel('Iterations'); ylabel('mss');
%         end
%         try hPlot.YData(iter) = mss; drawnow; end %#ok
    
        if mss > mss0, break; end % give up and use previous R        
        p.R(:,:,i) = R; % accecpt only if improving
        p.mss(i) = mss;
        if 1-mss/mss0 < 1e-6, break; end % little effect, stop

        a = dG(:, ind);
        p6 = (a * a') \ (a * dV'); % dG(:,ind)'\dV' estimate p6 from current R
        R = R * rigid_mat(p6); % inv(inv(rigid_mat(p6)) * inv(R_rst))
        mss0 = mss;
    end
    if iter==64
        warning('Max iterations reached: %s, vol %g', nii.hdr.file_name, i);
    end
end

doXform = toSave || nargout>1;
if doXform
    nii.img = single(nii.img); % single for result nii
    nii.hdr.sform_code = 2; % Aligned Anat
    nii.hdr.descrip = ['nii_moco.m: orig ' nii.hdr.file_name];
    
    F.Method = 'spline'; % much slower than linear
    F.ExtrapolationMethod = 'none';
    I = ones([4 d], 'single');
    [I(1,:,:,:), I(2,:,:,:), I(3,:,:,:)] = ndgrid(0:d(1)-1, 0:d(2)-1, 0:d(3)-1);
    I = reshape(I, 4, []); % ijk in 4 by nVox for original dim
    I = Rm * I; % xyz now
end

% Compute p.trans and p.rot, then p.FD, and xform nii if needed
p.trans = zeros(nVol,3); p.rot = zeros(nVol,3);
for i = 1:nVol
    if doXform % create xfrom 'ed nii
        J = p.R(:,:,i) * I; % R_rst \ (Rm * ijk)
        F.Values = nii.img(:,:,:,i);
        a = F(J(1,:), J(2,:), J(3,:));
        a(isnan(a)) = 0; % 'none' ExtrapolationMethod gives nan
        nii.img(:,:,:,i) = reshape(a, d(1:3));
    end
    R = Rm * p.R(:,:,i); % inv(R_rst / Rref)
    p.trans(i,:) = -R(1:3, 4);
    R = bsxfun(@rdivide, R, sqrt(sum(R.^2))); % to be safe
    p.rot(i,:) = -[atan2(R(2,3), R(3,3)) asin(R(1,3)) atan2(R(1,2), R(1,1))];
    p.R(:,:,i) = inv(p.R(:,:,i));
end
p.FD = diff([p.trans p.rot*50]); % 50 mm is radius of head
p.FD = [0; sum(abs(p.FD), 2)]; % Power et al method

% Update p.ref in case it is needed for other runs
if isnumeric(p.ref) % need to store p.ref
    refV.hdr.descrip = sprintf('Ref: vol %g of %s', p.ref, nii.hdr.file_name);
    if toSave
        [pth, nam, ext] = fileparts(out);
        if strcmpi(ext, '.gz'), [~, nam, e0] = fileparts(nam); ext = [e0 ext]; end
        p.ref = fullfile(pth, strcat(nam, '_ref', ext));
        nii_tool('save', refV, p.ref);
    else % store nii struct as ref in p: result large p
        refV.hdr.file_name = 'moco_ref'; % just avoid overwrite accident
        p.ref = nii_tool('update', refV); % override iRef for single vol nii
    end
end
if ischar(p.ref) % file name, make it full name in case of relative path
    [~, a] = fileattrib(p.ref);
    p.ref = a.Name;
end

if toSave % save corrected nii and p
    nii_tool('save', nii, out);
    [pth, nam, ext] = fileparts(out);
    if strcmpi(ext, '.gz'), [~, nam] = fileparts(nam); end
    nam = fullfile(pth, strcat(nam, '.mat'));
    save(nam, 'p'); % save a mat file with the same name as NIfTI
end

if nargout>0, varargout{1} = p; end
if nargout>1, varargout{2} = nii_tool('update', nii); end

%% Translation (mm) and rotation (deg) to 4x4 R. Order: ZYXT
function R = rigid_mat(p6)
ca = cosd(p6(4:6)); sa = sind(p6(4:6));
R = [1 0 0; 0 ca(1) sa(1); 0 -sa(1) ca(1)] * ...
    [ca(2) 0 sa(2); 0 1 0; -sa(2) 0 ca(2)] * ...
    [ca(3) sa(3) 0; -sa(3) ca(3) 0; 0 0 1]; % 3D rotation
R = [R p6(1:3); 0 0 0 1];

%% Simple gaussian smooth for motion correction, sz in unit of voxels
function out = smooth_mc(in, sz)
out = double(in);
if all(abs(diff(sz)/sz(1))<0.05) && abs(sz(1)-round(sz(1)))<0.05 ...
        && mod(round(sz(1)),2)==1
    out = smooth3(out, 'gaussian', round(sz)); % sz odd integer
    return; % save time for special case
end

d = size(in);
I = {1:d(1) 1:d(2) 1:d(3)};
n = sz/3;
if numel(n)==1, n = n*[1 1 1]; end
J = {1:n(1):d(1) 1:n(2):d(2) 1:n(3):d(3)};
intp = 'linear';
F = griddedInterpolant(I, out, intp);
out = smooth3(F(J), 'gaussian'); % sz=3
F = griddedInterpolant(J, out, intp);
out = F(I);
%%