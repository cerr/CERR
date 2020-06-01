function crc = dicomrt_checksum(file)
% dicomrt_checksum(file)
%
% Compute crc (Cyclic Redundancy Check) for input file.
%
% Input file defaults to dicomrt_configuration.
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

% Check number of argument
error(nargchk(0,1,nargin))

if nargin==0
    file='dicomrt_configuration';
    argName = 'dicomrt_configuration';
else
    argName = strtrim(file);
end

whichArg = convertFilename(argName);
message = isDirectory(whichArg);
if (isempty(message))
    % Check for bad extensions (p, mex types).
    message = endsWithBadExtension(argName);
    if (isempty(message))
        % If file exists exactly as typed, go ahead and open.
        [fExists, errMessage] = openFileIfExists(whichArg, argName);
        if (fExists == 1)
            if ~isempty(errMessage)
                error(errMessage);
            end
        end
        % Do a which and exist open file if possible.
        fName = evalin('caller', ['which(' whichArg ')']);
        exists = evalin('caller', ['exist(' whichArg ')']); 
        if isempty(fName)==1
            errordlg('File not found.','dicomrt_checksum: file error');
            % break % not M7 compatible
            return  % M7 compatible
        end
    end
end

fid = fopen(fName);
input = fscanf(fid,'%c',inf);

%input = textread(file,'%s','delimiter','\n','whitespace','');
%input = textread(file,'%c');
input = double(input);

% Initialise syndrome to all ones
syndrome = uint16(hex2dec('ffff'));

% Seperate data into MSByte and LSByte
data = zeros([2*length(input) 1]);
data(1:2:end) = bitshift( bitand(input,hex2dec('FF00')),-8 );
data(2:2:end) = bitand(input,hex2dec('00FF'));
data = uint16(data);

% Calculate CRC
for n = 1:length(data)
    syndrome = crc_byte(data(n),syndrome);
end

crc = syndrome;

% function to calculate the serial CRC of a byte
function op = crc_byte(inbyte,insyn)

temp = bitxor(bitshift(insyn,-8),inbyte);
insyn = bitshift(insyn,8);
quick = bitxor( temp,bitshift(temp,-4) );
insyn = bitxor(insyn,quick);
quick = bitshift(quick,5);
insyn = bitxor(insyn,quick);
quick = bitshift(quick,7);
op = bitxor(insyn,quick);
%------------------------------------------
% Helper function that trims spaces from a string.  Taken from the original 
% edit.m
function s1 = strtrim(s)
%STRTRIM Trim spaces from string.

if isempty(s)
   s1 = s;
else
   % remove leading and trailing blanks (including nulls)
   c = find(s ~= ' ' & s ~= 0);
   s1 = s(min(c):max(c));
end


%--------------------------------------------
% Return 1 if argument is a valid name; otherwise return 0.
% Taken from the original edit.m
function ans = localCheckValidName(s)

% Is this a valid filename?
if isunix
   ans = 1;
else
   invalid = '/\:*"?<>|';
   [a b] = strtok(s,invalid);
   ans = strcmp(a, s);
end


%------------------------------------------
% Helper method that checks if a string specified is a directory.
% If it is a directory, a non-empty error message is returned.
function errMessage = isDirectory(s)

% If argument specified is a simple filename, don't check to 
% see if it is a directory (will treat as a filename only).
if isSimpleFile(s)
   errMessage = '';
   return;
end

dir_result = eval(['dir(' s ')']);

if ~isempty(dir_result)
   dims = size(dir_result);
   if (dims(1) > 1)
      errMessage = sprintf('Can''t edit the directory %s.', s);
      return;
   else
      if (dir_result.isdir == 1)
         errMessage = sprintf('Can''t edit the directory %s.', s);
         return;
      end
   end   
end
errMessage = '';


%------------------------------------------
% Helper method that checks if a file exists (exactly as typed).
% Returns 1 if exists, 0 otherwise.
function [result, absPathname] = fileExists(s, argName)

dir_result = eval(['dir(' s ')']);

% Default return arguments
result = 0;
absPathname = argName;

if ~isempty(dir_result)
   dims = size(dir_result);
   if (dims(1) == 1)
      if dir_result.isdir == 0
         result = 1;  % File exists
         % If file exists in the current directory, return absolute path
         if (isSimpleFile(s))
            absPathname = [pwd filesep dir_result.name];
         end
      end
   end
end


%------------------------------------------
% Helper method that determines if filename specified has an extension.
% Returns 1 if filename does have an extension, 0 otherwise
function result = hasExtension(s)

[pathname,name,ext] = fileparts(s);
if (isempty(ext))
   result = 0;    
   return;
end
result = 1;    


%--------------------------------------------
% Helper method that returns error message for file not found
%
function errMessage = showFileNotFound(file, origArg)

if (strcmp(file, origArg))                  % we did not change the original argument
   errMessage = sprintf('File ''%s'' not found.', file);
else        % we couldn't find original argument, so we also tried modifying the name
   errMessage = sprintf('Neither ''%s'' nor ''%s'' could be found.', origArg, file);
end


%------------------------------------------
% Helper method that checks if filename specified ends in .mex or .p.
% For mex, actually checks if extension BEGINS with .mex to cover different forms.
% If any of those bad cases are true, returns a non-empty error message.
function errMessage = endsWithBadExtension(s)

[pathname,name,ext] = fileparts(s);
ext = lower(ext);
if (strcmp(ext, '.p') == 1)
   errMessage = sprintf('Can''t edit the P-file ''%s''.', s);
   return;
end
if (~isempty(strfind(ext, '.mex')) | strcmp(ext, '.dll') == 1)
   errMessage = sprintf('Can''t edit the MEX-file ''%s''.', s);
   return;
end
errMessage = '';


%------------------------------------------
% Helper method that converts filename to form with
% double quotes, suitable for which
function whichArg = convertFilename(filename)

whichArg = ['''' strrep(filename, '''', '''''') ''''];


%------------------------------------------
% Helper method that checks to see if a file exists
% exactly.  If it does, tries to open file.
function [fExists, errMessage] = openFileIfExists(whichArg, argName)

errMessage = '';
[fExists, pathName] = fileExists(whichArg, argName);

if (fExists == 1)
    errMessage = editor(pathName);
end

%------------------------------------------
% Helper method that checks for directory seps.
function result = isSimpleFile(file)

result = 0;
if isunix
    if isempty(strfind(file, '/'))
        result = 1;
    end
else % on windows be more restrictive
    if isempty(strfind(file, '\')) & isempty(strfind(file, '/'))...
        & isempty(strfind(file, ':')) % need to keep : for c: case
        result = 1;
    end
end