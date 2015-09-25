function s1 = dicomrt_cleanstring(string)
% dicomrt_cleanstring(string)
%
% Removes trailing blanks and other unwanted characters from a string.
%
% Unwanted characters are:
%
% :;/\~{}[]()&*$"!^%`?#|<>@
%
% See also: dicomrt_DICOMimport, deblank
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

% Remove trailing blank first
string=deblank(string);

if isempty(string)
   s1 = string([]);
else
   if ~isstr(string),
      warning('dicomrt_cleanstring: Input must be a string.');
   end
   
   % Replace unwanted characters with underscore RUDE BUT SIMPLE AND EFFECTIVE
   [r,c] = find( string==':' | string==';' | ...
   string=='/' | string=='\' | string=='~' | ...
   string=='{' | string=='}' | string=='[' | ...
   string==']' | string=='(' | string==')' | ...
   string=='&' | string=='*' | string=='$' | ...
   string=='"' | string=='!' | string=='^' | ...
   string=='%' | string=='`' | string==' ' | ...
   string==',' | string=='?' | string=='#' | ...
   string=='|' | string=='>' | string=='<' | ...
   string=='@');
   
   if isempty(c),
      s1 = string;
   else
      string(c)=' ';
      s1=string;
   end
end

s1(isspace(s1))=[];
