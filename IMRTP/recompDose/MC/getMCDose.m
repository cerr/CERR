function [dose3D] = getMCDose(IM, w, structNum)
%"getMCDose" 
%   Get the full MC dose.  If w is defined, it weights each pencil beam by
%   w.
%
%JRA 01/20/04
%
%Usage:
%   function [dose3D] = getMCDose(IM, w)

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