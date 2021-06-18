% Get number of space dimensions ("space dimension" field) according to the
% space descriptor, following the format definition at
% http://teem.sourceforge.net/nrrd/format.html#spacedirections.
%
% Returns 3 if "space" field is one of
% "right-anterior-superior" or "RAS"
% "left-anterior-superior" or "LAS"
% "left-posterior-superior" or "LPS"
% "scanner-xyz"
% "3D-right-handed"
% "3D-left-handed"
%
% Returns 4 if "space" field is one of
% "right-anterior-superior-time" or "RAST"
% "left-anterior-superior-time" or "LAST"
% "left-posterior-superior-time" or "LPST"
% "scanner-xyz-time"
% "3D-right-handed-time"
% "3D-left-handed-time"
%
% Date: October 25, 2017
% Author: Gaetan Rensonnet
function sd = nrrd_getSpaceDimensions(spacedescriptor)

if any(strcmpi(spacedescriptor,...
        {'right-anterior-superior', 'RAS',...
        'left-anterior-superior', 'LAS',...
        'left-posterior-superior', 'LPS',...
        'scanner-xyz',...
        '3D-right-handed',...
        '3D-left-handed'}...
        ))
    sd = 3;
    
elseif any(strcmpi(spacedescriptor,...
        {'right-anterior-superior-time', 'RAST',...
        'left-anterior-superior-time', 'LAST',...
        'left-posterior-superior-time', 'LPST', ...
        'scanner-xyz-time', ...
        '3D-right-handed-time', ...
        '3D-left-handed-time'}...
        ))
    sd = 4;
    
else
    sd = -1;
    % Unrecognized nrrd space descriptor (grace under fire)
end
end