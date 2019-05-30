function [countV,ktrAll,veAll,kepAll,vpAll] = runDCETofts(planC)
% runDCETofts.m
% Function to generate and write out DCE parameter maps, compute and save statistics to file.
%
% AI 5/26/16
% AI 7/06/16  Updated to provide option to scale AIF using reference region time course.
%
% Note: 
% Required parameters are read from user-input .txt file. 
% See ReadDCEParameterFile.m for list of valid input parameters.


%% --- Get model parameters --------

indexS = planC{end};

% Read input parameter file
[inputS,filePath] = ReadDCEParameterFile();
outPath = fileparts(filePath);
[paramS,shiftS] = getInputs(inputS);

% Get DCE scan no.
scanListC = unique({planC{indexS.scan}.scanType});
if numel(scanListC)>1
    [series,ok] = listdlg('ListString',scanListC,'Name','Select series','ListSize',[300,250],...
        'PromptString','Select DCE series','SelectionMode','Single');
    if ~ok
        return
    end
    scanNumV = find(strcmp({planC{indexS.scan}.scanType},scanListC{series}));
else
    scanNumV = 1:length(planC{indexS.scan});
end
scanS = planC{indexS.scan}(scanNumV);

%Extract relevant parameters from DICOM header 
headerS.manufacturer = scanS(1).scanInfo(1).DICOMHeaders.Manufacturer;
headerS.xSize = scanS(1).scanInfo(1).DICOMHeaders.Rows;
headerS.ySize = scanS(1).scanInfo(1).DICOMHeaders.Columns;
headerS.RepetitionTime = scanS(1).scanInfo(1).DICOMHeaders.RepetitionTime;
tDel = getTDel(planC);
headerS.tDel = double(tDel)/1000 ; % convert time step to seconds from ms
headerS.MagneticFieldStrength = scanS(1).scanInfo(1).DICOMHeaders.MagneticFieldStrength;
headerS.nSlices = size(scanS(1).scanArray,3);
FA = scanS(1).scanInfo(1).DICOMHeaders.FlipAngle;
headerS.FlipAngle = shiftS.FAF*FA; % correct flip angle by multiplicative factor FAF

switch(headerS.manufacturer)
    case 'GE MEDICAL SYSTEMS'
        totalImages = scanS(1).scanInfo(1).DICOMHeaders.ImagesinAcquisition;
        headerS.frames = totalImages/headerS.nSlices;
    case 'Philips Healthcare'
        headerS.frames = scanS(1).scanInfo(1).DICOMHeaders.NumberofTemporalPositions;
end
%Display:
fprintf(['\nVendor: %s\nNo. slices: %d\nNo. frames: %d\nTR(ms): %g\nDel_T(s): %g\n',...
    'Flip angle: %g\nImage Size(rows x cols): %d x %d\nB0: %g\n'],headerS.manufacturer,...
    headerS.nSlices,headerS.frames,headerS.RepetitionTime,headerS.tDel,...
    headerS.FlipAngle,headerS.xSize,headerS.ySize,headerS.MagneticFieldStrength);

%Time shift for ROI time course (user-input)
ROIPointShift = shiftS.TROIPointShift * strcmp(paramS.model,'T') + ...
    shiftS.ETROIPointShift * strcmp(paramS.model,'ET');
shiftS.ROIPointShift = ROIPointShift;

% r1  (Using relaxivities from Pintaske, et. al. Invest Radiol 2006) **
%     Gd-DTPA, 1.5T   =  3.9 L/(mmol x s)
%     Gd-DTPA, 3.0T   =  3.3 L/(mmol x s)
%     Gd-BOPTA (multihance) 1.5T  = 8.1 L/(mmol x s)
%     Gd-BOPTA (multihance) 3.0T = 6.3 L/(mmol x s)
r1 = 3.9*(headerS.MagneticFieldStrength < 2.0)*strcmp(paramS.cAgent,'gd')+ ...
     3.3*(headerS.MagneticFieldStrength > 2.0)*strcmp(paramS.cAgent,'gd') + ...
     8.1*(headerS.MagneticFieldStrength < 2.0)*strcmp(paramS.cAgent,'mh') + ...
     6.3*(headerS.MagneticFieldStrength > 2.0)*strcmp(paramS.cAgent,'mh');

%Vector of sampling times
ind = double(0:(headerS.frames-1)); 
tsec = ind*headerS.tDel;
tmin = tsec./60;         % ktrans, etc. are in /min.  Parker coefs are in  min or /min.
TR = headerS.RepetitionTime/1000;  % TR from DICOM header is in ms. Change to s.


% Parameter array for the concentrarion calculation: 
%    pCalcConc(1) = R1 = relaxivity of contrast agent (units are mmolxs)
%    pCalcConc(2) = TR (s)
%    pCalcConc(3) = flip angle (degrees)
%    pCalcConc(4) = pre-contrast T1 for tissue (s)
pCalcConc = [r1, TR, headerS.FlipAngle, paramS.T10];

%Generate AIF
%-------------temp:--------
coefFile = fullfile(getCERRPath,'PlanAnalysis','DCE-MR analysis','sample_param_and_coeff_files','Pros_Iliac_17pts_Parker_coefs.txt');
%---------------------------
fprintf('\n Generating AIF from Parker Coefficient file...');
AIFP = genAIF(tsec,coefFile,headerS.frames,tmin,paramS,shiftS);
fprintf('\n AIF generation complete.\n');

%If using T1 maps, load T1 maps for all slices into a 3D array
if ~(paramS.T1Map==0)
    T13M = getScanArray(paramS.T1Map,planC);
else
    T13M = [];
end

%% --------- Get ROI mask ---------------
%Identify structures associated with selected scan
structNumV = 1:length(planC{indexS.structures});
assocScansV = getStructureAssociatedScan(structNumV,planC);
structNumV = structNumV(ismember(assocScansV,scanNumV));
structS =  planC{indexS.structures}(structNumV);
emptyStructV = cellfun(@isempty,{structS.rasterSegments}); %Discard empty structures
structS =  structS(~emptyStructV);

%Extract mask
ROImask3M = true(size(scanS(1).scanArray));
structListC = cellfun(@lower,{structS.structureName},'un',0);
%User-selection of structure:
if numel(structListC)>1
    [strSel,ok] = listdlg('ListString',structListC,'Name','Select structure','ListSize',[300,250],...
        'PromptString','Select ROI','SelectionMode','Single');
    if ~ok
        return
    end
else
    strSel = 1;
end
strNum = structNumV(strSel);
rasterSegments = getRasterSegments(strNum,planC);
[temp,maskSlicesV] = rasterToMask(rasterSegments,1, planC);
ROImask3M(:,:,maskSlicesV) = temp;

%% ---- Concatenate DCE images ----------
sliceC = cell(1,maskSlicesV);
for k = 1:numel(maskSlicesV)
    timeSlices = arrayfun(@(x) x.scanArray(:,:,maskSlicesV(k)),scanS,'un',0);
    sliceC{k} = cat(3,timeSlices{:});
end
sliceTimeCourse4M = cat(4,sliceC{:}); 
%sliceTimeCourse4M = uint16(sliceTimeCourse4M);   %To match Kristen's code


%% ----- Scale AIF using reference region time course if reqd ----
% Get reference region (muscle) mask
useRefRegion = questdlg('Use muscle reference to scale AIF?','Reference region','Yes','No','No') ;
if strcmp(useRefRegion, 'No')
    AIFPScaled = AIFP;
else
    structListC = {structS.structureName};
    [strNum,ok] = listdlg('ListString',structListC,'SelectionMode','Single','Name','Select reference structure');
    if ~ok
        return
    end
    muscleRasterSegS = getRasterSegments(strNum,planC);
    [muscleMaskM,muscleROISlice] = rasterToMask(muscleRasterSegS,1, planC); %Assumed single-slice
    % Scale AIF using reference region time course
    muscleSliceC = arrayfun(@(x) x.scanArray(:,:,muscleROISlice),scanS,'un',0);
    muscleSliceTimeCourse3M  = cat(3,muscleSliceC{:});
    muscleTimeCourse3M = ROIMaskedSlices(muscleSliceTimeCourse3M,muscleMaskM);
    AIFPScaled = refRegionScale(AIFP,inputS,shiftS,filePath,headerS,muscleTimeCourse3M,muscleMaskM);
end


%% ---- Get parameter maps ----------
getVals = 'Yes';
nRuns = 1;
while(strcmp(getVals,'Yes'))
    if nRuns~=1                   %Runs with value from parameter file if checkShift='n' the first time
        shiftS.checkShift = 'y';  %Set checkShift to 'y' if user chooses to run again with different shift
        [countV,ktrAll,veAll,kepAll,vpAll,dceRsqAll,UserInShift,UserInBase] = getDCEToftsParams(paramS,shiftS,headerS.xSize,headerS.ySize,maskSlicesV,sliceTimeCourse4M,pCalcConc,...
            ROImask3M,T13M,tmin,AIFPScaled,outFolder);
    else
        [countV,ktrAll,veAll,kepAll,vpAll,dceRsqAll,UserInShift,UserInBase,outFolder] = getDCEToftsParams(paramS,shiftS,headerS,maskSlicesV,sliceTimeCourse4M,pCalcConc,...
            ROImask3M,T13M,tmin,AIFPScaled,outPath);
    end
    getVals = questdlg(sprintf('Current shift = %d.\n Run again with different shift?',UserInShift),...
        'Change shift?','Yes','No','No');
    nRuns = nRuns + 1;
end

%% ---Write user-input shifts to param file-------
fid = fopen(filePath);
inputC = textscan(fid, '%s %s %n','endofline','\r\n');
fclose(fid);
fieldsC = fieldnames(paramS);
if strcmp(paramS.model,'T') %Tofts
    shiftIdx = strcmp(fieldsC,'TROIPointShift');
else  %Extended tofts
    shiftIdx = strcmp(fieldsC,'ETROIPointShift');
end
baseIdx = strcmp(fieldsC,'basepts');
inputC{3}(shiftIdx) = UserInShift;
inputC{3}(baseIdx) = UserInBase;
fid = fopen(filePath,'w+');
fmt = '\r\n%s\t%s\t%d';
for lineNum = 1:size(inputC{1},1)
    col1 = inputC{1}(lineNum);
    col2 = inputC{2}(lineNum);
    col3 = inputC{3}(lineNum);
    fprintf(fid,fmt,col1{1},col2{1},col3);
end
fclose(fid);

%Write statistics 
writeStats(outFolder,outfileBase,paramS.model,paramS.cutOff,countV,ktrAll,veAll,kepAll,vpAll,dceRsqAll);


end

