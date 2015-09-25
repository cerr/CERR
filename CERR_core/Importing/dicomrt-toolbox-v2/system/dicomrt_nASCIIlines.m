function [nlines] = dicomrt_nASCIIlines(filename)
% dicomrt_nASCIIlines(filename)
%
% Returns the number of lines in an ASCII file.
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

fid=fopen(filename);
nlines = 0;
while 1
    if feof(fid)
        break;
    end
    nlines = nlines+1;
    fgetl(fid);    
end
fclose(fid);
