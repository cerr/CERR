function variable = saveRemoteVariable(variable)
%"saveRemoteVariable"
%   Takes a remote variable and, if it was loaded, saves the data to the
%   file specified in remotePath, and clears the isLoaded field.  Returns
%   the modified variable.
%
% JRA 10/15/04
%
%Usage: 
%   function variable = saveRemoteVariable(variable)
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

if isstruct(variable) & isfield(variable, 'remotePath') & isfield(variable, 'isLoaded') & isfield(variable, 'data') & isfield(variable, 'info') & strcmpi(variable.info, 'Remotely stored data.  Use getRemoteVariable to access.')'

    if variable.isLoaded
        switch upper(variable.storageType)
            case 'ZIP'              
                fullTemp = fullfile(tempdir, variable.remotePath);
                CERRRemoteVariable = variable.data;
                  
                %Save in ML6 style.
                saveOpt = getSaveInfo;
                if ~isempty(saveOpt);
                    save(fullTemp, 'CERRRemoteVariable', saveOpt);
                else
                    save(fullTemp, 'CERRRemoteVariable');
                end       
                
                variable.data = [];
                variable.isLoaded = 0;
            case {'LOCAL', 'NETWORK'}
                error('Local and Network storage not implemented yet.');
        end              
    else       
        return;
    end
else
    error('Invalid remote data struct.')
end