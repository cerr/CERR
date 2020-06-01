function runCommissioned(energy, fieldSize, FFA, FFB, FFDistance, nhist, r, c, s, batch)
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
% JC Oct 18, 2006  use target to flattening filter distance as 12.5cm instead of 9.5cm
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

%% Get the commissioned parameters from a .mAT file
[FileName,path] = uigetfile('*.mat','Select MAT file containing p ener a enerFF aFF');

if path == 0
    errordlg('File Should exist');
    error('File Should exist');
end

cd(path);
load (FileName, 'p', 'ener', 'a', 'enerFF', 'aFF')
cd(currentDir);

if (class(energy)== 'char')
    energy = str2num(energy);nhist = str2num(nhist); batch = str2num(batch);
    r = str2num(r); c = str2num(c); s = str2num(s); fieldSize = str2num(fieldSize);
end

[FileName,path] = uigetfile('*.*','Select dpm.dll to execute');

if path == 0
    errordlg('File Should exist');
    error('File Should exist');
end

cd(path)
% need ./local to run dpm. if no. crush.
% so creat it
mkdir local

rand('state',sum(100*clock));

% DPMIN.FlatFilterA = -0.21300000000000;
% DPMIN.FlatFilterB= -0.10000000000000;
% DPMIN.FlatFilterDist = 12.50000000000000;
DPMIN.FlatFilterA = str2num(FFA);
DPMIN.FlatFilterB= str2num(FFB);
DPMIN.FlatFilterDist = str2num(FFDistance);

% Add input ParticleType as 0 for photon or -1 for electron
DPMIN.ParticleType = 0;
DPMIN.SourceEnergy = energy;
% Jan 12, 2008
% Now "nhist" is defined as photons/cm^2 beamlet.
% Turn on Softening flag, for source model.
DPMIN.NumParticles = nhist*fieldSize*fieldSize;
DPMIN.Softening = 1;

DPMIN.IsoDistance = 100;
DPMIN.IncreaseFluence = 0;
DPMIN.OnlyHorn = 0;
DPMIN.UseFlatFilter = 0;
DPMIN.UsePhotSpectrum = 1;
DPMIN.OutputError = 0;
DPMIN.RandSeeds = [rand*1000 rand*10000];
DPMIN.PhotSpectrum =[ener', a'];

if (DPMIN.ParticleType == 0)
    DPMIN.Prefix = 'pre4phot'
elseif (DPMIN.ParticleType == -1)
    DPMIN.Prefix = 'pre4elec'
else
    error('DPMIN.ParticleType has to be 0 or -1')
end

% generratePB.
beamletSize = min(fieldSize,1);
generateOpenfieldPB(fieldSize, fieldSize, beamletSize);
filename = ['PB_', num2str(fieldSize), 'x', num2str(fieldSize), '_PBsize', num2str(beamletSize), 'cm.mat']
disp ('load PB info from above filename.')
load (filename, 'xPosV', 'yPosV', 'beamlet_delta_x', 'beamlet_delta_y', 'w_field');

% Load the Horn Coefficients.
Energy = '6MV10x10MDA.spectrum';
inds = max(strfind(Energy, '.'));
% filename:
fid = fopen([Energy(1:inds-1), '_CosHorn', Energy(inds:end)]);
% Here, the file extension ".spectrum" is only for the purpose of being
% consistent with other source model parameters files.
if (fid == -1),
    disp(['Can not Open CosHorn file',[Energy(1:inds-1), '_CosHorn', Energy(inds:end)]]);
end
tline = fgetl(fid);
tline = fgetl(fid);
CosHorn = fscanf(fid,'%g',[2 inf]); % It has two rows now.
CosHorn = CosHorn';
cosOffAxisAngle = DPMIN.IsoDistance ./ ...
    (sqrt((xPosV.^2+ yPosV.^2 + DPMIN.IsoDistance.^2)));
Horn = interp1(CosHorn(:,1), CosHorn(:,2), cosOffAxisAngle, 'linear');

DPMIN

doseV_PM_total = zeros(size(indV'));
doseV_EF_total = zeros(size(indV'));

for i = 1 : length(xPosV)

    source = DPMIN.SourceXYZ;

    % scale 40cm/100cm back from the iso center.
    % 0.5*0.4 = (half field size on the plus/minus sides; 0.5;
    %           (distance from source-to-jaw: 40cm / isodistance 100cm = 0.4)
    %  == 0.2
    % DPMIN.ClmtCorner1 = [source(1)-0.2*fieldSize    source(2)+40    source(3)+0.2*fieldSize];
    % DPMIN.ClmtCorner2 = [source(1)+0.2*fieldSize    source(2)+40    source(3)+0.2*fieldSize];
    % DPMIN.ClmtCorner3 = [source(1)+0.2*fieldSize    source(2)+40    source(3)-0.2*fieldSize];
    %load (filename, 'xPosV', 'yPosV', 'beamlet_delta_x', 'beamlet_delta_y', 'w_field');

    DPMIN.ClmtCorner1 = [source(1)-0.2*beamlet_delta_x(i)    source(2)+40    source(3)+0.2*beamlet_delta_y(i)];
    DPMIN.ClmtCorner2 = [source(1)+0.2*beamlet_delta_x(i)    source(2)+40    source(3)+0.2*beamlet_delta_y(i)];
    DPMIN.ClmtCorner3 = [source(1)+0.2*beamlet_delta_x(i)    source(2)+40    source(3)-0.2*beamlet_delta_y(i)];

    tic; doseV = dpm(DPMIN, CTscan); toc
    % Add the Horn coefficients
    doseV_PM_total = doseV_PM_total + (1+Horn(i))*doseV;

    %% Run only Flat Filter
    DPMIN.OnlyHorn = 0;
    DPMIN.UseFlatFilter = 1;
    %% Test, use 5 times particiles for EF.
    DPMIN.NumParticles = DPMIN.NumParticles*p(6)*5;
    DPMIN.PhotSpectrum = [enerFF', aFF'];
    DPMIN.RandSeeds = [rand*1000 rand*10000];
    tic; doseV = dpm(DPMIN, CTscan); toc
    doseV_EF_total = doseV_PM_total + doseV;

end

% At the end of the run, save the results.

cd(currentDir);
dose3D = zeros(r,c,s);
dose3D(indV) = doseV_PM_total;
filename = ['dose3D_PM_', num2str(batch),'.mat'];
save(filename, 'dose3D');

dose3Dsum = sum(a)*dose3D;

dose3D = zeros(r,c,s);
dose3D(indV) = doseV_EF_total;
filename =  ['dose3D_EF_',  num2str(batch), '.mat'];
save (filename, 'dose3D');
dose3Dsum = dose3Dsum + dose3D*sum(aFF);          % sum(aFF) == sum(a)*p(6);

filename =  ['dose3Dsum_',  num2str(batch), '.mat'];
save(filename,'dose3Dsum');

return;


% No Longer valide. Do not use.
% % % %% Run OnlyHorn
% % % DPMIN.NumParticles = DPMIN.NumParticles*p(7); % scale down the number of particles by the relative fluence weight of Horn.
% % % DPMIN.OnlyHorn = 1;
% % % DPMIN.RandSeeds = [rand*1000 rand*10000];
% % %
% % % cd(path);
% % % tic; doseV = dpm(DPMIN, CTscan); toc
% % % cd(currentDir);
% % %
% % % dose3D = zeros(r,c,s);
% % % dose3D(indV) = doseV;
% % % filename =  ['dose3D_Horn', num2str(batch), '.mat'];
% % % save (filename, 'dose3D');
% % % dose3Dsum = dose3Dsum + dose3D*sum(a)*p(7);



% Run electron
% Since for 6MV, the relative electron contribution is only about 0.1%, so
% it's negligible.
%  DPMIN.
%   DPMIN.Prefix = 'pre4elec';
%     DPMIN.UseFlatFilter = 0
%
%     cd(path);
%     tic; doseV = dpm(DPMIN, CTscan); toc
%     cd(currentDir);
%
%     dose3D = zeros(r,c,s);
%     dose3D(indV) = doseV;
%     filename = ['dose3D_elec.mat'];
%     save(filename,'dose3D');

