function AIFPScaled = refRegionScale(AIFP,inputS,shiftS,paramFile,headerS,muscleTimeCourse3M,muscleMaskM)
% Function to pull muscle time course from ROI mask & convert to concentration
% Loads average AIF for the study (or individual), runs Tofts fit over range of AIF amplitudes
% to find AIF amplitude that gives Tofts fit ve = 0.1 for Muscle time course data.
% Returns this AIF time course.
% 
% Kristen Zakian
% AI 7/06/16
% AI 7/21/16  Updated to write ROI signal shift to parameter file
 

% Get parameters
T10Muscle_ms = inputS.T10ref;             
TRms = headerS.TRms;
tDel = headerS.tDel ;
FA = headerS.FA;
frames = headerS.frames;
r1 = 3.9*(headerS.B0 < 2.0)*strcmp(inputS.cAgent,'gd')+ 3.3*(headerS.B0 > 2.0)*strcmp(inputS.cAgent,'gd') + ...
    8.1*(headerS.B0 < 2.0)*strcmp(inputS.cAgent,'mh') + 6.3*(headerS.B0 > 2.0)*strcmp(inputS.cAgent,'mh');

% Generate vector of sampling times  (1 x frames size)
ind = 0:(frames-1);                 
tsec = double(ind)*tDel;
tmin = tsec./60.;                      %ktrans, etc. are in /min.  Parker coefs are in min or /min.  Tofts fit will use minutes.


% Generate an average time course for the muscle ROI from the slice
avgROISigV = zeros(1,20);
for t = 1:frames
    muscleMaskSum = sum(muscleTimeCourse3M(:,:,t));
    avgROISigV(t) = sum(muscleMaskSum(:))/nnz(muscleMaskM);         % avg of masked elements
end

%  Display for deciding muscle ROI point shift. Must be shifted to zero for Tofts fit

%Plot the Muscle ROI time course
figTitle = 'Start of muscle time course';
figure ('Name', figTitle);
plot (tmin,avgROISigV,'-d');
pause(2);

%Pass AIFAmp from parameter file if available
%(AIFAmp is the value that gives ve < 0.1)
useValue = 'No';
shiftC = fieldnames(shiftS);
shiftIn = any(strcmp(shiftC,'muscleShift'));
if shiftIn
    if ~isempty(shiftS.muscleShift)
        aShiftIn = shiftS.muscleShift;
        useValue = questdlg(sprintf('Use value from parameter file:\n muscleShift = %g ?',aShiftIn),...
            'AIF scaling','Yes','No','Yes');
    end
end

if strcmp(useValue,'No')
    aShift = input('\nInput the muscle point shift (e.g. 2, to shift left 2 points):   ');
    %Store shift to parameter file
    fid = fopen(paramFile);
    inputC = textscan(fid, '%s %s %n','endofline','\r\n');
    fmt = '\r\n%s\t%s\t%d';
    fclose(fid);
    if shiftIn
        shiftIdx = strcmp (inputC{1},'muscleShift');
        inputC{3}(shiftIdx) = aShift;
        fid = fopen(paramFile,'w+');
        for lineNum = 1:size(inputC{1},1)
            col1 = inputC{1}(lineNum);
            col2 = inputC{2}(lineNum);
            col3 = inputC{3}(lineNum);
            fprintf(fid,fmt,col1{1},col2{1},col3);
        end
        fclose(fid);
    else
        fid = fopen(paramFile,'a');
        newEntryC = {'muscleShift','na',aShift};
        fprintf(fid,fmt,newEntryC{:});
        fclose(fid);
    end
else
    aShift = aShiftIn;
end
close(gcf);
muscleShiftV = circshift(avgROISigV', -aShift);
rawMuscleSigV = muscleShiftV';
shiftRawMuscleSigV = rawMuscleSigV(frames-aShift-8:frames-aShift);
meanRawMuscle = mean(shiftRawMuscleSigV(:));
rawMuscleSigV(frames-aShift+1:frames)= meanRawMuscle;
baseptsMuscle = aShift-1; % set number of baseline points = number of shifted points -1

% Display unshifted and shifted aif curve
figtitle = ['Muscle time course unshifted and shifted. Shift = ',num2str(aShift)];
figure ('Name', figtitle);
plot (tmin,avgROISigV,tmin,rawMuscleSigV,'--');
pause(4);
close(gcf);

% Convert ROI average time course to Concentration
% (need muscle pre-contrast T1 and average baseline value S0)
TR = TRms/1000.;                    %(TR in DICOM header is in ms. Change to s)
T10 = T10Muscle_ms/1000;
base = avgROISigV(1:baseptsMuscle); % baseline signal value obtained from time course BEFORE SHIFT
s0 = mean(base);
pCalcConcMuscle = [r1, TR, FA, T10];
muscleConcTCourseV = calcConc(rawMuscleSigV,pCalcConcMuscle,s0);
figtitle = ('Muscle concentration time course ');
figure ('Name', figtitle);
plot (tmin,muscleConcTCourseV);
pause(1);
close(gcf);

%  Fit muscle time course to Tofts model until ve = 0.1.
%Start with average AIF.
%Vary the amplitude of the average AIF until you get a ve of 0.1.
%That will then be the AIF that you use.

inputsC = fieldnames(inputS);                         %Pass AIFAmp from parameter file if available
if any(strcmp(inputsC,'AIFAmp'))                      %(AIFAmp is the value that gives ve < 0.1)
    if ~isempty(inputS.AIFAmp)
        AIFPScaled = refRegionToftsAIFScale(tmin,AIFP,muscleConcTCourseV,paramFile,inputS.AIFAmp);
    end
else
    AIFPScaled = refRegionToftsAIFScale(tmin,AIFP,muscleConcTCourseV,paramFile);
end
%Display figure
figtitle = 'AIF plasma and AIF scaled ';
figure ('Name', figtitle);
plot (tmin,AIFP,tmin,AIFPScaled,'--');
pause(1);
close(gcf);

end

