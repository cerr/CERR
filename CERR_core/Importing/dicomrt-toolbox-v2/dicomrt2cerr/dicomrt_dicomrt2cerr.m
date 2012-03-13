function [planC] = dicomrt_dicomrt2cerr(plan,xmesh,ymesh,zmesh,ct,ct_xmesh,ct_ymesh,ct_zmesh,voi,optName,MRCell,PETCell,SPECTCell)
% dicomrt_dicomrt2CERR(dose,xmesh,ymesh,zmesh,ct,ct_xmesh,ct_ymesh,ct_zmesh,voi)
%
% Convert DICOMRT-TOOLBOX data in CERR format .
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org)
%
% LM DK merging doses and beam information incase there are more than one


% Check number of argument and set-up some parameters and variables

error(nargchk(9,13,nargin))

if exist('optName')==0
    optName='CERROptions.m';
end

%Create CERR data Container & templates for certain cells.
planInitC       = initializeCERR;
indexS          = planInitC{end};
headerInitS     = planInitC{indexS.header};
commentInitS    = planInitC{indexS.comment};
scanInitS       = planInitC{indexS.scan};
structureInitS  = planInitC{indexS.structures};
beamsInitS      = planInitC{indexS.beams};
doseInitS       = planInitC{indexS.dose};

tagMapS = initTagMapS;
tags = dicomrt_d2c_rtogtags;

% Load options
optS=opts4Exe(optName);

% Initialize planC
planC = planInitC;
nCells = length(planInitC);
tags.nimages = 0;

% NOTE that conversion sequence is important and must be retained
%

% Convert header
disp('(+) Converting DICOM headers');
if isempty(plan)==0
    headerInitS=dicomrt_d2c_header(headerInitS,plan);
    disp('(+) Fetching data from RTPLAN');
elseif isempty(plan)==1 & isempty(ct)==0
    headerInitS=dicomrt_d2c_header(headerInitS,ct);
    disp('(+) Fetching data from CT scan');
elseif ~isempty(voi)
    headerInitS=dicomrt_d2c_header(headerInitS,voi);
    disp('(+) Fetching data from RTSTRUCT');
end
disp('(=) Conversion DICOM headers completed.');

% Convert comments
% commentInitS

% Convert scans
if isempty(ct)==0
    disp('(+) Converting DICOM scans');
    [tmp_scan,tags]=dicomrt_d2c_scan(scanInitS,indexS,ct,ct_xmesh,ct_ymesh,ct_zmesh,tags);
    disp('(=) Conversion DICOM scans completed.');
else
    disp('(=) CT scan not available.');
    tmp_scan = scanInitS;
end

% Validating and converting structures
% Validation
if isempty(voi)==0
    voitype=dicomrt_checkvoitype(voi);
    if isequal(voitype,'3D')
        voi=dicomrt_3dto2dVOI(voi);
    end

    if isempty(ct)==0
        disp('(+) Fitting DICOM structures to CT scans to comply with RTOG format');
        voi=dicomrt_fitvoi2ct(voi,ct_zmesh,ct);
        disp('(=) Fitting DICOM structures completed.');

        disp('(+) Validating DICOM structures');
        [voi]=dicomrt_validatevoi(voi,ct_xmesh,ct_ymesh,ct_zmesh);
        [newvoi]=dicomrt_closevoi(voi);
        disp('(=) Validation DICOM structures completed.');

        % Conversion
        disp('(+) Converting DICOM structures');
        %         names = fieldnames(structureInitS);
        %         if length(structureInitS) == 0 & ~isempty(names)
        %             structureInitS(1).(names{1}) = deal([]);
        %         end
        [tmp_str,tags]=dicomrt_d2c_voi(structureInitS,indexS,newvoi,ct_xmesh,ct_ymesh,ct_zmesh,tags,tmp_scan.scanUID);
        disp('(=) Conversion DICOM structures completed.');

    else
        % Conversion
        disp('(+) Converting DICOM structures');
        %         names = fieldnames(structureInitS);
        %         if length(structureInitS) == 0 & ~isempty(names)
        %             structureInitS(1).(names{1}) = deal([]);
        %         end
        [tmp_str,tags]=dicomrt_d2c_voi(structureInitS,indexS,voi,ct_xmesh,ct_ymesh,ct_zmesh,tags,tmp_scan.scanUID);
        disp('(=) Conversion DICOM structures completed.');
    end
else
    disp('(=) RTSTRUCT not available.');
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% DK
global dosetype;

if isempty(plan)==0
    if strcmpi(dosetype,'fraction')
        try
            beams=fieldnames(plan{1,1}{1}{1}.BeamSequence);
        catch
            warning('Beam Sequence not present in RTPLAN !');
        end
    else
        try
            try
                beams=fieldnames(plan{2,1}.BeamSequence);
            catch
                beams=fieldnames(plan{1}{1}.BeamSequence);
            end
        catch
            warning('Beam Sequence not present in RTPLAN !');
        end
    end
end

if exist('beams')==1
    % Convert beam geometry
    disp('(+) Converting DICOM beam geometry');
    %     names = fieldnames(beamsInitS);
    %     if length(beamsInitS) == 0 & ~isempty(names)
    %         beamsInitS(1).(names{1}) = deal([]);
    %     end
    if strcmpi(dosetype,'fraction')
        planSiz = length(plan);
        if planSiz == 1
            [tmp_beam,tags]=dicomrt_d2c_beam(beamsInitS,indexS,plan{1},tags);
        else
            for i = 1:planSiz(end)
                if i == 1
                [tmp_beam,tags]=dicomrt_d2c_beam(beamsInitS,indexS,plan{i},tags);
                else
                [tmp_beam1,tags]=dicomrt_d2c_beam(beamsInitS,indexS,plan{i},tags);    
                tmp_beam = dissimilarInsert(tmp_beam,tmp_beam1); % insert new dose intp planC
                end                
            end
        end
    else
        [tmp_beam,tags]=dicomrt_d2c_beam(beamsInitS,indexS,plan,tags);
        disp('(=) Conversion DICOM beam geometry completed.');
    end
else
    warning('Beam Sequence not present in RTPLAN !');
end

% Convert digital films
nfilms=0;
if isempty(plan)==0 & strcmpi(dosetype,'fraction')
    disp('(+) Converting DICOM dose fraction');
    planSiz = size(plan);
    for i = 1:planSiz(end)
        if i == 1
            [tmp_dose,tags]=dicomrt_d2c_dose(doseInitS,indexS,plan{i},xmesh{i},ymesh{i},zmesh{i},tags,tmp_scan.scanUID);
        else
            disp('(+) Converting DICOM dose fraction');
            [tmp_dose1,tags]=dicomrt_d2c_dose(doseInitS,indexS,plan{i},xmesh{i},ymesh{i},zmesh{i},tags,tmp_scan.scanUID);
            tmp_dose = dissimilarInsert(tmp_dose,tmp_dose1); % insert new dose intp planC
        end
    end
elseif isempty(plan)==0 & ~strcmpi(dosetype,'fraction') & isempty(plan{2,1})==0
    % Convert dose
    disp('(+) Converting DICOM dose');
    %     names = fieldnames(doseInitS);
    %     if length(doseInitS) == 0 & ~isempty(names)
    %         doseInitS(1).(names{1}) = deal([]);
    %     end
    [tmp_dose,tags]=dicomrt_d2c_dose(doseInitS,indexS,plan,xmesh,ymesh,zmesh,tags,tmp_scan.scanUID);
    disp('(=) Conversion DICOM dose completed.');
else
    disp('(=) RTDOSE not available');
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% end DK
% Convert DVH
% Convert seed geometry
% Convert MR
if ~isempty(MRCell)
    tmp_MR = dicomrt_d2c_MR(initializeMRInfo,MRCell);
end

% Convert PET
if ~isempty(PETCell)
    tmp_PET  = dicomrt_d2c_PET(initializePETInfo, PETCell);
end

if ~isempty(SPECTCell)
    tmp_SPECT = dicomrt_d2c_SPECT(initializeSPECTInfo, SPECTCell);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%Populate planC fields %%%%%%%%%%%%%%%%%%%%%%%%%%
% Store header info
planC{indexS.header} = headerInitS;

if isempty(plan)==0 & exist('beams')==1 & exist('tmp_dose')==1
    % Store beams
    planC{indexS.beams}=tmp_beam;
    % Store dose
    planC{indexS.dose}=tmp_dose;
elseif isempty(plan)==0 & exist('beams')==1 & exist('tmp_dose')==0
    % Store beams only
    planC{indexS.beams}=tmp_beam;
elseif isempty(plan)==0 & exist('beams')==0 &  exist('tmp_dose')==1
    % Store dose only
    planC{indexS.dose}=tmp_dose;
end

if isempty(ct)==0
    % Store scan
    planC{indexS.scan}=tmp_scan;
end

if isempty(voi)==0
    % Store structures
    planC{indexS.structures}=tmp_str;
end

% Store options and indexS
planC{indexS.CERROptions} = optS;
planC{indexS.indexS} = indexS;

% Post processing actions

if isempty(ct)==0
    % Determine voxel thicknesses
    planC=dicomrt_d2c_setVoxelThicknesses(planC,indexS);
end

if isempty(ct)==0 & isempty(voi)==0
    % Get structure scan segments
    planC =  getRasterSegs(planC, optS);

    % Get any dose surface points
    planC =  getDSHPoints(planC,optS);
end

if isempty(ct)==0
    % Create uniformized datasets
    flagVOI = isempty(voi);
    planC=dicomrt_d2c_uniformizescan(planC,optS,flagVOI);
end

if ~isempty(MRCell)
    planC{indexS.scan}= dissimilarInsert(planC{indexS.scan},tmp_MR);
end

if ~isempty(PETCell)
    planC{indexS.scan} = dissimilarInsert(planC{indexS.scan},tmp_PET);
end

if ~isempty(SPECTCell)
    planC{indexS.scan} = dissimilarInsert(planC{indexS.scan},tmp_SPECT);
end

% Set UID's for Scan, Dose and Structures
planC = guessPlanUID(planC);