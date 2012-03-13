function QIBDataS = loadPBDataPC
%Load auxiliary data associated with the QIB algorithm.
%JOD, 13 Nov 03.
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

%-----------Load dose calc params---------------------%

pathStr = getCERRPath;

if isunix == 1
    where = [getCERRPath 'Extras/IMRTPBeta'];
    
    load([where '/QIBData/aahn6b.dat'])
    load([where '/QIBData/aahn18b.dat'])
    
    QIBDataS.aahn6b = aahn6b;
    QIBDataS.aahn18b = aahn18b;
    
%     %QIB matrix
%     load([where '/QIBData/QIB_lin_0pt125.mat'])
%     QIBDataS.QIB = QIB_lin_0pt125;
%     
%     %Gaussian QIB matrix
%     load([where '/QIBData/QIBGauss_lin_0pt125.mat'])
%     QIBDataS.QIBGauss = QIBGauss_lin_0pt125;
    
else
    where = [getCERRPath 'Extras\IMRTPBeta'];
    
    load([where '\QIBData\aahn6b.dat'])
    load([where '\QIBData\aahn18b.dat'])
    
    QIBDataS.aahn6b = aahn6b;
    QIBDataS.aahn18b = aahn18b;
    
%     %QIB matrix
%     load([where '\QIBData\QIB_lin_0pt125.mat'])
%     QIBDataS.QIB = QIB_lin_0pt125;
%     
%     %Gaussian QIB matrix
%     load([where '\QIBData\QIBGauss_lin_0pt125.mat'])
%     QIBDataS.QIBGauss = QIBGauss_lin_0pt125;
end

% QIBDataS.deltaQBM=0.0125;
% 
% QIBDataS.QBMidIndexX= 793; %The entry at which intensity equals 0.5 on either axis.
% QIBDataS.QBMidIndexY= 793;

