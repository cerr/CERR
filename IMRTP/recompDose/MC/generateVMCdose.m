function [doseV_SUM indV] = generateVMCdose(IM, planC, w_field, sourceModel, doseToWater, fillWater, saveIM)
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
%      Last modified:
%           JJW, 21 June 2006
%           JJW, 26 June 2006
%           JC, 12 July 2006
%               Implement to use 'IM.params.cutoffDistance'.
%               Remove the assumption of SID = 100 cm.
%           JC, 12 Oct 2006
%               Replace length(pb) by size(pb,1)
%               when size(pb) is 1 by 3, should return 1
%               instead of 3.
%           JC, 1 Feb 2007
%               Add input "sourceModel", to be consistent with <generateDPMdose5HornIM.m>.
%               sourceModel == 0 for now, not used.
%               usable in the future, for applying source Model.
%           JC, 2 Feb 2007
%               Add distinguished file identifier, to make vmc++ can run
%               multiple copies simutaneously.
%           JC, 07 Aug 2007
%               Add "saveIM" flag, to save beamlet, and compare with DPM.



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

indexS=planC{end};

numBeams = length(IM.beams);


percentDone = 0;

%Create all path parameters.
%CERRdir = fileparts(which('CERR'));
% since 'which' doesn't work properly after compiling.
% Hard code the path for now.
CERRdir = '/home/matlab/jcui/plancheck/CERR/';
VMCPath = fullfile(CERRdir , 'Extras/IMRTPBeta/vmc++', '');

% JC Oct 17, 2006 Unfinished
% In order to run multiple vmc++ simutaneously, use the path specfic to the
% process.
% [x pid]= unix('ps | grep matlab');
% z =find(pid ==' ');
% pid = pid(1:z(1));
%
% vmcPID = ['vmcPID', pid];
% unixmkdir (vmcPID);

runsPath        = fullfile(VMCPath, 'runs', '')
phantomPath     = fullfile('.', 'phantoms', '');
energyPath      = fullfile('.', 'spectra', '');

% Initialize RAND to a differnet state each time.
rand('state',sum(100*clock));
% Generate unique file identifier for this particular run
pid = rand*10000;

%Create phantom default filename.
%phantomFilename = fullfile(phantomPath, 'CERR_IMRT.ct');
% JC. June 04, 2006
% Make each ct file to have the different name, since there're multiple
% runs for different plans on the same system.
filename = ['VMC_phantom', int2str(pid), '.ct'];
phantomFilename = fullfile(phantomPath, filename);

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
[offset, bbox] = generateCT_uniform(getUniformizedCTScan(0,planC), phantomFilename, fillWater);
cd(currDir);

scandr = bbox(2) - bbox(1) + 1;
scandc = bbox(4) - bbox(3) + 1;
scands = bbox(6) - bbox(5) + 1;

%Get x,y,z resolution.
[xV, yV, zV] = getUniformizedXYZVals(planC);
xres = abs(xV(2) - xV(1));
yres = abs(yV(2) - yV(1));
zres = abs(zV(2) - zV(1));

%Left hand side versus centre of each voxel
%offset(1:2)=offset(1:2)-yres/2;
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


%===========Loop over beams=============%

% To generate independent datasets, need to set
% VMCOpt.startQuasi.skip to skip the numbers of histories
% used in previous calculations

beamletCounter = 1;  %Keep up with how many beamlets have been computed.
errorBeamlets = [];

if (sourceModel == 0)

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
        pb=pb-repmat(IC, [size(pb,1), 1]);

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

        % JC Aug 30. 2006
        % For IMRT plans,dx=IM.beams(beamIndex).beamletDelta_x; is a vector.
        for i=1:size(pb,1),
            pb_new{i}=[pb(i, 1)+dx(i)*s3, pb(i, 2),  pb(i, 3)+dy(i)*s3
                pb(i, 1)-dx(i)*s3,  pb(i, 2),  pb(i, 3)+dy(i)*s3
                pb(i, 1)-dx(i)*s3,  pb(i, 2),  pb(i, 3)-dy(i)*s3];
        end

        % rotate by the gantry angle
        for i=1:size(pb,1),
            pb_rot{i}=(M*pb_new{i}')' + repmat(IC, [3 1]);
        end

        % include the offset from the CT image
        virtualSource=[IM.beams(beamIndex).x-offset(3), offset(2)-IM.beams(beamIndex).y, IM.beams(beamIndex).z-offset(5)];

        IC=[IC(1)-offset(3) offset(2)-IC(2) IC(3)-offset(5)];

        for i=1:size(pb,1),
            pb_rot{i}=pb_rot{i}-repmat([offset(3) 0 offset(5)], [3 1]);
            pb_rot{i}(:,2)=offset(2)-pb_rot{i}(:,2);
        end

        % rounding because VMC++ requires the edges of the beamlet form
        % a square, by testing the dot product      %PUT error function here??
        for i=1:size(pb,1),
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
            outfile=['MCpencilbeam_', int2str(pid), '_', int2str(beamIndex), '_', int2str(i), '.vmc'];
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
            end


            outfile=['MCpencilbeam_', int2str(pid), '_', int2str(beamIndex), '_', int2str(i)];
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
                tic;
                dos([fullfile(VMCPath,'vmc_wrapper') ' ' VMCPath ' ' runsPath ' ' VMCPath ' ' fullfile(VMCPath, 'bin', 'vmc_Linux.exe') ' ' outfile]);
                toc
                doseV = readDoseFile(fullfile(VMCPath, 'runs', [outfile '_' VMCOpt.startScoring.startDoseOptions.scoreInGeometries '.dos']), precision, scandr, scandc, scands);
                % Need to clear the dose file.....
                dos(['rm ' fullfile(runsPath, [outfile, '_phantom.dos'])]);
                dos(['rm ' fullfile(runsPath, [outfile, '.vmc'])]);
            end
            cd(currPath);

            if (i == 1)
                doseV_SUM = doseV * w_field (i);
            else
                doseV_SUM = doseV_SUM + doseV * w_field(i);
            end

    if (saveIM == 1)
        % z changes first, then y, then x
        doseV = applyIMRTCompression(IM.params, doseV);
        beamlet = createIMBeamlet(doseV, indV', beamIndex, 0);

        if(beamletCounter == 1)
            IM.beamlets = beamlet;
        else
            IM.beamlets(beamletCounter) = beamlet;
        end

    end
    
            beamletCounter = beamletCounter + 1;
        end
    end

   
    if length(errorBeamlets)>0
        disp(' ');
        disp('Error in generateVMCInfluence.m!');
        disp('The following beamlets were set to 0:');
        disp(errorBeamlets);
    end

else  % sourceModel ~= 0
    disp('not implement source Model for vmc yet');
    disp('Set sourceModel == 0, please');
end

% rm the phantom / CT file when finishes.
dos(['rm ' fullfile(VMCPath,phantomFilename)]);

return;