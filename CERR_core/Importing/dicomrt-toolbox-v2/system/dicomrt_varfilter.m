function [moutput]=dicomrt_varfilter(minput)
% dicomrt_varfilter(minput)
%
% Filter input variable data.
%
% If input variable data is a cell array this function returns the 
% array part of it: minput{2,1}.
%
% See also: dicomrt_restorevarformat
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org)

if iscell(minput)==1
    moutput=minput{2,1};
else
    moutput=minput;
end
