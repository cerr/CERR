function [rtplanforvarian] = dicomrt_VarianExport(case_study)
% dicomrt_VarianExport(case_study)
%
% Export MLC settings to Varian MLC file.
%
% Plan data is provided with case_study imported with dicomrt_loaddose or dicominfo
%
% See also dicomrt_loaddose, dicominfo
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

% Check case
if iscell(case_study) == 1 % this should be an rtplan cell array loaded with dicomrt_loaddose
    rtplan=case_study{1,1};
elseif isstruct(case_study) == 1 % this should be an rtplan structure loaded with dicominfo
    rtplan=case_study;
end


% 0) Set-up parameters
file_rev='G';
treatment='Dynamic Dose';
tolerance=0.50;
carriage_group=1;
operator='matlab_es';
note=0;
shape=0;
magnification=1.0;
nleaves=80;

% 1) retrieve patients data
first_name=getfield(rtplan.PatientName,'GivenName');
last_name=getfield(rtplan.PatientName,'FamilyName');

patientID=getfield(rtplan,'PatientID');

% 1a) retrieve number of beams and create a cell matrix which will contain 
%    the relevant plan parameters

beams=fieldnames(rtplan.BeamSequence);
nbeams=size(beams,1);

% 1b) For each beam retreive needed info and write to file

for i=1:nbeams
    
    collimatorangle=getfield(rtplan.BeamSequence,char(beams(i)),...
        'ControlPointSequence','Item_1','BeamLimitingDeviceAngle');
    segments=fieldnames(getfield(rtplan.BeamSequence,char(beams(i)),...
        'ControlPointSequence'));
    nsegments=size(segments,1);
    finalcumulativemetersetweight=getfield(rtplan.BeamSequence,char(beams(i)),'FinalCumulativeMetersetWeight');

    % 1c) Open Varian MLC file and write header information
    filename=[inputname(1),'_b',int2str(i),'.mlc'];
    varianfile=fopen(filename,'w');

    fprintf(varianfile,'File Rev = '); fprintf(varianfile,file_rev); fprintf(varianfile,'\n');
    fprintf(varianfile,'Treatment = '); fprintf(varianfile,treatment); fprintf(varianfile,'\n');
    fprintf(varianfile,'Last Name = '); fprintf(varianfile,last_name); fprintf(varianfile,'\n');
    fprintf(varianfile,'First Name = '); fprintf(varianfile,first_name); fprintf(varianfile,'\n');
    fprintf(varianfile,'Patient ID = '); fprintf(varianfile,patientID); fprintf(varianfile,'\n');
    fprintf(varianfile,'Number of Fields = '); fprintf(varianfile,'%2i',nsegments); fprintf(varianfile,'\n');
    fprintf(varianfile,'Number of Leaves = '); fprintf(varianfile,'%3i',nleaves); fprintf(varianfile,'\n');
    fprintf(varianfile,'Tolerance = '); fprintf(varianfile,'%6.4f',tolerance); fprintf(varianfile,'\n');

    for j=1:nsegments
        % retrieve beam limiting device position
        mlc_iec=getfield(rtplan.BeamSequence,char(beams(i)),'ControlPointSequence', ...
            char(segments{j,1}),'BeamLimitingDevicePositionSequence','Item_2','LeafJawPositions');
        %retrieve cumulative meterset weight (cumulative MUs delivered)
        cumulativemetersetweight=getfield(rtplan.BeamSequence,char(beams(i)), ...
            'ControlPointSequence',char(segments{j,1}),'CumulativeMetersetWeight');
        index=cumulativemetersetweight/finalcumulativemetersetweight;
        % Export data to Varian MLC file
        fprintf(varianfile,'\n');
        fprintf(varianfile,'Field = '); fprintf(varianfile,'%3i',j); fprintf(varianfile,'\n');
        fprintf(varianfile,'Index = '); fprintf(varianfile,'%6.4f',index); fprintf(varianfile,'\n');
        fprintf(varianfile,'Carriage Group = '); fprintf(varianfile,'%3i',carriage_group); fprintf(varianfile,'\n');
        fprintf(varianfile,'Operator = '); fprintf(varianfile,operator); fprintf(varianfile,'\n');
        fprintf(varianfile,'Collimator = '); fprintf(varianfile,'%6.4f',collimatorangle); fprintf(varianfile,'\n');
        
        bleaf=-flipdim(mlc_iec(1:40),1)*0.1;
        aleaf=flipdim(mlc_iec(41:80),1)*0.1;
        
        for k=1:length(mlc_iec)/2;
            kk = length(mlc_iec)/2 + 1 - k;    %leaf positions need to be reversed
            fprintf(varianfile,'Leaf '); fprintf(varianfile,'%2i',k); 
            fprintf(varianfile,'A = '); fprintf(varianfile,'%6.4f',aleaf(kk)); fprintf(varianfile,'\n');
        end
        for k=1:length(mlc_iec)/2;
            kk = length(mlc_iec)/2 + 1 - k;    %leaf positions need to be reversed
            fprintf(varianfile,'Leaf '); fprintf(varianfile,'%2i',k); 
            fprintf(varianfile,'B = '); fprintf(varianfile,'%6.4f',bleaf(kk)); fprintf(varianfile,'\n');
        end
        fprintf(varianfile,'Note = '); fprintf(varianfile,'%3i',note); fprintf(varianfile,'\n');
        fprintf(varianfile,'Shape = '); fprintf(varianfile,'%3i',shape); fprintf(varianfile,'\n');
        fprintf(varianfile,'Magnification = '); fprintf(varianfile,'%6.4f',magnification); fprintf(varianfile,'\n');
    end
    fclose(varianfile);
end