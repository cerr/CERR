function [dose3D] = getMCDose(IM, w, structNum)
%"getMCDose" 
%   Get the full MC dose.  If w is defined, it weights each pencil beam by
%   w.
%
%JRA 01/20/04
%
%Usage:
%   function [dose3D] = getMCDose(IM, w)
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

global planC;

siz = getUniformizedSize(planC);
beamlets = IM.beamlets;

if ~exist('structNum');
    structNum = 1;
end

dose3D = zeros(siz);

numPBs = size(beamlets,2);

if exist('w') & length(w) ~= numPBs
    error('Size of w vector does not match number of pencil beams.');    
end

%Loop over beamlets.  
for PBNum = 1 : numPBs

    %For each requested structure, add the effect of this beamlet to inflM.
    %*** Loops are in this order to cut down on out of order inserts into
    %*** sparse influence matrix. Greatly increases speed. Leave it!
        
        if ~isempty(beamlets(structNum,PBNum).influence)
                       
                doseV     = double(beamlets(structNum,PBNum).influence);        
                indV      = beamlets(structNum,PBNum).indexV;
                maxVal    = beamlets(structNum,PBNum).maxInfluenceVal;
                sizeParam = beamlets(structNum,PBNum).fullLength;
                               
                if isfield(beamlets, 'lowDosePoints')
                    lowDosePoints = unpackLogicals(beamlets(structNum,PBNum).lowDosePoints, size(indV));                        
                    doseScaledV(~lowDosePoints) = doseV(~lowDosePoints) * (maxVal / (2^8 -1));
                    doseScaledV(lowDosePoints) = doseV(lowDosePoints) * (maxVal / (2^8 -1) / (2^8 -1));
                else
                    doseScaledV = doseV * (maxVal / (2^8 -1));
                end
            
                if exist('w') & length(w) == numPBs
                    doseScaledV = doseScaledV * w(PBNum); 
                end 
                
            dose3D(indV) = dose3D(indV) + reshape(doseScaledV, size(indV));
            doseScaledV = [];
            
        end        
    
end