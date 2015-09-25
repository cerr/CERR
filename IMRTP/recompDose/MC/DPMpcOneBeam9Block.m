function DPMpcOneBeam9(leak, spectrum_File, planC_File, nhist, OutputError, whichBeam, PBMaxWidth, gradsense, MCsolver, saveIM, sourceModel, doseToWater, fillWater, useWedge, inputPB, Softening, batch)
% written by KZ, JC
% Calculate doseV dose3D directly from DPM, without compressing it.
% Use generateDPMdose.m instead of DPMInfluenceJing.m
% Calculate IM struct, call DPM, get
%
% Usage: IIMCalc = calculateBeamIM(0.018, 'DPM_10beams_planC', 1, 1, 5)
%   leak = 0.018
%   spectrum_File = file name of photon spectrum. eg. photon6MV.spectrum
%   planC_File = file name contained planC, eg. 'DPM_10beams_planC'
%   indexBeam = Beam Index: 1, 2, ...
%   imin = Beamlet index
%   imax = Beamlet index
%
%   eval(['load Beam',num2str(indexBeam),'_w']);
%   where, Beam1_w.mat (Beam2_w.mat) need to be in the current directory. It's the weight of
%   the beamlets for each beam.
%
% JC Feb 27 06
% Call in DPMInfluence.m; use sum(10*clock) as the random seeds input to DPM.
%
% JC. Aug 10, 2005, Need to make planC read from the disk, since in the
% stand-alone mode, no matlab run is expected.
%
% JC Dec 18 06
% Add 'saveIM' input,
%   If it's larger than 0, say 1, then save IM
%   If it's 0, don't save IM
%
% LM: JC Jan 26 2007
% Include non-zero couchAngle
% The desination coordinates should be the patient support
% system.
% The previous assumption is that the "fixed system" is the same as
% the "Patient support system".
% test
%
% LM: JC Mar 03, 2007
% Score dose to water flag. Only valid for VMC++ for now. "doseToWater"
% Add "fillWater" flag. It 1, fill the skin strucutere with all water
% density, i.e. CT value = 1024.
%
% LM: JC Mar 29, 2007
% get rid of 'stateS' arguments to 'generateVMCdose.m', 'generateDPMdose.m'
% get rid of the call for 'IMRTP_plancheck'
% add 'useWedge' flag. default = 0; when useWedge == 1, use Elekta
% universal wedge.
% only implemented for DPM, openField == 0, sourceModel == 0;
%
% open planC_File
% In matlab release 14, "eval" can be compiled.
Error = []; %Initialize Error to NULL.
load(planC_File);
%eval(['load ',planC_File]);
% This planC_File should contains planC and stateS
%leak = 0.018; %leakage in per *100
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

if ischar(leak)
    leak = str2num(leak)
end

if ischar(nhist)
    nhist = str2num(nhist)
end

if ischar(OutputError)
    OutputError = str2num(OutputError)
end

if ischar(whichBeam)
    whichBeam = str2num(whichBeam)
end


if ischar(PBMaxWidth)
    PBMaxWidth = str2num(PBMaxWidth)
end

if ischar(gradsense)
    gradsense = str2num(gradsense)
end

% If MCsolver == 1, use DPM, default
% If MCsolver == 2, use VMC++
% other, throw out error
if ischar(MCsolver)
    MCsolver = str2num(MCsolver)
end

% If saveIM == 0, calculate doseV, do not calc/save IM
% If saveIM ~= 0, calc/save IM, only valid for DPM for now, ie. MCsolver == 1.
if ischar(saveIM)
    saveIM = str2num(saveIM)
end

% If sourceModel == 0, no source model, only point source
% If sourceModel == 1, source model version 1: point source (Primary) + FF
% + electron contamination.
% Expandable to other source models for the future development.

if ischar(sourceModel)
    sourceModel = str2num(sourceModel)
end

if ischar(doseToWater)
    doseToWater = str2num(doseToWater)
end

if ischar(fillWater)
    fillWater = str2num(fillWater)
end

if ischar(useWedge)
    useWedge = str2num(useWedge)
end

if ischar(inputPB)
    inputPB = str2num(inputPB)           %Flag, inputPB == 1, ask user to input .mat file storing PB info. 
                                 % That file can be generated using
                                 % function generateOpenfiledPB.m
end
% Now, only work for DPM, planC{7} not empty.

if ischar(Softening)
    Softening = str2num(Softening)           %Flag,  == 1, use off-axis-softening in dpm calc. 
                                 
end
% Now, only work for DPM, planC{7} not empty.


if ischar(batch)
    batch = str2num(batch)
end

currentDir = cd;
if (~isempty(planC{7}))
    % When there are multiple beam definition in planC, use the first BEAM
    % data as the default.

    %for indexBeam = 1 : planC{7}(1).FractionGroupSequence.Item_1.NumberOfBeams
    for indexBeam = whichBeam
       
            bs = planC{7}(1).BeamSequence.(['Item_' num2str(indexBeam)]);

            %Parse BlockData into PB information.
            input = bs.BlockSequence.Item_1.BlockData;
            input = reshape(input, 2, [])';
            
            [xPosV, yPosV, beamlet_delta_x, beamlet_delta_y]=...
                BlockToPB(input, 10, 10);   %PB size here is in mm.
            w_field = ones(size(xPosV));
            
            gA = bs.ControlPointSequence.Item_1.GantryAngle;
            iC = bs.ControlPointSequence.Item_1.IsocenterPosition;
            IMBase.beams.gantryAngle = gA;
            % couchAngle is PatientSupportAngle, in DICOM, i.e. IEC format
            % (in deg)
            IMBase.beams.couchAngle = bs.ControlPointSequence.Item_1.PatientSupportAngle;
            % JC Apr. 10 2007, 
            % Add Beam Limiting Deviceing Angle, i.e. collimator angle from
            % DICOM, in IED format. (in deg) 
            % Not test for "Non-zero angle" yet.
            IMBase.beams.collimatorAngle = bs.ControlPointSequence.Item_1.BeamLimitingDeviceAngle

            try
            if ~isfield(planC{7}(1).PatientSetupSequence,(['Item_' num2str(indexBeam)]))
                position = {planC{7}(1).PatientSetupSequence.(['Item_' num2str(1)]).PatientPosition};
            else
                position = {planC{7}(1).PatientSetupSequence.(['Item_' num2str(indexBeam)]).PatientPosition};
            end
            catch
                position = 'HFS';
                disp('Use default patient posiont HFS')
            end

            if strcmpi(position, 'HFP')
                IMBase.beams(1).isocenter.x = iC(1)/10;
                IMBase.beams(1).isocenter.y = iC(2)/10;
                IMBase.beams(1).isocenter.z = -iC(3)/10;
            else
                IMBase.beams(1).isocenter.x = iC(1)/10;
                IMBase.beams(1).isocenter.y = -iC(2)/10;
                IMBase.beams(1).isocenter.z = -iC(3)/10;
            end

            IMBase.beams(1).isodistance = bs.SourceAxisDistance/10;

            IMBase.beams(1).beamEnergy = bs.ControlPointSequence.Item_1.NominalBeamEnergy;
          
            xPosV = xPosV/10;
            yPosV = yPosV/10;
            beamlet_delta_x = beamlet_delta_x/10;
            beamlet_delta_y = beamlet_delta_y/10;


            IMBase.goals.PBMargin = 0.5;
            IMBase.goals.structNum = 2;
            IMBase.params.xyDownsampleIndex = 1;
            IMBase.goals.isTarget(1) = 'y';
            IMBase.goals.xySampleRate = 2;
            IMBase.params.numCTSamplePts = 300;

            IMBase.beams(1).zRel = 0;
            IMBase.beams(1).xRel =  IMBase.beams(1).isodistance * sindeg(IMBase.beams(1).gantryAngle);
            IMBase.beams(1).yRel =  IMBase.beams(1).isodistance * cosdeg(IMBase.beams(1).gantryAngle);

            % JC In the above calc. for xRel and yRel, the assumption is the couchAngle
            % == 0. i.e. the "fixed system" is the same as the "patient support
            % system".
            % LM: JC Jan 26 2007
            % Include non-zero couchAngle
            % The desination coordinates should be the patient support
            % system.
            % The previous assumption is that the "fixed system" is the same as
            % the "Patient support system".
            % test

            %         patientVectorsM = zeros(size(RTOGVectorsM));
            patientxRel = cosdeg(IMBase.beams.couchAngle) * IMBase.beams(1).xRel- sindeg(IMBase.beams.couchAngle) * IMBase.beams(1).zRel;
            patientyRel = IMBase.beams(1).yRel;
            patientzRel = sindeg(IMBase.beams.couchAngle) * IMBase.beams(1).xRel + cosdeg(IMBase.beams.couchAngle) * IMBase.beams(1).zRel;
            IMBase.beams(1).xRel = patientxRel;
            IMBase.beams(1).yRel = patientyRel;
            IMBase.beams(1).zRel = patientzRel;
            clear patientxRel patientyRel patientzRel

            %IMBase.params.algorithm = 'VMC++';
            %IMCalc = IMRTP_MapCheck(IMBase);

            IMBase.params.algorithm = 'DPM';
            %      load PB_40x40.mat beamlet_delta_x beamlet_delta_y xPosV yPosV w_field
            %      load PB_15x15.mat beamlet_delta_x beamlet_delta_y xPosV yPosV w_field
            
            if inputPB         % get PB info from a specified .mat file.
                setappdata(0, 'usenativesystemdialogs', false)
                currentDir = cd;

                [FileName,path] = uigetfile('*.mat','Select MAT file containing beamlet_delta_x beamlet_delta_y xPosV yPosV w_field');

                if path == 0
                    errordlg('File Should exist');
                    error('File Should exist');
                end

                cd(path);
                load (FileName, 'beamlet_delta_x', 'beamlet_delta_y', 'xPosV', 'yPosV', 'w_field')
                cd(currentDir);
            end

            disp('Number of pencile beams are:')
            length(xPosV)

            sourceS = IMBase.beams(1);
            [RTOGPBVectorsM, RTOGPBVectorsM_MC, PBMaskM, rowPBV, colPBV, xPBPosV, yPBPosV, beamlet_delta_x, beamlet_delta_y] = ...
                    getPBRays(xPosV, yPosV, beamlet_delta_x, beamlet_delta_y, sourceS);
            IMCalc = IMBase;
            IMCalc.beams(1).RTOGPBVectorsM_MC = RTOGPBVectorsM_MC;
            IMCalc.beams(1).RTOGPBVectorsM    = RTOGPBVectorsM;
            IMCalc.beams(1).xPBPosV           = xPBPosV;
            IMCalc.beams(1).yPBPosV           = yPBPosV;
            IMCalc.beams(1).rowPBV            = rowPBV;
            IMCalc.beams(1).colPBV            = colPBV;
            % No need of this field
            IMCalc.beams(1).CTTraceS          = struct;
            IMCalc.beams(1).beamletDelta_x    = beamlet_delta_x;
            IMCalc.beams(1).beamletDelta_y    = beamlet_delta_y;

            %RTOG positions of sources
            IMCalc.beams(1).x = IMCalc.beams(1).xRel + IMCalc.beams(1).isocenter.x;
            IMCalc.beams(1).y = IMCalc.beams(1).yRel + IMCalc.beams(1).isocenter.y;
            IMCalc.beams(1).z = IMCalc.beams(1).zRel + IMCalc.beams(1).isocenter.z;
            %IMCalc = IMRTP_MapCheck(IMBase, planC, stateS, xPosV, yPosV, beamlet_delta_x, beamlet_delta_y, gA);
            % JC. 11 Aug, 05 Added more arguments to IMRTP_MapCheck,

            % JC. Aug. 3, 2005
            % Add fields to IMCalc, necessary for generateDPMInfluence.m
            IMCalc.beams.collimatorAngle = 0;
            IMCalc.params.ScatterMethod = 'exponential';
            % Use 0.002 instead the original default 0.01 as threshold value.
            % Change to 0.004, since the stored IM struct is very large.
            IMCalc.params.Scatter.Threshold = 0.004;
            IMCalc.params.Scatter.RandomStep = 30;
            IMCalc.beamlets = struct;

            %JC Add/porpulate VMC field in IM struct.
            IMCalc.params.VMC.NumParticles = nhist;
            IMCalc.params.VMC.NumBatches = 10;
            IMCalc.params.VMC.scoreDoseToWater = 'No';
            IMCalc.params.VMC.monoEnergy = 0;   %?
            IMCalc.params.VMC.repeatHistory = 0.2510;
            IMCalc.params.VMC.splitPhotons = 'Yes';
            IMCalc.params.VMC.photonSplitFactor = -40;
            IMCalc.params.VMC.base = 2;;
            IMCalc.params.VMC.dimension = 60;    %?
            IMCalc.params.VMC.skip = 0;  %? 1?
            IMCalc.params.VMC.includeError = 'No';
            IMCalc.params.VMC.spectrum = spectrum_File;
            IMCalc.beams.beamModality = 'photons';

            if doseToWater
            IMCalc.params.VMC.scoreDoseToWater = 'Yes';
            disp('VMC++ score dose to Water.');
            end
            
            % JC Jun 06 2006
            % Still need to fill in the structure of IMCalc, but don't need put
            % it back(?), since it's not to be used to calculate dose.
            % Will also need to use 'DoseScale' inside generateDPMdose.m,
            % since DPM output dose on a per partical base.
            % Need to use w_field as a way of telling DPM how to add beamlets
            % up.

            % JC Aug 30. 2006
            if (MCsolver == 1)

                [IMCalc doseV indV numberParticles] = generateDPMdose7(IMCalc,spectrum_File,nhist, OutputError,planC, indexBeam, w_field, saveIM, sourceModel, fillWater, useWedge, Softening);

            elseif (MCsolver == 2)
                % use VMC++
                [doseV indV] = generateVMCdose(IMCalc, planC, w_field, sourceModel, doseToWater, fillWater,saveIM);
            else
                error('INVALID input: MCsolver == 1, DPM; MCsolver == 2, VMC++')
            end

       
    end

else %If it's a conventional plan, planC{7} is empty

    indexBeam = whichBeam;
    if (length(planC{6}(indexBeam).file) > 5)
        [xPosV, yPosV, beamlet_delta_x, beamlet_delta_y, beamGeometry]=...
            planCToPB(planC, indexBeam, 1, 1);
    else
        % The field is shaped by Jaws, not MLC.
        [xPosV, yPosV, beamlet_delta_x, beamlet_delta_y, beamGeometry]=...
            planCToPBJaws(planC, indexBeam, 1, 1);
    end

    IMBase.beams(1).isocenter.x = beamGeometry.isocenter(1);
    IMBase.beams(1).isocenter.y = beamGeometry.isocenter(2);
    IMBase.beams(1).isocenter.z = beamGeometry.isocenter(3);
    % RTOG file has the same couchAngle definition as in IEC1217.
    IMBase.beams(1).couchAngle = beamGeometry.couchAngle;
    % RTOG file has different gantryAngle definition from IEC1217.
    % Use IEC 1217 coordinates.
    IMBase.beams(1).gantryAngle = - beamGeometry.gantryAngle;
    IMBase.beams(1).isodistance = beamGeometry.isoDistance;

    IMBase.goals.PBMargin = 0.5;
    IMBase.goals.structNum = 2;
    IMBase.params.xyDownsampleIndex = 1;
    IMBase.goals.isTarget(1) = 'y';
    IMBase.goals.xySampleRate = 1;
    IMBase.params.numCTSamplePts = 300;
    IMBase.beams(1).beamEnergy = planC{6}(1).beamEnergyMeV;

    IMBase.beams(1).zRel = 0;
    IMBase.beams(1).xRel =  IMBase.beams(1).isodistance * sindeg(IMBase.beams(1).gantryAngle);
    IMBase.beams(1).yRel =  IMBase.beams(1).isodistance * cosdeg(IMBase.beams(1).gantryAngle);

    % JC In the above calc. for xRel and yRel, the assumption is the couchAngle
    % == 0. i.e. the "fixed system" is the same as the "patient support
    % system".
    % LM: JC Jan 26 2007
    % Include non-zero couchAngle
    % The desination coordinates should be the patient support
    % system.
    % The previous assumption is that the "fixed system" is the same as
    % the "Patient support system".

    patientxRel = cosdeg(IMBase.beams.couchAngle) * IMBase.beams(1).xRel- sindeg(IMBase.beams.couchAngle) * IMBase.beams(1).zRel;
    patientyRel = IMBase.beams(1).yRel;
    patientzRel = sindeg(IMBase.beams.couchAngle) * IMBase.beams(1).xRel + cosdeg(IMBase.beams.couchAngle) * IMBase.beams(1).zRel;
    IMBase.beams(1).xRel = patientxRel;
    IMBase.beams(1).yRel = patientyRel;
    IMBase.beams(1).zRel = patientzRel;
    clear patientxRel patientyRel patientzRel

    IMBase.beams(1).collimatorAngle = beamGeometry.collimatorAngle;
    
    disp('Number of pencile beams are:')
            length(xPosV)

    % JC Mar 29, 2007
    % Repace 'IMRTP_plancheck' by the following command
            sourceS = IMBase.beams(1);
            [RTOGPBVectorsM, RTOGPBVectorsM_MC, PBMaskM, rowPBV, colPBV, xPBPosV, yPBPosV, beamlet_delta_x, beamlet_delta_y] = ...
                    getPBRays(xPosV, - yPosV, beamlet_delta_x, beamlet_delta_y, sourceS);
    % Note: In the above line, use '- yPosV' instead of 'yPosV'. Since IEC and RTOG have different definition about yPosV.            
            IMCalc = IMBase;
            IMCalc.beams(1).RTOGPBVectorsM_MC = RTOGPBVectorsM_MC;
            IMCalc.beams(1).RTOGPBVectorsM    = RTOGPBVectorsM;
            IMCalc.beams(1).xPBPosV           = xPBPosV;
            IMCalc.beams(1).yPBPosV           = yPBPosV;
            IMCalc.beams(1).rowPBV            = rowPBV;
            IMCalc.beams(1).colPBV            = colPBV;
            % No need of this field
            IMCalc.beams(1).CTTraceS          = struct;
            IMCalc.beams(1).beamletDelta_x    = beamlet_delta_x;
            IMCalc.beams(1).beamletDelta_y    = beamlet_delta_y;

            %RTOG positions of sources
            IMCalc.beams(1).x = IMCalc.beams(1).xRel + IMCalc.beams(1).isocenter.x;
            IMCalc.beams(1).y = IMCalc.beams(1).yRel + IMCalc.beams(1).isocenter.y;
            IMCalc.beams(1).z = IMCalc.beams(1).zRel + IMCalc.beams(1).isocenter.z;
    
    % JC Mar 29, 2007 
    % Replace 'IMRTP_MapCheck' by above commands.
    % IMCalc = IMRTP_MapCheck(IMBase, planC, stateS, xPosV, - yPosV, beamlet_delta_x, beamlet_delta_y, gA);
    clear IMBase beamlet_delta_x beamlet_delta_y PlanC_File xPosV yPosV

    % Add fields to IMCalc, necessary for generateDPMInfluence.m
    IMBase.params.algorithm = 'DPM';
    IMCalc.params.ScatterMethod = 'exponential';
    IMCalc.params.Scatter.Threshold = 0.004;
    IMCalc.params.Scatter.RandomStep = 30;
    IMCalc.beamlets = struct;

    % For the conventional RT. No change in w_field
    w_field = ones(length(IMCalc.beams.beamletDelta_x),1);
    %[doseV indV] = generateDPMdose(IMCalc,spectrum_File,nhist, OutputError,planC,stateS, indexBeam, w_field);
    % Dec 18, 2006
    % Use the new modified DPM, with Source Model.

    %JC Add/porpulate VMC field in IM struct.
    IMCalc.params.VMC.NumParticles = nhist;
    IMCalc.params.VMC.NumBatches = 10;
    IMCalc.params.VMC.scoreDoseToWater = 'No';
    IMCalc.params.VMC.monoEnergy = 0;   %?
    IMCalc.params.VMC.repeatHistory = 0.2510;
    IMCalc.params.VMC.splitPhotons = 'Yes';
    IMCalc.params.VMC.photonSplitFactor = -40;
    IMCalc.params.VMC.base = 2;;
    IMCalc.params.VMC.dimension = 60;    %?
    IMCalc.params.VMC.skip = 0;  %? 1?
    IMCalc.params.VMC.includeError = 'No';
    IMCalc.params.VMC.spectrum = spectrum_File;
    IMCalc.beams.beamModality = 'photons';
    
    if doseToWater
            IMCalc.params.VMC.scoreDoseToWater = 'Yes';
            disp('VMC++ score dose to Water.');
     end
            
    if (MCsolver == 1)

        [IMCalc doseV indV numberParticles] = generateDPMdose7(IMCalc,spectrum_File,nhist, OutputError,planC, indexBeam, w_field, saveIM, sourceModel, fillWater, useWedge, Softening);

    elseif (MCsolver == 2)
        % use VMC++
        [doseV indV] = generateVMCdose(IMCalc, planC, w_field, sourceModel, doseToWater, fillWater,saveIM);
    else
        error('INVALID input: MCsolver == 1, DPM; MCsolver == 2, VMC++')
    end

    % ?? Right place to put end???
end


%%%%%%%%%%%%%%%
    siz = getUniformizedSize(planC);
    dose3D = zeros(siz);

    if (OutputError == 1)            % OutputError only valid for DPM,ie., MCsolver == 1 
        doseV = doseV(:,1);
        Error_3D = zeros(siz);
        Error_3D(indV') = doseV(:,2);
    else
        disp('Do not output error')
        dose3D(indV') = doseV;
    end

    %        filename = ['doseV_',num2str(indexBeam),'_', num2str(nhist), '_', num2str(batch)];
    %        save(filename, 'doseV', 'indV');

    filename = ['dose3D_',num2str(indexBeam),'_', num2str(nhist), '_', num2str(batch)];
    save(filename, 'dose3D');

    % Only Output w_field for the first batch
    if(batch == 1)
        filename = ['w_field',num2str(indexBeam)];
        save(filename, 'w_field');%dose3D = (dose3D/max(dose3D(:)));
    end

if (saveIM == 1)
%saveIM  %Only valid for DPM, i.e. IM 
    filename = ['IMCalc_Beam',num2str(indexBeam),'_', num2str(nhist), '_', num2str(batch)];
    save(filename, 'IMCalc');
end
clear IMCalc dose3D w_field

end

