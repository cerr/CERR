function version = MLVersion
%"MLVersion"
%   Returns the numeric version of Matlab currently running.  Uses the first
%   3 digits of the Version field returned from ver('matlab').
%
%JRA 11/15/04
%
%Usage:
%   function version = MLVersion

verOutput = ver('MATLAB');
verString = verOutput.Version;

dotInd = strfind(verString, '.');
startInd = [1 dotInd+1];
endInd = [dotInd - 1 length(verString)];

for i = 1:length(startInd)
    versionCell{i} = str2num(verString(startInd(i):endInd(i)));
end

if length(versionCell) > 1
    version = versionCell{1} + versionCell{2}*1/(10^length(versionCell{2}));
else
    version = versionCell{1};
end
