function extension = dicomrt_fileextension(filename)
% dicomrt_fileextension(filename)
%
% Get the extension of a file.
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

k = strfind('.',filename);
if isempty(k)==0
    extension=filename(max(k)+1:end);
else
    extension=nan;
end