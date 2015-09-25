function [rtplanformc] = dicomrt_mcwarm(cell_case_study)
% dicomrt_mcwarm(cell_case_study)
%
% Create a subset of rtplan parameters used for MC simulation through the
% BEAM MC code system.
%
% cell_case_study is the rtplan dataset
%
% cell_case_study is a cell array with the following structure:
%
%  ------------------------
%  | [ rtplan structure ] |
%  | ----------------------
%  | [ 3D dose matrix   ] |
%  | ---------------------
%  | [ voxel dimensions ] |
%  ------------------------
%
% rtplanformc = dicomrt_mcwarm(cell_case_study) create a cell array rtplanformc with MC containing 
%               information suitable to feed MC calculation of the clinical plan 
%
% rtplanformc is a cell array with the following structure
%
%   beam name   common beam            primary collimator position         MLC and MU
%                  data
%  ---------------------------------------------------------------------------------------------------
%  | [beam 1] |gantry angle    | [jawsx 1st segment] [jawsy 1st segment]| [mlc 1st segment] [diff MU]|
%  |          |coll angle      |----------------------------------------------------------------------
%  |          |iso position (3)| [jawsx 2nd segment] [jawsy 2nd segment]| [mlc 2nd segment] [diff MU]|
%  |          |StBLD dist   (3)|----------------------------------------------------------------------
%  |          |voxel dim       |                   ...                  |             ...            |
%  |          |patient position|---------------------------------------------------------------------- 
%  |          |# fractions     | [jawsx nth segment] [jawsy nth segment]| [mlc nth segment] [diff MU]|
%  ---------------------------------------------------------------------------------------------------
%  |               ...                                    ...                                ...               
%  ---------------------------------------------------------------------------------------------------
%  | [beam n] |gantry angle    | [jawsx 1st segment] [jawsy 1st segment]| [mlc 1st segment] [diff MU]|
%  |          |coll angle      |----------------------------------------------------------------------
%  |          |iso position (3)| [jawsx 2nd segment] [jawsy 2nd segment]| [mlc 2nd segment] [diff MU]|
%  |          |StBLD dist   (3)|----------------------------------------------------------------------
%  |          |voxel dim       |                   ...                  |             ...            |
%  |          |patient position|---------------------------------------------------------------------- 
%  |          |# fractions     | [jawsx nth segment] [jawsy nth segment]| [mlc nth segment] [diff MU]|
%  ---------------------------------------------------------------------------------------------------
%
% See also dicomrt_loaddose, dicomrt_loadct
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

% Check
[cell_case_study,type,label,PatientPosition]=dicomrt_checkinput(cell_case_study);

if isequal(type,'RTPLAN')~=1
    error('dicomrt_mcwarm: Study does not have the correct format. Exit now!');
end

rtplan=cell_case_study{1,1}{1};


% 0) Set-up parameters

XCOLLtag='ASYMX';
YCOLLtag='ASYMY';
MLCXtag='MLCX';
MLCYtag='MLCY';
collimator_error=0;

% 1) retrieve number of beams and create a cell matrix which will contain 
%    the relevant plan parameters

beams=fieldnames(rtplan.BeamSequence);
nbeams=size(beams,1);

rtplanformc=cell(nbeams,5);

for i=1:nbeams
    rtplanformc{i,1}=getfield(rtplan,'BeamSequence',char(beams(i)),'BeamName');
end

% 2a) for each beam retrieve gantry angle, collimator angle, isocenter position, 
%     SourceToBeamLimitingDeviceDistancence (StBLD), voxel_dim

gantryangle=cell(nbeams,1);
collimatorangle=cell(nbeams,1);
isocenterposition=cell(nbeams,1);
StBLD=cell(nbeams,3);

% Retrieve patient position. This will be used by dicomrt_ctcreate to create ctphantom and by dicomrt_loadmcdose
% to read MC 3ddose distribution and restore original axis orientation (dicom-rt patient coordinate system).

%PatientPosition=getfield(rtplan,'PatientSetupSequence','Item_1','PatientPosition');

% get number of secondary collimators and check
ncoll=size(fieldnames(getfield(rtplan.BeamSequence,char(beams(1)),'BeamLimitingDeviceSequence')),1);

if ncoll == 2
    for i=1:nbeams
        collimator=getfield(rtplan.BeamSequence,char(beams(i)),'BeamLimitingDeviceSequence','Item_1','RTBeamLimitingDeviceType');
        if collimator ~= XCOLLtag
            warning('dicomrt_mcwarm: Secondary collimator is : '); disp(collimator);
            warning('dicomrt_mcwarm: Expected type is: '); disp(XCOLLtag);
            collimator_error=1;
        end
        collimator=getfield(rtplan.BeamSequence,char(beams(i)),'BeamLimitingDeviceSequence','Item_2','RTBeamLimitingDeviceType');
        if collimator ~= YCOLLtag
            warning('dicomrt_mcwarm: Secondary collimator is : '); disp(collimator);
            warning('dicomrt_mcwarm: Expected type is: '); disp(YCOLLtag);
            collimator_error=1;
        end
        if collimator_error==1
            error('dicomrt_mcwarm: Too many errors were reported while processing these data. Exit now!');
        end
    end % if we are not exit already that means that there were no major incompatibilities. Let's continue.
    % disp('This beam does not have MLC collimator. Data will be safely imported at this stage.');
    % disp('However this configuration is not currently supported by the toolbox.');
end

% get number of fractions: info used by dicomrt_loadmcdose for reconstructing MC dose
% check first is this a single fraction plan
fractions=isempty(rtplan.FractionGroupSequence.Item_1.NumberOfFractionsPlanned);
if fractions == 1 % single fraction
    nfractions=1;
else
    nfractions=rtplan.FractionGroupSequence.Item_1.NumberOfFractionsPlanned;
end

for i=1:nbeams
   gantryangle{i,1}=getfield(rtplan.BeamSequence,char(beams(i)),'ControlPointSequence','Item_1','GantryAngle');
   collimatorangle{i,1}=getfield(rtplan.BeamSequence,char(beams(i)),'ControlPointSequence','Item_1','BeamLimitingDeviceAngle');
   isocenterposition{i,1}=getfield(rtplan.BeamSequence,char(beams(i)),'ControlPointSequence','Item_1','IsocenterPosition');
   % check how many secondary collimators there are
   % check for compatibility with set-up parameters
   if ncoll == 3;
       collimator=getfield(rtplan.BeamSequence,char(beams(i)),'BeamLimitingDeviceSequence','Item_1','RTBeamLimitingDeviceType');
       if strcmpi(collimator,XCOLLtag)~=1
           warning('dicomrt_mcwarm: Secondary collimator is : '); disp(collimator);
           warning('dicomrt_mcwarm: Expected type is: '); disp(XCOLLtag);
       else
           StBLD{i,1}=getfield(rtplan.BeamSequence,char(beams(i)),'BeamLimitingDeviceSequence','Item_1','SourceToBeamLimitingDeviceDistance');
       end
       collimator=getfield(rtplan.BeamSequence,char(beams(i)),'BeamLimitingDeviceSequence','Item_2','RTBeamLimitingDeviceType');
       if strcmpi(collimator,MLCXtag)~=1
           warning('dicomrt_mcwarm: Secondary collimator is : '); disp(collimator);
           warning('dicomrt_mcwarm: Expected type is: '); disp(MLCXtag);
       else
           StBLD{i,2}=getfield(rtplan.BeamSequence,char(beams(i)),'BeamLimitingDeviceSequence','Item_2','SourceToBeamLimitingDeviceDistance');
       end
       collimator=getfield(rtplan.BeamSequence,char(beams(i)),'BeamLimitingDeviceSequence','Item_3','RTBeamLimitingDeviceType');
       if strcmpi(collimator,YCOLLtag)~=1
           warning('dicomrt_mcwarm: Secondary collimator is : '); disp(collimator);
           warning('dicomrt_mcwarm: Expected type is: ');disp(YCOLLtag);
       else
           StBLD{i,3}=getfield(rtplan.BeamSequence,char(beams(i)),'BeamLimitingDeviceSequence','Item_3','SourceToBeamLimitingDeviceDistance');
       end
   elseif ncoll == 2 % data were already checked for compatibility
       StBLD{i,1}=getfield(rtplan.BeamSequence,char(beams(i)),'BeamLimitingDeviceSequence','Item_1','SourceToBeamLimitingDeviceDistance');
       StBLD{i,2}=0;
       StBLD{i,3}=getfield(rtplan.BeamSequence,char(beams(i)),'BeamLimitingDeviceSequence','Item_2','SourceToBeamLimitingDeviceDistance');
   end
   % 2b) store additional data
   rtplanformc{i,2}=[gantryangle{i};collimatorangle{i};isocenterposition{i};StBLD{i,1};StBLD{i,2};StBLD{i,3}; ...
           cell_case_study{3,1};PatientPosition;nfractions];
end

% 3a) for each beam retrieve number of segments

segments=cell(nbeams,1);
nsegments=cell(nbeams,1);

for i=1:nbeams
   segments{i,1}=fieldnames(getfield(rtplan.BeamSequence,char(beams(i)),'ControlPointSequence'));
   nsegments{i,1}=size(segments{i,1},1);
end

% 3b) for each segment retrieve beam limiting device position and weights
%
% Beam Meterset: Machine setting to be delivered for current Beam, specified in Monitor Units (MU) or
% minutes as defined by Primary Dosimeter Unit (300A,00B3) (in RT Beams Module) for referenced Beam.
%
% Cumulative Meterset Weight: Cumulative weight to current control point. Cumulative Meterset Weight for the first item
% in Control Point Sequence shall always be zero. Cumulative Meterset Weight for the final item in Control Point Sequence 
% shall always be equal to Final Cumulative Meterset Weight. Required if Control Point Sequence (300A,0111) is sent.
% See C.8.8.14.1.
% 
% Final Cumulative Meterset Weight: Value of Cumulative Meterset Weight (300A,0134) for final Control Point in Control
% Point Sequence (300A,0111). Required if Cumulative Meterset Weight is non-null in Control Points specified within
% Control Point Sequence (300A,0111). See C.8.8.14.1.
%
% The Meterset at a given Control Point is equal to the Beam Meterset (300A,0086) specified in the
% Referenced Beam Sequence (300A,0004) of the RT Fraction Scheme Module, multiplied by the
% Cumulative Meterset Weight (300A,0134) for the Control Point, divided by the Final Cumulative
% Meterset Weight (300A,010E). The Meterset is specified in units defined by Primary Dosimeter Unit (300A,00B3).
%
% ==> cumulative MU/segment = (BEAM METERSET) * (CUMULATIVE METERSET WEIGHT) / (FINAL CUMULATIVE METERSET WEIGHT)
%     differential MU/segment = (cumulative MU/segment) (i+1) - (cumulative MU/segment) (i)
%     see LM_beams.xls

for i=1:nbeams
    jawsx=cell(nsegments{i,1}/2,1);
    jawsy=cell(nsegments{i,1}/2,1);
    mlc=cell(nsegments{i,1}/2,1);
    cumulativemetersetweight=cell(nsegments{i,1}/2,1);
    cumulativeweight=cell(nsegments{i,1}/2,1);
    differentialweight=cell(nsegments{i,1}/2,1);
    % beammeterset=cell(nbeams,1);
    % retrieve beam meter set (MUs if PrimaryDosimeterUnit=MU)
    beammeterset=getfield(rtplan.FractionGroupSequence.Item_1.ReferencedBeamSequence,char(beams(i)),'BeamMeterset');
    finalcumulativemetersetweight=getfield(rtplan.BeamSequence,char(beams(i)),'FinalCumulativeMetersetWeight');
    if ncoll == 3; % Normal case
        % deal with unusual irmt case when only 1 segment is used
        if nsegments{i}==2
            for j=1:nsegments{i}-1
                jawsx{j,1}=getfield(rtplan.BeamSequence,char(beams(i)),'ControlPointSequence',char(segments{i,1}{j,1}),'BeamLimitingDevicePositionSequence','Item_1','LeafJawPositions');
                jawsy{j,1}=getfield(rtplan.BeamSequence,char(beams(i)),'ControlPointSequence',char(segments{i,1}{j,1}),'BeamLimitingDevicePositionSequence','Item_3','LeafJawPositions');
                mlc{j,1}=getfield(rtplan.BeamSequence,char(beams(i)),'ControlPointSequence',char(segments{i,1}{j,1}),'BeamLimitingDevicePositionSequence','Item_2','LeafJawPositions');
                %retrieve cumulative meterset weight (cumulative MUs delivered)
                cumulativemetersetweight{j,1}=getfield(rtplan.BeamSequence,char(beams(i)),'ControlPointSequence',char(segments{i,1}{j+1,1}),'CumulativeMetersetWeight');
                cumulativeweight{j,1}=beammeterset*cumulativemetersetweight{j,1}/finalcumulativemetersetweight;
                temp1(j)=beammeterset*cumulativemetersetweight{j,1}/finalcumulativemetersetweight;
            end
        else
            for j=2:2:nsegments{i}
                % retrieve beam limiting device position
                jawsx{j/2,1}=getfield(rtplan.BeamSequence,char(beams(i)),'ControlPointSequence',char(segments{i,1}{j,1}),'BeamLimitingDevicePositionSequence','Item_1','LeafJawPositions');
                jawsy{j/2,1}=getfield(rtplan.BeamSequence,char(beams(i)),'ControlPointSequence',char(segments{i,1}{j,1}),'BeamLimitingDevicePositionSequence','Item_3','LeafJawPositions');
                mlc{j/2,1}=getfield(rtplan.BeamSequence,char(beams(i)),'ControlPointSequence',char(segments{i,1}{j,1}),'BeamLimitingDevicePositionSequence','Item_2','LeafJawPositions');
                %retrieve cumulative meterset weight (cumulative MUs delivered)
                cumulativemetersetweight{j/2,1}=getfield(rtplan.BeamSequence,char(beams(i)),'ControlPointSequence',char(segments{i,1}{j,1}),'CumulativeMetersetWeight');
                cumulativeweight{j/2,1}=beammeterset*cumulativemetersetweight{j/2,1}/finalcumulativemetersetweight;
                temp1(j/2)=beammeterset*cumulativemetersetweight{j/2,1}/finalcumulativemetersetweight;
            end
        end
    elseif ncoll == 2; % This is not an MLC plan set MLC leaves position to max allowed
        jawsx{1,1}=getfield(rtplan.BeamSequence,char(beams(i)),'ControlPointSequence',char(segments{i,1}{1,1}),'BeamLimitingDevicePositionSequence','Item_1','LeafJawPositions');
        jawsy{1,1}=getfield(rtplan.BeamSequence,char(beams(i)),'ControlPointSequence',char(segments{i,1}{1,1}),'BeamLimitingDevicePositionSequence','Item_2','LeafJawPositions');
        neg_mlc=[1:40]';neg_mlc(:)=-120;
        pos_mlc=[1:40]';pos_mlc(:)=120;
        mlc{1,1}=[neg_mlc;pos_mlc];
        % mlc{:}=0;
        %retrieve cumulative meterset weight (cumulative MUs delivered)
        cumulativemetersetweight{1,1}=getfield(rtplan.BeamSequence,char(beams(i)),'ControlPointSequence',char(segments{i,1}{1+1,1}),'CumulativeMetersetWeight');
        cumulativeweight{1,1}=beammeterset*cumulativemetersetweight{1,1}/finalcumulativemetersetweight;
        temp1(1)=beammeterset*cumulativemetersetweight{1,1}/finalcumulativemetersetweight;
    end
    temp2=diff(temp1);
    temp3=[temp1(1),temp2];
    for k=1:size(temp3,2);
        differentialweight{k,1}=temp3(k);
    end
    % 3c) store beam limiting device position
    rtplanformc{i,3}=[jawsx,jawsy];
    rtplanformc{i,4}=[mlc,differentialweight];
    clear differentialweight *cumulative* beammeterset mlc jawsy jawsx temp*
end
