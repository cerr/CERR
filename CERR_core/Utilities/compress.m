function varargout = compress(varargin) 
%"compress"
%   Take all input variables, compress them using the builtin java Zip
%   function, place them in a wrapper object with fields info and
%   compressedData, and return.  If any error is encountered, the input is
%   returned as the result to avoid overwriting of sensitive data.
%
%JRA 10/13/03
%
%Usage:
%   individual variable:                   variable = compress(variable);
%   structure array    : [structureArray.fieldName] = compress(structureArray.fieldName);
%
%These calls will replace the old data with the new compressed data.
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
%     disp(['Compressing input ' num2str(i) '/' num2str(nargin)]);
    if ~isfield(varargin{i}, 'compressedData')
        try
            data = varargin{i};
            filename = ['compression'];
            %Save routine for Matlab 7 compatability.
            saveOpt = getSaveInfo;
            if ~isempty(saveOpt);
                save([filename '.mat'], 'data', saveOpt);
            else
                save([filename '.mat'], 'data');
            end
%             save([filename '.mat'],'data');
            zip([filename '.zip'], [filename '.mat']);
            fid = fopen([filename '.zip'], 'r');
            compressed = fread(fid, inf, 'uint8=>uint8');
            fclose(fid);
            wrapper.compressedData = compressed;
            wrapper.info = 'Compressed variable. Use decompress to extract.';
            fid = fopen([filename '.mat'], 'r');
            fclose(fid);
            delete([filename '.mat']);
            delete([filename '.zip']);
            varargout{i} = wrapper;
        catch
            warning(['Input ' num2str(i) '/' num2str(nargin) ' caused error ''' lasterr '''. Returning input as result.']);
            varargout{i} = varargin{i};            
        end
    else
        warning(['Input ' num2str(i) '/' num2str(nargin) ' is already a valid compressed variable. Returning input as result.']);
        varargout{i} = varargin{i};
    end
end
return;