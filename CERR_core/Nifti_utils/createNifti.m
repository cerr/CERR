function createNifti(img,h,niiFolder,fnames,ext)
% function createNifti(img,h)
%
% APA, 2/1/2023 - based on dicm2nii (https://github.com/xiangruili/dicm2nii)

%% Check each file, store partial header in cell array hh
% first 2 fields are must. First 10 indexed in code
flds = {'Columns' 'Rows' 'BitsAllocated' 'SeriesInstanceUID' 'SeriesNumber' ...
    'ImageOrientationPatient' 'ImagePositionPatient' 'PixelSpacing' ...
    'SliceThickness' 'SpacingBetweenSlices' ... % these 10 indexed in code
    'PixelRepresentation' 'BitsStored' 'HighBit' 'SamplesPerPixel' ...
    'PlanarConfiguration' 'EchoTime' 'RescaleIntercept' 'RescaleSlope' ...
    'InstanceNumber' 'NumberOfFrames' 'B_value' 'DiffusionGradientDirection' ...
    'TriggerTime' 'RTIA_timer' 'RBMoCoTrans' 'RBMoCoRot' 'AcquisitionNumber' ...
    'CoilString' 'TemporalPositionIdentifier' ...
    'MRImageGradientOrientationNumber' 'MRImageLabelType' 'SliceNumberMR' 'PhaseNumber'};
%dict = dicm_dict('SIEMENS', flds); % dicm_hdr will update vendor if needed

%% sort headers into cell h by SeriesInstanceUID/SeriesNumber

pf.save_patientName = 0;
pf.save_json = 0;
pf.use_parfor = 0;
pf.use_seriesUID = 1;
pf.lefthand = 1;
pf.scale_16bit = 0;
pf.version = 1;
         
i = 1;
bids = 0;
no_save = 0;
rst3D = 0;
fmtStr = sprintf(' %%-%gs %%dx%%dx%%dx%%d\n', max(cellfun(@numel, fnames))+12);


nFile = numel(h{i});
h{i}{1}.NiftiName = fnames{i};
s = h{i}{1};
if nFile>1 && ~isfield(s, 'LastFile')
    h{i}{1}.LastFile = h{i}{nFile}; % store partial last header into 1st
end

% for j = 1:nFile
%     if j==1
%         img = dicm_img(s, 0); % initialize img with dicm data type
%         if ndims(img)>4 % err out, likely won't work for other series
%             error('Image with 5 or more dim not supported: %s', s.Filename);
%         end
%         applyRescale = tryGetField(s, 'ApplyRescale', false);
%         if applyRescale, img = single(img); end
%     else
%         if j==2, img(:,:,:,:,nFile) = 0; end % pre-allocate for speed
%         img(:,:,:,:,j) = dicm_img(h{i}{j}, 0);
%     end
%     if applyRescale
%         slope = tryGetField(h{i}{j}, 'RescaleSlope', 1);
%         inter = tryGetField(h{i}{j}, 'RescaleIntercept', 0);
%         img(:,:,:,:,j) = img(:,:,:,:,j) * slope + inter;
%     end
% end
% if strcmpi(tryGetField(s, 'DataRepresentation', ''), 'COMPLEX')
%     img = complex(img(:,:,:,1:2:end,:), img(:,:,:,2:2:end,:));
% end
% [~, ~, d3, d4, ~] = size(img);
% if strcmpi(tryGetField(s, 'SignalDomainColumns', ''), 'TIME') % no permute
% elseif d3<2 && d4<2, img = permute(img, [1 2 5 3 4]); % remove dim3,4
% elseif d4<2,         img = permute(img, [1:3 5 4]);   % remove dim4: Frames
% elseif d3<2,         img = permute(img, [1 2 4 5 3]); % remove dim3: RGB
% end
% 
% nSL = double(tryGetField(s, 'LocationsInAcquisition'));
% if tryGetField(s, 'SamplesPerPixel', 1) > 1 % color image
%     img = permute(img, [1 2 4:8 3]); % put RGB into dim8 for nii_tool
% elseif tryGetField(s, 'isMos', false) % mosaic
%     img = mos2vol(img, nSL, strncmpi(s.Manufacturer, 'UIH', 3));
% elseif ndims(img)==3 && ~isempty(nSL) % may need to reshape to 4D
%     if isfield(s, 'SortFrames'), img = img(:,:,s.SortFrames); end
%     dim = size(img);
%     dim(3:4) = [nSL dim(3)/nSL]; % verified integer earlier
%     img = reshape(img, dim);
% end

pf.intent_code = 0;
if ndims(img) == 5 % deformable vector field
    pf.intent_code = 1007;
end

if any(~isfield(s, flds(6:8))) || ~any(isfield(s, flds(9:10)))
    h{i}{1} = csa2pos(h{i}{1}, size(img,3));
end

if isa(img, 'uint16') && max(img(:))<32768, img = int16(img); end % lossless

converter = 'CERR_dcm2nii';
h{i}{1}.ConversionSoftware = converter;
setpref('nii_tool_para', 'intent_code', pf.intent_code);
nii = nii_tool('init', img); % create nii struct based on img
[nii, h{i}] = set_nii_hdr(nii, h{i}, pf, bids); % set most nii hdr

% Save bval and bvec files after bvec perm/sign adjusted in set_nii_hdr
fname = fullfile(niiFolder, fnames{i}); % name without ext
if s.isDTI && ~no_save, save_dti_para(h{i}{1}, fname); end

nii = split_components(nii, h{i}{1}); % split vol components
if no_save % only return the first nii
    nii(1).hdr.file_name = strcat(fnames{i}, '.nii');
    nii(1).hdr.magic = 'n+1';
    varargout{1} = nii_tool('update', nii(1));
    return;
end

for j = 1:numel(nii)
    nam = fnames{i};
    if numel(nii)>1, nam = nii(j).hdr.file_name; end
    fprintf(fmtStr, nam, nii(j).hdr.dim(2:5));
    nii(j).ext = set_nii_ext(nii(j).json); % NIfTI extension
    if pf.save_json, save_json(nii(j).json, fname); end
    nii_tool('save', nii(j), fullfile(niiFolder, strcat(nam, ext)), rst3D);
end

if isfield(nii(1).hdr, 'hdrTilt')
    nii = nii_xform(nii(1), nii.hdr.hdrTilt);
    fprintf(fmtStr, strcat(fnames{i}, '_Tilt'), nii.hdr.dim(2:5));
    nii_tool('save', nii, strcat(fname, '_Tilt', ext), rst3D); % save xformed nii
end
