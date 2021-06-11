function WRITE_stl(fileOUT,coordVERTICES,coordNORMALS,varargin)
% WRITE_stl  Write an STL file in either ascii or binary
%==========================================================================
% FILENAME:          WRITE_stl.m
% AUTHOR:            Adam H. Aitkenhead
% DATE:              12th May 2010
% PURPOSE:           Write an STL file in either ascii or binary
%
% EXAMPLE:           WRITE_stl(fileOUT,coordVERTICES,coordNORMALS,STLformat)
%
% OUTPUT FILES:      <fileOUT>
%
% INPUT PARAMETERS:
%     fileOUT       - A string defining the filename, eg. 'filename.stl'
%
%     coordVERTICES - an Nx3x3 array defining the vertices for each facet:
%                                   - 1 row for each facet
%                                   - 3 cols for the x,y,z coordinates
%                                   - 3 pages for the three vertices
%
%     coordNORMALS  - an Nx3 array defining the normal of each facet:
%                                   - 1 row for each facet
%                                   - 3 cols for the x,y,z components of
%                                     the vector
%
%     STLformat     - string (optional) - STL format: 'binary' or 'ascii'
%==========================================================================

%==========================================================================
% VERSION  USER  CHANGES
% -------  ----  -------
% 100512   AHA   Original version
% 100630   AHA   Improved speed by avoiding the use of a 'for' loop 
% 101123   AHA   Now writes either ascii or binary STL files
%==========================================================================

if nargin==4
  STLformat = lower(varargin{1});
  if strfind(STLformat,'binary')
    WRITE_stlbinary(fileOUT,coordVERTICES,coordNORMALS)
  else
    WRITE_stlascii(fileOUT,coordVERTICES,coordNORMALS)
  end
else
  WRITE_stlascii(fileOUT,coordVERTICES,coordNORMALS)
end

end %function



%--------------------------------------------------------------------------
function WRITE_stlascii(fileOUT,coordVERTICES,coordNORMALS)
% Write an ASCII STL file
%----------------------

facetcount = size(coordNORMALS,1);
filePREFIX = fileOUT(1:end-4);    % Get the prefix of the output filename

%----------------------
% Prepare data in a suitable format for easy writing to the STL file

outputALL = zeros(facetcount,3,4);

outputALL(:,:,1)     = coordNORMALS;
outputALL(:,:,2:end) = coordVERTICES;

outputALL = permute(outputALL,[2,3,1]);

%----------------------
% Write to the file

fidOUT = fopen([fileOUT],'w');    % Open the output file for writing

fprintf(fidOUT,'solid %s\n',filePREFIX);

% Write the data for each facet:
fprintf(fidOUT,[ 'facet normal %e %e %e\n',...
                 '  outer loop\n',...
                 '    vertex %e %e %e\n',...
                 '    vertex %e %e %e\n',...
                 '    vertex %e %e %e\n',...
                 '  endloop\n',...
                 'endfacet\n',...
               ],outputALL);

fprintf(fidOUT,'endsolid %s\n',filePREFIX);

fclose(fidOUT);          % Close the output file

end %function



%--------------------------------------------------------------------------
function WRITE_stlbinary(fileOUT,coordVERTICES,coordNORMALS)
% Write a binary STL file
%----------------------

facetcount = size(coordNORMALS,1);
filePREFIX = fileOUT(1:end-4);    % Get the prefix of the output filename

%----------------------
% Prepare data in a suitable format for easy writing to the STL file

outputALL = zeros(facetcount,3,4);

outputALL(:,:,1)     = coordNORMALS;
outputALL(:,:,2:end) = coordVERTICES;

outputALL = permute(outputALL,[2,3,1]);

%----------------------
% Write to the file

fidOUT = fopen([fileOUT],'w');    % Open the output file for writing

%Write the 80 byte header
headerdata = int8(zeros(80,1));
bytecount  = fwrite(fidOUT,headerdata,'int8');

%Write the 4 byte facet count
facetcount = int32(size(coordNORMALS,1));
bytecount  = fwrite(fidOUT,facetcount,'int32');

% Write the data for each facet:
for loopB = 1:facetcount
  fwrite(fidOUT,outputALL(loopB*12-11:loopB*12),'float');
  fwrite(fidOUT,0,'int16');   % Move to the start of the next facet.
end

fclose(fidOUT);          % Close the output file

end %function
