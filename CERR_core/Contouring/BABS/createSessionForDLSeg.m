function fullSessionPath = createSessionForDLSeg(sessionPath,planC)
%Create session dir for DL segmentation
%
% AI 09/30/21

%% Create session directory for segmentation metadata
indexS = planC{end};
% Create temp. dir labelled by series UID, local time and date
if isfield(planC{indexS.scan}(1).scanInfo(1),'seriesInstanceUID') && ...
        ~isempty(planC{indexS.scan}(1).scanInfo(1).seriesInstanceUID)
    folderNam = planC{indexS.scan}(1).scanInfo(1).seriesInstanceUID;
else
    %folderNam = dicomuid;
    orgRoot = '1.3.6.1.4.1.9590.100.1.2';
    folderNamJava = javaMethod('createUID','org.dcm4che3.util.UIDUtils',orgRoot);
    folderNam = folderNamJava;
    %folderNam = folderNamJava.toCharArray';
end
dateTimeV = clock;
randNum = 1000.*rand;
sessionDir = ['session',folderNam,num2str(dateTimeV(4)), num2str(dateTimeV(5)),...
    num2str(dateTimeV(6)), num2str(randNum)];
fullSessionPath = fullfile(sessionPath,sessionDir);

end