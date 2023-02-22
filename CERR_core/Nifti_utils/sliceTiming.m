
%% subfunction: set slice timing related info
function [h, hdr] = sliceTiming(h, hdr)
s = h{1};
TR = tryGetField(s, 'RepetitionTime'); % in ms
if isempty(TR), TR = tryGetField(s, 'TemporalResolution'); end
if isempty(TR), return; end
hdr.pixdim(5) = TR / 1000;
hdr.xyzt_units = 8; % seconds
if hdr.dim(5)<3 || tryGetField(s, 'isDTI', 0) || ...
        strncmp(tryGetField(s, 'MRAcquisitionType'), '3D', 2)
    return; % skip 3D, DTI, fieldmap, short EPI etc
end

nSL = hdr.dim(4);
delay = asc_header(s, 'lDelayTimeInTR', 0)/1000; % in ms now
if delay ~= 0, h{1}.DelayTimeInTR = delay; end
TA = TR - delay;

% Siemens mosaic
t = csa_header(s, 'MosaicRefAcqTimes'); % in ms
if ~isempty(t) && isfield(s, 'LastFile') && max(t)-min(t)>TA % MB wrong vol 1
    try t = mb_slicetiming(s, TA); end %#ok<*TRYNC>
end

if isempty(t) && strncmpi(s.Manufacturer, 'UIH', 3)
    t = zeros(nSL, 1);
    if isfield(s, 'MRVFrameSequence') % mosaic
        for j = 1:nSL
            item = sprintf('Item_%g', j);
            str = s.MRVFrameSequence.(item).AcquisitionDateTime;
            t(j) = datenum(str, 'yyyymmddHHMMSS.fff');
        end
    else
        dict = dicm_dict('', 'AcquisitionDateTime');
        for j = 1:nSL
            s1 = dicm_hdr(h{j}.Filename, dict);
            t(j) = datenum(s1.AcquisitionDateTime, 'yyyymmddHHMMSS.fff');
        end
    end
    t = (t - min(t)) * 24 * 3600 * 1000; % day to ms
end

if isempty(t) && any(isfield(s, {'TriggerTime' 'RTIA_timer'})) % GE
    ind = numel(h) + (1-nSL:0); % seen problem for 1st vol, so use last vol
    t = cellfun(@(c)tryGetField(c, 'TriggerTime', 0), h(ind));
    if all(diff(t)==0), t = cellfun(@(c)tryGetField(c, 'RTIA_timer', 0), h(ind)); end
    if all(diff(t)==0), t = []; 
    else
        t = t - min(t);
        ma = max(t) / TA;
        if ma>1, t = t / 10; % was ms*10, old dicom
        elseif ma<1e-3, t = t * 1000; % was sec, new dicom?
        end
    end
end

if isempty(t) && isfield(s, 'ProtocolDataBlock') && ...
        isfield(s.ProtocolDataBlock, 'SLICEORDER') % GE with invalid RTIA_timer
    SliceOrder = s.ProtocolDataBlock.SLICEORDER;
    t = (0:nSL-1)' * TA/nSL;
    if strcmp(SliceOrder, '1') % 0/1: sequential/interleaved based on limited data
        t([1:2:nSL 2:2:nSL]) = t;
    elseif ~strcmp(SliceOrder, '0')
        errorLog(['Unknown SLICEORDER (' SliceOrder ') for ' s.Filename]);
        return;
    end
end

% Siemens multiframe: read TimeAfterStart from last file
if isempty(t) && tryGetField(s, 'NumberOfFrames', 1)>1 &&  ...
        ~isempty(csa_header(s, 'TimeAfterStart'))
    % Use TimeAfterStart, not FrameAcquisitionDatetime. See
    % https://github.com/rordenlab/dcm2niix/issues/240#issuecomment-433036901
    % s2 = struct('FrameAcquisitionDatetime', {cell(nSL,1)});
    % s2 = dicm_hdr(h{end}, s2, 1:nSL); % avoid 1st volume
    % t = datenum(s2.FrameAcquisitionDatetime, 'yyyymmddHHMMSS.fff');
    % t = (t - min(t)) * 24 * 3600 * 1000; % day to ms
    s2 = struct('TimeAfterStart', nan(1, nSL));
    s2 = dicm_hdr(h{end}, s2, 1:nSL); % avoid 1st volume
    t = s2.TimeAfterStart; % in secs
    t = (t - min(t)) * 1000;
end

% Get slice timing for non-mosaic Siemens file. Could remove Manufacturer
% check, but GE/Philips AcquisitionTime seems useless
if isempty(t) && ~tryGetField(s, 'isMos', 0) && strncmpi(s.Manufacturer, 'SIEMENS', 7)
    dict = dicm_dict('', {'AcquisitionDateTime' 'AcquisitionDate' 'AcquisitionTime'});
    t = zeros(nSL, 1);
    for j = 1:nSL
        s1 = dicm_hdr(h{j}.Filename, dict);
        try str = s1.AcquisitionDateTime;
        catch
            try str = [s1.AcquisitionDate s1.AcquisitionTime];
            catch, t = []; break;
            end
        end
        t(j) = datenum(str, 'yyyymmddHHMMSS.fff');
    end
    t = (t - min(t)) * 24 * 3600 * 1000; % day to ms
end

if isempty(t) % non-mosaic Siemens: create 't' based on ucMode
    ucMode = asc_header(s, 'sSliceArray.ucMode'); % 1/2/4: Asc/Desc/Inter
    if isempty(ucMode), return; end
    t = (0:nSL-1)' * TA/nSL;
    if ucMode==2
        t = t(nSL:-1:1);
    elseif ucMode==4
        if mod(nSL,2), t([1:2:nSL 2:2:nSL]) = t;
        else, t([2:2:nSL 1:2:nSL]) = t;
        end
    end
    if asc_header(s, 'sSliceArray.ucImageNumb'), t = t(nSL:-1:1); end % rev-num
end

if numel(t)<2, return; end
t = t - min(t); % it may be relative to 1st slice

t1 = sort(t);
if t1(1)==t1(2) || (t1(end)>TA), sc = 0; % no useful info, or bad timing MB
elseif t1(1) == t1(2), sc = 0; t1 = unique(t1); % was 7 for MB but error in FS
elseif isequal(t, t1), sc = 1; % ascending
elseif isequal(t, flip(t1)), sc = 2; % descending
elseif t(1)<t(3) % ascending interleaved
    if t(1)<t(2), sc = 3; % odd slices first
    else, sc = 5; % Siemens even number of slices
    end
elseif t(1)>t(3) % descending interleaved
    if t(1)>t(2), sc = 4;
    else, sc = 6; % Siemens even number of slices
    end
else, sc = 0; % unlikely to reach
end

h{1}.SliceTiming = 0.5 - t/TR; % as for FSL custom timing
hdr.slice_code = sc;
hdr.slice_end = nSL-1; % 0-based, slice_start default to 0
hdr.slice_duration = min(diff(t1))/1000;
