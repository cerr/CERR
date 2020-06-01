function IM = generateVMCInfluence(IM, structROIV, sampleRateV)
%"generateVMCInfluence"
%   Uses the VMC++ MC engine to populate the beamlet fields of an IM structure.
%   StructROIV is the list of structures, sampleRateV is a vector of sample
%   rates, one for each structROIV.
%   The doses are stored in sparse format.
%   The stored index is with respect to the structure mask registered to the
%   uniformized CT scan.
%
%
%      Rewrite June 06, JOD, to be a 'drop-in' alternative to the pencil
%      beam calculations.
%
%      Based on code by P. Lindsay, J. Alaly, and J. Deasy
%
%      Last modified: JJW, 21 June 2006
%                     JJW, 26 June 2006
%                     JC,  12 July 2006
%                           Implement to use 'IM.params.cutoffDistance'.
%                           Remove the assumption of SID = 100 cm.
%           JC, 26 Feb 2007
%               Fix bug, "the dose was shifted by one voxel". to.
%               offset(1:2)=offset(1:2)+yres/2;
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

%  Flow:
%
%  Loop over beams
%    Loop over beamlets
%      Get MC2CT beamlet matrix.
%      Loop over structures
%            Get infl contribution from that beamlet to that structure
%                at that sample rate.
%            Store
%      end structure loop
%    End beamlet loop
%  End beam loop

%This is a different organizational structure compared to the PB generate influence
%flow.  In particular, we loop over beams first, not structures, because the MC
%calculation is always done to the entire CT matrix, and it is by far the slowest
%computation.


%==========Set up MC params=======================%


global planC
global stateS
indexS=planC{end};

%obtain associated scanNum for structures. It is assumed that all the
%structures are associated to same scan (which is checked in IMRTP.m)
scanNum = getStructureAssociatedScan(structROIV(1));

numBeams = length(IM.beams);

IMRTPGui('statusbar', 'Preparing VMC++ calculation');
percentDone = 0;
IMRTPGui('waitbar', percentDone);

%Create all path parameters.
IMRTPdir = fileparts(which('IMRTP'));
VMCPath         = fullfile(IMRTPdir , 'vmc++', '');
runsPath        = fullfile(VMCPath, 'runs', '')
phantomPath     = fullfile('.', 'phantoms', '');
energyPath      = fullfile('.', 'spectra', '');

%Create phantom default filename.
phantomFilename = fullfile(phantomPath, 'CERR_IMRT.ct');

%Set environment variables for PC.  Unix set at runtime.
if ispc
    dos(['"' fullfile(VMCPath, 'setx" ') 'vmc_home "' VMCPath '" -m']);
    dos(['"' fullfile(VMCPath, 'setx" ') 'vmc_dir "' runsPath '" -m']);
    dos(['"' fullfile(VMCPath, 'setx" ') 'xvmc_dir "' VMCPath '" -m']);

    [jnk, out1] = dos('set vmc_home');
    [jnk, out2] = dos('set vmc_dir');
    [jnk, out3] = dos('set xvmc_dir');

    %(1:end-1) to avoid CR at end of output1-3.
    if ~strcmpi(out1(1:end-1), ['vmc_home=' VMCPath]) | ~strcmpi(out2(1:end-1), ['vmc_dir=' runsPath ]) | ~strcmpi(out3(1:end-1), ['xvmc_dir=' VMCPath])
        error('Environment Variables were not properly set for VMC++.  CERR has set them--please restart Matlab and begin the calculation again.');
    end
end

%Calculation will be based on the resolution of uniformized CT dataset.
currDir = cd;
cd(VMCPath);
fillWater = 0;
[offset, bbox] = generateCT_uniform(getUniformizedCTScan(0,scanNum), phantomFilename, scanNum, fillWater);
cd(currDir);

scandr = bbox(2) - bbox(1) + 1;
scandc = bbox(4) - bbox(3) + 1;
scands = bbox(6) - bbox(5) + 1;

%Get x,y,z resolution.
[xV, yV, zV] = getUniformScanXYZVals(planC{indexS.scan}(scanNum));
xres = abs(xV(2) - xV(1));
yres = abs(yV(2) - yV(1));
zres = abs(zV(2) - zV(1));

%Left hand side versus centre of each voxel
offset(1:2)=offset(1:2)-yres/2;
% This is the fix, as in <generateCT_uniform.m> %THIS IS THE FIX::: Y=Y(end:-1:1);
offset(1:2)=offset(1:2)+yres/2;
offset(3:4)=offset(3:4)-xres/2;
offset(5:6)=offset(5:6)-zres/2;

%Setup the options for the VMC++ input.
VMCOpt = VMCOptInit;
phantomFilename(strfind(phantomFilename, '\')) = '/'; %VMC requires '/'.
VMCOpt.startGeometry.startXYZGeometry.phantomFile=phantomFilename;

%Set options from IM.params.VMC
VMCOpt.startMCControl.NCase                     = IM.params.VMC.NumParticles;
VMCOpt.startMCControl.NBatch                    = IM.params.VMC.NumBatches;
VMCOpt.startScoring.startDoseOptions.scoreDoseToWater = IM.params.VMC.scoreDoseToWater;
VMCOpt.startBeamletSource.monoEnergy            = IM.params.VMC.monoEnergy;
VMCOpt.startVarianceReduction.repeatHistory     = IM.params.VMC.repeatHistory;
VMCOpt.startVarianceReduction.splitPhotons      = IM.params.VMC.splitPhotons;
VMCOpt.startVarianceReduction.photonSplitFactor = IM.params.VMC.photonSplitFactor;
VMCOpt.startQuasi.base                          = IM.params.VMC.base;
VMCOpt.startQuasi.dimension                     = IM.params.VMC.dimension;
VMCOpt.startQuasi.skip                          = IM.params.VMC.skip;
switch lower(IM.params.VMC.includeError)
    case 'yes'
        VMCOpt.startScoring.startOutputOptions.dumpDose = 1;
    case 'no'
        VMCOpt.startScoring.startOutputOptions.dumpDose = 2;
    otherwise
        error('Invalid value for includeError property.');
end


% Precalc voxel indices for all structures
scanIndV=cell(max(structROIV),1);
for i = 1 : length(structROIV)
    if sampleRateV(i) ~= 1
        %Ensures that interpolative downsampling won't miss edge points:
        maskSingle3D = getSurfaceExpand(structROIV(i),0.5,1);
        if rem(log2(sampleRateV(i)),1) ~= 0
            error('Sample factor must (currently) be a power of 2.')
        end
        maskSample3D = getDown3Mask(maskSingle3D, sampleRateV(i), 1);
        %Get a mask of where to sample points
        tmpM = logical(maskSample3D) & maskSingle3D;
        clear maskSample3D maskSingle3D;
    else
        tmpM = getUniformStr(structROIV(i));
    end
    scanIndV{i} = find(tmpM);  %Indices with respect to the uniformized scan.
    clear tmpM
end


%===========Loop over beams=============%

% To generate independent datasets, need to set
% VMCOpt.startQuasi.skip to skip the numbers of histories
% used in previous calculations

beamletCounter = 1;  %Keep up with how many beamlets have been computed.
errorBeamlets = [];

for beamIndex=1:numBeams

    pb(:,1)=IM.beams(beamIndex).RTOGPBVectorsM_MC(:,1)+IM.beams(beamIndex).x;
    pb(:,2)=IM.beams(beamIndex).RTOGPBVectorsM_MC(:,2)+IM.beams(beamIndex).y;
    pb(:,3)=IM.beams(beamIndex).RTOGPBVectorsM_MC(:,3)+IM.beams(beamIndex).z;

    dx=IM.beams(beamIndex).beamletDelta_x;
    dy=IM.beams(beamIndex).beamletDelta_y;

    IC=[IM.beams(beamIndex).isocenter.x IM.beams(beamIndex).isocenter.y  IM.beams(beamIndex).isocenter.z];
    th=IM.beams(beamIndex).gantryAngle*pi/180;

    M=[cos(th) sin(th) 0; -sin(th) cos(th) 0; 0 0 1];
    Minv=[cos(th) -sin(th) 0; sin(th) cos(th) 0; 0 0 1];

    % translate to IC frame of reference
    pb=pb-repmat(IC, [length(pb), 1]);

    % anti rotate (i.e., to gantry angle of 0)
    pb=(Minv*pb')';

    % assuming SID=100
    % back project beams up by -50 cm
    %     s1=0.5;
    %     s2=50;
    %     s3=s1*0.5;
    % take SID from the IM struct. back project beams up by -50 cm
    s2 = 50;
    s1 = s2/IM.beams(beamIndex).isodistance;
    s3 = s1 * s1;

    pb(:,[1 3])=pb(:, [1 3])*s1;
    pb(:,2)=pb(:,2)+s2;

    for i=1:length(pb),
        pb_new{i}=[pb(i, 1)+dx*s3, pb(i, 2),  pb(i, 3)+dy*s3
            pb(i, 1)-dx*s3,  pb(i, 2),  pb(i, 3)+dy*s3
            pb(i, 1)-dx*s3,  pb(i, 2),  pb(i, 3)-dy*s3];
    end

    % rotate by the gantry angle
    for i=1:length(pb),
        pb_rot{i}=(M*pb_new{i}')' + repmat(IC, [3 1]);
    end

    % include the offset from the CT image
    virtualSource=[IM.beams(beamIndex).x-offset(3), offset(2)-IM.beams(beamIndex).y, IM.beams(beamIndex).z-offset(5)];

    IC=[IC(1)-offset(3) offset(2)-IC(2) IC(3)-offset(5)];

    for i=1:length(pb),
        pb_rot{i}=pb_rot{i}-repmat([offset(3) 0 offset(5)], [3 1]);
        pb_rot{i}(:,2)=offset(2)-pb_rot{i}(:,2);
    end

    % rounding because VMC++ requires the edges of the beamlet form
    % a square, by testing the dot product      %PUT error function here??
    for i=1:length(pb),
        temp=pb_rot{i};
        pb_rot{i}(:,1)=temp(:,2);
        pb_rot{i}(:,2)=temp(:,1);
        pb_rot{i}=round(pb_rot{i}*100000)/100000;
    end

    VMCOpt.startBeamletSource.virtualPointSourcePosition = [virtualSource(2) virtualSource(1) virtualSource(3)];


    %Write .vmc files for each pencil beam.
    for i=1:length(pb_rot),

        %Set beam spectrum file.
        switch IM.beams(beamIndex).beamEnergy
            case 6
                energyFile = fullfile(energyPath, 'var_6MV.spectrum');
            case 18
                energyFile = fullfile(energyPath, 'var_18MV.spectrum');
            otherwise
                error('Invalid beam energy.'); %Eventually add custom beamEnergy files here.
        end

        %if a spectrum was entered in the GUI, use this one instead
        if ~strcmp(IM.params.VMC.spectrum,'') && ~isempty(IM.params.VMC.spectrum)
            if exist(fullfile(VMCPath,'spectra',IM.params.VMC.spectrum), 'file') == 2
                energyFile = fullfile(energyPath,IM.params.VMC.spectrum);
            else
                fprintf('\nERROR: Spectrum %s does not exist!\n\n',fullfile(VMCPath,'spectra',IM.params.VMC.spectrum));
                return
            end
        end

        energyFile(strfind(energyFile, '\')) = '/'; %Must use '/' instead of '\' for VMC.

        VMCOpt.startBeamletSource.spectrum = energyFile;

        switch lower(IM.beams(beamIndex).beamModality)
            case 'photons'
                VMCOpt.startBeamletSource.charge = 0;
            case 'electrons'
                VMCOpt.startBeamletSource.charge = -1;
            otherwise
                error('Invalid beamModality.');
        end

        %Create different rands 1:30000 for each PB.
        VMCOpt.startMCControl.RNGSeeds = [round(rand*30000)+1 round(rand*30000)+1];

        %Set pencil beam edges.
        VMCOpt.startBeamletSource.beamletEdges= [pb_rot{i}(1, :), pb_rot{i}(2,:),pb_rot{i}(3, :)];

        %Write .vmc file.
        outfile=['MCpencilbeam_', int2str(beamIndex), '_', int2str(i), '.vmc'];
        VMCInputC = makeVMCInput(VMCOpt, fullfile(runsPath, outfile));
    end

    npb = length(pb_rot);

    clear pb pb_new pb_rot

    switch VMCOpt.startScoring.startOutputOptions.dumpDose
        case 1
            precision = 4;
        case 2
            precision = 2;
        otherwise
            error('Incorrect value for dumpDose in VMCOpt. Try 1 or 2.')
    end

    indV = 1:(scandr*scandc*scands);
    [r,c,s] = ind2sub([scandr,scandc,scands], indV);
    r = r + bbox(1) - 1;
    c = c + bbox(3) - 1;
    s = s + bbox(5) - 1;
    indV = sub2ind(getUniformizedSize(planC), r, c, s);
    clear r c s

    % Added by JC July 11, 2006
    % Used later in chop doseV/doseM off by 'IM.params.cutoffDistance'
    [xM yM zM] = meshgrid(xV, yV, zV);
    pM = [xM(indV)', yM(indV)', zM(indV)'];
    clear xM yM zM
    sourceM = repmat([IM.beams(beamIndex).x, IM.beams(beamIndex).y, IM.beams(beamIndex).z], length(pM), 1);
    pRelM = pM - sourceM;


    %=========Loop over beamlets=============%
    for i=1:npb

        if i > 1
            disp(['Computed ' int2str(i-1) ' out of ' num2str(npb)]); pause(0.003);
            try
                IMRTPGui('status', beamIndex, numBeams, ' CT scan ', i - 1, npb);
            end
        end


        outfile=['MCpencilbeam_', int2str(beamIndex), '_', int2str(i)];
        if ispc
            currPath = cd;
            cd(VMCPath);
            dos(['start /low /B /wait ' fullfile('.', 'bin', 'vmc_Windows.exe') ' ' outfile '']);

            %if exist('VMCOpt.denoising')
            %  if strcmpi(VMCOpt.denoising,'yes')
            %    niter=2;
            %    cerror=0.05;
            %    str=fullfile(VMCPath, 'runs', [outfile '_' VMCOpt.startScoring.startDoseOptions.scoreInGeometries '.dos'])
            %    dose = readDoseFile(fullfile(VMCPath, 'runs', [outfile '_' VMCOpt.startScoring.startDoseOptions.scoreInGeometries '.dos']), precision, scandr, scandc, scands);
            %    dose = reshape(dose, [scandr, scandc, scands]);
            %    maxValue = max(dose(:));
            %    mask = dose < (IM.params.Scatter.Threshold * maxValue);
            %%    lowDoses = zeros(size(dose));
            %    lowDoses(mask) = dose(mask);
            %    dose(mask) = 0;
            %    smoothLowDoses=anisodiff3d_miao(lowDoses, cerror, niter);  %denoising via anisotropic diffusion.
            %      clear mask
            %      clear lowDoses
            %    dose  = dose + smoothLowDoses;
            %    doseV = dose(:);
            %  end
            %end
            doseV = readDoseFile(fullfile('.', 'runs', [outfile '_' VMCOpt.startScoring.startDoseOptions.scoreInGeometries '.dos']), precision, scandr, scandc, scands);

        elseif isunix
            currPath = cd;
            cd(VMCPath);
            dos(['chmod u+x ' fullfile(VMCPath, 'vmc_wrapper')]);
            dos(['chmod u+x ' fullfile(VMCPath, 'bin', 'vmc_Linux.exe')]);
            dos(['dos2unix ' fullfile(VMCPath, 'vmc_wrapper')]); % to make sure endOfLine characters are correct
            dos([fullfile(VMCPath,'vmc_wrapper') ' ' VMCPath ' ' runsPath ' ' VMCPath ' ' fullfile(VMCPath, 'bin', 'vmc_Linux.exe') ' ' outfile]);
            doseV = readDoseFile(fullfile(VMCPath, 'runs', [outfile '_' VMCOpt.startScoring.startDoseOptions.scoreInGeometries '.dos']), precision, scandr, scandc, scands);

        end
        cd(currPath);

        % Added by JC July 11, 2006
        % Used later in chop doseV/doseM off by 'IM.params.cutoffDistance'
        RTOGPBVectorsM = IM.beams(beamIndex).RTOGPBVectorsM;
        PBV = RTOGPBVectorsM(i,:);
        distV = pRelM * PBV';    %Each row is the dot product of (the un-normalized) source-to-calc point
        %direction and the PB unit vector.
        %Hence, this is the distance along the PB ray line for each dose calc point.

        qM = sourceM + distV * PBV;  %The last term gives the vector i, j, and k components of
        clear distV
        %distance to the depth of closest approach.
        %Each row of sourceM is the i,j,k position of the source.
        %So vector sum locates the positions of closest approach
        %to the dose calc points.

        rM  = pM - qM;    %Each row of pM is the x, y, z location of a dose calc point.
        clear qM
        %rM is then the vector pointing from the dose calc point to the point
        %at which the PB vector makes closest approach.

        %Trap points which are too far away to need dose calcs
        %Uses sepsq if possible, much faster.
        try
            rDistVSquared = sepsq([0 0 0]', rM');  %mex file speedup
            goV = rDistVSquared < (IM.params.cutoffDistance^2);
        catch
            rDistV = (rM(:,1).^2 + rM(:,2).^2 + rM(:,3).^2);    %if mex not there
            goV = rDistV < IM.params.cutoffDistance^2;         %Mod by JOD to speedup, Dec 05.
        end

        % Cut off the dose by IM.params.cutoffDistance.
        doseV(~goV) = 0;
        clear goV rM

        % apply compression
        doseV = applyIMRTCompression(IM.params, doseV);

        % build 3D dose matrix
        doseM = zeros(getUniformScanSize(planC{indexS.scan}(scanNum)));
        if length(indV)==length(doseV)
            doseM(indV) = doseV;
        else
            errorBeamlets = [errorBeamlets beamletCounter];
        end

        %-----------Insert dose data into correct beamlet indices---------------------%
        for i = 1 : length(structROIV)

            beamlet = createIMBeamlet(doseM(scanIndV{i}), scanIndV{i}, beamIndex, 0);

            IM.beamlets(structROIV(i),beamletCounter)               = beamlet;
            IM.beamlets(structROIV(i),beamletCounter).structureName = planC{planC{end}.structures}(structROIV(i)).structureName;
            IM.beamlets(structROIV(i),beamletCounter).sampleRate    = sampleRateV(i);

        end
        beamletCounter = beamletCounter + 1;
    end
    IMRTPGui('status', beamIndex, numBeams, ' CT scan ', npb, npb);
end

if length(errorBeamlets)>0
    disp(' ');
    disp('Error in generateVMCInfluence.m!');
    disp('The following beamlets were set to 0:');
    disp(errorBeamlets);
end
