function [moutput]=dicomrt_restorevarformat(morig,data)
% dicomrt_restorevarformat(morig,data)
%
% Restore original variable data.
%
% The 3D dataset stored in "data" is associated with the frame given by the
% original dataset "morig" and returned in "moutput".
%
% Seel also: dicomrt_varfilter
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org)

if iscell(morig)==1
    morig{2,1}=data;
    moutput=morig;
else
    moutput=data;
end
