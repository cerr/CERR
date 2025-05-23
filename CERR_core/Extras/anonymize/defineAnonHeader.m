function anonHeaderS = defineAnonHeader()
%
% function anonHeaderS = defineAnonHeader()
%
% Defines the anonymous "header" data structure. The fields containing PHI have
% been left out by default. In order to leave out additional fields, remove
% them from the list below. 
%
% The following three operations are allowed per field of the input data structure:
% 1. Keep the value as is: listed as 'keep' in the list below.
% 2. Allow only the specific values: permitted values listed within a cell array. 
%    If no match is found, a default anonymous string will be inserted.
% 3. Insert dummy date: listed as 'date' in the list below. Date will be
%    replaced by a dummy value of 11/11/1111.
%
% APA, 1/11/2018

anonHeaderS = struct( ...
                     'archive', 'keep', ...
                     'writer', {{'CERR DICOM Import'}}, ...
                  'timeSaved', 'keep', ...
             'lastSavedInVer', 'keep', ...
          'CERRImportVersion', 'keep', ...
               'anonymizedID', 'keep'  ...
           );
