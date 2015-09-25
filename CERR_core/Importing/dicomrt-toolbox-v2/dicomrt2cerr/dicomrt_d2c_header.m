function [headerInitS]=dicomrt_d2c_headers(headerInitS,plan)
% dicomrt_d2c_headers(planC,plan)
%
% Convert DICOM header information in CERR format
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

% Get DICOM-RT toolbox header
% LM DK check for change in data structure for importing dose fraction.
global dosetype

if strcmpi(dosetype,'FRACTION')
    plan_header=plan{1}{1,1}{1};
else    
    if size(plan{1,1},2)>1
        plan_header=plan{1,1}{1};
    else
        plan_header=plan{1};
    end
end

% Write CERR header
headerInitS(1).archive='';
headerInitS(1).tapeStandardNumber=3.2;
headerInitS(1).intercomparisonStandard='';
try
    headerInitS(1).institution=plan_header.InstitutionName;
catch
    headerInitS(1).institution='unknown';
end
headerInitS(1).dateCreated=plan_header.StudyDate;
try
    headerInitS(1).writer=plan_header.OperatorName.FamilyName;
catch
    headerInitS(1).writer='unknown';
end
    