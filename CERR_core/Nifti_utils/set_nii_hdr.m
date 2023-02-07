
%% Subfunction: Set most nii header and re-orient img
function [nii, h] = set_nii_hdr(nii, h, pf, bids)
dim = nii.hdr.dim(2:4); nVol = nii.hdr.dim(5);
% fld = 'NumberOfTemporalPositions';
% if ~isfield(h{1}, fld) && nVol>1, h{1}.(fld) = nVol; end

% Transformation matrix: most important feature for nii
[ixyz, R, pixdim, xyz_unit] = xform_mat(h{1}, dim); % R: dicom xform matrix
R(1:2,:) = -R(1:2,:); % dicom LPS to nifti RAS, xform matrix before reorient

% Compute bval & bvec in image reference for DTI series before reorienting
if h{1}.isDTI, [h, nii] = get_dti_para(h, nii); end

% Store CardiacTriggerDelayTime
fld = 'CardiacTriggerDelayTime';
if ~isfield(h{1}, 'CardiacTriggerDelayTimes') && nVol>1 && isfield(h{1}, fld)
    if numel(h) == 1 % multi frames
        iFrames = 1:dim(3):dim(3)*nVol;
        if isfield(h{1}, 'SortFrames'), iFrames = h{1}.SortFrames(iFrames); end
        s2 = struct(fld, nan(1,nVol));
        s2 = dicm_hdr(h{1}, s2, iFrames);
        tt = s2.(fld);
    else
        tt = zeros(1, nVol);
        inc = numel(h) / nVol;
        for j = 1:nVol
            tt(j) = tryGetField(h{(j-1)*inc+1}, fld, 0);
        end
    end
    if ~all(diff(tt)==0), h{1}.CardiacTriggerDelayTimes = tt; end
end

% Get EchoTime for each vol for 4D multi frames
if ~isfield(h{1}, 'EchoTimes') && nVol>1 && isfield(h{1}, 'EchoTime') && numel(h)<2
    iFrames = 1:dim(3):dim(3)*nVol;
    if isfield(h{1}, 'SortFrames'), iFrames = h{1}.SortFrames(iFrames); end
    s2 = struct('EffectiveEchoTime', nan(1,nVol));
    s2 = dicm_hdr(h{1}, s2, iFrames);
    ETs = s2.EffectiveEchoTime;
    if ~all(diff(ETs)==0), h{1}.EchoTimes = ETs; end
end

% set TR and slice timing related info before re-orient
[h, nii.hdr] = sliceTiming(h, nii.hdr);
nii.hdr.xyzt_units = xyz_unit + nii.hdr.xyzt_units; % normally: mm (2) + sec (8)
s = h{1};

% set TaskName if present in filename (using bids labels convention)
if bids % parse filename: _task-label
    task = regexp(s.NiftiName, '(?<=_task-).*?(?=_)', 'match', 'once'); 
    if ~isempty(task), s.TaskName = task; end
end

% Store motion parameters for MoCo series
if ~isempty(csa_header(s, 'RBMoCoRot')) && nVol>1
    inc = numel(h) / nVol;
    s.RBMoCoTrans = zeros(nVol, 3);
    s.RBMoCoRot   = zeros(nVol, 3);
    for j = 1:nVol
        s.RBMoCoTrans(j,:) = csa_header(h{(j-1)*inc+1}, 'RBMoCoTrans');
        s.RBMoCoRot(j,:)   = csa_header(h{(j-1)*inc+1}, 'RBMoCoRot');
    end
end

% Store FrameReferenceTime: seen in Philips PET
if isfield(s, 'FrameReferenceTime') && nVol>1
    inc = numel(h) / nVol;
    vTime = zeros(1, nVol);
    dict = dicm_dict('', 'FrameReferenceTime');
    for j = 1:nVol
        s2 = dicm_hdr(h{(j-1)*inc+1}.Filename, dict);
        vTime(j) = tryGetField(s2, 'FrameReferenceTime', 0);
    end
    if vTime(1) > vTime(end) % could also re-read sorted h{i}{1}
        vTime = flip(vTime);
        nii.img = flip(nii.img, 4);
    end
    s.VolumeTiming = vTime / 1000; % ms to seconds
end

% dim_info byte: freq_dim, phase_dim, slice_dim low to high, each 2 bits
[phPos, iPhase] = phaseDirection(s); % phPos relative to image in FSL feat!
if     iPhase == 2, fps_bits = [1 4 16];
elseif iPhase == 1, fps_bits = [4 1 16]; 
else,               fps_bits = [0 0 16];
end

% Reorient if MRAcquisitionType==3D && nSL>1
% If FSL etc can read dim_info for STC, we can always reorient.
[~, perm] = sort(ixyz); % may permute 3 dimensions in this order
if strcmp(tryGetField(s, 'MRAcquisitionType', ''), '3D') && ...
        dim(3)>1 && (~isequal(perm, 1:3)) % skip if already XYZ order
    R(:, 1:3) = R(:, perm); % xform matrix after perm
    fps_bits = fps_bits(perm);
    ixyz = ixyz(perm); % 1:3 after perm
    dim = dim(perm);
    pixdim = pixdim(perm);
    nii.hdr.dim(2:4) = dim;
    nii.img = permute(nii.img, [perm 4:8]);
    if isfield(s, 'bvec'), s.bvec = s.bvec(:, perm); end
end
iSL = find(fps_bits==16);
iPhase = find(fps_bits==4); % axis index for phase_dim in re-oriented img

nii.hdr.dim_info = (1:3) * fps_bits'; % useful for EPI only
nii.hdr.pixdim(2:4) = pixdim; % voxel zize

flp = R(ixyz+[0 3 6])<0; % flip an axis if true
d = det(R(:,1:3)) * prod(1-flp*2); % det after all 3 axis positive
if (d>0 && pf.lefthand) || (d<0 && ~pf.lefthand)
    flp(1) = ~flp(1); % left or right storage
end
rotM = diag([1-flp*2 1]); % 1 or -1 on diagnal
rotM(1:3, 4) = (dim-1) .* flp; % 0 or dim-1
R = R / rotM; % xform matrix after flip
for k = 1:3, if flp(k), nii.img = flip(nii.img, k); end; end
if flp(iPhase), phPos = ~phPos; end
if isfield(s, 'bvec'), s.bvec(:, flp) = -s.bvec(:, flp); end
if flp(iSL) && isfield(s, 'SliceTiming') % slices flipped
    s.SliceTiming = flip(s.SliceTiming);
    sc = nii.hdr.slice_code;
    if sc>0, nii.hdr.slice_code = sc+mod(sc,2)*2-1; end % 1<->2, 3<->4, 5<->6
end

% sform
frmCode = all(isfield(s, {'ImageOrientationPatient' 'ImagePositionPatient'}));
frmCode = tryGetField(s, 'TemplateSpace', frmCode);
nii.hdr.sform_code = frmCode; % 1: SCANNER_ANAT
nii.hdr.srow_x = R(1,:);
nii.hdr.srow_y = R(2,:);
nii.hdr.srow_z = R(3,:);

R0 = normc(R(:, 1:3));
sNorm = null(R0(:, setdiff(1:3, iSL))');
if sign(sNorm(ixyz(iSL))) ~= sign(R(ixyz(iSL),iSL)), sNorm = -sNorm; end
shear = norm(R0(:,iSL)-sNorm) > 0.01;
R0(:,iSL) = sNorm;

% qform
nii.hdr.qform_code = frmCode;
nii.hdr.qoffset_x = R(1,4);
nii.hdr.qoffset_y = R(2,4);
nii.hdr.qoffset_z = R(3,4);
[q, nii.hdr.pixdim(1)] = dcm2quat(R0); % 3x3 dir cos matrix to quaternion
nii.hdr.quatern_b = q(2);
nii.hdr.quatern_c = q(3);
nii.hdr.quatern_d = q(4);

if shear
    nii.hdr.hdrTilt = nii.hdr; % copy all hdr for tilt version
    nii.hdr.qform_code = 0; % disable qform
    gantry = tryGetField(s, 'GantryDetectorTilt', 0);
    nii.hdr.hdrTilt.pixdim(iSL+1) = norm(R(1:3, iSL)) * cosd(gantry);
    R(1:3, iSL) = sNorm * nii.hdr.hdrTilt.pixdim(iSL+1);
    nii.hdr.hdrTilt.srow_x = R(1,:);
    nii.hdr.hdrTilt.srow_y = R(2,:);
    nii.hdr.hdrTilt.srow_z = R(3,:);
end

% store some possibly useful info in descrip and other text fields
str = tryGetField(s, 'ImageComments', '');
if isType(s, '\MOCO\'), str = ''; end % useless for MoCo
foo = tryGetField(s, 'StudyComments');
if ~isempty(foo), str = [str ';' foo]; end
str = [str ';' sscanf(s.Manufacturer, '%s', 1)];
foo = tryGetField(s, 'ProtocolName');
if ~isempty(foo), str = [str ';' foo]; end
nii.hdr.aux_file = str; % char[24], info only
seq = asc_header(s, 'tSequenceFileName'); % like '%SiemensSeq%\ep2d_bold'
if isempty(seq)
    seq = tryGetField(s, 'ScanningSequence'); 
else % also add Siemens extra for json
    ind = strfind(seq, '\');
    if ~isempty(ind), seq = seq(ind(end)+1:end); end % like 'ep2d_bold'
    if ~isfield(s, 'ParallelReductionFactorInPlane')
        s.ParallelReductionFactorInPlane = asc_header(s, 'sPat.lAccelFactPE');
    end
    if ~isfield(s, 'ParallelAcquisitionTechnique')
        modes = {'none' 'GRAPPA' 'mSENSE' '' '' 'SliceAccel' '' ''};
        patMode = logical(bitget(asc_header(s, 'sPat.ucPATMode'), 1:8)); % guess
        s.ParallelAcquisitionTechnique = strjoin(modes(patMode), ';');
    end
end
if pf.save_patientName, nii.hdr.db_name = PatientName(s); end % char[18]
nii.hdr.intent_name = seq; % char[16], meaning of the data

foo = tryGetField(s, 'AcquisitionDateTime');
descrip = sprintf('time=%s;', foo(1:min(18,end))); 
if strncmpi(tryGetField(s, 'SequenceName', ''), '*fm2d2r', 3) % Siemens fieldmap
    TE0 = asc_header(s, 'alTE[0]')/1000; % s.EchoTime stores only 1 TE
    TE1 = asc_header(s, 'alTE[1]')/1000;
    dTE = abs(TE1 - TE0); % TE difference
    if ~isempty(dTE)
        descrip = sprintf('dTE=%.4g;%s', dTE, descrip);
        s.deltaTE = dTE;
    end
    if isType(s, '\P\')
        s.EchoTime = TE0; % overwrite EchoTime for json etc.
        s.SecondEchoTime = TE1;
    end
end
TE0 = tryGetField(s, 'EchoTime');
if ~isempty(TE0), descrip = sprintf('TE=%.4g;%s', TE0, descrip); end

% Get dwell time
if ~strcmp(tryGetField(s, 'MRAcquisitionType'), '3D') && ~isempty(iPhase)
    dwell = double(tryGetField(s, 'EffectiveEchoSpacing')) / 1000; % GE
    % http://www.spinozacentre.nl/wiki/index.php/NeuroWiki:Current_developments
    if isempty(dwell) % Philips
        wfs = tryGetField(s, 'WaterFatShift');
        epiFactor = tryGetField(s, 'EPIFactor');
        dwell = wfs ./ (434.215 * (double(epiFactor)+1)) * 1000;
    end
    if isempty(dwell) % Siemens
        hz = csa_header(s, 'BandwidthPerPixelPhaseEncode');
        dwell = 1000 ./ hz / dim(iPhase); % in ms
    end
    if isempty(dwell) % next is not accurate, so as last resort
        dur = csa_header(s, 'RealDwellTime') * 1e-6; % ns to ms
        dwell = dur * asc_header(s, 'sKSpace.lBaseResolution');
    end
    if isempty(dwell) && strncmpi(s.Manufacturer, 'UIH', 3)
        try dwell = s.AcquisitionDuration; % not confirmed yet
        catch
            try dwell = s.MRVFrameSequence.Item_1.AcquisitionDuration; end
        end
        if ~isempty(dwell), dwell = dwell / dim(iPhase); end
    end
    
    if ~isempty(dwell)
        s.EffectiveEPIEchoSpacing = dwell;
        % https://github.com/rordenlab/dcm2niix/issues/130
        readout = dwell * (dim(iPhase)- 1) / 1000; % since 170923
        s.ReadoutSeconds = readout;
        descrip = sprintf('readout=%.3g;dwell=%.3g;%s', readout, dwell, descrip);
    end
end

if ~isempty(iPhase)
    if isempty(phPos), pm = '?'; b67 = 0;
    elseif phPos,      pm = '';  b67 = 1;
    else,              pm = '-'; b67 = 2;
    end
    nii.hdr.dim_info = nii.hdr.dim_info + b67*64;
    axes = 'xyz'; % actually ijk
    phDir = [pm axes(iPhase)];
    s.UnwarpDirection = phDir;
    descrip = sprintf('phase=%s;%s', phDir, descrip);
end
nii.hdr.descrip = descrip; % char[80], drop from end if exceed

% slope and intercept: apply to img if no rounding error 
sclApplied = tryGetField(s, 'ApplyRescale', false);
if any(isfield(s, {'RescaleSlope' 'RescaleIntercept'})) && ~sclApplied
    slope = tryGetField(s, 'RescaleSlope', 1); 
    inter = tryGetField(s, 'RescaleIntercept', 0);
    if isfield(s, 'MRScaleSlope') % Philips: see PAR file for detail
        inter = inter / (slope * double(s.MRScaleSlope));
        slope = 1 / double(s.MRScaleSlope);
    end
    val = sort(double([max(nii.img(:)) min(nii.img(:))]) * slope + inter);
    dClass = class(nii.img);
    if isa(nii.img, 'float') || (mod(slope,1)==0 && mod(inter,1)==0 ... 
            && val(1)>=intmin(dClass) && val(2)<=intmax(dClass))
        nii.img = nii.img * slope + inter; % apply to img if no rounding
    else
        nii.hdr.scl_slope = slope;
        nii.hdr.scl_inter = inter;
    end
elseif sclApplied && isfield(s, 'MRScaleSlope')
    slope = tryGetField(s, 'RescaleSlope', 1) * s.MRScaleSlope; 
    nii.img = nii.img / slope;
end

if pf.scale_16bit && any(nii.hdr.datatype==[4 512]) % like dcm2niix
    if nii.hdr.datatype == 4 % int16
        scale = floor(32000 / double(max(abs(nii.img(:)))));
    else % datatype==512 % uint16
        scale = floor(64000 / double((max(nii.img(:)))));
    end
    nii.img = nii.img * scale;
    nii.hdr.scl_slope = nii.hdr.scl_slope / scale;
end
h{1} = s;

% Possible patient position: HFS/HFP/FFS/FFP / HFDR/HFDL/FFDR/FFDL
% Seems dicom takes care of this, and maybe nothing needs to do here.
% patientPos = tryGetField(s, 'PatientPosition', '');

flds = { % store for nii.ext and json
  'ConversionSoftware' 'SeriesNumber' 'SeriesDescription' 'ImageType' 'Modality' ...
  'AcquisitionDateTime' 'TaskName' 'bval' 'bvec' 'VolumeTiming' ...
  'ReadoutSeconds' 'DelayTimeInTR' 'SliceTiming' 'RepetitionTime' ...
  'ParallelReductionFactorInPlane' 'ParallelAcquisitionTechnique' ...
  'UnwarpDirection' 'EffectiveEPIEchoSpacing' 'EchoTime' 'deltaTE' 'EchoTimes' ...
  'SecondEchoTime' 'InversionTime' 'CardiacTriggerDelayTimes' ...
  'PatientName' 'PatientSex' 'PatientAge' 'PatientSize' 'PatientWeight' ...
  'PatientPosition' 'SliceThickness' 'FlipAngle' 'RBMoCoTrans' 'RBMoCoRot' ...
  'Manufacturer' 'SoftwareVersion' 'MRAcquisitionType' ...
  'InstitutionName' 'InstitutionAddress' 'DeviceSerialNumber' ...
  'ScanningSequence' 'SequenceVariant' 'ScanOptions' 'SequenceName' ...
  'TableHeight' 'DistanceSourceToPatient' 'DistanceSourceToDetector'};
if ~pf.save_patientName, flds(strcmp(flds, 'PatientName')) = []; end
if bids, flds(~cellfun('isempty', regexp(flds, 'Patient.*'))) = []; end
for i = 1:numel(flds)
    if ~isfield(s, flds{i}), continue; end
    nii.json.(flds{i}) = s.(flds{i});
end
