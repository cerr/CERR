function [midstring] = midstring(aString,BeginSubString,EndSubString)

% Returns a substring within specified positions
%
%   Input arguments: aString (original string)
%                    BeginSubString (specified beginning position)
%                    EndSubString (specified end position)
%   Output:
%                    'Undefined' if length(aString) < EndSubString (undefined)
%                    SubString = aString(BeginSubString:EndSubString)
%
%   Example: 
%   a = 'D:\plans\plan1.mat';
%   b = midstring(a, length(a)-2, length(a));
%   b = 'mat'
%
%   Execution speed:
%   tic
%   for i = 1 : 10000
%       b = midstring(a, length(a) -2, length(a));
%   end
%   toc
%   ans = 6.8500e-004 % seconds per call on Athlon machine
%   Angel Blanco 3-23-2002

% copyright (c) 2001-2006, Washington University in St. Louis.
% Permission is granted to use or modify only for non-commercial, 
% non-treatment-decision applications, and further only if this header is 
% not removed from any file. No warranty is expressed or implied for any 
% use whatever: use at your own risk.  Users can request use of CERR for 
% institutional review board-approved protocols.  Commercial users can 
% request a license.  Contact Joe Deasy for more information 
% (radonc.wustl.edu@jdeasy, reversed).

midstring = '';
if ( ~isnumeric(BeginSubString) | ~isnumeric(EndSubString) | ...
        EndSubString > length(aString)  | BeginSubString > ...
    length(aString) | BeginSubString > EndSubString )
    midstring = 'Undefined';
else
    for i = BeginSubString:EndSubString
        midstring = strcat(midstring,char(aString(i)));
    end
end
