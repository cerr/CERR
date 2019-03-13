% batch_export_dvh_to_excel.m
%
% This script exports DVHs for the specified structure names to Excel.
%
% The binwidth to use for DVH calculation is defined in CERROptions.json.
%
% APA, 1/28/2019

% Directory containing CERR files
dirPath = 'path:\to\cerr\files';

% Output Excel file
xlSaveFile = 'path:\to\expoty\excel\dvh.xlsx';

% Names of structures to calculate and export DVHs
strC = {'Lungs_combined', 'Lung_L_combined', 'Lung_R_combined',...
    'Heart_combined', 'Outer_combined', 'Stomach_combined', 'PTV_combined'};


%Find all CERR files
fileC = {};
if strcmpi(dirPath,'\') || strcmpi(dirPath,'/')
    filesTmp = getCERRfiles(dirPath(1:end-1));
else
    filesTmp = getCERRfiles(dirPath);
end
fileC = [fileC filesTmp];

filesNotConvertedC = {};

pathStr = getCERRPath;
optName = [pathStr 'CERROptions.json'];
optS = opts4Exe(optName);

dvhC = {};

%Loop over CERR plans
for iFile = 1:length(fileC)
    
    planC = loadPlanC(fileC{iFile},tempdir);
    planC = quality_assure_planC(fileC{iFile},planC);
    planC = updatePlanFields(planC);
    indexS = planC{end};
    
    strNameC = {planC{indexS.structures}.structureName};
    
    for indStr = 1:length(strC)
                %DVH
                strNum = find(strcmpi(strC{indStr},strNameC));
                doseNum = length(planC{indexS.dose});
                if ~isempty(strNum)
                    [dosesV, volsV] = getDVH(strNum, doseNum, planC);
                    [doseBinsV, volsHistV] = doseHist(dosesV, volsV, optS.DVHBinWidth);
                    doseBinsV = doseBinsV * 100; % Gy to cGy
                    fVol = volsHistV;
                    dvhC{iFile,indStr} = [doseBinsV; fVol];
                else
                    dvhC{iFile,indStr} = [];
                end
    end
    
end

for iDvh = 1:size(dvhC,2)
    dvhM = [dvhC{:,iDvh}];
    doseHistV = unique(dvhM(1,:));
    dvhM = zeros(length(fileC),length(doseHistV));
    doseHistC{iDvh} = doseHistV;
    for iFile = 1:size(dvhC,1)
        if ~isempty(dvhC{iFile,iDvh})
            indMin = findnearest(doseHistV,min(dvhC{iFile,iDvh}(1,:)));
            indMax = findnearest(doseHistV,max(dvhC{iFile,iDvh}(1,:)));
            dvhM(iFile,indMin:indMax) = dvhC{iFile,iDvh}(2,:);
        end
    end
    dvhToWriteC{iDvh} = dvhM;
end

[~,namC] = cellfun(@fileparts,fileC,'UniformOutput',false);
for indStr = 1:length(strC)
    xlswrite(xlSaveFile,namC',strC{indStr},['A2:A',num2str(length(fileC)+1)])
    colEnd = xlsColNum2Str(length(doseHistC{indStr})+1);
    xlswrite(xlSaveFile,doseHistC{indStr},strC{indStr},...
        ['B1:',colEnd{1},'1'])
    colEnd = xlsColNum2Str(size(dvhToWriteC{indStr},2)+1);
    xlswrite(xlSaveFile,dvhToWriteC{indStr},strC{indStr},...
        ['B2:',colEnd{1},num2str(size(dvhToWriteC{indStr},1)+1)])
end

