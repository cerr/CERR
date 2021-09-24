function QIBDataS = loadPBData
%Load auxiliary data associated with the QIB algorithm.
%JOD, 13 Nov 03.
%
% Last Modified:
%  JJW 07/05/2006 added k1, k2, k3, k4
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

IMRTPdir = fileparts(which('IMRTP'));

load(fullfile(IMRTPdir,'QIBData','aahn_6b.dat'))
load(fullfile(IMRTPdir,'QIBData','aahn_18b.dat'))

QIBDataS.aahn6b = aahn_6b;
QIBDataS.aahn18b = aahn_18b;

%QIB matrix
load(fullfile(IMRTPdir,'QIBData','QIB_lin_0pt125.mat'))
QIBDataS.QIB = QIB_lin_0pt125;

%Gaussian QIB matrix
load(fullfile(IMRTPdir,'QIBData','QIBGauss_lin_0pt125.mat'))
QIBDataS.QIBGauss = QIBGauss_lin_0pt125;


QIBDataS.deltaQBM=0.0125;

QIBDataS.QBMidIndexX= 793; %The entry at which intensity equals 0.5 on either axis.
QIBDataS.QBMidIndexY= 793;

%Ahnesjo parameters:
QIBDataS.k1 = 1.1284;
QIBDataS.k2 = 0.476;
QIBDataS.k3 = 0.0354;
QIBDataS.k4 = 0.715;


