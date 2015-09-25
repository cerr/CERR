function [Dose, rDepth, xMin, xMax, yMin, yMax, PBSizeX, PBSizeY, maxFlu] = getDose_UnitD(sigma, kernelSize, bs, inflMap, xV, yV,leak)
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

beamEnergy = bs.ControlPointSequence.Item_1.NominalBeamEnergy;

PBSizeX = 0.1; % x, y voxel size in cm
PBSizeY = 0.1;

[inflMask, xVV, yVV, xMin, xMax, yMin, yMax] = DICOMInfl2CERRPB(inflMap, xV, yV, PBSizeX, PBSizeY);

Dmin = 0; 
Dmax = 48;

delta = (Dmax - Dmin)/120; %z - voxel size

rDepth = Dmin:delta:Dmax;

voxelCtr = diff(rDepth);

voxelCtr(end+1) = voxelCtr(end);

rDepth = rDepth + voxelCtr/2;

rDepth(rDepth > 48) = 48;

QIBDataS = loadPBDataPC;

[A_zV, a_zV, B_zV, b_zV] = GetPBConsts(rDepth, beamEnergy, QIBDataS, 'nearest');

clear QIBDataS;

%%%%%% A_zV fit to MC
if beamEnergy == 6 & isempty(A_zV) == 0

    load MCfit6;

    N = length(MCfit);

    xDepth = linspace(48/N, 48, N);

    MC_Pr = interp1(xDepth, MCfit, rDepth);

    %     load MC_PR_New6;

    x = 1:106;
    y = 7*sqrt(x/20);
    y = y/100;
    MC_NewN_2 = MC_Pr(16:121) + y;
    MC_PR_New = MC_Pr;
    MC_PR_New(16:121) = MC_NewN_2;

elseif beamEnergy == 18 & isempty(A_zV) == 0

    load MCfit18;

    N = length(MCfit);

    xDepth = linspace(48/N, 48, N);

    MC_Pr = interp1(xDepth, MCfit, rDepth);

    %     load MC_PR_New18;
    x = 1:106;
    y = 7*sqrt(x/20);
    y = y/100;
    MC_NewN_2 = MC_Pr(16:121) + y;
    MC_PR_New = MC_Pr;
    MC_PR_New(16:121) = MC_NewN_2;
end

% A_zV + B_zV fit to MC profile

A_zV = MC_Pr' - B_zV;

MC_Pr = MC_PR_New;

sX = PBSizeX;% space kernel size in cm, more sX less smooth??
sY = PBSizeY;

xK = linspace(-sX*kernelSize/2, sX*kernelSize/2, kernelSize);
yK = linspace(-sY*kernelSize/2, sY*kernelSize/2, kernelSize);

inflMask(isnan(inflMask) == 1) = 0;

% boundaries

ss = [size(inflMask) length(rDepth)];

inflMaskB = zeros(ss(1) + (kernelSize + 1),ss(2) + (kernelSize + 1));

inflMaskB((kernelSize + 1)/2+1:end - (kernelSize + 1)/2,(kernelSize + 1)/2+1:end - (kernelSize + 1)/2) = inflMask;

Dose = zeros([size(inflMaskB) length(rDepth)]);

s = size(inflMaskB);

% figure, imagesc(inflMaskB);

h = waitbar(0,['Generating Reference/Convolution Dose For Beam ',num2str(bs.BeamNumber)]);

for k = 1 : ss(3),
    
    % norm kernels
   
    for i = 1:length(xK),
        for j = 1:length(yK),
            if xK(i) == 0 & yK(j) == 0
                PriDC(i,j) = 1;
                ScatDC(i,j) = 1;
                GaussDC(i,j) = 1;
            else
                PriDC(i,j) =  exp(-a_zV(k)*sqrt(xK(i)^2+yK(j)^2))./sqrt(xK(i)^2+yK(j)^2);
                ScatDC(i,j) = exp(-b_zV(k)*sqrt(xK(i)^2+yK(j)^2))./sqrt(xK(i)^2+yK(j)^2);
                GaussDC(i,j)=exp(-(xK(i)^2+yK(j)^2)./(2*sigma^2));
            end
        end
    end
    
    %norm kernels
    maxPriDC = max(PriDC(:));
    PriDC = A_zV(k)*(PriDC/maxPriDC);
    
    maxScatDC = max(ScatDC(:));
    ScatDC = B_zV(k)*(ScatDC/maxScatDC);
        
    %circular shift
    PriD=appendc7(PriDC,s(1),s(2));
    ScatD = appendc7(ScatDC,s(1),s(2));
    GaussD = appendc7(GaussDC,s(1),s(2));
         
%     Dose(:,:,k) = real(ifft2(fft2(inflMaskB).*fft2(PriD + ScatD).*fft2(GaussD)));
    
     Dose(:,:,k) = real(ifft2(fft2(inflMaskB).*fft2(PriD + ScatD)));
     
     Dose(:,:,k) = MC_Pr(k)*(Dose(:,:,k)/max(max(Dose(:,:,k))));
     
     waitbar(k/ss(3));
end

close(h);

maxFlu = max(inflMap(:));
Dose = maxFlu*(Dose/max(Dose(:)));
mm = max(Dose(:));
Dose(Dose < mm/1000000) = 0;

