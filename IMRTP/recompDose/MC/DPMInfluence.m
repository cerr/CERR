function IM = DPMInfluence(IM, Energy,nhist,OutputError,planC,stateS,indBeam)
%"generateMCInfluence"
%   Given an IM structure, begin/continue calculating montecarlo influence
%   data.
%
%   Based on code by P. Lindsay.
%
%JRA, 26 Aug 04

% JC Feb 27 06
% Use sum(10*clock) as the random seeds in DPMInfluence.m
%
%Usage:
%   function IM = generateMCInfluence(IM, Energy);
%JC, July 28, 2005
%Put the photon spectrum into the DPMIN struct
%IM := IM structure
%Energy := the name of the energy specturm file.
%nhist := the number of history per cm^2
%The first two lines are just information.
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


%load DPM_10beams
% global planC
% global stateS
indexS=planC{end};
numBeams = length(IM.beams);

%Create all path parameters.
%JC Feb 10, 06 Turn "getCERRPath" off, in order to run stand-along, without
%CERR.

%DPMPath         = fullfile(getCERRPath, 'planCheck', 'MC', '');
%runsPath        = fullfile(DPMPath, 'runs', '')
%energyPath      = fullfile('.', 'spectrum', '');

% Added to get the bounding box of  the skin structure
% In order to reduce size of the interested CTscan

% In "DPM_test.mat", skin is number 9 structure.
% In planCheck, skin is number 1 structure.
%! skin structure is the last one, #21 in planC(4)
j = find(strcmpi({planC{indexS.structures}.structureName}, 'Skin'));

if isempty(j)
    j = find(strcmpi({planC{indexS.structures}.structureName}, 'Body'));
end

if isempty(j)
    error('Skin structure must be defined to input to DPM.');
else
    j = j(1);
end

skinMask=getUniformStr(j,planC);

bbox=boundingBox(skinMask);
% bbox =     61   183    17   240     1    90
% They're yini, yfin, xini, xfin, zini, zfin

scandr = bbox(2) - bbox(1) + 1;
scandc = bbox(4) - bbox(3) + 1;
scands = bbox(6) - bbox(5) + 1;

% Get the Uniformized CT dataset.
scan = getUniformizedCTScan(0, planC);
scan(~skinMask) = 0;
inSkinDensity = scan(skinMask);
inSkinDensity(inSkinDensity < 1) = 1;
scan(skinMask) = inSkinDensity;
% xV = the x in the middle of the voxel, in the x direction.
% x1, x2, ..., xmax.
[xV, yV, zV] = getUniformizedXYZVals(planC);
% Get x,y,z resolution: dx, dy, dz
xres = abs(xV(2) - xV(1));
yres = abs(yV(2) - yV(1));
zres = abs(zV(2) - zV(1));
indV = 1:(scandr*scandc*scands);
[c,r,s] = ind2sub([scandc,scandr,scands], indV);
r = r + bbox(1) - 1;
c = c + bbox(3) - 1;
s = s + bbox(5) - 1;
indV = sub2ind(getUniformizedSize(planC), r, c, s);

% Set options from IM.params.DPM
% Need to porpulate all the field of DPMIN struct.
%

% scan = planC{indexS.scan}.scanArray;
size_scan = size(scan)
% Assign the values to CTscan, which is the input structure for dpm.

% Probably need to make CTscan sturc a part of IM structure.
% unless it's only used locally, in this function.
% However, the solution/output of dpm has to be accessable for other
% functions/files.
CTscan.Num_y_vox = size_scan(1);
CTscan.Num_x_vox = size_scan(2);
CTscan.Num_z_vox = size_scan(3);

CTscan.dxvox = xres;
CTscan.dyvox = yres;
CTscan.dzvox = zres;

% Change the 3D array to a vector, used as DPM input

scan = double(scan)/1024;
CTscan.density = zeros(size_scan(1)*size_scan(2)*size_scan(3), 1);
CTscan.material = CTscan.density;
%CTscan.material (CTscan.material == 0) = -1;

% Need to convert the array to a vector, need to know the order of changing
% x, y, and z. which is first?
% rwo: x; col: y; slice: z


% scan1 is the changed order of the original scan (z y x)
%
scan1 = permute(scan, [3 1 2]);
CTscan.density = scan1(:);
clear scan1 scan r c s


% The following part comes from genvoxel.in
% Which specify the number & order of the material in CT scan.

%Number of materials:
% 5
%Material densities (g/cm^3), in the order corresponding to PENELOPE .geo file:
% 1.00        Water
% 0.3         LungICRP
% 1.85        CorticalBone
% 2.6989      Al
% 4.54        Ti

% According to the density value, get the material number.
Lung = 0.3                          % #2
Water = 1.0                         % #1
Bone = 1.85                         % #3
Al = 2.6989                         % #4
Ti = 4.54                           % #5

CTscan.material(CTscan.density < 0.5*(Lung+Water)) = 2;
CTscan.material(0.5*(Lung+Water) <= CTscan.density  & CTscan.density < 0.5*(Water+Bone)) = 1;
CTscan.material(0.5*(Water+Bone) <= CTscan.density & CTscan.density < 0.5*(Bone+Al)) = 3;
CTscan.material(0.5*(Bone+Al) <= CTscan.density & CTscan.density < 0.5*(Al+Ti)) = 4;
CTscan.material(0.5*(Al+Ti)<= CTscan.density) = 5;

% Find the upper left corner of the CTscan
% Need to check dpm.f to see whether it can handle x, y, z less than zero.
% Actually need to get the region of the intereted structures, not the
% whole CT scan, to eliminate the uncessary calculation.

% Initialize IM.params.DPM struct
IM.params.DPM = struct(...
    'NumParticles', [50], ...      % Number of particles
    'AlctTime', [-9e+008], ...       % Allocated CPU Time
    'ParticleType', [0], ...         % Particle Type, choice: -1, 0. -1 for electron; 0 for photon
    'SourceEnergy', [2e+007], ...    % Beam source energy, in(eV)
    'SqBeamSize', [1.5], ...         % Parallel Square Beam size (cm)
    'ElctAbsEnergy', [2.0e+005], ... % Electron Absorption Energy, in (eV)
    'PhotAbsEnergy', [5.0e+004], ... % Photon Absorption Energy, in (eV)
    'Prefix', 'pre4elec', ...        % Perfix files: pre4elec.*
    'minBoxV', [0 0 0], ...          % minimum [x y z] of the interested field
    'maxBoxV', [20 10 15], ...       % maximum [x y z] of the interested field
    'RandSeeds', [0 0], ...          % Random seeds [x1 x2], integer
    'TypeSource',[2], ...            % Type of source, choice: 0, 1, 2. 0 for parallel beam; 1 for disk source; 2 for rectangular collimator
    'SourceXYZ', [10 5 100], ...       % Source location, [x y z]
    'ClmtCorner1', [9.8 4.9 95], ...   % Corner 1 of the collimator: [x y z]
    'ClmtCorner2', [10.2 4.9 95], ...  % Corner 2 of the collimator: [x y z]
    'ClmtCorner3', [10.2 5.1 95], ...  % Corner 3 of the collimator: [x y z]
    'DiameterClmt', [1.5], ...         % The diameter of the disk collimator
    'PhotSpectrum', 'test.spectrum', ... % Photon energy spectrum n*2 matrix
    'OutputError', [0], ...              % Choice: 1 ='Yes', or 0 = 'No'.
    'IsoVector', [0 1 0], ...            % The unit vector from source to the iso-center
    'BinEnergy', [-1 -1], ...            % During commissing, the low bound and upper bound for each energy bin.
    'UsePhotSpectrum', 1 ...             % If it's 1, use DPMIN.PhotSpectrum; if it's 0, use "BinEnergy".
    );

% Above is from "initIMRTProblem.m".

% Loop for every beam.
beamletCount = 1;

%for beamIndex=1:numBeams,
%for beamIndex=1:1,
beamIndex = 1;

DPMIN.NumParticles = 10000000;
DPMIN.AlctTime = IM.params.DPM.AlctTime;
%DPMIN.ParticleType = IM.params.DPM.ParticleType;
DPMIN.ParticleType = 0;
DPMIN.SourceEnergy = IM.beams(beamIndex).beamEnergy*1000000; %MeV->eV
%DPMIN.SourceEnergy = 20000000;
DPMIN.SqBeamSize = IM.params(beamIndex).DPM.SqBeamSize;
DPMIN.ElctAbsEnergy = IM.params(beamIndex).DPM.ElctAbsEnergy;
DPMIN.PhotAbsEnergy = IM.params(beamIndex).DPM.PhotAbsEnergy;
DPMIN.Prefix = IM.params(beamIndex).DPM.Prefix;
DPMIN.MinCTscanCorner = [(bbox(3)-1)*xres (bbox(1)-1)*yres (bbox(5)-1)*zres];
%DPMIN.MaxCTscanCorner = [(bbox(4)-0.95)*xres (bbox(2)-1)*yres (bbox(6)-1)*zres];
DPMIN.MaxCTscanCorner = [(bbox(4)-0.95)*xres (bbox(2)-0.95)*yres (bbox(6)-0.95)*zres];
DPMIN.RandSeeds = IM.params(beamIndex).DPM.RandSeeds;
DPMIN.TypeSource = IM.params(beamIndex).DPM.TypeSource;
%Just to initialize DPMIN order.
DPMIN.SourceXYZ = [0 0 0];
% Collimators info need to be determined by pencil beam info.
DPMIN.ClmtCorner1 = IM.params(beamIndex).DPM.ClmtCorner1;
DPMIN.ClmtCorner2 = IM.params(beamIndex).DPM.ClmtCorner2;
DPMIN.ClmtCorner3 = IM.params(beamIndex).DPM.ClmtCorner3;
DPMIN.DiameterClmt = IM.params(beamIndex).DPM.DiameterClmt;
% Get the photon spectrum file.
fid = fopen(Energy);
if (fid == -1),
    disp('Can not Open photon spectrum file');
end
tline = fgetl(fid);
tline = fgetl(fid);
photon_spectrum = fscanf(fid,'%g %g',[2 inf]); % It has two rows now.
DPMIN.PhotSpectrum = photon_spectrum';
fclose(fid);
DPMIN.OutputError = IM.params(beamIndex).DPM.OutputError;
DPMIN.IsoVector = IM.params.DPM.IsoVector;
DPMIN.BinEnergy = IM.params.DPM.BinEnergy;
DPMIN.UsePhotSpectrum = IM.params.DPM.UsePhotSpectrum;
%JC Feb 09 2005. Make sure OutputError is changed based on input.
DPMIN.OutputError = OutputError;



% IM.beams(beamIndex).x is the x coordinate of the beam source.
% IM.beams.RTOGPBVectorsM_MC are the vectors from the source to the center
% of every pencil beam on the plane of the isocenter.
% So pb(:,1:3) are the locations of the center of every pencile beam on the
% plane passing the isocenter.

%nhist_time = zeros(2, length(IM.beams(beamIndex).beamletDelta_x));
%rand('state',sum(100*clock));

%currentDIR=pwd;
%cd(DPMPath);
if(exist('local')~= 3)
    dos('mkdir local')
end

%h = waitbar(0,['Generating Monte Carlo Dose for Beam ',num2str(indBeam)]);

for i= 1:length(IM.beams.beamletDelta_x),
    
    % Every time to call a Beam calculation, set the rand to a different
    % initial state.

    %for i = str2num(imin):str2num(imax)

    %Need to scale NumParticles based on the area of the pencil beam.
    %10Million particles per cm^2
    dx=IM.beams.beamletDelta_x(i);
    dy=IM.beams.beamletDelta_y(i);
    %DPMIN.NumParticles = str2num(nhist)*dx*dy;
    DPMIN.NumParticles = nhist*dx*dy;
    % Use clock as the random seeds.
    %DPMIN.RandSeeds = rand(1,2)*1000;
    
    DPMIN.RandSeeds(1) = sum(1000*clock);
    
    pb(i,1)=IM.beams(beamIndex).RTOGPBVectorsM_MC(i,1)+IM.beams(beamIndex).x;
    pb(i,2)=IM.beams(beamIndex).RTOGPBVectorsM_MC(i,2)+IM.beams(beamIndex).y;
    pb(i,3)=IM.beams(beamIndex).RTOGPBVectorsM_MC(i,3)+IM.beams(beamIndex).z;

    IC=[IM.beams.isocenter.x IM.beams.isocenter.y  IM.beams.isocenter.z];
    th=IM.beams.gantryAngle*pi/180;
    cA=IM.beams.couchAngle*pi/180;
    clA=IM.beams.collimatorAngle*pi/180;
    IsDist = IM.beams.isodistance;

    % coordinates of beams from perspectives of beam's eye view. z = const.
    coll3V(i,:) = scan2Collimator(pb(i,:), th, cA, clA, IC,IM.beams.isodistance);

    %%%%Find corners of the pencil beams.
    %%%%What order should it be?
    %%%% Previously, we had corner3, corner2, corner1, now

    corner1 = [coll3V(i,1)-0.5*dx   coll3V(i,2)-0.5*dy      coll3V(i,3)];
    corner2 = [coll3V(i,1)+0.5*dx   coll3V(i,2)-0.5*dy      coll3V(i,3)];
    corner3 = [coll3V(i,1)+0.5*dx   coll3V(i,2)+0.5*dy      coll3V(i,3)];

    % project back towards the plane 50cm from the source
    corner1_new = corner1/IsDist*50;
    corner2_new = corner2/IsDist*50;
    corner3_new = corner3/IsDist*50;

    % Project back to orginal coordinates.
    corner1_final = collimator2Scan(corner1_new, th, cA, clA, IC,IM.beams.isodistance);
    corner2_final = collimator2Scan(corner2_new, th, cA, clA, IC,IM.beams.isodistance);
    corner3_final = collimator2Scan(corner3_new, th, cA, clA, IC,IM.beams.isodistance);

    corner1_final = corner1_final-[xV(1)-xres/2 yV(end)-yres/2 zV(1)-zres/2];
    corner2_final = corner2_final-[xV(1)-xres/2 yV(end)-yres/2 zV(1)-zres/2];
    corner3_final = corner3_final-[xV(1)-xres/2 yV(end)-yres/2 zV(1)-zres/2];

    corner1_final(2) = yres*CTscan.Num_y_vox - corner1_final(2);
    corner2_final(2) = yres*CTscan.Num_y_vox - corner2_final(2);
    corner3_final(2) = yres*CTscan.Num_y_vox - corner3_final(2);

    % DPMIN.SourceXYZ = [IM.beams(beamIndex).x-xV(1)   yres*CTscan.Num_y_vox - (IM.beams(beamIndex).y-yV(end))  IM.beams(beamIndex).z-zV(1)];
    DPMIN.SourceXYZ = [IM.beams(beamIndex).x-(xV(1)-xres/2)   yres*CTscan.Num_y_vox - (IM.beams(beamIndex).y-(yV(end)-yres/2))  IM.beams(beamIndex).z-(zV(1)-zres/2)];
    DPMIN.ClmtCorner1 = corner1_final;
    DPMIN.ClmtCorner2 = corner2_final;
    DPMIN.ClmtCorner3 = corner3_final;
    clear corner1 corner2 corner3 corner1_new corner2_new corner3_new corner1_final corner2_final corner3_final
    
    % In DPM, the y direction is the opposite of the y of CERR coordinates.
    DPMIN.IsoVector = [IC(1) - IM.beams(beamIndex).x, -(IC(2) - IM.beams(beamIndex).y),IC(3) - IM.beams(beamIndex).z]/IsDist;
    
    disp(i);
    
% JC Feb 08 06 Turn off the electron calculation.
% The weight of the photon should be sum of the weight for each enery
    % bin.
% JC Feb 10 06 Turn on the electron calculation.
% The weight of the photon should be sum of the weight for each enery
    % bin.
    
    
     %Weight_phot = 374.2488;
     %Weight_elec = 0.0170;
%         
    %runDPM for photon spectrum
    DPMIN.ParticleType = 0;
    %DPMIN.NumParticles = 0.9*DPMIN.NumParticles;
    %tic; doseVF = dpmKZ(DPMIN, CTscan); 
     % Use clock as the random seeds.
    %DPMIN.RandSeeds = rand(1,2)*1000;
    
    DPMIN.RandSeeds(2) = sum(1000*clock);
    tic; doseV = dpm(DPMIN, CTscan); toc 
    
%     % Define the electron parameters, and run DPM for electron
%     % contamination
%      DPMIN.NumParticles = 0.1*DPMIN.NumParticles;
%      DPMIN.ParticleType = -1;  
%      DPMIN.RandSeeds = [0 0];
% %     
%      doseVE = dpm(DPMIN, CTscan); toc
%          
%    doseV = Weight_phot*doseVF  + Weight_elec*doseVE; 
%     
%    clear doseVE; clear doseVF
    
    if(DPMIN.OutputError == 1)
        Error = doseV(:, 2);
        doseV = doseV(:, 1);
    end
   
    % z changes first, then y, then x
    doseV = applyIMRTCompression(IM.params, doseV);
    beamlet = createIMBeamlet(doseV, indV', beamIndex, 0);

    if(DPMIN.OutputError == 1)
        Error = applyIMRTCompression(IM.params, Error);
        Error = createIMBeamlet(Error, indV', beamIndex, 0);
    end
    % Need to transpose either doseV or indV, because their dimensions
    % don't match.
    clear doseV

    % 14 Aug 05 JC
    % Do not use dissimilarInsert, where "setfield" is called, which causes
    % problem with mcc.
    %    IM.beamlets = dissimilarInsert(IM.beamlets, beamlet, beamletCount);
    % Add "beamlet" to IM.beamlets directory. When beamletCount == 1,
    % IM.beamlets = []; all beamlet structs have the same fields/order.
    if(beamletCount == 1)
        IM.beamlets = beamlet;
        if(DPMIN.OutputError == 1)
            IM.Errors = struct;
            IM.Errors = Error;
        end
    else
        IM.beamlets(beamletCount) = beamlet;
        if(DPMIN.OutputError == 1)
            IM.Errors(beamletCount) = Error;
        end

    end
    
    beamletCount = beamletCount + 1;
    
    %waitbar(i/length(IM.beams.beamletDelta_x));
    
end

%close(h);

%cd(currentDIR);
