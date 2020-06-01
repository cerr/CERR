function [bool, storageType, remotePath, fileName] = isLocal(variable)
%"isLocal"
%   Returns false if passed variable has been stored outside of the planC.
%   
% JRA 10/14/04
%
%Usage:
%   [bool, storageType, remotePath] = isLocal(variable);
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

bool = 1;
if isstruct(variable) && isfield(variable, 'remotePath') & isfield(variable, 'info') && strcmpi(variable.info, 'Remotely stored data.  Use getRemoteVariable to access.')
    bool = 0;
    storageType = variable.storageType;
    remotePath  = variable.remotePath;    
    fileName    = variable.filename;
else
    storageType = [];
    remotePath  = [];
end