function varargout = decompress(varargin)
%"decompress"
%   Decompresses variables compressed using the compress function, or that
%   are bitstream versions of data compressed with matlab Zip.  Any errors
%   on an individual variable causes the output to be the same as the input for
%   that variable.  See compress for details.
%
%JRA 10/13/03
%
%Usage:
%   individual variable:                   variable = decompress(variable);
%   structure array    : [structureArray.fieldName] = decompress(structureArray.fieldName);
%
%These calls will replace the old data with the new decompressed data.
%
% Copyright 2010, Joseph O. Deasy, on behalf of the CERR development team.
% 
% This file is part of The Computational Environment for Radiotherapy Research (CERR).
% 
% CERR development has been led by:  Aditya Apte, Divya Khullar, James Alaly, and Joseph O. Deasy.
% 
% CERR has been financially supported by the US National Institutes of Health under multiple grants.
% 
% CERR is distributed under the terms of the Lesser GNU Public License. 
% 
%     This version of CERR is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
% CERR is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
% without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
% See the GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with CERR.  If not, see <http://www.gnu.org/licenses/>.

nargout = nargin;
for i=1:nargin    
%     disp(['Decompressing input ' num2str(i) '/' num2str(nargin)]);
    %Check that we have proper compressed object as input.
    if isfield(varargin{i}, 'compressedData')
        try
            data = varargin{i}.compressedData;
            fid = fopen('decompression.zip', 'w');
            fwrite(fid, data, 'uint8');
            fclose(fid);
            unzip('decompression.zip'); 
            load 'compression.mat';
            varargout{i} = data;
            fid = fopen('compression.mat', 'r');
            fclose(fid);
            delete('decompression.zip');
            delete('compression.mat');
        catch
            warning(['Input ' num2str(i) '/' num2str(nargin) ' caused error: ' lasterr '. Returning input as result.']);
            varargout{i} = varargin{i};     
        end
    else
        warning(['Input ' num2str(i) '/' num2str(nargin) ' is not a valid compressed variable. Returning input as result.']);
        varargout{i} = varargin{i};
    end
end
return;
    
    
    
    
