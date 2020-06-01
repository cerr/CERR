function IM = generateMCInfluence(IM, structROIV, sampleRateV);
%"generateMCInfluence"
%   Given an IM structure, begin/continue calculating montecarlo influence
%   data.
%
%   Based on code by P. Lindsay.
%           JC, 26 Feb 2007
%               Fix bug, "the dose was shifted by one voxel". to.
%               offset(1:2)=offset(1:2)+yres/2;
%
%JRA, 26 Aug 04
%
%Usage:
%   function IM = generateMCInfluence(IM, structROIV, sampleRateV);
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

global planC
global stateS
indexS=planC{end};

%obtain associated scanNum for structures. It is assumed that all the
%structures are associated to same scan (which is checked in IMRTP.m)
scanNum = getStructureAssociatedScan(structROIV(1));

numBeams = length(IM.beams);

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

% To generate independent datasets, need to set 
% VMCOpt.startQuasi.skip to skip the numbers of histories 
% used in previous calculations
beamletCount = 1;
for beamIndex=1:numBeams, 
    
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
    s1=0.5;
    s2=50;
    s3=s1*0.5;
    
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
    % a square, by testing the dot product
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
    clear r;
    clear c;
    clear s;
    
    for i=1:npb
        outfile=['MCpencilbeam_', int2str(beamIndex), '_', int2str(i)];                  
        if ispc        
            currPath = cd;
            cd(VMCPath);
            dos(['start /low /B /wait ' fullfile('.', 'bin', 'vmc_Windows.exe') ' ' outfile '']);                                   
            % 		niter=2;
            % 		cerror=0.05;
            % 		str=fullfile(VMCPath, 'runs', [outfile '_' VMCOpt.startScoring.startDoseOptions.scoreInGeometries '.dos'])
            %         dose = readDoseFile(fullfile(VMCPath, 'runs', [outfile '_' VMCOpt.startScoring.startDoseOptions.scoreInGeometries '.dos']), precision, scandr, scandc, scands);                                              
            %         dose = reshape(dose, [scandr, scandc, scands]);
            % 		maxValue = max(dose(:));
            % 		mask = dose < (IM.params.Scatter.Threshold * maxValue);
            %         lowDoses = zeros(size(dose));
            % 		lowDoses(mask) = dose(mask);
            % 		dose(mask) = 0;
            % 		smoothLowDoses=anisodiff3d_miao(lowDoses, cerror, niter);
            %         clear mask
            %         clear lowDoses
            % 		dose = dose + smoothLowDoses;
            %   
            %         doseV = dose(:);
            doseV = readDoseFile(fullfile('.', 'runs', [outfile '_' VMCOpt.startScoring.startDoseOptions.scoreInGeometries '.dos']), precision, scandr, scandc, scands);                                              
            cd(currPath);
        elseif isunix
            currPath = cd;
            cd(VMCPath);
            dos(['chmod u+x ' fullfile(VMCPath, 'vmc_wrapper')]);
            dos(['dos2unix ' fullfile(VMCPath, 'vmc_wrapper')]); % to make sure endOfLine characters are correct
            dos([fullfile(VMCPath,'vmc_wrapper') ' ' VMCPath ' ' runsPath ' ' VMCPath ' ' fullfile(VMCPath, 'bin', 'vmc_Linux.exe') ' ' outfile]);                   
            doseV = readDoseFile(fullfile(VMCPath, 'runs', [outfile '_' VMCOpt.startScoring.startDoseOptions.scoreInGeometries '.dos']), precision, scandr, scandc, scands);                                                        
            cd(currPath);
        end
        if strcmpi(IM.params.DoseTerm,'bterm') | strcmpi(IM.params.DoseTerm,'nogauss+scatter') | strcmpi(IM.params.DoseTerm,'nogauss')
            doseV = applyIMRTCompression(IM.params, doseV);
        end
        
        beamlet = createIMBeamlet(doseV, indV, beamIndex, 0);
        IM.beamlets = dissimilarInsert(IM.beamlets, beamlet, beamletCount);
        beamletCount = beamletCount + 1;      
        try
            IMRTPGui('status', beamIndex, numBeams, 1, i, npb);
        end
    end
end