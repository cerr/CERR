% screen_capture_to_qa
%
% This script loops over cerr files in individual patient directories under
% cerrFilesDir and writes images to imageSaveDir for QA.
%
% APA, 7/21/2022

cerrFilesDir = 'L:\Data\30GyHN_Lee_Dave\cerr_files';
imageSaveDir = 'L:\Data\30GyHN_Lee_Dave\qa_segs';

dirS = dir(cerrFilesDir);
dirS(1:2) = [];
toDeleteV = strncmpi({dirS.name},'.DS_Store',9);
dirS(toDeleteV) = [];

ptIdC = {dirS.name};
ptDirC = fullfile(cerrFilesDir,ptIdC);

numPats = length(ptDirC);

noStructC = {};

for i=1:numPats
    
    ptId = ptIdC{i};
    
    cerrDirForPat = ptDirC{i};    
    cerrDirS = dir(cerrDirForPat);
    cerrDirS([cerrDirS.isdir]) = [];
    fileNameC = {cerrDirS.name};
    plancFileNameC = fullfile(cerrDirForPat,fileNameC);
    
    numTimePts = length(plancFileNameC);
    for iFile = 1:numTimePts
        dirName = strtok(fileNameC{iFile},'.');
        fileNam = plancFileNameC{iFile};
                
        sliceCallBack('init')
        sliceCallBack('OPENNEWPLANC',fileNam)
        
        global planC stateS
        indexS = planC{end};
        
        numStructs = length(planC{indexS.structures});
        if numStructs == 0
            % Close plan
            force_close = true;
            sliceCallBack('CLOSEREQUEST',force_close)
            clear global stateS
            clear global planC   
            noStructC{end+1} = [ptId,'_',dirName];
            continue
        end
        structNum = 1;
        
        seriesNumber = planC{indexS.scan}(1).scanInfo(1).DICOMHeaders.SeriesNumber;
        
        % Focus on tumor x,y,z
        [xCtr,yCtr,zCtr] = calcIsocenter(structNum,'COM',planC);
        viewC = {};
        for iAxis = 1:length(stateS.handle.CERRAxis)
            viewC{iAxis} = getAxisInfo(stateS.handle.CERRAxis(iAxis),'view');
        end
        axialAx = strncmp(viewC,'transverse',10);
        sagAx = strncmp(viewC,'sagittal',8);
        corAx = strncmp(viewC,'coronal',7);
        setAxisInfo(stateS.handle.CERRAxis(axialAx), 'coord', zCtr);
        setAxisInfo(stateS.handle.CERRAxis(sagAx), 'coord', xCtr);
        setAxisInfo(stateS.handle.CERRAxis(corAx), 'coord', yCtr);
        CERRRefresh
        
        % Set display window to highlight tumor
        mask3M = getStrMask(structNum,planC);
        scanNum = getStructureAssociatedScan(structNum,planC);
        scanArray3M = single(planC{indexS.scan}(scanNum).scanArray) - ...
            planC{indexS.scan}(scanNum).scanInfo(1).CTOffset;
        scanV = scanArray3M(mask3M);
        windowCtr = median(scanV);
        windowWidth = quantile(scanV,0.95) - quantile(scanV,0.05);
        windowWidth = windowWidth * 2;
        scanUID = ['c',repSpaceHyp(planC{indexS.scan}(scanNum).scanUID(max(1,end-61):end))];
        stateS.scanStats.CTLevel.(scanUID) = windowCtr;        
        stateS.scanStats.CTWidth.(scanUID) = windowWidth; 
        stateS.scanStats.CTWidth.(scanUID) = max([0.1 stateS.scanStats.CTWidth.(scanUID)]);
        set(stateS.handle.CTLevel,'String',num2str(stateS.scanStats.CTLevel.(scanUID)))
        set(stateS.handle.CTWidth,'String',num2str(stateS.scanStats.CTWidth.(scanUID)))
        stateS.CTDisplayChanged = 1;        
        CERRRefresh
        
        % Screen capture figure        
        qaForPat = fullfile(imageSaveDir,ptId);
        if ~exist(qaForPat,'dir')
            mkdir(qaForPat)
        end
        saveFileName = fullfile(qaForPat,[dirName,'_',num2str(seriesNumber),'.png']);
        screencapture(stateS.handle.CERRSliceViewer,saveFileName)
        
        % Close plan
        force_close = true;
        sliceCallBack('CLOSEREQUEST',force_close)
        clear global stateS
        clear global planC
        
    end
    
end


