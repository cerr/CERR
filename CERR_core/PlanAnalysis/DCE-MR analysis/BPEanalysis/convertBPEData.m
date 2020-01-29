function convertBPEData(xlsFile,outPath)
% convertBPEData.m
% Function to import T1, T1 FS-pre, T1 FS_post sequences for BPE analysis from paths in spreadsheet 
%
% iyera@mskcc.org  5/4/18
%--------------------------------------------------------------------------


%% Read spreadsheet
[~,~,X] = xlsread(xlsFile,1);
X = X(2:end,:);

convertedC = {};
planNameC = {};

%% Import images to CERR
init_ML_DICOM;
for n = 1:size(X,1)
    outname = num2str(X{n,1});
    selDirC = {X{n,2},X{n,3},X{n,4}};
    try
        for k = 1:length(selDirC)
            hWaitbar = waitbar(0,'Scanning Directory Please wait...');
            sourceDir = selDirC{k};
            temp(k) = scandir_mldcm(sourceDir, hWaitbar, 1);
            patient.PATIENT(k) = temp(k).PATIENT;
            close(hWaitbar);
        end
        for j = 1:length(patient.PATIENT)
            dcmdirS.(['patient_' num2str(j)]) = patient.PATIENT(j);
        end
        patNameC = fieldnames(dcmdirS);
        selected = 'all';
        if strcmpi(selected,'all')
            combinedDcmdirS = struct('STUDY',dcmdirS.(patNameC{1}).STUDY,'info',dcmdirS.(patNameC{1}).info);
            for i = 2:length(patNameC)
                for j = 1:length(dcmdirS.(patNameC{i}).STUDY.SERIES)
                    combinedDcmdirS.STUDY.SERIES(end+1) = dcmdirS.(patNameC{i}).STUDY.SERIES(j);
                end
            end
            % Pass the java dicom structures to function to create CERR plan
            planC = dcmdir2planC(combinedDcmdirS,'no');
        else
            planC = dcmdir2planC(patient.PATIENT);
        end
        
        %% Save to CERR files
        saved_fullFileName = fullfile(outPath,[outname,'.mat']);
        save_planC(planC,[], 'passed', saved_fullFileName);
        convertedC{end+1} = sprintf('%0.8s',outname);
        planNameC{end+1} = saved_fullFileName;
        
    catch e
        
        convertedC{end+1} = sprintf('%0.8d',outname);
        planNameC{end+1} = ['Failed with error ', e.message];
        
    end
    
    clear planC
    
end

%% Book-keeping
for i=1:length(convertedC)
    xlswrite(fullfile(outPath,'batch_convert_results.xls'),{convertedC{i}},'Sheet1',['A',num2str(i)])
    xlswrite(fullfile(outPath,'batch_convert_results.xls'),{planNameC{i}},'Sheet1',['B',num2str(i)])
end



end