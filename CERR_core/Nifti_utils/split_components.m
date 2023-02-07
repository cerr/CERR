%% subfunction: split nii components into multiple nii
function nii = split_components(nii, s)
fld = 'ComplexImageComponent';
if ~strcmp(tryGetField(s, fld, ''), 'MIXED'), return; end

if ~isfield(s, 'Volumes') % PAR file and single-frame file have this
    nSL = nii.hdr.dim(4); nVol = nii.hdr.dim(5);
    iFrames = 1:nSL:nSL*nVol;
    if isfield(s, 'SortFrames'), iFrames = s.SortFrames(iFrames); end
    s1 = struct(fld, {cell(1, nVol)}, 'MRScaleSlope', nan(1,nVol), ...
            'RescaleSlope', nan(1,nVol), 'RescaleIntercept', nan(1,nVol));
    s.Volumes = dicm_hdr(s, s1, iFrames);
end
if ~isfield(s, 'Volumes'), return; end

% suppose scl not applied in set_nii_hdr, since MRScaleSlope is not integer
flds = {'EchoTimes' 'CardiacTriggerDelayTimes'}; % to split
s1 = s.Volumes;
nii0 = nii;
% [c, ia] = unique(s.Volumes.(fld), 'stable'); % since 2013a?
[~, ia] = unique(s1.(fld));
ia = sort(ia);
c = s1.(fld)(ia);
for i = 1:numel(c)
    nii(i) = nii0;
    ind = strcmp(c{i}, s1.(fld));
    nii(i).img = nii0.img(:,:,:,ind);
    slope = s1.RescaleSlope(ia(i)); if isnan(slope), slope = 1; end 
    inter = s1.RescaleIntercept(ia(i)); if isnan(inter), inter = 0; end
    if ~isnan(s1.MRScaleSlope(ia(i)))
        inter = inter / (slope * s1.MRScaleSlope(ia(i)));
        slope = 1 / s1.MRScaleSlope(ia(i));
    end
    nii(i).hdr.scl_inter = inter;
    nii(i).hdr.scl_slope = slope;
    nii(i).hdr.file_name = [s.NiftiName '_' lower(c{i})];
    nii(i) = nii_tool('update', nii(i));
    
    for j = 1:numel(flds)
        if ~isfield(nii(i).json, flds{j}), continue; end
        nii(i).json.(flds{j}) = nii(i).json.(flds{j})(ind);
    end
end
