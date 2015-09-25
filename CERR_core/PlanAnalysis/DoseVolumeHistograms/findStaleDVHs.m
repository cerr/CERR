function [isStale, planC] = findStaleDVHs(planC)
%"findStaleDVHs"
%   Find calculated DVHs stored in planC that were generated from doses
%   that no longer exist.  Stale DVHs are defined as those without the
%   "doseSignature" field, or those that do have the field but it's
%   contents do not match the signature of any existing doses.
%
%   isStale is a boolean vector, with 1 if the DVH is stale.
%
%   Confirmed stale DVHs have the doseSignature field set to [].
%
%JRA 12/4/04
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
%
%Usage:
%   function [isStale, planC] = findStaleDVHs(planC)

indexS = planC{end};

doseSigs = {};
isStale = [];

%Iterate over all DVHs...
for i=1:length(planC{indexS.DVH});
    
    %If doseSignature doesnt exist or is empty, treat as stale.
    if ~isfield(planC{indexS.DVH}(i), 'doseSignature') | isempty(planC{indexS.DVH}(i).doseSignature);
        isStale(i) = 1;
    else
        %Check stored dose in position dI's sig...
        dI = planC{indexS.DVH}(i).doseIndex;
        
        %If already calculated dose's sig, don't repeat.
        if dI > length(doseSigs) | isempty(doseSigs{dI})
            try
                doseSigs{dI} = calcDoseSignature(dI, planC);
            catch
                %If can't get sig, treat as stale.
                isStale(i) = 1;
                planC{indexS.DVH}(i).doseSignature = [];
                continue;
            end                
        end
        
        %If stored signature matches calculated, flag as not stale,
        %otherwise flag as stale and set signature to null.
        if isequal(planC{indexS.DVH}(i).doseSignature, doseSigs{dI})
            isStale(i) = 0;
        else            
            isStale(i) = 1;
            planC{indexS.DVH}(i).doseSignature = [];
        end
    end
end               