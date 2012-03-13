function doseV = applyIMRTCompression(params, doseV)
%"applyCompression"
%   Applies compression specified in the IM structure to the doseV vector
%   and returns it.
%
%   Based on code by JOD and CZ
%
%JRA 30 Aug 04
%
%Usage:
%   function doseV = applyCompression(IM, doseV)
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

switch lower(params.ScatterMethod)
    case 'exponential'   
        %Apply "exponential" compression.
        maxD = max(doseV);   
        doseVLow = doseV;    
        doseVLow(doseVLow > params.Scatter.Threshold*maxD) = 0;    
        lowInd = find(doseVLow);
        
        if ~isempty(lowInd)
            [sortDose, ind] = sort(doseVLow(lowInd)); %%
            maxOfSorted = max(sortDose(:));
            normSortDose = sortDose/maxOfSorted;
            coins = rand(length(normSortDose), 1);
            keepers = find(normSortDose > coins);
            
            doseV(doseV < params.Scatter.Threshold*maxD) = 0;                  
            doseV(lowInd(ind(keepers))) = doseVLow(lowInd(ind(keepers)));% + evenDose;
        else
            doseV;
        end
        
    case 'random' %Also known as "probabilistic".
        maxD = max(doseV);    
        Step = params.Scatter.RandomStep;
        doseVLow = doseV;    
        doseVLow(doseVLow > params.Scatter.Threshold*maxD) = 0;    
        lowInd = find(doseVLow);    
        N = floor(length(lowInd)/Step);    
                
        downInd = round(rand(N,1) * (Step-1) + 1);
        tmp = cumsum([0;ones(N-1,1)]*Step);
        downInd = downInd + tmp;                             
%         for p = 1 : N-1;
%             downInd(p) = lowInd(ceil(Step*rand) + Step*(p-1));
%         end    
        if exist('doseVLowDown')
            clear doseVLowDown;    
        end
        doseVLowDown  = zeros(size(doseV));    
        f = 1:N-1;
%         for f = 1:N-1
            doseVLowDown(downInd(f)) = doseVLow(downInd(f));
%         end    
        doseV(doseV < params.Scatter.Threshold*maxD) = 0;    
        doseV = doseV + doseVLowDown;
    case 'threshold'               
        maxD = max(doseV);        
        doseV(doseV < params.Scatter.Threshold*maxD) = 0;                
    otherwise
        error('Invalid compression method in IM.params.ScatterMethod.');
end
