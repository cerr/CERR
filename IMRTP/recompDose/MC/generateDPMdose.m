function [IM doseV_SUM indV sampleParticles] = generateDPMdose (IM, Energy, nhist, OutputError, planC, indBeam, w_field, saveIM, sourceModel, fillWater, useWedge, Softening, UseFlatFilter)
%"generateMCInfluence"
%   Given an IM structure, begin/continue calculating montecarlo influence
%   data.
%
%   Based on code by P. Lindsay.
%
%JRA, 26 Aug 04

% JC Feb 27 06
% JC Jun 06 06
% Use stream of the doseV, do not put every dose inside IM struct.
% Use sum(10*clock) as the random seeds in DPMInfluenceJing.m

%
%Usage:
%   function IM = generateMCInfluence(IM, Energy);
%JC, July 28, 2005
%Put the photon spectrum into the DPMIN struct
%IM := IM structure
%Energy := the name of the energy specturm file.
%nhist := the number of history per cm^2
%The first two lines are just information.

%JC Nov 16, 2006, Use the most up-to-date DPM.
% Add more input to DPMIN.

%JC Nov 27, 2006,
% DPMIN.Prefix = 'pre4phot' for photon.
% Correct the distance from target/source to the jaw is 40cm, not 50cm;
% So scale the DPMIN.ClmCorner[1-3].

%JC Jan 04 2006
% According to Virgil's suggestions, use 1.15 as cutoff between Water and
% Bone, instead of 0.5*(Bone+Water) == 1.425

%JC Jan 30 2007
% Turn on FF calc.

% LM: JC Mar 26, 2007
% Add more variables in DPMIN: DoseNormFlag, HornCoef, OpenField.

% LM: JC Aug 06 2007
% Add "Softening" flag in DPMIN, default == 1
% Remove scaling of the dose by "sum(spectrum(:2))" for SourceModel == 0;
% thus no scaling of the dose.


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
    j = find(strcmpi({planC{indexS.structures}.structureName}, 'External'));
end

if isempty(j)
    error('Skin/Body/External structure must be defined to input to DPM.');
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

if fillWater   % Assign everything of skinMask to water
    scan = 1000*ones(size(scan));
end

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

scan = double(scan)/1000;
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

% %Number of materials:
% % 5
% %Material densities (g/cm^3), in the order corresponding to PENELOPE .geo file:
% % 1.00        Water
% % 0.3         LungICRP
% % 1.85        CorticalBone
% % 2.6989      Al
% % 4.54        Ti

% % % % According to the density value, get the material number.
% % % Lung = 0.3                          % #2
% % % Water = 1.0                         % #1
% % % Bone = 1.85                         % #3
% % % Al = 2.6989                         % #4
% % % Ti = 4.54                           % #5
% % % 
% % % CTscan.material(CTscan.density < 0.5*(Lung+Water)) = 2;
% % % % According to Virgil's suggestions, use 1.15 as cutoff between Water and
% % % % Bone, instead of 0.5*(Bone+Water) == 1.425
% % % %CTscan.material(0.5*(Lung+Water) <= CTscan.density  & CTscan.density < 0.5*(Water+Bone)) = 1;
% % % %CTscan.material(0.5*(Water+Bone) <= CTscan.density & CTscan.density < 0.5*(Bone+Al)) = 3;
% % % CTscan.material(0.5*(Lung+Water) <= CTscan.density  & CTscan.density < 1.15) = 1;
% % % CTscan.material(1.15 <= CTscan.density & CTscan.density < 0.5*(Bone+Al)) = 3;
% % % CTscan.material(0.5*(Bone+Al) <= CTscan.density & CTscan.density < 0.5*(Al+Ti)) = 4;
% % % CTscan.material(0.5*(Al+Ti)<= CTscan.density) = 5;
% For now
load materialMap materialMap
[CTscan.material materialNames] = generateMaterialMap(CTscan.density, materialMap);

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
    'MinCTscanCorner', [0 0 0], ...          % minimum [x y z] of the interested field
    'MaxCTscanCorner', [20 10 15], ...       % maximum [x y z] of the interested field
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
    'UsePhotSpectrum', 1, ...            % If it's 1, use DPMIN.PhotSpectrum; if it's 0, use "BinEnergy".
    'UseFlatFilter', 0, ...              % If it's 1, use FlatFilter.
    'FlatFilterA', -0.213, ...           % Coefficient A, to determine the distribution of particles on FlatFilter
    'FlatFilterB', -0.1, ...             % Coefficient B, to determine the distribution of particles on FlatFilter
    'FlatFilterDist', 9.5, ...           % The distance from the source/target to the FlatFilter, cm
    'IsoDistance', 100, ...              % Iso Distance, in cm
    'IncreaseFluence', 0, ...            % How rapid to increase fluence when off-axis angle increase.
    'OnlyHorn', 0, ...                   % Only model the "Horn" effect, used when commissioning.
    'DoseNormFlag', 1, ...               % 1:Use # of succesfully sampled particles to normalize dose;
    ...  % 2:Use # of total sampled particles to normalize dose;
    'HornCoef', [1.0 0; 9.9253e-01   4.3309e-02; 9.8507e-01   4.8225e-02;   9.7761e-01   4.7987e-02;  9.7014e-01   4.7750e-02], ...
    ... % Use lateral dose profile as the increase of fluence.
    'OpenField', 0, ...                  % OpenField == 0; Don't sample isotropic source. 'uniformly' sample 
    'Softening', 1, ...                   % Softening == 0; Don't use off-axi-softening.
    'maxSampleAngle', 0.36, ...                   % For OpenField (==1), the max sampling angle for primary source.
    'maxSampleAngleFF', 0.245 ...                   % For OpenField (==1), the max sampling angle for FF source.
        );             

% Above is from "initIMRTProblem.m".

% Loop for every beam.
beamletCount = 1;

%for beamIndex=1:numBeams,
%for beamIndex=1:1,
beamIndex = 1;

% Initialize DPMIN struct
DPMIN = IM.params.DPM;

DPMIN.NumParticles = 10000000;
DPMIN.AlctTime = IM.params.DPM.AlctTime;
%DPMIN.ParticleType = IM.params.DPM.ParticleType;
DPMIN.ParticleType = 0;
% Dec 04, 2006
% No need to convert from MeV to eV
%DPMIN.SourceEnergy = IM.beams(beamIndex).beamEnergy*1000000; %MeV->eV
DPMIN.SourceEnergy = IM.beams(beamIndex).beamEnergy;
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
    disp('Can not Open photon spectrum file for the primary source');
end
tline = fgetl(fid);
tline = fgetl(fid);
photon_spectrum = fscanf(fid,'%g %g',[2 inf]); % It has two rows now.
PhotSpectrumPrimary = photon_spectrum';
DPMIN.PhotSpectrum = PhotSpectrumPrimary;
fclose(fid);

if (sourceModel == 1)  % Use source model, version 1.
    % Get the photon spectrum file for the Flatteing Filter.
    % Get the correct filename
    inds = max(strfind(Energy, '.'));
    fid = fopen([Energy(1:inds-1), '_FF', Energy(inds:end)]);
    if (fid == -1),
        disp('Can not Open photon spectrum file for the flattening filter');
    end
    tline = fgetl(fid);
    tline = fgetl(fid);
    photon_spectrum = fscanf(fid,'%g %g',[2 inf]); % It has two rows now.
    PhotSpectrumFF = photon_spectrum';

    % Get all the other parameters for the whole source model
    % Fluence weight of Flattening Filter, Horn, and Electron contamination
    inds = max(strfind(Energy, '.'));
    fid = fopen([Energy(1:inds-1), '_Params', Energy(inds:end)]);
    if (fid == -1),
        disp('Can not Open photon spectrum file for the flattening filter');
    end
    tline = fgetl(fid);
    tline = fgetl(fid);
    SourceModelParams = fscanf(fid,'%g',[1 inf]); % It has two rows now.

    % Oct 26, 2007
    % Add the "CosHorn
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
    cosOffAxisAngle = IM.beams.isodistance ./ ...
        (sqrt((IM.beams.RTOGPBVectorsM_MC(:,1).^2 +IM.beams.RTOGPBVectorsM_MC(:,2).^2+ IM.beams.RTOGPBVectorsM_MC(:,3).^2)));
    Horn = interp1(CosHorn(:,1), CosHorn(:,2), cosOffAxisAngle, 'linear');

end
    
    
DPMIN.OutputError = IM.params(beamIndex).DPM.OutputError;
DPMIN.IsoVector = IM.params.DPM.IsoVector;
DPMIN.BinEnergy = IM.params.DPM.BinEnergy;
DPMIN.UsePhotSpectrum = IM.params.DPM.UsePhotSpectrum;
%JC Feb 09 2005. Make sure OutputError is changed based on input.
DPMIN.OutputError = OutputError;
%JC Nov 16, 2006, Use the most up-to-date DPM.
% Add more input to DPMIN.
DPMIN.UseFlatFilter = IM.params.DPM.UseFlatFilter;          % If it's 1, use FlatFilter, Liu; 2, use Jiang. (3 Gaussian)

% Define the FlatFilter Parameters based on the Source Energy
% If 6MV: -0.213 -0.1 9.5

if (DPMIN.SourceEnergy == 6)
    DPMIN.FlatFilterA = -0.213;              % Coefficient A, to determine the distribution of particles on FlatFilter
    DPMIN.FlatFilterB = -0.1;               % Coefficient B, to determine the distribution of particles on FlatFilter
    DPMIN.FlatFilterDist = 9.5;        % The distance from the source/target to the FlatFilter, cm
    % If 18MV: -0.774 -0.00508 9.5
elseif (DPMIN.SourceEnergy == 18)
    DPMIN.FlatFilterA = -0.774;              % Coefficient A, to determine the distribution of particles on FlatFilter
    DPMIN.FlatFilterB = -0.00508;               % Coefficient B, to determine the distribution of particles on FlatFilter
    DPMIN.FlatFilterDist = 9.5;        % The distance from the source/target to the FlatFilter, cm
else
    DPMIN.FlatFilterA = -0.213;              % Coefficient A, to determine the distribution of particles on FlatFilter
    DPMIN.FlatFilterB = -0.1;               % Coefficient B, to determine the distribution of particles on FlatFilter
    DPMIN.FlatFilterDist = 9.5;        % The distance from the source/target to the FlatFilter, cm
    warndlg('BE AWARE! Beam Energy is not 6MV or 18MV, using settings for 6MV for flatteing filter')
end

DPMIN.IsoDistance = IM.params.DPM.IsoDistance';             % Iso Distance, in cm
DPMIN.IncreaseFluence = IM.params.DPM.IncreaseFluence;      % How rapid to increase fluence when off-axis angle increase.
DPMIN.OnlyHorn = IM.params.DPM.OnlyHorn;                    % Only model the "Horn" effect, used when commissioning.
DPMIN.DoseNormFlag = IM.params.DPM.DoseNormFlag;               % 1:Use # of succesfully sampled particles to normalize dose;
DPMIN.HornCoef = IM.params.DPM.HornCoef;
DPMIN.OpenField = IM.params.DPM.OpenField;

% Aug 06, 2007 
DPMIN.Softening = Softening;
    'maxSampleAngle', 0.36, ...                   % For OpenField (==1), the max sampling angle for primary source.
    'maxSampleAngleFF', 0.245 ...                   % For OpenField (==1), the max sampling angle for FF source.

% IM.beams(beamIndex).x is the x coordinate of the beam source.
% IM.beams.RTOGPBVectorsM_MC are the vectors from the source to the center
% of every pencil beam on the plane of the isocenter.
% So pb(:,1:3) are the locations of the center of every pencile beam on the
% plane passing the isocenter.

%nhist_time = zeros(2, length(IM.beams(beamIndex).beamletDelta_x));
rand('state',sum(100*clock));

%currentDIR=pwd;
%cd(DPMPath);
if(exist('local')~= 7)
    dos('mkdir local')
end

%h = waitbar(0,['Generating Monte Carlo Dose for Beam ',num2str(indBeam)]);




% JC Mar 29, 2007
if (useWedge == 1)
%Energy       mu over rho        mu e n over rho 
%      (MeV)      (cm2/g)     (cm2/g)
%____________________________________
 [wedge_data wedge_density] = wedge();
 [rayWedgeLength] = rayWedgeIntersect(IM, 1, 18.6);
end   
attenuation = ones(size(IM.beams.beamletDelta_x)); 


% Since this function is called by DPMpc*OneBeam*.m, so IM always has
% one beams field.

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
    DPMIN.RandSeeds = rand(1,2)*1000;

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

    %% JC Nov 27 2006
    %% Use 0.4 instead of 0.5 to scale.

    corner1 = [coll3V(i,1)-0.5*dx   coll3V(i,2)-0.5*dy      coll3V(i,3)];
    corner2 = [coll3V(i,1)+0.5*dx   coll3V(i,2)-0.5*dy      coll3V(i,3)];
    corner3 = [coll3V(i,1)+0.5*dx   coll3V(i,2)+0.5*dy      coll3V(i,3)];
    %   project back towards the plane 40cm from the source
    corner1_new = corner1/IsDist*40;
    corner2_new = corner2/IsDist*40;
    corner3_new = corner3/IsDist*40;


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

    % run DPM for the primary photon spectrum
    DPMIN.ParticleType = 0;
    DPMIN.NumParticles = nhist*dx*dy;
    DPMIN.Prefix = 'pre4phot';
    DPMIN.PhotSpectrum = PhotSpectrumPrimary;
   
    % Mar 31, 2007

    if (useWedge ==1) 
     mu_en = interp1(wedge_data(:,1), wedge_data(:,2), PhotSpectrumPrimary(:,1));
     % figure; loglog(softPhotSpectrumPrimary(:,1),mu_en, '.');
     % hold on; loglog(wedge_data(:,1), wedge_data(:,2), '+r');
     sampledAttenuation = exp(-rayWedgeLength(i).*mu_en.*wedge_density);
     %figure; plot(PhotSpectrumPrimary(:,1), sampledAttenuation);
     attenSpectrum = sampledAttenuation.*(PhotSpectrumPrimary(:,2)/sum(PhotSpectrumPrimary(:,2)));
     attenuation(i) = sum(attenSpectrum);
     DPMIN.PhotSpectrum = [PhotSpectrumPrimary(:,1) attenSpectrum];
     end
    
 % The current approach should be: Modify the spectrum for each beamlet,
 % based on the rayWedgeLength.
 % And the scale the total dose by the attentuation.
 
    DPMIN.UseFlatFilter = 0;
	% Assigin the default numbers, to keep the input to DPM consistent.
    DPMIN.FlatFilterA = -0.213;              % Coefficient A, to determine the distribution of particles on FlatFilter
    DPMIN.FlatFilterB = -0.1;               % Coefficient B, to determine the distribution of particles on FlatFilterDPMIN.OnlyHorn = 0;
    DPMIN.RandSeeds = [rand*1000 rand*10000];
    tic; [dosePrimary sampleParticles] = dpm(DPMIN, CTscan);

    if (sourceModel ==1)    % Use source model, version 1.

        % run DPM for the Horn effect; Use the Primary Photon Spectrum
        % Will Apply Horn into the fluence map, i.e. PB weight: w_field.
        % Not Applicable here.
        %     DPMIN.OnlyHorn = 1;
        %     DPMIN.NumParticles = nhist*dx*dy*SourceModelParams(7);
        %     DPMIN.RandSeeds = [rand*1000 rand*10000];
        %     doseHorn = dpm(DPMIN, CTscan);

        % run DPM for the flattening filter spectrum
        DPMIN.OnlyHorn = 0;
        DPMIN.UseFlatFilter = UseFlatFilter;
		if (UseFlatFilter == 2 & DPMIN.SourceEnergy == 6)
			DPMIN.FlatFilterA = [0.0332 0.0517 0.032];
			DPMIN.FlatFilterB = [0.65 1.33 4.52];
		% Need to add other combinations of SourceEnergy and UseFlatFilter.
		end
			
			
        DPMIN.NumParticles = nhist*dx*dy*SourceModelParams(6);
        DPMIN.RandSeeds = [rand*1000 rand*10000];
        DPMIN.PhotSpectrum = PhotSpectrumFF;
        [doseFF sampleParticles]  = dpm(DPMIN, CTscan);

        if (SourceModelParams(8) > 0.005) %If the relative fluence of electron contamination is less than 0.5%, then call DPM for electron.
            DPMIN.ParticleType = -1;
            DPMIN.Prefix = 'pre4elec';
            DPMIN.UseFlatFilter = 0;
            DPMIN.NumParticles = nhist*dx*dy*SourceModelParams(8);
            [doseElec  sampleParticles]= dpm(DPMIN, CTscan);
        else
            doseElec= zeros(size(dosePrimary));
        end

        toc
        % Sum different components of dose up.
% JC Sept 20. 2007
% Remove the scaling of the dose by "sum(PhotSpectrumPrimary(:,2))"
%        doseV = sum(PhotSpectrumPrimary(:,2))* ...
%            (dosePrimary*(1+Horn(i)) + SourceModelParams(6)*doseFF + SourceModelParams(8)*doseElec);
       doseV = dosePrimary*(1+Horn(i)) + SourceModelParams(6)*doseFF + SourceModelParams(8)*doseElec;

    else  % No source model, only primary source.
        % Aug 06, 2007, DO NOT scale the dose.
        % doseV = dosePrimary*sum(PhotSpectrumPrimary(:,2));
        doseV = dosePrimary;
    end
    
    % JC Mar 29, 2007, add wedge
    if (useWedge == 1)
        doseV = attenuation(i)*doseV;
    end
      

    % Scale Dose, since DPM outputs dose/particle
    % How to deal with the Error ? Since it's STD, so should not be scaled.
    % When output Error, doseV is nx2 matrix. Need not to be scaled
    doseV(:,1) = doseV(:,1) * dx * dy;

    if (i == 1)
        doseV_SUM = doseV * w_field (i);
    else
        doseV_SUM = doseV_SUM + doseV * w_field(i);
    end

    
   % Do not apply w_field here.
    if(DPMIN.OutputError == 1)
        Error =  dosePrimary(:, 2);
        dosePrimary =  dosePrimary(:, 1);

        if (sourceModel == 1)

            ErrorFF =  doseFF(:, 2);
            doseFF =  doseFF(:, 1);

            ErrorElec =  doseElec(:, 2);
            doseElec =  doseElec(:, 1);

        end

    end

    if (saveIM == 1)
        % z changes first, then y, then x
        % Aug 07, 2007 Compress doseV instead of dosePrimary. Do not apply
        % w_Field here.
        doseV = applyIMRTCompression(IM.params, doseV);
        beamlet = createIMBeamlet(doseV, indV', beamIndex, 0);
        

        %  JC Dec 2007
        %  Add the field "beamletPrimary" in IM struct. For the calibration of
        %       Horn coefficients.
        %       Here, all the dose/fluence components are "un-touched", means not
        %       scaled by any factor.

        if (sourceModel == 1)
            % To get the dose in the units of dose/particle
            dosePrimary = applyIMRTCompression(IM.params, (dx*dy)*dosePrimary);
            beamletPrimary = createIMBeamlet(dosePrimary, indV', beamIndex, 0);
            clear dosePrimary
            
            doseFF = applyIMRTCompression(IM.params, (dx*dy)*doseFF);
            beamletFF = createIMBeamlet(doseFF, indV', beamIndex, 0);
            clear doseFF
            
            doseElec = applyIMRTCompression(IM.params, dx*dy*doseElec);
            beamletElec = createIMBeamlet(doseElec, indV', beamIndex, 0);
            clear doseElec
        end

        if(DPMIN.OutputError == 1)
            Error = applyIMRTCompression(IM.params, Error);
            Error = createIMBeamlet(Error, indV', beamIndex, 0);
            if (sourceModel ==1)
                ErrorFF = applyIMRTCompression(IM.params, ErrorFF);
                ErrorFF = createIMBeamlet(ErrorFF, indV', beamIndex, 0);
                ErrorElec = applyIMRTCompression(IM.params, ErrorElec);
                ErrorElec = createIMBeamlet(ErrorElec, indV', beamIndex, 0);
            end
        end
        % Need to transpose either doseV or indV, because their dimensions
        % don't match.


        % 14 Aug 05 JC
        % Do not use dissimilarInsert, where "setfield" is called, which causes
        % problem with mcc.
        %    IM.beamlets = dissimilarInsert(IM.beamlets, beamlet, beamletCount);
        % Add "beamlet" to IM.beamlets directory. When beamletCount == 1,
        % IM.beamlets = []; all beamlet structs have the same fields/order.
        if(beamletCount == 1)
            IM.beamlets = beamlet;
            if (sourceModel == 1)
            %  JC Dec 2007
            %  Add the field "beamletPrimary" in IM struct. For the calibration of
                IM.beamletsPrimary(beamletCount) = beamletPrimary;
                IM.beamletsFF(beamletCount) = beamletFF;
                IM.beamletsElec(beamletCount) = beamletElec;
            end
            if(DPMIN.OutputError == 1)
                IM.Errors = struct;
                IM.Errors = Error;

                if (sourceModel == 1)
                    IM.ErrorsFF = struct;
                    IM.ErrorsFF = ErrorFF;

                    IM.ErrorsElec = struct;
                    IM.ErrorsElec = ErrorElec;
                end
            end
        else
            IM.beamlets(beamletCount) = beamlet;
            if (sourceModel == 1)
                IM.beamletsPrimary(beamletCount) = beamletPrimary;
                IM.beamletsFF(beamletCount) = beamletFF;
                IM.beamletsElec(beamletCount) = beamletElec;
            end
            if(DPMIN.OutputError == 1)
                IM.Errors(beamletCount) = Error;
                if (sourceModel == 1)
                    IM.ErrorsFF(beamletCount) = ErrorFF;
                    IM.ErrorsElec(beamletCount) = ErrorElec;
                end
            end

        end

    end
    beamletCount = beamletCount + 1;


end

%waitbar(i/length(IM.beams.beamletDelta_x));
% filename = ['IM_',num2str(indBeam),'_', num2str(nhist)];
% save(filename, 'IM');

end

%close(h);

%cd(currentDIR);
