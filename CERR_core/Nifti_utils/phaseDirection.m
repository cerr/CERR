
%% subfunction: return phase positive and phase axis (1/2) in image reference
function [phPos, iPhase] = phaseDirection(s)
iPhase = [];
fld = 'InPlanePhaseEncodingDirection';
if isfield(s, fld)
    if     strncmpi(s.(fld), 'COL', 3), iPhase = 2; % based on dicm_img(s,0)
    elseif strncmpi(s.(fld), 'ROW', 3), iPhase = 1;
    else, errorLog(['Unknown ' fld ' for ' s.Filename ': ' s.(fld)]);
    end
end

phPos = csa_header(s, 'PhaseEncodingDirectionPositive'); % SIEMENS, image ref
if ~isempty(phPos), return; end
if isfield(s, 'RectilinearPhaseEncodeReordering') % GE
    phPos = ~isempty(regexpi(s.RectilinearPhaseEncodeReordering, 'REVERSE', 'once'));
    return;
elseif isfield(s, 'UserDefineData') % earlier GE
    % https://github.com/rordenlab/dcm2niix/issues/163
    try
    b = s.UserDefineData;
    i = typecast(b(25:26), 'uint16'); % hdr_offset
    v = typecast(b(i+1:i+4), 'single'); % 5.0 to 40.0
    if v >= 25.002, i = i + 76; flag2_off = 777; else, flag2_off = 917; end
    sliceOrderFlag = bitget(b(i+flag2_off), 2);
    phasePolarFlag = bitget(b(i+49), 3);
    phPos = ~xor(phasePolarFlag, sliceOrderFlag);
    end
    return;
end

if isfield(s, 'Stack') % Philips
    try d = s.Stack.Item_1.MRStackPreparationDirection(1); catch, return; end
elseif all(isfield(s, {'PEDirectionFlipped' 'PEDirectionDisplayed'})) % UIH
    % https://github.com/rordenlab/dcm2niix/issues/410
    d = s.PEDirectionDisplayed;
    if s.PEDirectionFlipped, d = d(end); else, d = d(1); end
elseif isfield(s, 'Private_0177_1100') % Bruker
    expr ='(?<=\<\+?)[LRAPSI]{1}(?=;\s*phase\>)'; % <+P;phase> or <P;phase>
    d = regexp(char(s.Private_0177_1100'), expr, 'match', 'once');
    id = regexp('LRAPSI', d);
    id = id + mod(id,2)*2-1;
    str = 'LRAPFH'; d = str(id);
else % unknown Manufacturer
    return;
end
try R = reshape(s.ImageOrientationPatient, 3, 2); catch, return; end
[~, ixy] = max(abs(R)); % like [1 2]
if isempty(iPhase) % if no InPlanePhaseEncodingDirection
    iPhase = strfind('RLAPFH', d);
    iPhase = ceil(iPhase/2); % 1/2/3 for RL/AP/FH
    iPhase = find(ixy==iPhase); % now 1 or 2
end
if     any(d == 'LPH'), phPos = false; % in dicom ref
elseif any(d == 'RAF'), phPos = true;
end
if R(ixy(iPhase), iPhase)<0, phPos = ~phPos; end % tricky! in image ref
if strncmpi(s.Manufacturer, 'Philips', 7), phPos = []; end % invalidate for now