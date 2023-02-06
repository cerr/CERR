
%% subfunction: return nii ext from dicom struct
% The txt extension is in format of: name = parameter;
% Each parameter ends with [';' char(0 10)]. Examples:
% Modality = 'MR'; % str parameter enclosed in single quotation marks
% FlipAngle = 72; % single numeric value, brackets may be used, but optional
% SliceTiming = [0.5 0.1 ... ]; % vector parameter enclosed in brackets
% bvec = [0 -0 0 
% -0.25444411 0.52460458 -0.81243353 
% ...
% 0.9836791 0.17571079 0.038744]; % matrix rows separated by char(10) and/or ';'
function ext = set_nii_ext(s)
flds = fieldnames(s);
ext.ecode = 6; % text ext
ext.edata = '';
for i = 1:numel(flds)
    try val = s.(flds{i}); catch, continue; end
    if ischar(val)
        str = sprintf('''%s''', val);
    elseif numel(val) == 1 % single numeric
        str = sprintf('%.8g', val);
    elseif isvector(val) % row or column
        str = sprintf('%.8g ', val);
        str = sprintf('[%s]', str(1:end-1)); % drop last space
    elseif isnumeric(val) % matrix, like DTI bvec
        fmt = repmat('%.8g ', 1, size(val, 2));
        str = sprintf([fmt char(10)], val'); %#ok
        str = sprintf('[%s]', str(1:end-2)); % drop last space and char(10)
    else % in case of struct etc, skip
        continue;
    end
    ext.edata = [ext.edata flds{i} ' = ' str ';' char([0 10])];
end
