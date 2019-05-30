function [countV,ktransAll,veAll,kepAll,vpAll] = calcToftsFit(planC)
% Function to generate and write out DCE parameter maps, compute and save statistics to file.
% AI 5/26/16
% AI 7/06/16  Updated to provide option to scale AIF using reference region time course.
% AI 9/08/16  Removed philips scaling by SS to match Kristen's code.
% ------------------------------------------------------------------------------------------------
% INPUTS
% planC : Patient CERR file.
%         This function uses CERR structures if available.
%         Alternatively, user can select DICOM mask files.
%         Masks/ROIs are assumed to be on sequential slices (slStart to slEnd).
%
% Patient parameters are read from user-selected .txt file.
% For a list of valid input parameters, see ReadDCEParameterFile.m
% -------------------------------------------------------------------------------------------------

%% Get inputs

% Get CERR archive
if nargin==0
    [fname,fpath] = uigetfile('*.mat');
    fprintf('\n Loading patient CERR file ....\n');
    load(fullfile(fpath,fname));
    fprintf('\n Load complete.\n');
end
indexS = planC{end};
% Get parameter file input
paramDir = fullfile(getCERRPath,'PlanAnalysis','DCE-MR analysis','sample_param_and_coeff_files');
[inputS,filePath] = ReadDCEParameterFile(paramDir);
outPath = fileparts(filePath);
[paramS,shiftS] = getInputs(inputS);
% Get DCE scan set when multiple series' are available
planD = planC; 
scanListC = unique({planD{indexS.scan}.scanType});
if numel(scanListC)>1
    [series,ok] = listdlg('ListString',scanListC,'Name','Select series','ListSize',[300,250],...
        'PromptString','Select DCE series','SelectionMode','Single');
    if ~ok
        return
    end
    scanNumV = strcmp({planD{indexS.scan}.scanType},scanListC{series});
    planD{indexS.scan} = planD{indexS.scan}(scanNumV);
    %Keep structures associated with selected scan
    structNumV = ismember([planD{indexS.structures}.associatedScan],find(scanNumV));
    planD{indexS.structures} =  planD{indexS.structures}(structNumV);
    %Discard empty structures
    emptyStructV = cellfun(@isempty,{planD{indexS.structures}.rasterSegments});
    planD{indexS.structures} =  planD{indexS.structures}(~emptyStructV);
end

%% Display select header info
headerS.manufacturer = planD{indexS.scan}(1).scanInfo(1).DICOMHeaders.Manufacturer;
headerS.xSize = planD{indexS.scan}(1).scanInfo(1).DICOMHeaders.Rows;
headerS.ySize = planD{indexS.scan}(1).scanInfo(1).DICOMHeaders.Columns;
headerS.TRms = planD{indexS.scan}(1).scanInfo(1).DICOMHeaders.RepetitionTime;
tDel = getTDel(planD);
headerS.tDel = double(tDel)/1000 ;                                       % convert time step to seconds from ms
headerS.B0 = planD{indexS.scan}(1).scanInfo(1).DICOMHeaders.MagneticFieldStrength;
headerS.nSlices = size(planD{indexS.scan}(1).scanArray,3);
FA = planD{indexS.scan}(1).scanInfo(1).DICOMHeaders.FlipAngle;
headerS.FA = shiftS.FAF*FA;                                              % correct flip angle by multiplicative factor FAF
if isfield(paramS,'outfileBase')
    outfileBase = paramS.outfileBase;
else
    outfileBase = '';
end

%Get no. frames
switch(headerS.manufacturer)
    case 'GE MEDICAL SYSTEMS'
        userSel = questdlg('Manufacturer: GE MEDICAL SYSTEMS','Scanner check','Continue','Cancel');
        if strcmp(userSel,'Cancel')
            return;
        end
        totalImages = planD{indexS.scan}(1).scanInfo(1).DICOMHeaders.ImagesinAcquisition;
        headerS.frames = totalImages/headerS.nSlices;
    case 'Philips Healthcare'
        headerS.frames = planD{indexS.scan}(1).scanInfo(1).DICOMHeaders.NumberofTemporalPositions;
end

fprintf(['\nVendor: %s\nNo. slices: %d\nNo. frames: %d\nTR(ms): %g\nDel_T(s): %g\n',...
    'Flip angle: %g\nImage Size(rows x cols): %d x %d\nB0: %g\n'],headerS.manufacturer,...
    headerS.nSlices,headerS.frames,headerS.TRms,headerS.tDel,headerS.FA,headerS.xSize,headerS.ySize,headerS.B0);

%% Compute model parameters
% ** Time shift for ROI time course (from input) **
ROIPointShift = shiftS.TROIPointShift * strcmp(paramS.model,'T') + ...
    shiftS.ETROIPointShift * strcmp(paramS.model,'ET');
shiftS.ROIPointShift = ROIPointShift;
% ** r1  (Using relaxivities from Pintaske, et. al. Invest Radiol 2006) **
%     Gd-DTPA, 1.5T   =  3.9 L/(mmol x s)
%     Gd-DTPA, 3.0T   =  3.3 L/(mmol x s)
%     Gd-BOPTA (multihance) 1.5T  = 8.1 L/(mmol x s)
%     Gd-BOPTA (multihance) 3.0T = 6.3 L/(mmol x s)

r1 = 3.9*(headerS.B0 < 2.0)*strcmp(paramS.cAgent,'gd')+ 3.3*(headerS.B0 > 2.0)*strcmp(paramS.cAgent,'gd') + ...
    8.1*(headerS.B0 < 2.0)*strcmp(paramS.cAgent,'mh') + 6.3*(headerS.B0 > 2.0)*strcmp(paramS.cAgent,'mh');
r1 = r1(1);           

%** Vector of sampling times (1 x frames size) **
ind = double(0:(headerS.frames-1));                      % ind: vector with elements 0,1,2,3...AIF_frames-1
tsec = ind*headerS.tDel;
tmin = tsec./60;                                         % ktrans, etc. are in /min.  Parker coefs are in  min or /min.
TR = headerS.TRms/1000;                                  % TR from DICOM header is in ms. Change to s.

%**  Parameter array for the concentrarion calculation: 
%    pCalcConc(1) = R1 = relaxivity of contrast agent (units are mmolxs)
%    pCalcConc(2) = TR (s)
%    pCalcConc(3) = flip angle (degrees)
%    pCalcConc(4) = pre-contrast T1 for tissue (s)
pCalcConc = [r1, TR, headerS.FA, paramS.T10];

%** Get Parker coefficient file **
[coefFile, fPath] = uigetfile([paramDir '/*.txt'],'Select coefficient file');
coefFile = fullfile(fPath,coefFile);

%% Get 3D mask
mask3M = ones(size(planD{indexS.scan}(1).scanArray));
roiSlicesV = [];
%if strcmp (paramS.maskSource,'MM') % Use CERR ROI (for Kristen)
structListC = cellfun(@lower,{planD{indexS.structures}.structureName},'un',0);
%---- For Kristen Zakian ---
%To Skip reference structures (labeled 'muscle') :
isMuscleC = strfind(structListC,'muscle');
strIdxC = cellfun(@isempty,isMuscleC,'un',0);
strNumV = find([strIdxC{:}]);
structListC = structListC(strNumV);
%--------------------------------
if numel(structListC)>1
    [strSel,ok] = listdlg('ListString',structListC,'Name','Select structure','ListSize',[300,250],...
        'PromptString','Select structure','SelectionMode','Single');
    if ~ok
        return
    end
else
    strSel = 1;
end
strNumV = strNumV(strSel);
structListC = structListC(strSel);
for l  = 1:length(structListC)
    rasterSegments = getRasterSegments(strNumV(l),planD);
    maskSlices = unique(rasterSegments(:,6));
    mask3M(:,:,maskSlices) = rasterToMask(rasterSegments,1, planD);
    roiSlicesV = [roiSlicesV;maskSlices];
end
% For Kristen (to use DICOM masks )
%else
%     % Get mask from file
%     [maskName,maskPathname] = getMaskFiles(paramS.slStart,pathBase);
%     maskFileS = dir([maskPathname,maskName,'*']);
%     numMasks = paramS.slEnd-paramS.slStart+1;
%     readMasks3M = zeros(headerS.xSize,headerS.ySize,numMasks);
%     for k = 1:numMasks
%         readMasks3M(:,:,k) = dicomread(fullfile(maskPathname,maskFileS(k).name));
%     end
%     %Get corresponding cerr file slice nos
%     [~,sliceNoV] = sort([planD{indexS.scan}(1).scanInfo.imageNumber]);
%     roiSlicesV = sliceNoV(paramS.slStart:paramS.slEnd);
%     mask3M(:,:,roiSlicesV) = readMasks3M;
%     % Copy to planD object
%     planD = maskToCERRStructure(mask3M, 0, 1, 'Imported structure', planD);
%     roiSlicesV = sort(roiSlicesV);
%end
%fprintf('ROIslices: %d',roiSlicesV);
paramS.slStart = roiSlicesV(1);
paramS.slEnd = roiSlicesV(end);
workSlices = paramS.slEnd-paramS.slStart+1;

%If using T1 maps, load T1 maps for all slices into a 3D array
if strcmp(paramS.T1Map , 'y')
    T13M = getT1Maps(headerS.xSize, headerS.ySize, headerS.nSlices, paramS.slStart, workSlices);
else
    T13M = [];
end

%% Read scans grouped by slice location & time point
sliceC = cell(1,workSlices);
infoC = cell(1,workSlices);
for k = 1:workSlices
    timeSlices = arrayfun(@(x) x.scanArray(:,:,roiSlicesV(k)),planD{indexS.scan},'un',0); 
    sliceC{k} = cat(3,timeSlices{:});
    infoC{k} = planD{indexS.scan}(1).scanInfo(roiSlicesV(k)).DICOMHeaders;
end
if isfield(planD{indexS.scan}(1).scanInfo(1),'scaleSlope') & ~isempty(planD{indexS.scan}(1).scanInfo(1).scaleSlope)
    scaleSlope = planD{indexS.scan}(1).scanInfo(1).scaleSlope;
else
    scaleSlope = 1;
end
sliceTimeCourse4M = cat(4,sliceC{:});
sliceTimeCourse4M = sliceTimeCourse4M *scaleSlope; %To match Kristen's code
sliceTimeCourse4M = uint16(sliceTimeCourse4M);     %To match Kristen's code

%% Generate AIFP
fprintf('\n Generating AIF from Parker Coefficient file...');
AIFP = genAIF(tsec,coefFile,headerS.frames,tmin,paramS,shiftS);
fprintf('\n AIF generation complete.\n');


%% Get reference region (muscle) mask

useRefRegion = questdlg('Use muscle reference to scale AIF?','Reference region','Yes','No','No') ;

if strcmp(useRefRegion, 'No')
    AIFPScaled = AIFP;
else
    %if strcmp (paramS.refMaskSource,'MM') %For Kristen
    structListC = {planD{indexS.structures}.structureName};
    [strNum,ok] = listdlg('ListString',structListC,'SelectionMode','Single',...
                  'PromptString','Select reference structure');
    if ~ok
        return
    end
    muscleRasterSegS = getRasterSegments(strNum,planD);
    [muscleMaskM,muscleROISlice] = rasterToMask(muscleRasterSegS,1, planD);
    %     else
    %         %For Kristen: to read DICOM masks
    %         [refMaskName,refMaskPath] = uigetfile('.dcm','Select muscle mask file');
    %         slNum = strfind(refMaskName,'_SL');
    %         muscleROISlice = str2num(refMaskName(slNum+3:slNum+4));
    %         muscleMaskM = dicomread(fullfile(refMaskPath,refMaskName));
    %         %Copy reference region mask to CERR plan
    %         refMask3M  = zeros(size(planD{indexS.scan}(1).scanArray));
    %         muscleROISlice = sliceNoV(muscleROISlice);
    %         refMask3M(:,:,muscleROISlice) = muscleMaskM;
    %         planD = maskToCERRStructure(refMask3M, 0, 1, 'Muscle', planD);
    %     end
    % Scale AIF using reference region time course
    muscleSliceC = arrayfun(@(x) x.scanArray(:,:,muscleROISlice),planD{indexS.scan},'un',0);
    muscleSliceTimeCourse3M  = cat(3,muscleSliceC{:});
    muscleTimeCourse3M = ROIMaskedSlices(muscleSliceTimeCourse3M,muscleMaskM);
    AIFPScaled = refRegionScale(AIFP,inputS,shiftS,filePath,headerS,muscleTimeCourse3M,muscleMaskM);
end


%% Write DICOM Maps to file
getVals = 'Yes';
nRuns = 1;
while(strcmp(getVals,'Yes'))
    if nRuns~=1                %Runs with value from parameter file if checkShift='n' the first time
     shiftS.checkShift = 'y';  %Automatically set checkShift to 'y' if user chooses to run again with different shift
     [countV,ktransAll,veAll,kepAll,vpAll,dceRsqAll,UserInShift,UserInBase] = ...
     getDCEToftsParams(paramS,shiftS,headerS,roiSlicesV,sliceTimeCourse4M,pCalcConc,...
     mask3M,T13M,tmin,AIFPScaled,outFolder);
    else
     [countV,ktransAll,veAll,kepAll,vpAll,dceRsqAll,UserInShift,UserInBase,outFolder] = ...
     getDCEToftsParams(paramS,shiftS,headerS,roiSlicesV,sliceTimeCourse4M,pCalcConc,...
     mask3M,T13M,tmin,AIFPScaled,outPath);
    end
    getVals = questdlg(sprintf('Current shift = %d.\n Run again with different shift?',UserInShift),...
        'Change shift?','Yes','No','No');
    nRuns = nRuns + 1;
end


%% Store shifts to file
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



%% Write statistics to file
keepIdx = dceRsqAll> paramS.cutOff;
ktransAll(~keepIdx) = 0; 
veAll(~keepIdx) = 0;
kepAll(~keepIdx) = 0;
vpAll(~keepIdx) = 0;
writeStats(outFolder,outfileBase,paramS.model,paramS.cutOff,countV,ktransAll,veAll,kepAll,vpAll);

ktransAll(ktransAll==100) = nan;
ktransAll(~keepIdx) = nan;
veAll(veAll==100) = nan;
veAll(~keepIdx) = nan;
kepAll(kepAll==100) = nan;
kepAll(~keepIdx) = nan;
vpAll(vpAll==100) = nan;
vpAll(~keepIdx) = nan;


end

