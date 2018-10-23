function planAnonC = anonCERRplanC(planC)
% function planAnonC = initializeAnonCERR(planC)
%
% Defines the anonymous planC data structure by calling various functions 
% that define its anonymous elements.
% 
% APA, 1/10/2018

% Define anonymous Scan data structure
anonScanS = defineAnonScan();

% Define anonymous Dose data structure
anonDoseS = defineAnonDose();

% Define anonymous Structure data structure
anonStructuresS = defineAnonStructures();

% Define anonymous structureArray data structure
anonStructureArrayS = defineAnonStructurearray();

% Define anonymous structureArrayMore data structure
anonStructureArrayMoreS = defineAnonStructurearraymore();

% Define anonymous Header data structure
anonHeaderS = defineAnonHeader();

% Define anonymous Comment data structure
anonCommentS = defineAnonComment();

% Define anonymous Beams data structure
anonBeamsS = defineAnonBeams();

% Define anonymous BeamGeometry data structure
anonBeamGeometryS = defineAnonBeamgeometry();

% Define anonymous DVH data structure
anonDVHS = defineAnonDvh();

% Define anonymous IVH data structure
anonIVHS = defineAnonIvh();

% Define anonymous PlanParam data structure
anonPlanParamS = defineAnonPlanparam();

% Define anonymous SeedGeometry data structure
anonSeedGeometryS = defineAnonSeedgeometry();

% Define anonymous DigitalFilm data structure
anonDigitalFilmS = defineAnonDigitalfilm();

% Define anonymous RTTreatment data structure
% anonRTTreatmentS = defineAnonRTTreatment();

% Define anonymous IM data structure
anonIMS = defineAnonIm();

% Define anonymous GSPS data structure
anonGSPSS = defineAnonGsps();

% Define anonymous Deform data structure
anonDeform = defineAnonDeform();

% Define anonymous Registration data structure
anonRegistration = defineAnonRegistration();

% Define anonymous FeatureSet data structure
anonFeatureSet = defineAnonFeatureset();

% Define anonymous ImportLog data structure
anonImportLog = defineAnonImportlog();

% Define anonymous SegmentLabel data structure
anonSegmentLabel = defineAnonSegmentlabel();

% Define anonymous CERROptions data structure
anonCERROptions = defineAnonCerroptions();

% Define anonymous IndexS data structure
% anonindexS = defineAnonIndexS();


% Anonymize planC elements according the defined anonymization
indexS = planC{end};
fieldC = fieldnames(indexS);
numPlanCFields = length(fieldC);
planAnonC = cell(1,numPlanCFields);
for i = 1:numPlanCFields
    fieldNam = fieldC{i};
    fileFieldNam = fieldNam;
    fileFieldNam = lower(fileFieldNam);
    fileFieldNam(1) = upper(fileFieldNam(1));
    disp(strcat('Anonymizing ', fieldNam))
    % Add element to planAnonC if its anonymization is defined.
    if exist(strcat('defineAnon', fileFieldNam),'file')
        planAnonC{indexS.(fieldNam)} = anonymizeCERRdataStruct(...
            planC{indexS.(fieldNam)}, eval(strcat('defineAnon', fileFieldNam)));            
    end
end
planAnonC{end} = indexS;
