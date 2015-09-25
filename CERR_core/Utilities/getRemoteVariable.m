function [data, variable] = getRemoteVariable(variable,varargin)
%"getRemoveVariable"
%   Accesses, loads and returns data that is stored remotely.
%
%   Also returns an optional copy of the variable with remote data stored
%   in the data field, and the loaded field set to 1.
%
% JRA 10/14/04
% APA 11/23/05 - Added Local storage capability in tarball format
%
%Usage: 
%   [data, variable] = getRemoteVariable(variable)
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

global stateS planC
indexS = planC{end};

if isstruct(variable) & isfield(variable, 'remotePath') & isfield(variable, 'isLoaded') & isfield(variable, 'data') & isfield(variable, 'info') & strcmpi(variable.info, 'Remotely stored data.  Use getRemoteVariable to access.')'

    if variable.isLoaded
        data = variable.data;       
    else       
        switch upper(variable.storageType)
            case 'ZIP'              
                load(fullfile(tempdir, variable.remotePath));
                data = CERRRemoteVariable;
                variable.data = data;
                variable.isLoaded = 1;
            case 'LOCAL'
                load(fullfile(variable.remotePath,variable.filename));
                data = CERRRemoteVariable;
                variable.data = data;
                variable.isLoaded = 1;       
            case 'NETWORK'
                error('Local and Network storage not implemented yet.');
        end       
    end
else
    error('Invalid remote data struct.')
end