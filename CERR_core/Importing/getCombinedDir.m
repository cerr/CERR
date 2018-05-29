function combinedDcmdirS = getCombinedDir(srcDir)

%hWaitbar = waitbar(0,'Scanning Directory Please wait...');
hWaitbar = NaN;
patient = scandir_mldcm(srcDir, hWaitbar, 1);
%close(hWaitbar);
dcmdirS = struct(['patient_' num2str(1)],patient.PATIENT(1));
for j = 2:length(patient.PATIENT)
    dcmdirS.(['patient_' num2str(j)]) = patient.PATIENT(j);
end
patNameC = fieldnames(dcmdirS);
selected = 'all';
combinedDcmdirS = struct('STUDY',dcmdirS.(patNameC{1}).STUDY,'info',dcmdirS.(patNameC{1}).info);
if strcmpi(selected,'all')
    combinedDcmdirS = struct('STUDY',dcmdirS.(patNameC{1}).STUDY,'info',dcmdirS.(patNameC{1}).info);
    for i = 2:length(patNameC)
        for j = 1:length(dcmdirS.(patNameC{i}).STUDY.SERIES)
            combinedDcmdirS.STUDY.SERIES(end+1) = dcmdirS.(patNameC{i}).STUDY.SERIES(j);
        end
    end
    
    
end


end