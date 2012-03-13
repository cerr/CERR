function runBinEnergy(energy, fieldSize, numBin, extraBin, startBin, endBin, IncreaseFluence, OnlyHorn, UseFlatFilter, FFA, FFB, FFDistance, ParticleType, DoseNormFlag, nhist, r, c, s)
% 'runBinEnergy'
% JC 1/29/06
% How to use
%> runBinEnergy 18 20 4 100000000
%
% Written by JC. Dec 2005
% Run DPM for the different energy bins, for optimize the photon spectrum later.
%"input" is the .MAT file have DPMIN, CTscan, and indV
%DPMIN - DPM input structure
%CTscan - DPM scan structure
%indV = sub2ind(getUniformizedSize(planC), r, c, s); see DPMInfluence.m
%line 72
%DPMIN_CTscan_indV DMPIN, CTScan, indV
%"number" is how many bins we're going to divide the whole energy range
% Typical value for "number" is 20
%nhis - number of histories
%
% JC Oct 18, 2006  use target to flattening filter distance as 12.5cm instead of 9.5cm);
% JC Feb 26, 2007  
    % Add  DoseNormFlag
    % DPMIN.NumParticles = nhist*fieldSize*fieldSize;
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
    
setappdata(0, 'usenativesystemdialogs', false)
currentDir = cd;

[FileName,path] = uigetfile('*.mat','Select MAT file containing DPMIN, CTscan, & indV, p');

if path == 0
    errordlg('File Should exist');
    error('File Should exist');
end

cd(path);
load (FileName, 'DPMIN', 'CTscan', 'indV')
cd(currentDir);


if (class(energy)== 'char')
    energy = str2num(energy);numBin = str2num(numBin);extraBin = str2num(extraBin);nhist = str2num(nhist);
    r = str2num(r); c = str2num(c); s = str2num(s); fieldSize = str2num(fieldSize);
end

[FileName,path] = uigetfile('*.*','Select dpm.dll to execute');

if path == 0
    errordlg('File Should exist');
    error('File Should exist');
end

% need ./local to run dpm. if no. crush.
% so creat it
mkdir local

rand('state',sum(100*clock));
%for i = 0: numBin + extraBin - 1,

% Add input ParticleType as 0 for photon or -1 for electron
DPMIN.ParticleType = str2num(ParticleType);
DPMIN.SourceEnergy = energy;
% DPMIN.NumParticles = nhist;
DPMIN.NumParticles = nhist*fieldSize*fieldSize;

source = DPMIN.SourceXYZ;
% scale 40cm/100cm back from the iso center.
% 0.5*0.4 = (half field size on the plus/minus sides; 0.5;
%           (distance from source-to-jaw: 40cm / isodistance 100cm = 0.4)
%  == 0.2
DPMIN.ClmtCorner1 = [source(1)-0.2*fieldSize    source(2)+40    source(3)+0.2*fieldSize];
DPMIN.ClmtCorner2 = [source(1)+0.2*fieldSize    source(2)+40    source(3)+0.2*fieldSize];
DPMIN.ClmtCorner3 = [source(1)+0.2*fieldSize    source(2)+40    source(3)-0.2*fieldSize];

% DPMIN.FlatFilterA = -0.21300000000000;
% DPMIN.FlatFilterB= -0.10000000000000;
% DPMIN.FlatFilterDist = 12.50000000000000;
DPMIN.FlatFilterA = str2num(FFA);
DPMIN.FlatFilterB= str2num(FFB);
DPMIN.FlatFilterDist = str2num(FFDistance);

DPMIN.IsoDistance = 100;
DPMIN.IncreaseFluence = str2num(IncreaseFluence);
DPMIN.OnlyHorn = str2num(OnlyHorn);
DPMIN.UseFlatFilter = str2num(UseFlatFilter)
DPMIN.DoseNormFlag = str2num(DoseNormFlag);


if(DPMIN.ParticleType == 0)

    for i = str2num(startBin): str2num(endBin)
        DPMIN.BinEnergy = [i*energy/numBin (i+1)*energy/numBin]
        DPMIN.UsePhotSpectrum = 0;
        DPMIN.OutputError = 0;
        DPMIN.RandSeeds = [rand*1000 rand*10000];

        if (DPMIN.ParticleType == 0)
            DPMIN.Prefix = 'pre4phot'
        elseif (DPMIN.ParticleType == -1)
            DPMIN.Prefix = 'pre4elec'
        else
            error('DPMIN.ParticleType has to be 0 or -1')
        end

        cd(path);
        tic; doseV = dpm(DPMIN, CTscan); toc
        cd(currentDir);

        dose3D = zeros(r,c,s);
        %   Change the convention of the filename, using the upper bound of the
        %   bin as the file name, instead of the lower bound.
        %    filename = ['doseV_', num2str(i*energy/numBin),'MV.mat'];
        dose3D(indV) = doseV;
        filename = ['dose3D_', num2str((i+1)*energy/numBin),'MV.mat'];
        if (DPMIN.OnlyHorn == 1)
            filename =  ['dose3D_Horn_', num2str((i+1)*energy/numBin),'MV.mat'];
		end

		% Jan 11, 2008. After the extension, UseFlatFilter can be 0, 1, or 2.
        if (DPMIN.UseFlatFilter ~= 0)
            filename =  ['dose3D_FF_', num2str((i+1)*energy/numBin),'MV.mat'];
        end

        save (filename, 'dose3D');

    end

elseif (DPMIN.ParticleType == -1)
    DPMIN.Prefix = 'pre4elec';
    DPMIN.UseFlatFilter = 0

    cd(path);
    tic; doseV = dpm(DPMIN, CTscan); toc
    cd(currentDir);

    dose3D = zeros(r,c,s);
    dose3D(indV) = doseV;
    filename = ['dose3D_elec.mat'];
    save(filename,'dose3D');

else
    error('DPMIN.ParticleType has to be 0 or -1')
end
end
