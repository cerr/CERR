function VMCOpt = VMCOptInit
%"VMCOptInit"
%   Initialize VMC options
%   We include defaults
%
%JOD,    Jun 02.
%JRA, 13 Jun 04.
%
%Usage:
%   function VMCOpt = VMCOptInit
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

%* indicates variables that can be set via the GUI.

VMCOpt.startScoring.startInGeometry                    =  'phantom';

VMCOpt.startScoring.description                        =  'CERR Test';

VMCOpt.startScoring.startDoseOptions.scoreInGeometries =  'phantom';

VMCOpt.startScoring.startDoseOptions.scoreDoseToWater  =  'yes'; %*

VMCOpt.startScoring.startOutputOptions.name            =  'phantom';

VMCOpt.startScoring.startOutputOptions.dumpDose        =  2; %* Keep track of disk space usage... 1 is 4x bigger than 2.

VMCOpt.startGeometry.startXYZGeometry.myName           =  'phantom';

VMCOpt.startGeometry.startXYZGeometry.methodOfInput    =  'CT-PHANTOM';

VMCOpt.startGeometry.startXYZGeometry.phantomFile      =  '';

VMCOpt.startBeamletSource.myName                       =  'source 1';

VMCOpt.startBeamletSource.monitorUnitsSource          =  1;

VMCOpt.startBeamletSource.monoEnergy                  =  []; %*

VMCOpt.startBeamletSource.charge                      =  0; %*photons=0 electrons = -1 

VMCOpt.startBeamletSource.beamletEdges                =  [];

VMCOpt.startBeamletSource.virtualPointSourcePosition  =  [];

VMCOpt.startBeamletSource.spectrum                    = ''; %* 6 18 file mono

VMCOpt.startMCParameter.automaticParameter            =  'yes';

VMCOpt.startMCControl.NCase                           =   100000;       %*

VMCOpt.startMCControl.NBatch                          =   10;           %*

VMCOpt.startMCControl.RNGSeeds                        =   [1 1];

VMCOpt.startVarianceReduction.repeatHistory           =   0.251; %*

VMCOpt.startVarianceReduction.splitPhotons            =   1; %*

VMCOpt.startVarianceReduction.photonSplitFactor       =   -40; %*

VMCOpt.startQuasi.base                                =   2; %*

VMCOpt.startQuasi.dimension                           =   60; %*

VMCOpt.startQuasi.skip                                =   1; %*