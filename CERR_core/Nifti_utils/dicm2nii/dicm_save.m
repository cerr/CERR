function dicm_save(img, fname, s)
% DICM_SAVE(img, dicomFileName, info_struct);
% 
% Save img into dicom file, using tags stored in struct, as dicomwrite does.
% The img can have up to 4 dimensions, with 3rd typically RGB and 4th frames.
%
% Comparing to dicomwrite: Advantage 1: DICM_SAVE supports img with any Matlab
% numeric type, although dicom standard allows only 8 and 16-bit integer.
% Advantage 2: DICM_SAVE saves popular private tags for common MRI img from
% Siemens/GE/Philips. Limitation: DICM_SAVE uses only popular TransferSyntaxUID
% of '1.2.840.10008.1.2.1', which means Little Endian, Explicit VR, and no
% compression.
%
% See also DICM_DICT, DICM_HDR, DICM_IMG

% 200109 (yymmdd) Write it (xiangrui.li at gmail.com)

persistent dict;
if isempty(dict)
    try dict = dicm_dict(s.Manufacturer); catch, dict = dicm_dict(''); end
    try %#ok try to use Matlab full dictionary if avaiable
        C = fileread('dicom-dict.txt');
        C = regexp(C, '\n\(([0-9A-F]{4}),([0-9A-F]{4})\)\t(\w{2})\t(\w+)\t', 'tokens');
        C = reshape([C{:}], 4, [])';
        grp = hex2dec(C(:,1));
        elt = hex2dec(C(:,2));
        if isstruct(dict)
            dict.group = [dict.group; grp];
            dict.element = [dict.element; elt];
            dict.tag = [dict.tag; grp*2^16+elt];
            dict.vr = [dict.vr; C(:,3)];
            dict.name = [dict.name; C(:,4)];
            [dict.tag, i] = unique(dict.tag); % dicm_dict take precedence
            dict.group = dict.group(i); dict.element = dict.element(i);
            dict.vr = dict.vr(i); dict.name = dict.name(i);
        else
            dict = [dict; num2cell([grp elt grp*2^16+elt]) C(:,3:4)];
            [~, i] = unique(dict.tag); % dicm_dict take precedence
            dict = dict(i,:);
        end
    end
    i = strcmp(dict.name, 'PixelData') | ... % +1 PixelData tags, remove them
        strcmp(dict.name, 'SmallestImagePixelValue') | ... % uint16 not enough
        strcmp(dict.name, 'LargestImagePixelValue') | ...
        (dict.group~=2 & dict.element==0) | ... % remove GroupLength except grp 2
        dict.tag>2145386512; % after PixelData
    if isstruct(dict)
        dict.group(i) = []; dict.element(i) = []; dict.tag(i) = [];
        dict.vr(i) = []; dict.name(i) = [];
    else
        dict(i,:) = [];
    end
end

narginchk(2, 3);
if ~isnumeric(img), error('Provide img array as 1st input.'); end
if ~ischar(fname) && ~isstring(fname), error('Need a string as file name.'); end

fmt = class(img);
switch fmt
    case {'int8'  'uint8' }, vr = 'OB'; nBit = 8; 
    case {'int16' 'uint16'}, vr = 'OW'; nBit = 16;
    case {'int32' 'uint32'}, vr = 'OL'; nBit = 32;
    case {'int64' 'uint64'}, vr = 'OV'; nBit = 64;
    case 'single',           vr = 'OF'; nBit = 32;
    case 'double',           vr = 'OD'; nBit = 64;
    otherwise, error('Unknown image type: %s', fmt);
end

fid = fopen(fname, 'w', 'l');
if fid<0, error('Failed to open file %s', fname); end
closeFile = onCleanup(@()fclose(fid)); % auto close when done or error

% Update file and PixelData related meta
s.FileMetaInformationGroupLength = 210; % be updated later
s.FileMetaInformationVersion = [0 1]';
s.TransferSyntaxUID = '1.2.840.10008.1.2.1'; % add or overwrite
s.SOPInstanceUID = dicm_uid(s); % use new one even provided
s.MediaStorageSOPInstanceUID = s.SOPInstanceUID;
s.ImplementationClassUID = s.SOPInstanceUID(1:27); % pacsone needs 3 UID
% s.ImplementationVersionName = 'dicm_save.m 200130';
sz = size(img); sz(numel(sz)+1:4) = 1;
s.Rows = sz(1);
s.Columns = sz(2);
if sz(3)>1, s.SamplesPerPixel = sz(3); s.PlanarConfiguration = 1; end
if sz(4)>1, s.NumberOfFrames = sz(4); end
if strfind(fmt, 'int'), s.PixelRepresentation = fmt(1)~='u'; end %#ok
s.BitsAllocated = nBit;
s.BitsStored = nBit;
s.HighBit = nBit - 1;

% Write file
fwrite(fid, 0, 'int8', 127); % waste
fwrite(fid, 'DICM', 'char*1'); % signature at 128
for i = 1:numel(dict.tag) % write group 2 (maybe group 0?): always LE, expl VR
    if dict.group(i)>2, update_length(fid, i0); break; end % done for g2
    if ~isfield(s, dict.name{i}), continue; end
    write_tag(fid, s.(dict.name{i}), dict, i);
    if dict.tag(i)==131072, i0 = ftell(fid); end % (0002,0000) g2len
    s = rmfield(s, dict.name{i});
end
write_meta(fid, s, dict); % write meta without group 2-

% Write PixelData separately
fwrite(fid, [32736 16], 'uint16');
fwrite(fid, vr, 'char*1');
fwrite(fid, nBit/8*numel(img), 'uint32', 2); % maybe odd length?
fwrite(fid, permute(img, [2 1 3:numel(sz)]), fmt);

%% Write meta info in struct s
function write_meta(fid, s, dict)
flds = fieldnames(s);
N = numel(flds);
ind = zeros(N, 1);
for i = 1:N
    if regexp(flds{i}, '^(Private|Unknown)(_[0-9a-f]{4}){2}$', 'once')
        j = find(hex2dec(flds{i}([9:12 14:17])) == dict.tag, 1);
    else
        j = find(strcmp(flds{i}, dict.name));
        if numel(j) > 1 % multiple tag for the fld
            if isstruct(s.(flds{i})) % take vr=SQ if struct
                ii = strcmp(dict.vr(j), 'SQ');
                if any(ii), j = j(ii); end
            end
        end
    end
    if ~isempty(j), ind(i) = j(1); end % otherwise take early one
end
[ind, i] = sort(ind); % in the order of tags
flds = flds(i); % use flds since it may have Private|Unknown

for i = find(ind,1) : N
    write_tag(fid, s.(flds{i}), dict, ind(i));
end

%% Write i-th tag in dict
function write_tag(fid, val, dict, iTag)
vr = dict.vr{iTag};
fwrite(fid, [dict.group(iTag) dict.element(iTag)], 'uint16');
fwrite(fid, vr, 'char*1');
if strcmp(vr, 'SQ')
    fwrite(fid, 0, 'uint32', 2); % skip 2-byte, then SQ length
    iSQ = ftell(fid); % start of SQ length
    if isstruct(val) && isfield(val, 'Item_1'), val = struct2cell(val); end
    if ~iscell(val), val = {val}; end % not safe
    for i = 1:numel(val)
        if ~isstruct(val{i}), continue; end % skip
        fwrite(fid, [65534 57344 0 0], 'uint16'); % FFFE E000 (Item) & len
        i0 = ftell(fid); % start of Item length
        write_meta(fid, val{i}, dict); % recuisive call
        update_length(fid, i0);
        % fwrite(fid, [65534 57357 0 0], 'uint16'); % FFFE E00D, ItemDelimitationItem
    end
    % fwrite(fid, [65534 57565 0 0], 'uint16'); % FFFE E0DD, SequenceDelimitationItem
    update_length(fid, iSQ);
    return;
end

if isstruct(val) && strcmp(vr, 'PN'), val = strtrim(strjoin(struct2cell(val)));
elseif iscellstr(val), val = sprintf('%s\n', val{:}); %#ok
end
if any(strcmp(vr, {'DS' 'IS'}))
    fmt = 'char*1';
    if strcmp(vr, 'IS'), val = sprintf('%.0f\\', val);
    else, val = sprintf('%.16g\\', val);
    end
    val(end) = '';
    n = numel(val);
else
    [fmt, bpv] = vr2fmt(vr);
    n = numel(val) * bpv;
end

len16 = 'AE AS AT CS DA DS DT FD FL IS LO LT PN SH SL SS ST TM UI UL US';
if isempty(strfind(len16, vr)) %#ok<*STREMP>
    fmtLen = 'uint32';
    fwrite(fid, 0, 'uint16');
else
    fmtLen = 'uint16';
end
odd = mod(n, 2);
fwrite(fid, n+odd, fmtLen); % length is even
fwrite(fid, val, fmt);
if odd, fwrite(fid, 0, 'uint8'); end

%% Return format str and Bytes per value from VR
function [fmt, bpv] = vr2fmt(vr)
switch vr
    case {'AE' 'AS' 'CS' 'DA' 'DT' 'LO' 'LT' 'PN' 'SH' 'ST' 'TM' 'UI' 'UT'}
               bpv = 1; fmt = 'char*1';
    case 'US', bpv = 2; fmt = 'uint16';
    case 'OB', bpv = 1; fmt = 'uint8';
    case 'FD', bpv = 8; fmt = 'double';
    case 'SS', bpv = 2; fmt = 'int16';
    case 'UL', bpv = 4; fmt = 'uint32';
    case 'SL', bpv = 4; fmt = 'int32';
    case 'FL', bpv = 4; fmt = 'single';
    case 'AT', bpv = 2; fmt = 'uint16';
    case 'OW', bpv = 2; fmt = 'uint16';
    case 'OF', bpv = 4; fmt = 'single';
    case 'OD', bpv = 8; fmt = 'double';
    otherwise, bpv = 1; fmt = 'uint8';
end

%% Update length in uint32: i0 is the end location of length
function update_length(fid, i0)
i1 = ftell(fid);
fseek(fid, i0-4, 'bof');
fwrite(fid, i1-i0, 'uint32');
fseek(fid, i1, 'bof');

%% Generate 'unique' dicom ID
function uid = dicm_uid(s)
try pre = regexp(s.MediaStorageSOPInstanceUID, '.*\.', 'match', 'once');
catch, pre = '1.3.6.1.4.1.9590.100.1.8876.'; % Matlab ipt UID.XL
end
uid = sprintf('%s%s%08.0f', pre, datestr(now, 'yyyymmddHHMMSSfff'), rand*1e8);
