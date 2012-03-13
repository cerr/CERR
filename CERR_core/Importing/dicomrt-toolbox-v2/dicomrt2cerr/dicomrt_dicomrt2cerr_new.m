function [planC] = dicomrt_dicomrt2cerr(plan,xmesh,ymesh,zmesh,ct,ct_xmesh,ct_ymesh,ct_zmesh,voi,optName)
% dicomrt_dicomrt2CERR(dose,xmesh,ymesh,zmesh,ct,ct_xmesh,ct_ymesh,ct_zmesh,voi)
%
% Convert DICOMRT-TOOLBOX data in CERR format .
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

% Check number of argument and set-up some parameters and variables
error(nargchk(9,10,nargin))

if exist('optName')==0
    disp('dicomrt_dicomrt2cerr: option filename not provided, using ''CERROptions.m'' as default');
    optName='CERROptions.m';
end

%Create CERR data Container & templates for certain cells.
planInitC       = initializeCERR;
indexS          = planInitC{end};
headerInitS     = planInitC{indexS.header};
commentInitS    = planInitC{indexS.comment};
scanInitS       = initializeScanInfo;
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
else
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
        [tmp_str,tags]=dicomrt_d2c_voi(structureInitS,indexS,newvoi,ct_xmesh,ct_ymesh,ct_zmesh,tags);
        disp('(=) Conversion DICOM structures completed.');
        
    else
        % Conversion
        disp('(+) Converting DICOM structures');
        [tmp_str,tags]=dicomrt_d2c_voi(structureInitS,indexS,voi,ct_xmesh,ct_ymesh,ct_zmesh,tags);
        disp('(=) Conversion DICOM structures completed.');
    end
else
    disp('(=) RTSTRUCT not available.');
end

if isempty(plan)==0
    % Convert beam geometry
    disp('(+) Converting DICOM beam geometry');
    [tmp_beam,tags]=dicomrt_d2c_beam(beamDataInitS,indexS,plan,tags);
    disp('(=) Conversion DICOM beam geometry completed.');
end

% Convert digital films
nfilms=0;

if isempty(plan)==0
    % Convert dose
    disp('(+) Converting DICOM dose');
    [tmp_dose,tags]=dicomrt_d2c_dose(doseInitS,indexS,plan,xmesh,ymesh,zmesh,tags);
    disp('(=) Conversion DICOM dose completed.');
end

% Convert DVH

% Convert seed geometry

% Store header info
planC{indexS.header} = headerInitS;

if isempty(plan)==0
    % Store beams
    planC{indexS.beamData}=tmp_beam;
    % Store dose
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
    planC =  getDSHPoints(planC, indexS, optS);
end

if isempty(ct)==0
    % Create uniformized datasets
    planC=dicomrt_d2c_uniformizescan(planC,optS);
end

% Save plan
save_planC(planC,optS);